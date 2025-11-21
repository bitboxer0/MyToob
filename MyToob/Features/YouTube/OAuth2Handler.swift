//
//  OAuth2Handler.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import AuthenticationServices
import Combine
import Foundation
import os

/// Handles Google OAuth 2.0 authentication flow for YouTube Data API access.
///
/// **Security:**
/// - Uses ASWebAuthenticationSession (native macOS authentication UI)
/// - Requests minimal scope: `https://www.googleapis.com/auth/youtube.readonly`
/// - Stores tokens in Keychain with hardware-backed encryption
/// - Never stores OAuth credentials in code (uses Configuration enum)
///
/// **OAuth Flow:**
/// 1. User triggers authentication
/// 2. Present ASWebAuthenticationSession with Google authorization URL
/// 3. User authorizes in Google's UI
/// 4. Google redirects to custom URL scheme with authorization code
/// 5. Exchange code for access token + refresh token
/// 6. Store tokens in Keychain
///
/// Usage:
/// ```swift
/// do {
///   try await OAuth2Handler.shared.authenticate()
///   // Tokens now stored in Keychain
/// } catch OAuth2Error.userCancelled {
///   // User cancelled authorization
/// } catch {
///   // Handle other errors
/// }
/// ```
@MainActor
final class OAuth2Handler: NSObject, ObservableObject {
  /// Shared singleton instance
  static let shared = OAuth2Handler()

  /// OAuth authentication state
  @Published private(set) var isAuthenticated: Bool = false

  /// OAuth authentication session (retained during flow)
  private var authSession: ASWebAuthenticationSession?

  // MARK: - Constants

  private enum Endpoints {
    static let authorization = "https://accounts.google.com/o/oauth2/v2/auth"
    static let token = "https://oauth2.googleapis.com/token"
  }

  private enum Scope {
    static let youtubeReadonly = "https://www.googleapis.com/auth/youtube.readonly"
  }

  private enum KeychainKeys {
    static let accessToken = "youtube_access_token"
    static let refreshToken = "youtube_refresh_token"
    static let tokenExpiry = "youtube_token_expiry"
  }

  // MARK: - Initialization

  private override init() {
    super.init()
    // Check if we have valid tokens on init
    self.isAuthenticated = hasValidTokens()
  }

  // MARK: - Public API

  /// Authenticate user with Google OAuth 2.0
  /// - Throws: OAuth2Error if authentication fails or user cancels
  func authenticate() async throws {
    LoggingService.shared.network.info("Starting OAuth 2.0 authentication flow")

    // Build authorization URL
    guard let authURL = buildAuthorizationURL() else {
      throw OAuth2Error.invalidConfiguration
    }

    // Get authorization code from user
    let authCode = try await requestAuthorizationCode(authURL: authURL)

    // Exchange code for tokens
    try await exchangeCodeForTokens(authorizationCode: authCode)

    isAuthenticated = true
    LoggingService.shared.network.info("OAuth 2.0 authentication succeeded")
  }

  /// Sign out (delete stored tokens)
  func signOut() throws {
    LoggingService.shared.network.info("Signing out, deleting OAuth tokens")

    try? KeychainService.shared.delete(forKey: KeychainKeys.accessToken)
    try? KeychainService.shared.delete(forKey: KeychainKeys.refreshToken)
    try? KeychainService.shared.delete(forKey: KeychainKeys.tokenExpiry)

    isAuthenticated = false
  }

  /// Get valid access token (refreshes if expired)
  /// - Returns: Valid access token
  /// - Throws: OAuth2Error if token refresh fails
  func getAccessToken() async throws -> String {
    // Check if current token is valid
    if let token = try? KeychainService.shared.retrieve(forKey: KeychainKeys.accessToken),
      !isTokenExpired() {
      return token
    }

    // Token expired, refresh it
    try await refreshAccessToken()

    // Return refreshed token
    guard let token = try? KeychainService.shared.retrieve(forKey: KeychainKeys.accessToken) else {
      throw OAuth2Error.tokenRetrievalFailed
    }

    return token
  }

  // MARK: - Private Methods

  /// Build Google OAuth authorization URL
  private func buildAuthorizationURL() -> URL? {
    var components = URLComponents(string: Endpoints.authorization)

    components?.queryItems = [
      URLQueryItem(name: "client_id", value: Configuration.googleOAuthClientID),
      URLQueryItem(name: "redirect_uri", value: Configuration.googleOAuthRedirectURI),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "scope", value: Scope.youtubeReadonly),
      URLQueryItem(name: "access_type", value: "offline"),  // Request refresh token
      URLQueryItem(name: "prompt", value: "consent"),  // Always show consent screen
    ]

    return components?.url
  }

  /// Request authorization code from user via ASWebAuthenticationSession
  private func requestAuthorizationCode(authURL: URL) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(
        url: authURL,
        callbackURLScheme: extractScheme(from: Configuration.googleOAuthRedirectURI)
      ) { callbackURL, error in
        if let error = error {
          // Check if user cancelled
          let nsError = error as NSError
          if nsError.domain == ASWebAuthenticationSessionErrorDomain,
            nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
            LoggingService.shared.network.info("User cancelled OAuth authorization")
            continuation.resume(throwing: OAuth2Error.userCancelled)
          } else {
            LoggingService.shared.network.error(
              "OAuth authorization failed: \(error.localizedDescription, privacy: .public)"
            )
            continuation.resume(throwing: OAuth2Error.authorizationFailed(error))
          }
          return
        }

        guard let callbackURL = callbackURL else {
          continuation.resume(throwing: OAuth2Error.invalidCallback)
          return
        }

        // Extract authorization code from callback URL
        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
          .queryItems?
          .first(where: { $0.name == "code" })?
          .value
        else {
          continuation.resume(throwing: OAuth2Error.authorizationCodeMissing)
          return
        }

        continuation.resume(returning: code)
      }

      session.presentationContextProvider = self
      self.authSession = session

      guard session.start() else {
        continuation.resume(throwing: OAuth2Error.sessionStartFailed)
        return
      }
    }
  }

  /// Exchange authorization code for access token and refresh token
  private func exchangeCodeForTokens(authorizationCode: String) async throws {
    guard let tokenURL = URL(string: Endpoints.token) else {
      throw OAuth2Error.invalidConfiguration
    }

    var request = URLRequest(url: tokenURL)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let bodyParams = [
      "code": authorizationCode,
      "client_id": Configuration.googleOAuthClientID,
      "client_secret": Configuration.googleOAuthClientSecret,
      "redirect_uri": Configuration.googleOAuthRedirectURI,
      "grant_type": "authorization_code",
    ]

    request.httpBody = bodyParams
      .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
      .joined(separator: "&")
      .data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw OAuth2Error.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      LoggingService.shared.network.error(
        "Token exchange failed: HTTP \(httpResponse.statusCode, privacy: .public)"
      )
      throw OAuth2Error.tokenExchangeFailed(statusCode: httpResponse.statusCode)
    }

    // Parse token response
    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

    // Store tokens in Keychain
    try KeychainService.shared.save(value: tokenResponse.accessToken, forKey: KeychainKeys.accessToken)

    if let refreshToken = tokenResponse.refreshToken {
      try KeychainService.shared.save(value: refreshToken, forKey: KeychainKeys.refreshToken)
    }

    // Store token expiry time
    let expiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
    let expiryString = ISO8601DateFormatter().string(from: expiryDate)
    try KeychainService.shared.save(value: expiryString, forKey: KeychainKeys.tokenExpiry)

    LoggingService.shared.network.debug("OAuth tokens stored in Keychain")
  }

  /// Refresh access token using refresh token
  private func refreshAccessToken() async throws {
    guard let refreshToken = try? KeychainService.shared.retrieve(forKey: KeychainKeys.refreshToken) else {
      throw OAuth2Error.refreshTokenMissing
    }

    guard let tokenURL = URL(string: Endpoints.token) else {
      throw OAuth2Error.invalidConfiguration
    }

    var request = URLRequest(url: tokenURL)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let bodyParams = [
      "refresh_token": refreshToken,
      "client_id": Configuration.googleOAuthClientID,
      "client_secret": Configuration.googleOAuthClientSecret,
      "grant_type": "refresh_token",
    ]

    request.httpBody = bodyParams
      .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
      .joined(separator: "&")
      .data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw OAuth2Error.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      LoggingService.shared.network.error(
        "Token refresh failed: HTTP \(httpResponse.statusCode, privacy: .public)"
      )
      throw OAuth2Error.tokenRefreshFailed(statusCode: httpResponse.statusCode)
    }

    // Parse token response (refresh only returns new access token)
    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

    // Update access token
    try KeychainService.shared.update(value: tokenResponse.accessToken, forKey: KeychainKeys.accessToken)

    // Update expiry time
    let expiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
    let expiryString = ISO8601DateFormatter().string(from: expiryDate)
    try KeychainService.shared.update(value: expiryString, forKey: KeychainKeys.tokenExpiry)

    LoggingService.shared.network.debug("Access token refreshed")
  }

  /// Check if tokens exist and are valid
  private func hasValidTokens() -> Bool {
    guard KeychainService.shared.exists(forKey: KeychainKeys.accessToken),
      KeychainService.shared.exists(forKey: KeychainKeys.refreshToken)
    else {
      return false
    }

    return !isTokenExpired()
  }

  /// Check if access token is expired
  private func isTokenExpired() -> Bool {
    guard let expiryString = try? KeychainService.shared.retrieve(forKey: KeychainKeys.tokenExpiry),
      let expiryDate = ISO8601DateFormatter().date(from: expiryString)
    else {
      return true
    }

    // Consider expired if less than 5 minutes remaining
    return expiryDate.timeIntervalSinceNow < 300
  }

  /// Extract URL scheme from redirect URI
  private func extractScheme(from uri: String) -> String? {
    guard let colonIndex = uri.firstIndex(of: ":") else { return nil }
    return String(uri[..<colonIndex])
  }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OAuth2Handler: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    // Return the key window, or first window, or create a new one if none exist
    if let keyWindow = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
      return keyWindow
    }
    if let firstWindow = NSApplication.shared.windows.first {
      return firstWindow
    }
    // Fallback: create a new window (should never happen in normal app lifecycle)
    return NSWindow()
  }
}

// MARK: - TokenResponse

/// OAuth token response from Google
private struct TokenResponse: Codable {
  let accessToken: String
  let expiresIn: Int
  let refreshToken: String?
  let scope: String?
  let tokenType: String

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case expiresIn = "expires_in"
    case refreshToken = "refresh_token"
    case scope
    case tokenType = "token_type"
  }
}

// MARK: - OAuth2Error

/// Errors that can occur during OAuth 2.0 flow
enum OAuth2Error: LocalizedError {
  case invalidConfiguration
  case sessionStartFailed
  case userCancelled
  case authorizationFailed(Error)
  case invalidCallback
  case authorizationCodeMissing
  case invalidResponse
  case tokenExchangeFailed(statusCode: Int)
  case tokenRefreshFailed(statusCode: Int)
  case refreshTokenMissing
  case tokenRetrievalFailed

  var errorDescription: String? {
    switch self {
    case .invalidConfiguration:
      return "OAuth configuration is invalid. Check GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET."
    case .sessionStartFailed:
      return "Failed to start authentication session."
    case .userCancelled:
      return "Authorization was cancelled."
    case .authorizationFailed(let error):
      return "Authorization failed: \(error.localizedDescription)"
    case .invalidCallback:
      return "Invalid callback URL received."
    case .authorizationCodeMissing:
      return "Authorization code missing from callback."
    case .invalidResponse:
      return "Invalid response from authorization server."
    case .tokenExchangeFailed(let statusCode):
      return "Token exchange failed with HTTP \(statusCode)."
    case .tokenRefreshFailed(let statusCode):
      return "Token refresh failed with HTTP \(statusCode)."
    case .refreshTokenMissing:
      return "Refresh token not found. Please sign in again."
    case .tokenRetrievalFailed:
      return "Failed to retrieve access token from Keychain."
    }
  }
}

//
//  Configuration.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import Foundation
import OSLog

/// Centralized configuration management for app settings and credentials.
///
/// **Security Note:** OAuth credentials are loaded from environment variables
/// or a `.env` file (excluded from version control). Never hardcode secrets.
///
/// Usage:
/// ```swift
/// let clientID = Configuration.googleOAuthClientID
/// let clientSecret = Configuration.googleOAuthClientSecret
/// ```
enum Configuration {
  // MARK: - CloudKit Configuration

  /// CloudKit container identifier for iCloud sync.
  /// Format: iCloud.{bundle-identifier}
  /// Registered in Apple Developer portal and Xcode capabilities.
  static let cloudKitContainerIdentifier = "iCloud.finley.MyToob"

  /// Whether CloudKit sync is enabled.
  /// Default: false (requires paid Apple Developer account and entitlement configuration)
  /// Set CLOUDKIT_SYNC_ENABLED=true in environment to enable after configuring entitlements.
  /// When disabled, app uses local-only storage without iCloud sync.
  static var cloudKitSyncEnabled: Bool {
    // Check environment override
    if let value = getValue(for: "CLOUDKIT_SYNC_ENABLED") {
      return value.lowercased() == "true"
    }
    // Default to disabled until entitlements are configured
    return false
  }

  // MARK: - Google OAuth Credentials

  /// Google OAuth 2.0 Client ID
  /// Set via GOOGLE_OAUTH_CLIENT_ID environment variable or .env file
  static var googleOAuthClientID: String {
    guard let clientID = getValue(for: "GOOGLE_OAUTH_CLIENT_ID"), !clientID.isEmpty else {
      LoggingService.shared.app.fault("GOOGLE_OAUTH_CLIENT_ID not configured")
      fatalError("Missing GOOGLE_OAUTH_CLIENT_ID. See README for setup instructions.")
    }
    return clientID
  }

  /// Google OAuth 2.0 Client Secret
  /// Set via GOOGLE_OAUTH_CLIENT_SECRET environment variable or .env file
  static var googleOAuthClientSecret: String {
    guard let clientSecret = getValue(for: "GOOGLE_OAUTH_CLIENT_SECRET"), !clientSecret.isEmpty else {
      LoggingService.shared.app.fault("GOOGLE_OAUTH_CLIENT_SECRET not configured")
      fatalError("Missing GOOGLE_OAUTH_CLIENT_SECRET. See README for setup instructions.")
    }
    return clientSecret
  }

  /// Google OAuth 2.0 redirect URI (custom URL scheme for macOS app)
  static var googleOAuthRedirectURI: String {
    // Automatically construct redirect URI from Client ID
    // Extract the identifier part before .apps.googleusercontent.com
    let clientID = googleOAuthClientID

    // Client ID format: 123456-abc.apps.googleusercontent.com
    // We want: com.googleusercontent.apps.123456-abc:/oauth2redirect
    if let identifier = clientID.split(separator: ".").first {
      return "com.googleusercontent.apps.\(identifier):/oauth2redirect"
    }

    // Fallback (should never happen if Client ID is valid)
    LoggingService.shared.app.fault("Failed to construct redirect URI from Client ID")
    fatalError("Invalid GOOGLE_OAUTH_CLIENT_ID format. Expected format: xxxxx.apps.googleusercontent.com")
  }

  // MARK: - Private Helpers

  /// Load value from environment or .env file
  private static func getValue(for key: String) -> String? {
    // First try process environment
    if let value = ProcessInfo.processInfo.environment[key] {
      return value
    }

    // Then try .env file in project root
    if let envValue = loadFromEnvFile(key: key) {
      return envValue
    }

    return nil
  }

  /// Load value from .env file
  private static func loadFromEnvFile(key: String) -> String? {
    // Try multiple locations for .env file
    let possiblePaths = [
      // 1. PROJECT_DIR environment variable (if set by Xcode scheme)
      ProcessInfo.processInfo.environment["PROJECT_DIR"].map { "\($0)/.env" },

      // 2. Current working directory (when running from Xcode)
      FileManager.default.currentDirectoryPath + "/.env",

      // 3. Parent directories (traverse up from app bundle)
      Bundle.main.bundleURL.deletingLastPathComponent().path + "/.env",
      Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().path + "/.env",
      Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path + "/.env",

      // 4. Hardcoded for development (adjust if needed)
      "/Users/danielfinley/projects/App Projects/MyToob/MyToob/.env",
    ].compactMap { $0 }

    for envPath in possiblePaths {
      guard let envContents = try? String(contentsOfFile: envPath, encoding: .utf8) else {
        continue
      }

      // Parse .env file (KEY=VALUE format)
      let lines = envContents.components(separatedBy: .newlines)
      for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Skip comments and empty lines
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

        let parts = trimmed.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { continue }

        let envKey = parts[0].trimmingCharacters(in: .whitespaces)
        let envValue = parts[1].trimmingCharacters(in: .whitespaces)
          .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))  // Remove quotes

        if envKey == key {
          return envValue
        }
      }
    }

    return nil
  }
}

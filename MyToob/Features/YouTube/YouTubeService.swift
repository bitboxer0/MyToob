//
//  YouTubeService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

import Foundation
import os

/// Service for interacting with YouTube Data API v3
///
/// **Authentication:**
/// - Uses OAuth 2.0 access tokens from OAuth2Handler
/// - Automatically refreshes tokens via OAuth2Handler.getAccessToken()
///
/// **Error Handling:**
/// - 401 Unauthorized → Token refresh triggered automatically
/// - 403 Quota Exceeded → Throws quotaExceeded error
/// - 429 Rate Limited → Throws rateLimitExceeded error
/// - 5xx Server Errors → Throws serverError with status code
///
/// **Quota Management:**
/// - search.list: 100 units
/// - videos.list: 1 unit
/// - channels.list: 1 unit
/// - playlists.list: 1 unit
/// - playlistItems.list: 1 unit
/// - subscriptions.list: 1 unit
///
/// Usage:
/// ```swift
/// let service = YouTubeService.shared
/// let results = try await service.searchVideos(query: "SwiftUI", maxResults: 10)
/// ```
final class YouTubeService {
  // MARK: - Singleton

  static let shared = YouTubeService()

  // MARK: - Properties

  private let baseURL = "https://www.googleapis.com/youtube/v3"
  private let session: URLSession
  private let jsonDecoder: JSONDecoder

  // MARK: - Initialization

  private init() {
    // Configure URLSession with default settings
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    self.session = URLSession(configuration: config)

    // Configure JSONDecoder
    self.jsonDecoder = JSONDecoder()
    self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
  }

  // MARK: - Search API

  /// Search for videos using YouTube Data API search.list endpoint
  /// - Parameters:
  ///   - query: Search query string
  ///   - maxResults: Maximum number of results (1-50, default: 25)
  ///   - pageToken: Page token for pagination
  /// - Returns: Search response with video results
  /// - Throws: YouTubeAPIError if request fails
  func searchVideos(
    query: String,
    maxResults: Int = 25,
    pageToken: String? = nil
  ) async throws -> YouTubeSearchResponse {
    var queryItems = [
      URLQueryItem(name: "part", value: "snippet"),
      URLQueryItem(name: "type", value: "video"),
      URLQueryItem(name: "q", value: query),
      URLQueryItem(name: "maxResults", value: "\(min(maxResults, 50))"),
    ]

    if let pageToken = pageToken {
      queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
    }

    LoggingService.shared.network.info(
      "YouTube API: Searching videos with query '\(query, privacy: .public)'"
    )

    return try await makeRequest(
      endpoint: "search",
      queryItems: queryItems
    )
  }

  // MARK: - Videos API

  /// Fetch detailed video information by video IDs
  /// - Parameters:
  ///   - videoIDs: Array of video IDs (max 50)
  ///   - parts: Parts to include (snippet, contentDetails, statistics, etc.)
  /// - Returns: Array of video details
  /// - Throws: YouTubeAPIError if request fails
  func fetchVideoDetails(
    videoIDs: [String],
    parts: [String] = ["snippet", "contentDetails", "statistics"]
  ) async throws -> [YouTubeVideo] {
    guard !videoIDs.isEmpty else {
      LoggingService.shared.network.warning("fetchVideoDetails called with empty videoIDs array")
      return []
    }

    let ids = videoIDs.prefix(50).joined(separator: ",")

    let queryItems = [
      URLQueryItem(name: "part", value: parts.joined(separator: ",")),
      URLQueryItem(name: "id", value: ids),
    ]

    LoggingService.shared.network.info(
      "YouTube API: Fetching details for \(videoIDs.count, privacy: .public) video(s)"
    )

    let response: YouTubeVideoListResponse = try await makeRequest(
      endpoint: "videos",
      queryItems: queryItems
    )

    return response.items
  }

  // MARK: - Channels API

  /// Fetch channel information by channel ID
  /// - Parameters:
  ///   - channelID: YouTube channel ID
  ///   - parts: Parts to include (snippet, statistics, contentDetails, etc.)
  /// - Returns: Channel information
  /// - Throws: YouTubeAPIError if request fails or channel not found
  func fetchChannelInfo(
    channelID: String,
    parts: [String] = ["snippet", "statistics", "contentDetails"]
  ) async throws -> YouTubeChannel {
    let queryItems = [
      URLQueryItem(name: "part", value: parts.joined(separator: ",")),
      URLQueryItem(name: "id", value: channelID),
    ]

    LoggingService.shared.network.info(
      "YouTube API: Fetching channel info for ID '\(channelID, privacy: .private)'"
    )

    let response: YouTubeChannelResponse = try await makeRequest(
      endpoint: "channels",
      queryItems: queryItems
    )

    guard let channel = response.items.first else {
      throw YouTubeAPIError.channelNotFound(channelID: channelID)
    }

    return channel
  }

  // MARK: - Playlists API

  /// Fetch playlists for a channel
  /// - Parameters:
  ///   - channelID: YouTube channel ID
  ///   - maxResults: Maximum number of results (default: 25)
  ///   - pageToken: Page token for pagination
  /// - Returns: Playlist response
  /// - Throws: YouTubeAPIError if request fails
  func fetchPlaylists(
    channelID: String,
    maxResults: Int = 25,
    pageToken: String? = nil
  ) async throws -> YouTubePlaylistResponse {
    var queryItems = [
      URLQueryItem(name: "part", value: "snippet,contentDetails"),
      URLQueryItem(name: "channelId", value: channelID),
      URLQueryItem(name: "maxResults", value: "\(min(maxResults, 50))"),
    ]

    if let pageToken = pageToken {
      queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
    }

    LoggingService.shared.network.info(
      "YouTube API: Fetching playlists for channel '\(channelID, privacy: .private)'"
    )

    return try await makeRequest(
      endpoint: "playlists",
      queryItems: queryItems
    )
  }

  /// Fetch items in a playlist
  /// - Parameters:
  ///   - playlistID: YouTube playlist ID
  ///   - maxResults: Maximum number of results (default: 50)
  ///   - pageToken: Page token for pagination
  /// - Returns: Playlist items response
  /// - Throws: YouTubeAPIError if request fails
  func fetchPlaylistItems(
    playlistID: String,
    maxResults: Int = 50,
    pageToken: String? = nil
  ) async throws -> YouTubePlaylistItemsResponse {
    var queryItems = [
      URLQueryItem(name: "part", value: "snippet,contentDetails"),
      URLQueryItem(name: "playlistId", value: playlistID),
      URLQueryItem(name: "maxResults", value: "\(min(maxResults, 50))"),
    ]

    if let pageToken = pageToken {
      queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
    }

    LoggingService.shared.network.info(
      "YouTube API: Fetching playlist items for '\(playlistID, privacy: .private)'"
    )

    return try await makeRequest(
      endpoint: "playlistItems",
      queryItems: queryItems
    )
  }

  // MARK: - Subscriptions API

  /// Fetch user's subscriptions (requires authentication)
  /// - Parameters:
  ///   - maxResults: Maximum number of results (default: 50)
  ///   - pageToken: Page token for pagination
  /// - Returns: Subscription response
  /// - Throws: YouTubeAPIError if request fails
  func fetchSubscriptions(
    maxResults: Int = 50,
    pageToken: String? = nil
  ) async throws -> YouTubeSubscriptionResponse {
    var queryItems = [
      URLQueryItem(name: "part", value: "snippet"),
      URLQueryItem(name: "mine", value: "true"),
      URLQueryItem(name: "maxResults", value: "\(min(maxResults, 50))"),
    ]

    if let pageToken = pageToken {
      queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
    }

    LoggingService.shared.network.info("YouTube API: Fetching user subscriptions")

    return try await makeRequest(
      endpoint: "subscriptions",
      queryItems: queryItems
    )
  }

  // MARK: - Private Methods

  /// Make authenticated request to YouTube Data API
  private func makeRequest<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> T {
    // Build URL
    guard let baseURL = URL(string: baseURL) else {
      throw YouTubeAPIError.invalidURL
    }

    let url = baseURL.appendingPathComponent(endpoint)
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.queryItems = queryItems

    guard let requestURL = components?.url else {
      throw YouTubeAPIError.invalidURL
    }

    // Get access token from OAuth2Handler (automatically refreshes if expired)
    let accessToken: String
    do {
      accessToken = try await OAuth2Handler.shared.getAccessToken()
    } catch {
      LoggingService.shared.network.error(
        "Failed to get access token for YouTube API request: \(error.localizedDescription, privacy: .public)"
      )
      throw YouTubeAPIError.unauthorized
    }

    // Build request with Bearer token
    var request = URLRequest(url: requestURL)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    // Execute request
    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw YouTubeAPIError.invalidResponse
    }

    // Log response
    LoggingService.shared.network.debug(
      "YouTube API response: \(httpResponse.statusCode, privacy: .public) - \(data.count, privacy: .public) bytes"
    )

    // Handle HTTP status codes
    switch httpResponse.statusCode {
    case 200...299:
      // Success - decode response
      do {
        return try jsonDecoder.decode(T.self, from: data)
      } catch {
        // Log decoding error with response data for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
          LoggingService.shared.network.error(
            "Failed to decode YouTube API response: \(error.localizedDescription, privacy: .public)\nResponse: \(jsonString, privacy: .private)"
          )
        }
        throw YouTubeAPIError.invalidResponse
      }

    case 401:
      LoggingService.shared.network.error("YouTube API returned 401 Unauthorized")
      throw YouTubeAPIError.unauthorized

    case 403:
      // Try to parse error details to distinguish quota vs other 403 errors
      if let errorResponse = try? jsonDecoder.decode(YouTubeAPIErrorResponse.self, from: data),
        let reason = errorResponse.error.errors?.first?.reason {
        if reason == "quotaExceeded" || reason == "dailyLimitExceeded" {
          LoggingService.shared.network.error(
            "YouTube API quota exceeded: \(errorResponse.error.message, privacy: .public)"
          )
          throw YouTubeAPIError.quotaExceeded
        }
      }
      LoggingService.shared.network.error("YouTube API returned 403 Forbidden")
      throw YouTubeAPIError.forbidden

    case 429:
      LoggingService.shared.network.error("YouTube API rate limit exceeded (429)")
      throw YouTubeAPIError.rateLimitExceeded

    case 500...599:
      LoggingService.shared.network.error(
        "YouTube API server error: HTTP \(httpResponse.statusCode, privacy: .public)"
      )
      throw YouTubeAPIError.serverError(statusCode: httpResponse.statusCode)

    default:
      LoggingService.shared.network.error(
        "YouTube API unexpected status code: \(httpResponse.statusCode, privacy: .public)"
      )
      throw YouTubeAPIError.unexpectedStatusCode(statusCode: httpResponse.statusCode)
    }
  }
}

// MARK: - YouTubeAPIError

/// Errors that can occur when interacting with YouTube Data API
enum YouTubeAPIError: LocalizedError {
  case invalidURL
  case unauthorized
  case forbidden
  case quotaExceeded
  case rateLimitExceeded
  case serverError(statusCode: Int)
  case unexpectedStatusCode(statusCode: Int)
  case invalidResponse
  case networkError(Error)
  case channelNotFound(channelID: String)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL for YouTube API request."

    case .unauthorized:
      return "Authorization failed. Please sign in again."

    case .forbidden:
      return "Access forbidden by YouTube API."

    case .quotaExceeded:
      return "YouTube API quota exceeded. Please try again later."

    case .rateLimitExceeded:
      return "YouTube API rate limit exceeded. Please try again in a few moments."

    case .serverError(let statusCode):
      return "YouTube server error (HTTP \(statusCode)). Please try again later."

    case .unexpectedStatusCode(let statusCode):
      return "Unexpected response from YouTube API (HTTP \(statusCode))."

    case .invalidResponse:
      return "Invalid response from YouTube API."

    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"

    case .channelNotFound(let channelID):
      return "Channel not found: \(channelID)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .unauthorized:
      return "Please sign out and sign in again to refresh your authorization."

    case .quotaExceeded:
      return "The daily YouTube API quota has been exceeded. Quota resets at midnight Pacific Time. Local file playback is still available."

    case .rateLimitExceeded:
      return "Too many requests in a short time. Please wait a moment before trying again."

    case .serverError:
      return "YouTube servers are experiencing issues. Please try again in a few minutes."

    case .networkError:
      return "Check your internet connection and try again."

    default:
      return nil
    }
  }
}

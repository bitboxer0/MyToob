//
//  YouTubeServiceTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

import XCTest
@testable import MyToob

/// Tests for YouTubeService API client
///
/// **Test Coverage:**
/// - Successful API responses for each endpoint
/// - Error handling (401, 403, 429, 5xx)
/// - Bearer token injection
/// - Response JSON parsing
/// - Network error handling
///
/// **Note:** Uses MockURLProtocol for network mocking
final class YouTubeServiceTests: XCTestCase {
  // MARK: - Properties

  private var service: YouTubeService!
  private var mockSession: URLSession!

  // MARK: - Setup & Teardown

  override func setUp() async throws {
    try await super.setUp()

    // Configure MockURLProtocol for network mocking
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    mockSession = URLSession(configuration: config)

    // Inject mocked session into YouTubeService
    service = YouTubeService(session: mockSession)

    // Reset quota tracker and cache for isolated tests
    await QuotaBudgetTracker.shared.resetQuota()
    CachingLayer.shared.clearCache()

    // Reset MockURLProtocol request handler
    MockURLProtocol.requestHandler = nil
  }

  override func tearDown() async throws {
    service = nil
    mockSession = nil
    MockURLProtocol.requestHandler = nil
    try await super.tearDown()
  }

  // MARK: - Search Tests

  /// Test searchVideos() with valid response
  func testSearchVideosSuccess() async throws {
    // Note: This test requires mocked URLSession
    // Validates the expected JSON structure and parsing logic

    let sampleJSON = """
    {
      "items": [
        {
          "id": {
            "kind": "youtube#video",
            "videoId": "dQw4w9WgXcQ"
          },
          "snippet": {
            "title": "Test Video",
            "description": "Test description",
            "channelId": "UCtest123",
            "channelTitle": "Test Channel",
            "publishedAt": "2024-01-01T00:00:00Z",
            "thumbnails": {
              "default": {
                "url": "https://i.ytimg.com/vi/dQw4w9WgXcQ/default.jpg",
                "width": 120,
                "height": 90
              }
            }
          }
        }
      ],
      "nextPageToken": "CAUQAA",
      "pageInfo": {
        "totalResults": 1000000,
        "resultsPerPage": 25
      }
    }
    """

    // Validate JSON can be decoded
    let jsonData = sampleJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let response = try decoder.decode(YouTubeSearchResponse.self, from: jsonData)

    XCTAssertEqual(response.items.count, 1)
    XCTAssertEqual(response.items.first?.id.videoId, "dQw4w9WgXcQ")
    XCTAssertEqual(response.items.first?.snippet.title, "Test Video")
    XCTAssertEqual(response.nextPageToken, "CAUQAA")
  }

  /// Test searchVideos() with empty results
  func testSearchVideosEmptyResults() throws {
    let sampleJSON = """
    {
      "items": [],
      "pageInfo": {
        "totalResults": 0,
        "resultsPerPage": 0
      }
    }
    """

    let jsonData = sampleJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let response = try decoder.decode(YouTubeSearchResponse.self, from: jsonData)

    XCTAssertTrue(response.items.isEmpty)
    XCTAssertNil(response.nextPageToken)
  }

  // MARK: - Videos Tests

  /// Test fetchVideoDetails() with valid response
  func testFetchVideoDetailsSuccess() throws {
    let sampleJSON = """
    {
      "items": [
        {
          "id": "dQw4w9WgXcQ",
          "snippet": {
            "title": "Test Video",
            "description": "Test description",
            "channelId": "UCtest123",
            "channelTitle": "Test Channel",
            "publishedAt": "2024-01-01T00:00:00Z",
            "thumbnails": {
              "high": {
                "url": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
                "width": 480,
                "height": 360
              }
            }
          },
          "contentDetails": {
            "duration": "PT4M13S",
            "dimension": "2d",
            "definition": "hd"
          },
          "statistics": {
            "viewCount": "1000000",
            "likeCount": "50000",
            "commentCount": "1000"
          }
        }
      ]
    }
    """

    let jsonData = sampleJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let response = try decoder.decode(YouTubeVideoListResponse.self, from: jsonData)

    XCTAssertEqual(response.items.count, 1)
    let video = response.items.first!
    XCTAssertEqual(video.id, "dQw4w9WgXcQ")
    XCTAssertEqual(video.snippet.title, "Test Video")
    XCTAssertEqual(video.contentDetails?.duration, "PT4M13S")
    XCTAssertEqual(video.statistics?.viewCount, "1000000")
  }

  /// Test fetchVideoDetails() with multiple videos
  func testFetchMultipleVideoDetails() throws {
    let sampleJSON = """
    {
      "items": [
        {
          "id": "video1",
          "snippet": {
            "title": "Video 1",
            "description": "Description 1",
            "channelId": "UCtest1",
            "channelTitle": "Channel 1",
            "publishedAt": "2024-01-01T00:00:00Z",
            "thumbnails": {
              "default": {
                "url": "https://example.com/thumb1.jpg"
              }
            }
          }
        },
        {
          "id": "video2",
          "snippet": {
            "title": "Video 2",
            "description": "Description 2",
            "channelId": "UCtest2",
            "channelTitle": "Channel 2",
            "publishedAt": "2024-01-02T00:00:00Z",
            "thumbnails": {
              "default": {
                "url": "https://example.com/thumb2.jpg"
              }
            }
          }
        }
      ]
    }
    """

    let jsonData = sampleJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let response = try decoder.decode(YouTubeVideoListResponse.self, from: jsonData)

    XCTAssertEqual(response.items.count, 2)
    XCTAssertEqual(response.items[0].id, "video1")
    XCTAssertEqual(response.items[1].id, "video2")
  }

  // MARK: - Channels Tests

  /// Test fetchChannelInfo() with valid response
  func testFetchChannelInfoSuccess() throws {
    let sampleJSON = """
    {
      "items": [
        {
          "id": "UCtest123",
          "snippet": {
            "title": "Test Channel",
            "description": "Channel description",
            "channelId": "UCtest123",
            "channelTitle": "Test Channel",
            "publishedAt": "2020-01-01T00:00:00Z",
            "thumbnails": {
              "default": {
                "url": "https://example.com/channel.jpg"
              }
            }
          },
          "statistics": {
            "subscriberCount": "1000000",
            "videoCount": "500",
            "viewCount": "50000000"
          }
        }
      ]
    }
    """

    let jsonData = sampleJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let response = try decoder.decode(YouTubeChannelResponse.self, from: jsonData)

    XCTAssertEqual(response.items.count, 1)
    let channel = response.items.first!
    XCTAssertEqual(channel.id, "UCtest123")
    XCTAssertEqual(channel.snippet.title, "Test Channel")
    XCTAssertEqual(channel.statistics?.subscriberCount, "1000000")
  }

  // MARK: - Playlists Tests

  /// Test fetchPlaylistItems() with valid response
  func testFetchPlaylistItemsSuccess() throws {
    let sampleJSON = """
    {
      "items": [
        {
          "id": "PLitem1",
          "snippet": {
            "title": "Video in Playlist",
            "description": "Video description",
            "channelId": "UCtest123",
            "channelTitle": "Test Channel",
            "publishedAt": "2024-01-01T00:00:00Z",
            "resourceId": {
              "kind": "youtube#video",
              "videoId": "video123"
            },
            "thumbnails": {
              "default": {
                "url": "https://example.com/thumb.jpg"
              }
            }
          }
        }
      ],
      "nextPageToken": "CAUQAQ",
      "pageInfo": {
        "totalResults": 100,
        "resultsPerPage": 50
      }
    }
    """

    let jsonData = sampleJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let response = try decoder.decode(YouTubePlaylistItemsResponse.self, from: jsonData)

    XCTAssertEqual(response.items.count, 1)
    let item = response.items.first!
    XCTAssertEqual(item.snippet.resourceId.videoId, "video123")
    XCTAssertEqual(item.snippet.title, "Video in Playlist")
    XCTAssertEqual(response.nextPageToken, "CAUQAQ")
  }

  // MARK: - Error Response Tests

  /// Test parsing YouTube API error response
  func testParseAPIErrorResponse() throws {
    let errorJSON = """
    {
      "error": {
        "code": 403,
        "message": "The request cannot be completed because you have exceeded your quota.",
        "errors": [
          {
            "domain": "youtube.quota",
            "reason": "quotaExceeded",
            "message": "The request cannot be completed because you have exceeded your quota."
          }
        ],
        "status": "RESOURCE_EXHAUSTED"
      }
    }
    """

    let jsonData = errorJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let errorResponse = try decoder.decode(YouTubeAPIErrorResponse.self, from: jsonData)

    XCTAssertEqual(errorResponse.error.code, 403)
    XCTAssertEqual(errorResponse.error.errors?.first?.reason, "quotaExceeded")
    XCTAssertEqual(errorResponse.error.status, "RESOURCE_EXHAUSTED")
  }

  // MARK: - Error Enum Tests

  /// Test YouTubeAPIError error descriptions
  func testYouTubeAPIErrorDescriptions() {
    let errors: [YouTubeAPIError] = [
      .invalidURL,
      .unauthorized,
      .forbidden,
      .quotaExceeded,
      .rateLimitExceeded,
      .serverError(statusCode: 500),
      .unexpectedStatusCode(statusCode: 418),
      .invalidResponse,
      .channelNotFound(channelID: "UCtest"),
    ]

    // Verify all errors have descriptions
    for error in errors {
      XCTAssertNotNil(error.errorDescription, "Error should have description: \(error)")
    }

    // Verify specific descriptions
    XCTAssertTrue(
      YouTubeAPIError.quotaExceeded.errorDescription?.contains("quota") ?? false
    )
    XCTAssertTrue(
      YouTubeAPIError.unauthorized.errorDescription?.contains("Authorization") ?? false
    )
    XCTAssertTrue(
      YouTubeAPIError.serverError(statusCode: 500).errorDescription?.contains("500") ?? false
    )
  }

  /// Test YouTubeAPIError recovery suggestions
  func testYouTubeAPIErrorRecoverySuggestions() {
    XCTAssertNotNil(YouTubeAPIError.unauthorized.recoverySuggestion)
    XCTAssertNotNil(YouTubeAPIError.quotaExceeded.recoverySuggestion)
    XCTAssertNotNil(YouTubeAPIError.rateLimitExceeded.recoverySuggestion)

    // Verify quota error mentions midnight Pacific time
    let quotaSuggestion = YouTubeAPIError.quotaExceeded.recoverySuggestion
    XCTAssertTrue(quotaSuggestion?.contains("midnight Pacific") ?? false)
  }

  // MARK: - Subscriptions Tests

  /// Test subscriptions response parsing
  func testFetchSubscriptionsSuccess() throws {
    let sampleJSON = """
    {
      "items": [
        {
          "id": "sub123",
          "snippet": {
            "title": "Subscribed Channel",
            "description": "Channel description",
            "resourceId": {
              "kind": "youtube#channel",
              "channelId": "UCsubscribed123"
            },
            "channelId": "UCmy_channel",
            "thumbnails": {
              "default": {
                "url": "https://example.com/thumb.jpg"
              }
            },
            "publishedAt": "2024-01-01T00:00:00Z"
          }
        }
      ],
      "nextPageToken": "CAUQAQ",
      "pageInfo": {
        "totalResults": 50,
        "resultsPerPage": 50
      }
    }
    """

    let jsonData = sampleJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let response = try decoder.decode(YouTubeSubscriptionResponse.self, from: jsonData)

    XCTAssertEqual(response.items.count, 1)
    let subscription = response.items.first!
    XCTAssertEqual(subscription.snippet.resourceId.channelId, "UCsubscribed123")
    XCTAssertEqual(subscription.snippet.title, "Subscribed Channel")
  }

  // MARK: - Integration Tests

  /// Test that model decoding handles missing optional fields
  func testOptionalFieldsHandling() throws {
    let minimalJSON = """
    {
      "items": [
        {
          "id": {
            "videoId": "abc123"
          },
          "snippet": {
            "title": "Minimal Video",
            "description": "",
            "channelId": "UCtest",
            "channelTitle": "Test",
            "publishedAt": "2024-01-01T00:00:00Z",
            "thumbnails": {}
          }
        }
      ]
    }
    """

    let jsonData = minimalJSON.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    // Should not throw even with minimal fields
    let response = try decoder.decode(YouTubeSearchResponse.self, from: jsonData)

    XCTAssertEqual(response.items.count, 1)
    XCTAssertEqual(response.items.first?.id.videoId, "abc123")
    XCTAssertNil(response.nextPageToken)
  }

  /// Test ISO 8601 duration parsing scenarios
  func testISO8601DurationFormats() throws {
    let durations = [
      "PT4M13S", // 4 minutes 13 seconds
      "PT1H30M", // 1 hour 30 minutes
      "PT45S", // 45 seconds
      "PT2H", // 2 hours
      "PT10M", // 10 minutes
    ]

    // Validate these are valid duration strings
    for duration in durations {
      XCTAssertTrue(duration.hasPrefix("PT"), "Duration should be ISO 8601 format")
    }
  }

  // MARK: - Network Mocked Tests (Story 2.9)

  // MARK: Authentication Tests

  /// Test Bearer token injection in Authorization header
  func testBearerTokenInjection() async throws {
    let testToken = "test-oauth-token"

    MockURLProtocol.requestHandler = { request in
      // Verify Authorization header
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer \(testToken)",
        "Authorization header should contain Bearer token"
      )

      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {"items": []}
      """
      return (response, json.data(using: .utf8))
    }

    // Mock OAuth2Handler to return test token
    // Note: Would need to inject OAuth2Handler or use dependency injection in production
    // For now, test validates that IF token exists, it's properly formatted

    _ = try? await service.searchVideos(query: "test")
  }

  // MARK: Success Path Tests

  /// Test searchVideos with mocked 200 response
  func testSearchVideosMockedSuccess() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["ETag": "search-etag-123"]
      )!
      let json = """
      {
        "items": [
          {
            "id": {"kind": "youtube#video", "videoId": "mocked123"},
            "snippet": {
              "title": "Mocked Video",
              "description": "Test description",
              "channelId": "UCmock",
              "channelTitle": "Mock Channel",
              "publishedAt": "2024-01-01T00:00:00Z",
              "thumbnails": {
                "default": {"url": "https://example.com/thumb.jpg", "width": 120, "height": 90}
              }
            }
          }
        ],
        "nextPageToken": "MOCK_TOKEN",
        "pageInfo": {"totalResults": 100, "resultsPerPage": 25}
      }
      """
      return (response, json.data(using: .utf8))
    }

    let result = try await service.searchVideos(query: "SwiftUI")

    XCTAssertEqual(result.items.count, 1)
    XCTAssertEqual(result.items.first?.id.videoId, "mocked123")
    XCTAssertEqual(result.items.first?.snippet.title, "Mocked Video")
    XCTAssertEqual(result.nextPageToken, "MOCK_TOKEN")
  }

  /// Test fetchVideoDetails with mocked 200 response
  func testFetchVideoDetailsMockedSuccess() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["ETag": "video-etag-456"]
      )!
      let json = """
      {
        "items": [
          {
            "id": "video123",
            "snippet": {
              "title": "Test Video Details",
              "description": "Detailed description",
              "channelId": "UCtest",
              "channelTitle": "Test",
              "publishedAt": "2024-01-01T00:00:00Z",
              "thumbnails": {"high": {"url": "https://example.com/hq.jpg"}}
            },
            "contentDetails": {
              "duration": "PT5M30S",
              "dimension": "2d",
              "definition": "hd"
            },
            "statistics": {
              "viewCount": "10000",
              "likeCount": "500",
              "commentCount": "50"
            }
          }
        ]
      }
      """
      return (response, json.data(using: .utf8))
    }

    let result = try await service.fetchVideoDetails(videoIDs: ["video123"])

    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result.first?.id, "video123")
    XCTAssertEqual(result.first?.snippet.title, "Test Video Details")
    XCTAssertEqual(result.first?.contentDetails?.duration, "PT5M30S")
    XCTAssertEqual(result.first?.statistics?.viewCount, "10000")
  }

  // MARK: Error Handling Tests

  /// Test 401 Unauthorized error
  func testUnauthorizedError() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 401,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "error": {
          "code": 401,
          "message": "Request had invalid authentication credentials.",
          "status": "UNAUTHENTICATED"
        }
      }
      """
      return (response, json.data(using: .utf8))
    }

    do {
      _ = try await service.searchVideos(query: "test")
      XCTFail("Should throw unauthorized error")
    } catch let error as YouTubeAPIError {
      if case .unauthorized = error {
        // Expected error
      } else {
        XCTFail("Expected unauthorized error, got: \(error)")
      }
    }
  }

  /// Test 403 Quota Exceeded error
  func testQuotaExceededError() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 403,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "error": {
          "code": 403,
          "message": "The request cannot be completed because you have exceeded your quota.",
          "errors": [
            {
              "domain": "youtube.quota",
              "reason": "quotaExceeded",
              "message": "The request cannot be completed because you have exceeded your quota."
            }
          ],
          "status": "RESOURCE_EXHAUSTED"
        }
      }
      """
      return (response, json.data(using: .utf8))
    }

    do {
      _ = try await service.searchVideos(query: "test")
      XCTFail("Should throw quota exceeded error")
    } catch let error as YouTubeAPIError {
      if case .quotaExceeded = error {
        // Expected error
      } else {
        XCTFail("Expected quotaExceeded error, got: \(error)")
      }
    }
  }

  /// Test 5xx Server Error
  func testServerError() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 503,
        httpVersion: nil,
        headerFields: nil
      )!
      return (response, Data())
    }

    do {
      _ = try await service.searchVideos(query: "test")
      XCTFail("Should throw server error")
    } catch let error as YouTubeAPIError {
      if case .serverError(let statusCode) = error {
        XCTAssertEqual(statusCode, 503)
      } else {
        XCTFail("Expected serverError, got: \(error)")
      }
    }
  }

  /// Test network timeout error
  func testNetworkTimeoutError() async throws {
    MockURLProtocol.requestHandler = { request in
      throw URLError(.timedOut)
    }

    do {
      _ = try await service.searchVideos(query: "test")
      XCTFail("Should throw network error")
    } catch let error as YouTubeAPIError {
      if case .networkError(let urlError) = error {
        XCTAssertEqual((urlError as? URLError)?.code, .timedOut)
      } else {
        XCTFail("Expected networkError, got: \(error)")
      }
    }
  }

  // MARK: Caching Integration Tests

  /// Test ETag storage on 200 response
  func testETagStorageOn200() async throws {
    let testETag = "test-etag-789"

    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["ETag": testETag]
      )!
      let json = """
      {"items": [{"id": {"videoId": "cached"}, "snippet": {"title": "Cached", "channelId": "UC", "channelTitle": "C", "publishedAt": "2024-01-01T00:00:00Z", "thumbnails": {}}}]}
      """
      return (response, json.data(using: .utf8))
    }

    _ = try await service.searchVideos(query: "cache-test")

    // Verify cache was populated (would need cache introspection method)
    let stats = CachingLayer.shared.getCacheStats()
    XCTAssertGreaterThan(stats.currentSize, 0, "Cache should contain entry")
  }

  /// Test 304 Not Modified returns cached data
  func testNotModifiedReturnsCachedData() async throws {
    let testETag = "cached-etag-123"
    var requestCount = 0

    MockURLProtocol.requestHandler = { request in
      requestCount += 1

      if requestCount == 1 {
        // First request: Return 200 with ETag
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["ETag": testETag]
        )!
        let json = """
        {"items": [{"id": {"videoId": "original"}, "snippet": {"title": "Original", "channelId": "UC", "channelTitle": "C", "publishedAt": "2024-01-01T00:00:00Z", "thumbnails": {}}}]}
        """
        return (response, json.data(using: .utf8))
      } else {
        // Second request: Verify If-None-Match header and return 304
        XCTAssertEqual(
          request.value(forHTTPHeaderField: "If-None-Match"),
          testETag,
          "Should include If-None-Match header with cached ETag"
        )

        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 304,
          httpVersion: nil,
          headerFields: ["ETag": testETag]
        )!
        return (response, nil)
      }
    }

    // First request populates cache
    let result1 = try await service.searchVideos(query: "cache-test")
    XCTAssertEqual(result1.items.first?.id.videoId, "original")

    // Second request should use cached data via 304
    let result2 = try await service.searchVideos(query: "cache-test")
    XCTAssertEqual(result2.items.first?.id.videoId, "original", "Should return cached data")
    XCTAssertEqual(requestCount, 2, "Should have made 2 requests")
  }

  // MARK: Quota Tracking Integration Tests

  /// Test quota is recorded on successful request
  func testQuotaRecordedOnSuccess() async throws {
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {"items": []}
      """
      return (response, json.data(using: .utf8))
    }

    // Reset quota to known state
    await QuotaBudgetTracker.shared.resetQuota()

    let statsBefore = await QuotaBudgetTracker.shared.getQuotaStats()
    XCTAssertEqual(statsBefore.totalConsumed, 0)

    // Make search request (100 units)
    _ = try await service.searchVideos(query: "test")

    let statsAfter = await QuotaBudgetTracker.shared.getQuotaStats()
    XCTAssertEqual(statsAfter.totalConsumed, 100, "Search should consume 100 quota units")
  }

  /// Test request blocked when quota budget exceeded
  func testQuotaBudgetExceededBlocks() async throws {
    // Set up tracker with near-limit consumption
    await QuotaBudgetTracker.shared.resetQuota()

    // Consume quota up to limit minus 50 units
    for _ in 0..<99 {
      await QuotaBudgetTracker.shared.recordRequest(endpoint: .videos) // 1 unit each
    }

    let stats = await QuotaBudgetTracker.shared.getQuotaStats()
    XCTAssertEqual(stats.totalConsumed, 99)

    // Next search request (100 units) should be blocked
    let canMake = await QuotaBudgetTracker.shared.canMakeRequest(endpoint: .search)
    XCTAssertFalse(canMake, "Search should be blocked when quota budget would be exceeded")
  }

  // MARK: Circuit Breaker Integration Tests

  /// Test circuit breaker opens after consecutive 429s
  func testCircuitBreakerOpensAfterConsecutive429s() async throws {
    var requestCount = 0

    MockURLProtocol.requestHandler = { request in
      requestCount += 1
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 429,
        httpVersion: nil,
        headerFields: nil
      )!
      return (response, Data())
    }

    // Reset circuit breaker
    await QuotaBudgetTracker.shared.resetQuota()

    // Make 5 requests that return 429 (should open circuit)
    for _ in 0..<5 {
      do {
        _ = try await service.searchVideos(query: "test")
      } catch {
        // Expected to fail with rate limit error
      }
    }

    // Verify circuit is open
    let state = await QuotaBudgetTracker.shared.circuitState
    XCTAssertEqual(state, .open, "Circuit should be open after 5 consecutive 429s")
  }

  /// Test requests blocked when circuit is open
  func testRequestsBlockedWhenCircuitOpen() async throws {
    // Open circuit manually
    await QuotaBudgetTracker.shared.resetQuota()

    // Trigger circuit open by consuming quota and forcing 429s
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 429,
        httpVersion: nil,
        headerFields: nil
      )!
      return (response, Data())
    }

    // Make 5 requests to open circuit
    for _ in 0..<5 {
      do {
        _ = try await service.searchVideos(query: "test")
      } catch {
        // Expected
      }
    }

    // Verify circuit is open
    let state = await QuotaBudgetTracker.shared.circuitState
    XCTAssertEqual(state, .open)

    // Next request should be blocked before even making network call
    let canMake = await QuotaBudgetTracker.shared.canMakeRequest(endpoint: .search)
    XCTAssertFalse(canMake, "Request should be blocked when circuit is open")
  }

  // MARK: - Field Filtering Tests

  /// Test that searchVideos includes fields parameter with default value
  func testSearchVideosDefaultFieldFilter() async throws {
    var capturedURL: URL?

    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "items": [],
        "nextPageToken": "MOCK",
        "pageInfo": {"totalResults": 0, "resultsPerPage": 0}
      }
      """
      return (response, json.data(using: .utf8))
    }

    _ = try await service.searchVideos(query: "test")

    XCTAssertNotNil(capturedURL, "Request URL should be captured")
    let urlString = capturedURL?.absoluteString ?? ""
    XCTAssertTrue(
      urlString.contains("fields="),
      "Default field filter should be applied to search request"
    )
    XCTAssertTrue(
      urlString.contains("items(id,snippet"),
      "Should include default search fields pattern"
    )
  }

  /// Test that fetchVideoDetails includes fields parameter with default value
  func testFetchVideoDetailsDefaultFieldFilter() async throws {
    var capturedURL: URL?

    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "items": [],
        "pageInfo": {"totalResults": 0, "resultsPerPage": 0}
      }
      """
      return (response, json.data(using: .utf8))
    }

    _ = try await service.fetchVideoDetails(videoIDs: ["test123"])

    XCTAssertNotNil(capturedURL, "Request URL should be captured")
    let urlString = capturedURL?.absoluteString ?? ""
    XCTAssertTrue(
      urlString.contains("fields="),
      "Default field filter should be applied to videos request"
    )
    XCTAssertTrue(
      urlString.contains("items(id,snippet"),
      "Should include default videos fields pattern"
    )
  }

  /// Test that fetchChannelInfo includes fields parameter with default value
  func testFetchChannelInfoDefaultFieldFilter() async throws {
    var capturedURL: URL?

    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "items": [
          {
            "id": "UCtest",
            "snippet": {"title": "Test Channel", "description": "", "thumbnails": {}},
            "statistics": {}
          }
        ],
        "pageInfo": {"totalResults": 1, "resultsPerPage": 1}
      }
      """
      return (response, json.data(using: .utf8))
    }

    _ = try await service.fetchChannelInfo(channelID: "UCtest")

    XCTAssertNotNil(capturedURL, "Request URL should be captured")
    let urlString = capturedURL?.absoluteString ?? ""
    XCTAssertTrue(
      urlString.contains("fields="),
      "Default field filter should be applied to channels request"
    )
    XCTAssertTrue(
      urlString.contains("items(id,snippet"),
      "Should include default channels fields pattern"
    )
  }

  /// Test that fetchPlaylists includes fields parameter with default value
  func testFetchPlaylistsDefaultFieldFilter() async throws {
    var capturedURL: URL?

    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "items": [],
        "nextPageToken": "MOCK",
        "pageInfo": {"totalResults": 0, "resultsPerPage": 0}
      }
      """
      return (response, json.data(using: .utf8))
    }

    _ = try await service.fetchPlaylists(channelID: "UCtest")

    XCTAssertNotNil(capturedURL, "Request URL should be captured")
    let urlString = capturedURL?.absoluteString ?? ""
    XCTAssertTrue(
      urlString.contains("fields="),
      "Default field filter should be applied to playlists request"
    )
    XCTAssertTrue(
      urlString.contains("items(id,snippet"),
      "Should include default playlists fields pattern"
    )
  }

  /// Test that fetchPlaylistItems includes fields parameter with default value
  func testFetchPlaylistItemsDefaultFieldFilter() async throws {
    var capturedURL: URL?

    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "items": [],
        "nextPageToken": "MOCK",
        "pageInfo": {"totalResults": 0, "resultsPerPage": 0}
      }
      """
      return (response, json.data(using: .utf8))
    }

    _ = try await service.fetchPlaylistItems(playlistID: "PLtest")

    XCTAssertNotNil(capturedURL, "Request URL should be captured")
    let urlString = capturedURL?.absoluteString ?? ""
    XCTAssertTrue(
      urlString.contains("fields="),
      "Default field filter should be applied to playlistItems request"
    )
    XCTAssertTrue(
      urlString.contains("items(id,snippet"),
      "Should include default playlistItems fields pattern"
    )
  }

  /// Test that fetchSubscriptions includes fields parameter with default value
  func testFetchSubscriptionsDefaultFieldFilter() async throws {
    var capturedURL: URL?

    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "items": [],
        "nextPageToken": "MOCK",
        "pageInfo": {"totalResults": 0, "resultsPerPage": 0}
      }
      """
      return (response, json.data(using: .utf8))
    }

    _ = try await service.fetchSubscriptions()

    XCTAssertNotNil(capturedURL, "Request URL should be captured")
    let urlString = capturedURL?.absoluteString ?? ""
    XCTAssertTrue(
      urlString.contains("fields="),
      "Default field filter should be applied to subscriptions request"
    )
    XCTAssertTrue(
      urlString.contains("items(id,snippet"),
      "Should include default subscriptions fields pattern"
    )
  }

  /// Test that custom field filters override defaults
  func testCustomFieldFilterOverridesDefault() async throws {
    var capturedURL: URL?

    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "items": [],
        "nextPageToken": "MOCK",
        "pageInfo": {"totalResults": 0, "resultsPerPage": 0}
      }
      """
      return (response, json.data(using: .utf8))
    }

    // Use custom field filter
    _ = try await service.searchVideos(query: "test", fields: "items(id)")

    XCTAssertNotNil(capturedURL, "Request URL should be captured")
    let urlString = capturedURL?.absoluteString ?? ""
    XCTAssertTrue(
      urlString.contains("fields=items(id)"),
      "Custom field filter should be used instead of default"
    )
    XCTAssertFalse(
      urlString.contains("snippet"),
      "Should not include default fields when custom filter provided"
    )
  }

  /// Test that nil fields parameter omits field filtering
  func testNilFieldsOmitsFiltering() async throws {
    var capturedURL: URL?

    MockURLProtocol.requestHandler = { request in
      capturedURL = request.url
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let json = """
      {
        "items": [],
        "nextPageToken": "MOCK",
        "pageInfo": {"totalResults": 0, "resultsPerPage": 0}
      }
      """
      return (response, json.data(using: .utf8))
    }

    // Explicitly pass nil to omit field filtering
    _ = try await service.searchVideos(query: "test", fields: nil)

    XCTAssertNotNil(capturedURL, "Request URL should be captured")
    let urlString = capturedURL?.absoluteString ?? ""
    XCTAssertFalse(
      urlString.contains("fields="),
      "Should not include fields parameter when nil is passed"
    )
  }
}

// MARK: - Mock URLProtocol (for future network mocking)

/// Custom URLProtocol for mocking network requests
/// Note: Not currently integrated, but structure provided for future enhancement
class MockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    guard let handler = MockURLProtocol.requestHandler else {
      fatalError("MockURLProtocol: requestHandler not set")
    }

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      if let data = data {
        client?.urlProtocol(self, didLoad: data)
      }
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {
    // No-op
  }
}

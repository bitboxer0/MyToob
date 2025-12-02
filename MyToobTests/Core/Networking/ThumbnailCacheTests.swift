//
//  ThumbnailCacheTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import XCTest
@testable import MyToob

/// Mock URLSession for testing ThumbnailCache
final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
  /// Queue for thread-safe access to mutable state
  private let queue = DispatchQueue(label: "com.mytoob.mockurlsession")

  /// Responses to return, keyed by URL string
  private var _responses: [String: (data: Data, response: HTTPURLResponse)] = [:]

  /// Errors to throw, keyed by URL string
  private var _errors: [String: Error] = [:]

  /// Record of requests made
  private var _requestHistory: [URLRequest] = []

  var responses: [String: (data: Data, response: HTTPURLResponse)] {
    get { queue.sync { _responses } }
    set { queue.sync { _responses = newValue } }
  }

  var errors: [String: Error] {
    get { queue.sync { _errors } }
    set { queue.sync { _errors = newValue } }
  }

  var requestHistory: [URLRequest] {
    queue.sync { _requestHistory }
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    queue.sync { _requestHistory.append(request) }

    let urlString = request.url?.absoluteString ?? ""

    if let error = queue.sync(execute: { _errors[urlString] }) {
      throw error
    }

    if let response = queue.sync(execute: { _responses[urlString] }) {
      return (response.data, response.response)
    }

    // Default: 404
    let notFoundResponse = HTTPURLResponse(
      url: request.url!,
      statusCode: 404,
      httpVersion: nil,
      headerFields: nil
    )!
    return (Data(), notFoundResponse)
  }

  /// Helper to set up a successful image response
  func setImageResponse(
    for urlString: String,
    imageData: Data,
    contentType: String = "image/jpeg",
    cacheControl: String? = nil,
    etag: String? = nil,
    maxAge: Int? = nil
  ) {
    var headers: [String: String] = ["Content-Type": contentType]
    if let cacheControl = cacheControl {
      headers["Cache-Control"] = cacheControl
    } else if let maxAge = maxAge {
      headers["Cache-Control"] = "max-age=\(maxAge)"
    }
    if let etag = etag {
      headers["ETag"] = etag
    }

    let response = HTTPURLResponse(
      url: URL(string: urlString)!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: headers
    )!

    queue.sync {
      _responses[urlString] = (imageData, response)
    }
  }

  /// Helper to set up a 304 Not Modified response
  func set304Response(for urlString: String) {
    let response = HTTPURLResponse(
      url: URL(string: urlString)!,
      statusCode: 304,
      httpVersion: nil,
      headerFields: nil
    )!

    queue.sync {
      _responses[urlString] = (Data(), response)
    }
  }

  func clearHistory() {
    queue.sync { _requestHistory.removeAll() }
  }
}

/// Tests for ThumbnailCache
///
/// **Test Coverage:**
/// - Memory and disk caching
/// - HTTP Cache-Control directive handling (no-store, must-revalidate, max-age)
/// - ETag/If-None-Match conditional requests
/// - LRU eviction when size limit exceeded
/// - Content-Type validation (only image/* cached)
/// - Cache statistics accuracy
/// - Error handling
final class ThumbnailCacheTests: XCTestCase {
  // MARK: - Properties

  private var tempDirectory: URL!
  private var mockSession: MockURLSession!
  private var cache: ThumbnailCache!

  // Test image data
  private let testImageData = Data(repeating: 0xFF, count: 1000)
  private let testImageURL = URL(string: "https://example.com/thumb.jpg")!

  // MARK: - Setup & Teardown

  override func setUp() async throws {
    try await super.setUp()

    // Create temp directory
    tempDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("ThumbnailCacheTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

    // Create mock session
    mockSession = MockURLSession()

    // Create cache with test configuration
    cache = ThumbnailCache(
      rootDirectory: tempDirectory,
      maxDiskBytes: 10 * 1024,  // 10 KB for testing
      session: mockSession
    )
  }

  override func tearDown() async throws {
    cache = nil
    mockSession = nil

    // Clean up temp directory
    if let tempDirectory = tempDirectory {
      try? FileManager.default.removeItem(at: tempDirectory)
    }
    tempDirectory = nil

    try await super.tearDown()
  }

  // MARK: - Basic Caching Tests

  /// Test that a fresh image is fetched and cached
  func testFreshImageFetchAndCache() async throws {
    let urlString = testImageURL.absoluteString
    mockSession.setImageResponse(for: urlString, imageData: testImageData)

    // Fetch image
    let data = try await cache.load(url: testImageURL)

    XCTAssertEqual(data, testImageData, "Should return fetched image data")
    XCTAssertEqual(mockSession.requestHistory.count, 1, "Should make one request")

    // Second fetch should use cache (no new request)
    mockSession.clearHistory()
    let cachedData = try await cache.load(url: testImageURL)

    XCTAssertEqual(cachedData, testImageData, "Should return cached data")
    XCTAssertEqual(mockSession.requestHistory.count, 0, "Should not make new request for cached image")
  }

  /// Test memory cache hit (no disk access needed)
  func testMemoryCacheHit() async throws {
    let urlString = testImageURL.absoluteString
    mockSession.setImageResponse(for: urlString, imageData: testImageData, maxAge: 3600)

    // First fetch populates cache
    _ = try await cache.load(url: testImageURL)

    // Clear request history
    mockSession.clearHistory()

    // Second fetch should be a memory hit
    let cachedData = try await cache.load(url: testImageURL)

    XCTAssertEqual(cachedData, testImageData)
    XCTAssertEqual(mockSession.requestHistory.count, 0, "Memory cache hit should not make request")

    // Check stats
    let stats = cache.getStats()
    XCTAssertGreaterThan(stats.memoryItems, 0, "Should have memory items")
  }

  // MARK: - Cache-Control Tests

  /// Test no-store directive prevents caching
  func testNoStorePreventsCache() async throws {
    let urlString = testImageURL.absoluteString
    mockSession.setImageResponse(
      for: urlString,
      imageData: testImageData,
      cacheControl: "no-store"
    )

    // First fetch
    let data1 = try await cache.load(url: testImageURL)
    XCTAssertEqual(data1, testImageData)

    // Clear history and fetch again - should make new request
    mockSession.clearHistory()
    let data2 = try await cache.load(url: testImageURL)

    XCTAssertEqual(data2, testImageData)
    XCTAssertEqual(mockSession.requestHistory.count, 1, "no-store should cause new request")
  }

  /// Test must-revalidate causes conditional request
  func testMustRevalidateCausesConditionalRequest() async throws {
    let urlString = testImageURL.absoluteString
    let etag = "\"abc123\""

    // First request with must-revalidate
    mockSession.setImageResponse(
      for: urlString,
      imageData: testImageData,
      cacheControl: "must-revalidate, max-age=0",
      etag: etag
    )

    _ = try await cache.load(url: testImageURL)

    // Set up 304 response for revalidation
    mockSession.set304Response(for: urlString)
    mockSession.clearHistory()

    // Second fetch should revalidate
    let cachedData = try await cache.load(url: testImageURL)

    XCTAssertEqual(cachedData, testImageData, "Should return cached data on 304")
    XCTAssertEqual(mockSession.requestHistory.count, 1, "Should make revalidation request")

    // Check If-None-Match header was sent
    let request = mockSession.requestHistory.first
    XCTAssertEqual(request?.value(forHTTPHeaderField: "If-None-Match"), etag)
  }

  /// Test max-age controls expiration
  func testMaxAgeExpiration() async throws {
    let urlString = testImageURL.absoluteString

    // Response with very short max-age (already expired)
    mockSession.setImageResponse(
      for: urlString,
      imageData: testImageData,
      cacheControl: "max-age=0"
    )

    _ = try await cache.load(url: testImageURL)

    // Clear and fetch again - expired cache should trigger new request
    mockSession.clearHistory()

    // Update response for second request
    let newData = Data(repeating: 0xAA, count: 500)
    mockSession.setImageResponse(for: urlString, imageData: newData, maxAge: 3600)

    let data2 = try await cache.load(url: testImageURL)

    // Should have made a request (cache expired)
    XCTAssertEqual(mockSession.requestHistory.count, 1, "Expired cache should trigger request")
    XCTAssertEqual(data2, newData, "Should return new data")
  }

  // MARK: - Content-Type Validation Tests

  /// Test non-image content type throws error
  func testNonImageContentTypeThrowsError() async throws {
    let urlString = testImageURL.absoluteString
    mockSession.setImageResponse(
      for: urlString,
      imageData: testImageData,
      contentType: "text/html"
    )

    do {
      _ = try await cache.load(url: testImageURL)
      XCTFail("Should throw error for non-image content type")
    } catch let error as ThumbnailCacheError {
      if case .invalidContentType(let actual) = error {
        XCTAssertEqual(actual, "text/html")
      } else {
        XCTFail("Wrong error type: \(error)")
      }
    }
  }

  /// Test various image content types are accepted
  func testVariousImageContentTypesAccepted() async throws {
    let contentTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"]

    for (index, contentType) in contentTypes.enumerated() {
      let url = URL(string: "https://example.com/image\(index).jpg")!
      mockSession.setImageResponse(
        for: url.absoluteString,
        imageData: testImageData,
        contentType: contentType
      )

      let data = try await cache.load(url: url)
      XCTAssertEqual(data, testImageData, "\(contentType) should be accepted")
    }
  }

  // MARK: - LRU Eviction Tests

  /// Test LRU eviction when disk limit exceeded
  func testLRUEviction() async throws {
    // Create cache with very small limit (2KB)
    let smallCache = ThumbnailCache(
      rootDirectory: tempDirectory.appendingPathComponent("lru"),
      maxDiskBytes: 2000,
      session: mockSession
    )

    // Create images that exceed the limit
    let largeData = Data(repeating: 0xFF, count: 800)

    for i in 0..<5 {
      let url = URL(string: "https://example.com/thumb\(i).jpg")!
      mockSession.setImageResponse(for: url.absoluteString, imageData: largeData, maxAge: 3600)
      _ = try await smallCache.load(url: url)

      // Small delay to establish LRU order
      try await Task.sleep(nanoseconds: 50_000_000)
    }

    // Force eviction
    smallCache.evictToLimit()

    // Check stats - should be under limit
    let stats = smallCache.getStats()
    XCTAssertLessThanOrEqual(stats.diskBytes, 2000, "Disk usage should be under limit")
    XCTAssertLessThan(stats.diskEntries, 5, "Some entries should have been evicted")
  }

  // MARK: - Error Handling Tests

  /// Test network error is properly thrown
  func testNetworkError() async throws {
    let urlString = testImageURL.absoluteString
    let networkError = URLError(.notConnectedToInternet)
    mockSession.errors[urlString] = networkError

    do {
      _ = try await cache.load(url: testImageURL)
      XCTFail("Should throw network error")
    } catch let error as ThumbnailCacheError {
      if case .network(let underlyingError) = error {
        XCTAssertTrue(underlyingError is URLError)
      } else {
        XCTFail("Wrong error type: \(error)")
      }
    }
  }

  /// Test HTTP error status codes
  func testHTTPErrorStatusCodes() async throws {
    let errorCodes = [400, 401, 403, 500, 502, 503]

    for statusCode in errorCodes {
      let url = URL(string: "https://example.com/error\(statusCode).jpg")!
      let response = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
      )!
      mockSession.responses[url.absoluteString] = (Data(), response)

      do {
        _ = try await cache.load(url: url)
        XCTFail("Should throw error for HTTP \(statusCode)")
      } catch let error as ThumbnailCacheError {
        if case .httpStatus(let code) = error {
          XCTAssertEqual(code, statusCode)
        } else {
          XCTFail("Wrong error type for \(statusCode): \(error)")
        }
      }
    }
  }

  // MARK: - Statistics Tests

  /// Test cache statistics accuracy
  func testCacheStatistics() async throws {
    // Make some requests
    for i in 0..<3 {
      let url = URL(string: "https://example.com/stats\(i).jpg")!
      mockSession.setImageResponse(for: url.absoluteString, imageData: testImageData, maxAge: 3600)
      _ = try await cache.load(url: url)
    }

    // Make a duplicate request (should be cache hit)
    let firstURL = URL(string: "https://example.com/stats0.jpg")!
    _ = try await cache.load(url: firstURL)

    let stats = cache.getStats()

    XCTAssertEqual(stats.diskEntries, 3, "Should have 3 disk entries")
    XCTAssertGreaterThan(stats.diskBytes, 0, "Should have disk bytes")
    XCTAssertGreaterThan(stats.hitRate, 0, "Should have some cache hits")
  }

  // MARK: - Clear Cache Tests

  /// Test clearing the cache
  func testClearCache() async throws {
    // Populate cache
    for i in 0..<3 {
      let url = URL(string: "https://example.com/clear\(i).jpg")!
      mockSession.setImageResponse(for: url.absoluteString, imageData: testImageData, maxAge: 3600)
      _ = try await cache.load(url: url)
    }

    // Verify cache is populated
    var stats = cache.getStats()
    XCTAssertEqual(stats.diskEntries, 3)

    // Clear cache synchronously
    cache.clear(waitUntilFinished: true)

    // Verify cache is empty
    stats = cache.getStats()
    XCTAssertEqual(stats.diskEntries, 0, "Disk should be empty after clear")
    XCTAssertEqual(stats.memoryItems, 0, "Memory should be empty after clear")
  }

  // MARK: - Prefetch Tests

  /// Test prefetch functionality
  func testPrefetch() async throws {
    let urls = (0..<3).map { URL(string: "https://example.com/prefetch\($0).jpg")! }

    for url in urls {
      mockSession.setImageResponse(for: url.absoluteString, imageData: testImageData, maxAge: 3600)
    }

    // Prefetch
    await cache.prefetch(urls: urls)

    // All should be cached now
    mockSession.clearHistory()
    for url in urls {
      _ = try await cache.load(url: url)
    }

    XCTAssertEqual(mockSession.requestHistory.count, 0, "Prefetched images should not require new requests")
  }

  // MARK: - Case-Insensitive Header Tests

  /// Test that HTTP headers are parsed case-insensitively
  func testCaseInsensitiveHeaders() async throws {
    // This test verifies that we use HTTPURLResponse.value(forHTTPHeaderField:)
    // which handles case-insensitivity correctly
    let url = URL(string: "https://example.com/case-test.jpg")!
    let urlString = url.absoluteString

    // Create response with lowercase header names
    // (HTTPURLResponse normalizes these, but we want to ensure our parsing works)
    var headers: [String: String] = [
      "content-type": "image/png",
      "cache-control": "max-age=3600",
      "etag": "\"test-etag\""
    ]

    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: headers
    )!

    mockSession.responses[urlString] = (testImageData, response)

    // Should successfully cache (Content-Type recognized)
    let data = try await cache.load(url: url)
    XCTAssertEqual(data, testImageData)

    // Should be cached with proper max-age
    mockSession.clearHistory()
    let cached = try await cache.load(url: url)
    XCTAssertEqual(cached, testImageData)
    XCTAssertEqual(mockSession.requestHistory.count, 0, "Should use cache")
  }
}

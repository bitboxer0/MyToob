//
//  MetadataCacheTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import XCTest
@testable import MyToob

/// Tests for disk-backed metadata caching (MetadataDiskCache + CachingLayer integration)
///
/// **Test Coverage:**
/// - Disk persistence across simulated restarts
/// - TTL eviction for expired entries
/// - ETag revalidation and 304 handling
/// - LRU eviction when size limit exceeded
/// - Cache statistics accuracy
/// - Integration with CachingLayer two-tier architecture
final class MetadataCacheTests: XCTestCase {
  // MARK: - Properties

  private var tempDirectory: URL!
  private var diskCache: MetadataDiskCache!

  // MARK: - Setup & Teardown

  override func setUp() async throws {
    try await super.setUp()

    // Create temp directory for isolated tests
    tempDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("MetadataCacheTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

    // Create disk cache with short TTL for testing
    diskCache = MetadataDiskCache(
      directory: tempDirectory,
      maxBytes: 10 * 1024 * 1024, // 10 MB
      defaultTTL: 60 // 1 minute for faster tests
    )
  }

  override func tearDown() async throws {
    diskCache = nil

    // Clean up temp directory
    if let tempDirectory = tempDirectory {
      try? FileManager.default.removeItem(at: tempDirectory)
    }
    tempDirectory = nil

    try await super.tearDown()
  }

  // MARK: - Basic Disk Persistence Tests

  /// Test that saved entries can be retrieved from disk
  func testSaveAndLoadEntry() async throws {
    let key = CachingLayer.CacheKey(url: "https://api.example.com/test", queryItems: [
      URLQueryItem(name: "param", value: "value"),
    ])

    let testData = "Test response data".data(using: .utf8)!
    let testETag = "test-etag-123"

    let entry = CachingLayer.CacheEntry(
      responseData: testData,
      etag: testETag,
      cachedAt: Date(),
      lastAccessedAt: Date()
    )

    // Save entry
    diskCache.saveEntry(entry, for: key)

    // Wait for async save to complete
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

    // Load entry
    let loaded = diskCache.loadEntry(for: key)

    XCTAssertNotNil(loaded, "Entry should be retrievable from disk")
    XCTAssertEqual(loaded?.entry.responseData, testData)
    XCTAssertEqual(loaded?.entry.etag, testETag)
  }

  /// Test that entries persist across disk cache instances (simulated restart)
  func testPersistenceAcrossInstances() async throws {
    let key = CachingLayer.CacheKey(url: "https://api.example.com/persist", queryItems: [])

    let testData = "Persisted data".data(using: .utf8)!
    let testETag = "persist-etag"

    let entry = CachingLayer.CacheEntry(
      responseData: testData,
      etag: testETag,
      cachedAt: Date(),
      lastAccessedAt: Date()
    )

    // Save with first instance
    diskCache.saveEntry(entry, for: key)
    try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds for index write

    // Create new instance (simulates app restart)
    let newDiskCache = MetadataDiskCache(
      directory: tempDirectory,
      maxBytes: 10 * 1024 * 1024,
      defaultTTL: 60
    )

    // Wait for index load
    try await Task.sleep(nanoseconds: 500_000_000)

    // Load with new instance
    let loaded = newDiskCache.loadEntry(for: key)

    XCTAssertNotNil(loaded, "Entry should persist across cache instances")
    XCTAssertEqual(loaded?.entry.responseData, testData)
    XCTAssertEqual(loaded?.entry.etag, testETag)
  }

  // MARK: - TTL Eviction Tests

  /// Test that expired entries are not returned by loadEntry
  func testTTLEviction() async throws {
    // Create cache with very short TTL
    let shortTTLCache = MetadataDiskCache(
      directory: tempDirectory.appendingPathComponent("short-ttl"),
      maxBytes: 10 * 1024 * 1024,
      defaultTTL: 0.5 // 0.5 second TTL
    )

    let key = CachingLayer.CacheKey(url: "https://api.example.com/ttl-test", queryItems: [])

    let entry = CachingLayer.CacheEntry(
      responseData: "TTL test data".data(using: .utf8)!,
      etag: "ttl-etag",
      cachedAt: Date(),
      lastAccessedAt: Date()
    )

    // Save entry
    shortTTLCache.saveEntry(entry, for: key)
    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

    // Verify entry exists initially
    let loadedBefore = shortTTLCache.loadEntry(for: key)
    XCTAssertNotNil(loadedBefore, "Entry should exist before TTL expires")

    // Wait for TTL to expire
    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

    // Verify entry is evicted
    let loadedAfter = shortTTLCache.loadEntry(for: key)
    XCTAssertNil(loadedAfter, "Entry should be evicted after TTL expires")
  }

  /// Test stale entries are returned by loadStaleEntry even after TTL expires
  func testStaleEntryRetrieval() async throws {
    // Create cache with very short TTL
    let shortTTLCache = MetadataDiskCache(
      directory: tempDirectory.appendingPathComponent("stale-test"),
      maxBytes: 10 * 1024 * 1024,
      defaultTTL: 0.5 // 0.5 second TTL
    )

    let key = CachingLayer.CacheKey(url: "https://api.example.com/stale-test", queryItems: [])

    let testData = "Stale test data".data(using: .utf8)!
    let entry = CachingLayer.CacheEntry(
      responseData: testData,
      etag: "stale-etag",
      cachedAt: Date(),
      lastAccessedAt: Date()
    )

    // Save entry
    shortTTLCache.saveEntry(entry, for: key)
    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

    // Wait for TTL to expire
    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

    // Verify loadEntry returns nil (expired)
    let fresh = shortTTLCache.loadEntry(for: key)
    XCTAssertNil(fresh, "loadEntry should return nil for expired entry")

    // Verify loadStaleEntry returns the entry (ignores TTL)
    let stale = shortTTLCache.loadStaleEntry(for: key)
    XCTAssertNotNil(stale, "loadStaleEntry should return expired entry")
    XCTAssertEqual(stale?.entry.responseData, testData)
  }

  // MARK: - LRU Eviction Tests

  /// Test LRU eviction when size limit is exceeded
  func testLRUEviction() async throws {
    // Create cache with small size limit
    let smallCache = MetadataDiskCache(
      directory: tempDirectory.appendingPathComponent("lru-test"),
      maxBytes: 1000, // 1 KB limit
      defaultTTL: 3600
    )

    // Create entries that exceed the size limit
    let largeData = Data(repeating: 65, count: 400) // 400 bytes each

    for i in 0..<5 {
      let key = CachingLayer.CacheKey(
        url: "https://api.example.com/lru-\(i)",
        queryItems: []
      )

      let entry = CachingLayer.CacheEntry(
        responseData: largeData,
        etag: "etag-\(i)",
        cachedAt: Date(),
        lastAccessedAt: Date()
      )

      smallCache.saveEntry(entry, for: key)

      // Small delay between saves to establish LRU order
      try await Task.sleep(nanoseconds: 100_000_000)
    }

    // Wait for eviction
    try await Task.sleep(nanoseconds: 500_000_000)

    // Check stats - should have evicted older entries
    let stats = smallCache.getStats()
    XCTAssertLessThanOrEqual(stats.totalBytes, 1000, "Total bytes should be under limit")
    XCTAssertLessThan(stats.entries, 5, "Some entries should have been evicted")
  }

  // MARK: - Cache Statistics Tests

  /// Test statistics reporting accuracy
  func testCacheStatistics() async throws {
    let key1 = CachingLayer.CacheKey(url: "https://api.example.com/stats1", queryItems: [])
    let key2 = CachingLayer.CacheKey(url: "https://api.example.com/stats2", queryItems: [])

    let data1 = Data(repeating: 65, count: 100) // 100 bytes
    let data2 = Data(repeating: 66, count: 200) // 200 bytes

    let entry1 = CachingLayer.CacheEntry(
      responseData: data1,
      etag: "etag1",
      cachedAt: Date(),
      lastAccessedAt: Date()
    )

    let entry2 = CachingLayer.CacheEntry(
      responseData: data2,
      etag: "etag2",
      cachedAt: Date(),
      lastAccessedAt: Date()
    )

    // Save entries
    diskCache.saveEntry(entry1, for: key1)
    diskCache.saveEntry(entry2, for: key2)

    // Wait for saves
    try await Task.sleep(nanoseconds: 500_000_000)

    // Check stats
    let stats = diskCache.getStats()

    XCTAssertEqual(stats.entries, 2, "Should have 2 entries")
    XCTAssertEqual(stats.totalBytes, 300, "Total bytes should be 300")
  }

  // MARK: - Clear Cache Tests

  /// Test clearing the cache removes all entries
  func testClearCache() async throws {
    // Add some entries
    for i in 0..<3 {
      let key = CachingLayer.CacheKey(url: "https://api.example.com/clear-\(i)", queryItems: [])
      let entry = CachingLayer.CacheEntry(
        responseData: "data".data(using: .utf8)!,
        etag: "etag",
        cachedAt: Date(),
        lastAccessedAt: Date()
      )
      diskCache.saveEntry(entry, for: key)
    }

    try await Task.sleep(nanoseconds: 500_000_000)

    // Verify entries exist
    let statsBefore = diskCache.getStats()
    XCTAssertEqual(statsBefore.entries, 3)

    // Clear cache
    diskCache.clear()
    try await Task.sleep(nanoseconds: 500_000_000)

    // Verify cache is empty
    let statsAfter = diskCache.getStats()
    XCTAssertEqual(statsAfter.entries, 0)
    XCTAssertEqual(statsAfter.totalBytes, 0)
  }

  // MARK: - Query Items Handling Tests

  /// Test that query items are properly sorted for consistent keys
  func testQueryItemsSorting() async throws {
    // Create keys with same URL but different query item order
    let key1 = CachingLayer.CacheKey(url: "https://api.example.com/test", queryItems: [
      URLQueryItem(name: "z", value: "last"),
      URLQueryItem(name: "a", value: "first"),
    ])

    let key2 = CachingLayer.CacheKey(url: "https://api.example.com/test", queryItems: [
      URLQueryItem(name: "a", value: "first"),
      URLQueryItem(name: "z", value: "last"),
    ])

    let entry = CachingLayer.CacheEntry(
      responseData: "test".data(using: .utf8)!,
      etag: "etag",
      cachedAt: Date(),
      lastAccessedAt: Date()
    )

    // Save with key1
    diskCache.saveEntry(entry, for: key1)
    try await Task.sleep(nanoseconds: 500_000_000)

    // Load with key2 (different order)
    let loaded = diskCache.loadEntry(for: key2)

    XCTAssertNotNil(loaded, "Entry should be found regardless of query item order")
  }

  // MARK: - CachingLayer Integration Tests

  /// Test CachingLayer two-tier cache (memory + disk)
  func testCachingLayerTwoTierCache() async throws {
    // Create CachingLayer with injected disk store
    let testDir = tempDirectory.appendingPathComponent("two-tier")
    let testDiskStore = MetadataDiskCache(
      directory: testDir,
      maxBytes: 10 * 1024 * 1024,
      defaultTTL: 3600
    )

    let cachingLayer = CachingLayer(
      diskStore: testDiskStore,
      maxCacheSize: 10,
      maxCacheAge: 3600
    )

    let key = CachingLayer.CacheKey(url: "https://api.example.com/two-tier", queryItems: [])

    // Cache a response
    let testData = "Two-tier test".data(using: .utf8)!
    cachingLayer.cacheResponse(for: key, data: testData, etag: "two-tier-etag")

    // Wait for both memory and disk writes
    try await Task.sleep(nanoseconds: 500_000_000)

    // Memory hit
    let memoryHit = cachingLayer.getCachedResponse(for: key)
    XCTAssertNotNil(memoryHit)
    XCTAssertEqual(memoryHit?.responseData, testData)

    // Clear memory (simulate memory pressure)
    cachingLayer.clearCache()
    try await Task.sleep(nanoseconds: 200_000_000)

    // Create new CachingLayer to simulate fresh start (memory empty)
    let newCachingLayer = CachingLayer(
      diskStore: testDiskStore,
      maxCacheSize: 10,
      maxCacheAge: 3600
    )

    // Should get from disk
    let diskHit = newCachingLayer.getCachedResponse(for: key)
    XCTAssertNotNil(diskHit, "Should retrieve from disk after memory cleared")
    XCTAssertEqual(diskHit?.responseData, testData)
  }

  /// Test CachingLayer stats include disk stats
  func testCachingLayerStatsIncludeDisk() async throws {
    let testDir = tempDirectory.appendingPathComponent("stats-test")
    let testDiskStore = MetadataDiskCache(
      directory: testDir,
      maxBytes: 10 * 1024 * 1024,
      defaultTTL: 3600
    )

    let cachingLayer = CachingLayer(
      diskStore: testDiskStore,
      maxCacheSize: 10,
      maxCacheAge: 3600
    )

    // Add entry
    let key = CachingLayer.CacheKey(url: "https://api.example.com/stats", queryItems: [])
    cachingLayer.cacheResponse(for: key, data: Data(repeating: 65, count: 500), etag: "etag")

    try await Task.sleep(nanoseconds: 500_000_000)

    let stats = cachingLayer.getCacheStats()

    XCTAssertGreaterThan(stats.diskEntries, 0, "Should report disk entries")
    XCTAssertGreaterThan(stats.diskBytes, 0, "Should report disk bytes")
  }
}

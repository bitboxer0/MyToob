//
//  CachingLayer.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

import Foundation
import os

/// HTTP response caching layer with ETag support and LRU eviction
///
/// **Features:**
/// - Stores API responses with ETags for validation caching
/// - LRU eviction policy (1000-item limit)
/// - TTL-based expiration (7-day maximum age)
/// - Cache hit/miss metrics for performance monitoring
///
/// **Usage:**
/// ```swift
/// // Check cache
/// if let cached = CachingLayer.shared.getCachedResponse(for: cacheKey) {
///   // Use cached.etag for If-None-Match header
///   // Return cached.responseData on 304 response
/// }
///
/// // Update cache on 200 response
/// CachingLayer.shared.cacheResponse(for: cacheKey, data: responseData, etag: etag)
/// ```
final class CachingLayer {
  // MARK: - Singleton

  static let shared = CachingLayer()

  // MARK: - Types

  struct CacheKey: Hashable {
    let url: String
    let queryItems: [URLQueryItem]

    init(url: String, queryItems: [URLQueryItem]) {
      self.url = url
      // Sort query items for consistent key generation
      self.queryItems = queryItems.sorted { $0.name < $1.name }
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(url)
      for item in queryItems {
        hasher.combine(item.name)
        hasher.combine(item.value)
      }
    }
  }

  struct CacheEntry {
    let responseData: Data
    let etag: String
    let cachedAt: Date
    var lastAccessedAt: Date
  }

  struct CacheStats {
    let hits: Int
    let misses: Int
    let evictions: Int
    let currentSize: Int
    let maxSize: Int

    var hitRate: Double {
      let total = hits + misses
      guard total > 0 else { return 0.0 }
      return Double(hits) / Double(total) * 100.0
    }
  }

  // MARK: - Properties

  private var cache: [CacheKey: CacheEntry] = [:]
  private let maxCacheSize = 1000
  private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

  // Metrics
  private var hits = 0
  private var misses = 0
  private var evictions = 0

  // Thread safety
  private let queue = DispatchQueue(label: "com.mytoob.cachingLayer", attributes: .concurrent)

  // Background eviction timer
  private var evictionTimer: Timer?

  // MARK: - Initialization

  private init() {
    // Start background eviction timer (runs every hour)
    evictionTimer = Timer.scheduledTimer(
      withTimeInterval: 3600,
      repeats: true
    ) { [weak self] _ in
      self?.evictExpiredEntries()
    }
  }

  deinit {
    evictionTimer?.invalidate()
  }

  // MARK: - Public API

  /// Retrieve cached response for given key
  /// - Parameter key: Cache key combining URL and query parameters
  /// - Returns: Cached entry if found and not expired, nil otherwise
  func getCachedResponse(for key: CacheKey) -> CacheEntry? {
    return queue.sync {
      guard var entry = cache[key] else {
        misses += 1
        LoggingService.shared.network.debug("Cache MISS for \(key.url, privacy: .public)")
        return nil
      }

      // Check if expired (7-day TTL)
      if Date().timeIntervalSince(entry.cachedAt) > maxCacheAge {
        cache.removeValue(forKey: key)
        misses += 1
        evictions += 1
        LoggingService.shared.network.debug("Cache entry expired for \(key.url, privacy: .public)")
        return nil
      }

      // Update last accessed time (LRU tracking)
      entry.lastAccessedAt = Date()
      cache[key] = entry

      hits += 1
      LoggingService.shared.network.debug("Cache HIT for \(key.url, privacy: .public)")
      return entry
    }
  }

  /// Retrieve stale cached response (ignores expiration) for offline fallback
  /// - Parameter key: Cache key combining URL and query parameters
  /// - Returns: Cached entry if found, regardless of expiration, nil otherwise
  /// - Note: Used when network is unavailable to provide degraded service with stale data
  func getStaleCachedResponse(for key: CacheKey) -> CacheEntry? {
    return queue.sync {
      guard var entry = cache[key] else {
        misses += 1
        LoggingService.shared.network.debug("Stale cache MISS for \(key.url, privacy: .public)")
        return nil
      }

      // Update last accessed time (LRU tracking)
      entry.lastAccessedAt = Date()
      cache[key] = entry

      // Track as miss for metrics (since it's stale data)
      misses += 1

      let age = Date().timeIntervalSince(entry.cachedAt)
      LoggingService.shared.network.warning(
        "Returning STALE cache for \(key.url, privacy: .public) (age: \(age / 3600, format: .fixed(precision: 1), privacy: .public)h)"
      )

      return entry
    }
  }

  /// Cache response with ETag
  /// - Parameters:
  ///   - key: Cache key
  ///   - data: Response body data
  ///   - etag: ETag header value
  func cacheResponse(for key: CacheKey, data: Data, etag: String) {
    queue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }

      // Check if we need to evict entries
      if self.cache.count >= self.maxCacheSize {
        self.evictLRUEntry()
      }

      // Store new entry
      let entry = CacheEntry(
        responseData: data,
        etag: etag,
        cachedAt: Date(),
        lastAccessedAt: Date()
      )

      self.cache[key] = entry

      LoggingService.shared.network.debug(
        "Cached response for \(key.url, privacy: .public) with ETag: \(etag, privacy: .private)"
      )
    }
  }

  /// Get current cache statistics
  /// - Returns: Cache statistics including hit rate
  func getCacheStats() -> CacheStats {
    return queue.sync {
      return CacheStats(
        hits: hits,
        misses: misses,
        evictions: evictions,
        currentSize: cache.count,
        maxSize: maxCacheSize
      )
    }
  }

  /// Clear all cached entries (useful for testing or manual cache reset)
  func clearCache() {
    queue.async(flags: .barrier) { [weak self] in
      self?.cache.removeAll()
      LoggingService.shared.network.info("Cache cleared - all entries removed")
    }
  }

  // MARK: - Private Methods

  /// Evict least recently used entry when cache is full
  private func evictLRUEntry() {
    // Find entry with oldest lastAccessedAt timestamp
    guard let lruKey = cache.min(by: { $0.value.lastAccessedAt < $1.value.lastAccessedAt })?.key else {
      return
    }

    cache.removeValue(forKey: lruKey)
    evictions += 1

    LoggingService.shared.network.debug(
      "Cache LRU eviction: removed \(lruKey.url, privacy: .public)"
    )
  }

  /// Evict all entries older than maxCacheAge (7 days)
  func evictExpiredEntries() {
    queue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }

      let now = Date()
      var expiredKeys: [CacheKey] = []

      for (key, entry) in self.cache {
        if now.timeIntervalSince(entry.cachedAt) > self.maxCacheAge {
          expiredKeys.append(key)
        }
      }

      for key in expiredKeys {
        self.cache.removeValue(forKey: key)
        self.evictions += 1
      }

      if !expiredKeys.isEmpty {
        LoggingService.shared.network.info(
          "Cache TTL eviction: removed \(expiredKeys.count, privacy: .public) expired entries"
        )
      }

      // Log cache statistics periodically
      let stats = CacheStats(
        hits: self.hits,
        misses: self.misses,
        evictions: self.evictions,
        currentSize: self.cache.count,
        maxSize: self.maxCacheSize
      )

      LoggingService.shared.network.info(
        "Cache stats: \(stats.hitRate, format: .fixed(precision: 1), privacy: .public)% hit rate (\(stats.hits) hits / \(stats.hits + stats.misses) requests), \(stats.currentSize) entries"
      )
    }
  }
}

//
//  CachingLayer.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

import Foundation
import os

/// HTTP response caching layer with ETag support, LRU eviction, and disk persistence.
///
/// **Features:**
/// - Two-tier caching: memory (fast) + disk (persistent)
/// - Stores API responses with ETags for validation caching
/// - LRU eviction policy (configurable item limit)
/// - TTL-based expiration (configurable, default 7 days)
/// - Cache hit/miss metrics for performance monitoring
/// - Disk persistence survives app restarts
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
    let diskEntries: Int
    let diskBytes: Int

    var hitRate: Double {
      let total = hits + misses
      guard total > 0 else { return 0.0 }
      return Double(hits) / Double(total) * 100.0
    }
  }

  // MARK: - Properties

  private var cache: [CacheKey: CacheEntry] = [:]
  private let maxCacheSize: Int
  private let maxCacheAge: TimeInterval

  // Disk store for persistence
  private let diskStore: MetadataDiskCache

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
    self.maxCacheSize = Configuration.Cache.metadataMemoryItemsLimit
    self.maxCacheAge = Configuration.Cache.metadataTTL

    // Initialize disk store
    let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
      .appendingPathComponent(Configuration.Cache.cacheRootDirName)
      .appendingPathComponent(Configuration.Cache.metadataSubdir, isDirectory: true)
    self.diskStore = MetadataDiskCache(
      directory: cachesDir,
      maxBytes: Configuration.Cache.metadataDiskMaxBytes,
      defaultTTL: Configuration.Cache.metadataTTL
    )

    // Start background eviction timer (runs every hour)
    evictionTimer = Timer.scheduledTimer(
      withTimeInterval: Configuration.Cache.evictionInterval,
      repeats: true
    ) { [weak self] _ in
      self?.evictExpiredEntries()
    }
  }

  /// Test-only initializer for dependency injection.
  /// - Parameters:
  ///   - diskStore: Custom disk store for testing
  ///   - maxCacheSize: Maximum memory cache size
  ///   - maxCacheAge: Maximum cache age (TTL)
  init(
    diskStore: MetadataDiskCache,
    maxCacheSize: Int = Configuration.Cache.metadataMemoryItemsLimit,
    maxCacheAge: TimeInterval = Configuration.Cache.metadataTTL
  ) {
    self.diskStore = diskStore
    self.maxCacheSize = maxCacheSize
    self.maxCacheAge = maxCacheAge
  }

  deinit {
    evictionTimer?.invalidate()
  }

  // MARK: - Public API

  /// Retrieve cached response for given key.
  ///
  /// Checks memory first, then falls back to disk cache.
  /// Uses at most two barrier blocks to minimize lock contention:
  /// 1. Memory lookup with metrics and LRU tracking
  /// 2. Disk promotion and hit counting (only if disk hit)
  ///
  /// - Parameter key: Cache key combining URL and query parameters
  /// - Returns: Cached entry if found and not expired, nil otherwise
  func getCachedResponse(for key: CacheKey) -> CacheEntry? {
    // 1) Memory lookup under barrier (mutates cache, metrics)
    if let memEntry = queue.sync(flags: .barrier, execute: { () -> CacheEntry? in
      guard var entry = cache[key] else { return nil }

      // Check if expired (TTL)
      if Date().timeIntervalSince(entry.cachedAt) > maxCacheAge {
        cache.removeValue(forKey: key)
        evictions += 1
        misses += 1
        LoggingService.shared.network.debug("Cache entry expired for \(key.url, privacy: .public)")
        return nil
      }

      // Update last accessed time (LRU tracking)
      entry.lastAccessedAt = Date()
      cache[key] = entry
      hits += 1
      LoggingService.shared.network.debug("Memory cache HIT for \(key.url, privacy: .public)")
      return entry
    }) {
      return memEntry
    }

    // 2) Disk lookup (outside lock - diskStore has its own synchronization)
    guard let (diskEntry, _) = diskStore.loadEntry(for: key) else {
      // Count miss exactly once
      queue.sync(flags: .barrier) { misses += 1 }
      LoggingService.shared.network.debug("Cache MISS for \(key.url, privacy: .public)")
      return nil
    }

    // 3) Promote to memory + count hit
    queue.sync(flags: .barrier) {
      if cache.count >= maxCacheSize {
        evictLRUEntry()
      }
      cache[key] = diskEntry
      hits += 1
    }
    LoggingService.shared.network.debug("Disk cache HIT for \(key.url, privacy: .public)")
    return diskEntry
  }

  /// Retrieve stale cached response (ignores expiration) for offline fallback.
  ///
  /// Checks memory first, then falls back to disk cache. Returns data regardless
  /// of TTL expiration, suitable for degraded service when network is unavailable.
  ///
  /// - Parameter key: Cache key combining URL and query parameters
  /// - Returns: Cached entry if found, regardless of expiration, nil otherwise
  /// - Note: All stale responses are tracked as "misses" in metrics since
  ///   they represent degraded service rather than true cache hits.
  func getStaleCachedResponse(for key: CacheKey) -> CacheEntry? {
    // Memory stale path (ignore TTL)
    if let mem = queue.sync(flags: .barrier, execute: { () -> CacheEntry? in
      guard var entry = cache[key] else { return nil }
      entry.lastAccessedAt = Date()
      cache[key] = entry
      misses += 1  // Stale usage tracked as miss
      return entry
    }) {
      let age = Date().timeIntervalSince(mem.cachedAt)
      LoggingService.shared.network.warning(
        "Returning STALE memory cache for \(key.url, privacy: .public) (age: \(age / 3600, format: .fixed(precision: 1), privacy: .public)h)"
      )
      return mem
    }

    // Disk stale path
    if let (diskEntry, _) = diskStore.loadStaleEntry(for: key) {
      queue.sync(flags: .barrier) {
        cache[key] = diskEntry
        misses += 1  // Stale usage tracked as miss
      }

      let age = Date().timeIntervalSince(diskEntry.cachedAt)
      LoggingService.shared.network.warning(
        "Returning STALE disk cache for \(key.url, privacy: .public) (age: \(age / 3600, format: .fixed(precision: 1), privacy: .public)h)"
      )
      return diskEntry
    }

    // Full miss
    queue.sync(flags: .barrier) { misses += 1 }
    LoggingService.shared.network.debug("Stale cache MISS for \(key.url, privacy: .public)")
    return nil
  }

  /// Cache response with ETag.
  ///
  /// Writes to both memory and disk caches.
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

      // Store new entry in memory
      let entry = CacheEntry(
        responseData: data,
        etag: etag,
        cachedAt: Date(),
        lastAccessedAt: Date()
      )

      self.cache[key] = entry

      // Also persist to disk asynchronously
      self.diskStore.saveEntry(entry, for: key)

      LoggingService.shared.network.debug(
        "Cached response for \(key.url, privacy: .public) with ETag: \(etag, privacy: .private)"
      )
    }
  }

  /// Get current cache statistics including disk stats.
  /// - Returns: Cache statistics including hit rate and disk usage
  func getCacheStats() -> CacheStats {
    return queue.sync {
      let diskStats = diskStore.getStats()
      return CacheStats(
        hits: hits,
        misses: misses,
        evictions: evictions,
        currentSize: cache.count,
        maxSize: maxCacheSize,
        diskEntries: diskStats.entries,
        diskBytes: diskStats.totalBytes
      )
    }
  }

  /// Clear all cached entries (memory and disk).
  ///
  /// - Parameter waitUntilFinished: If true, blocks until clearing completes.
  ///   Defaults to false for non-blocking behavior.
  func clearCache(waitUntilFinished: Bool = false) {
    let work = { [weak self] in
      guard let self = self else { return }

      // Clear memory
      self.cache.removeAll()
      self.hits = 0
      self.misses = 0
      self.evictions = 0

      LoggingService.shared.network.info("Cache cleared - all entries removed (memory + disk)")
    }

    if waitUntilFinished {
      queue.sync(flags: .barrier, execute: work)
      diskStore.clear(waitUntilFinished: true)
    } else {
      queue.async(flags: .barrier, execute: work)
      diskStore.clear(waitUntilFinished: false)
    }
  }

  // MARK: - Private Methods

  /// Evict least recently used entry when cache is full.
  private func evictLRUEntry() {
    // Find entry with oldest lastAccessedAt timestamp
    guard let lruKey = cache.min(by: { $0.value.lastAccessedAt < $1.value.lastAccessedAt })?.key else {
      return
    }

    cache.removeValue(forKey: lruKey)
    evictions += 1

    LoggingService.shared.network.debug(
      "Memory cache LRU eviction: removed \(lruKey.url, privacy: .public)"
    )
  }

  /// Evict all entries older than maxCacheAge.
  ///
  /// Also triggers disk cache eviction.
  func evictExpiredEntries() {
    queue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }

      let now = Date()
      var expiredKeys: [CacheKey] = []

      // Find expired memory entries
      for (key, entry) in self.cache {
        if now.timeIntervalSince(entry.cachedAt) > self.maxCacheAge {
          expiredKeys.append(key)
        }
      }

      // Remove expired memory entries
      for key in expiredKeys {
        self.cache.removeValue(forKey: key)
        self.evictions += 1
      }

      if !expiredKeys.isEmpty {
        LoggingService.shared.network.info(
          "Memory cache TTL eviction: removed \(expiredKeys.count, privacy: .public) expired entries"
        )
      }

      // Also run disk eviction
      self.diskStore.evictExpiredAndEnforceLRU()

      // Log combined cache statistics
      let diskStats = self.diskStore.getStats()
      let stats = CacheStats(
        hits: self.hits,
        misses: self.misses,
        evictions: self.evictions,
        currentSize: self.cache.count,
        maxSize: self.maxCacheSize,
        diskEntries: diskStats.entries,
        diskBytes: diskStats.totalBytes
      )

      LoggingService.shared.network.info(
        "Cache stats: \(stats.hitRate, format: .fixed(precision: 1), privacy: .public)% hit rate (\(stats.hits) hits / \(stats.hits + stats.misses) requests), memory: \(stats.currentSize) entries, disk: \(stats.diskEntries) entries (\(stats.diskBytes / 1024 / 1024) MB)"
      )
    }
  }
}

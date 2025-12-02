//
//  ThumbnailCache.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import Foundation
import os

// MARK: - URLSession Protocol for Testability

/// Protocol for URLSession to enable mocking in tests.
protocol URLSessionProtocol: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - ThumbnailCache Error Types

/// Errors specific to thumbnail cache operations.
enum ThumbnailCacheError: LocalizedError {
  case httpStatus(Int)
  case invalidContentType(actual: String?)
  case invalidResponse
  case network(Error)

  var errorDescription: String? {
    switch self {
    case .httpStatus(let code):
      return "Thumbnail request failed: HTTP \(code)"
    case .invalidContentType(let contentType):
      return "Non-image content, not cached (Content-Type: \(contentType ?? "unknown"))"
    case .invalidResponse:
      return "Invalid response for thumbnail request."
    case .network(let error):
      return "Network error: \(error.localizedDescription)"
    }
  }
}

/// Disk-backed image cache with HTTP cache semantics.
///
/// **Features:**
/// - Two-tier caching: memory (NSCache) + disk (file-based)
/// - Respects HTTP Cache-Control directives:
///   - `no-store`: Do not cache
///   - `no-cache` / `must-revalidate`: Cache but always revalidate
///   - `max-age`: TTL from server
/// - Supports ETag / If-None-Match and Last-Modified / If-Modified-Since
/// - LRU eviction with configurable disk size limit (default 500MB)
/// - Only caches Content-Type: image/* (compliance: no stream caching)
///
/// **Thread Safety:**
/// - `stateQueue`: Guards counters (hits, totalRequests) and inMemoryMeta dictionary
/// - `diskQueue`: Guards disk operations and diskIndex
/// - `memoryCache` (NSCache): Thread-safe by design
///
/// **Usage:**
/// ```swift
/// let data = try await ThumbnailCache.shared.load(url: thumbnailURL)
/// let image = NSImage(data: data)
/// ```
final class ThumbnailCache: @unchecked Sendable {
  // MARK: - Singleton

  static let shared = ThumbnailCache()

  // MARK: - Types

  /// Parsed HTTP cache policy from response headers (case-insensitive)
  struct CachePolicy {
    let noStore: Bool
    let noCache: Bool
    let mustRevalidate: Bool
    let maxAge: TimeInterval?
    let expiresAt: Date?
    let etag: String?
    let lastModified: String?

    /// Parse cache policy from HTTPURLResponse (case-insensitive header access).
    static func from(response: HTTPURLResponse, responseDate: Date = Date()) -> CachePolicy {
      var noStore = false
      var noCache = false
      var mustRevalidate = false
      var maxAge: TimeInterval?
      var expiresAt: Date?

      // Parse Cache-Control header (case-insensitive via HTTPURLResponse)
      if let cacheControl = response.value(forHTTPHeaderField: "Cache-Control")?.lowercased() {
        let directives = cacheControl.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        noStore = directives.contains("no-store")
        noCache = directives.contains("no-cache")
        mustRevalidate = directives.contains("must-revalidate")

        // Extract max-age
        for directive in directives {
          if directive.hasPrefix("max-age=") {
            let value = directive.dropFirst("max-age=".count)
            if let seconds = TimeInterval(value) {
              maxAge = seconds
              expiresAt = responseDate.addingTimeInterval(seconds)
            }
          }
        }
      }

      // Fallback to Expires header if no max-age
      if expiresAt == nil, let expiresString = response.value(forHTTPHeaderField: "Expires") {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: expiresString) {
          expiresAt = date
        }
      }

      return CachePolicy(
        noStore: noStore,
        noCache: noCache,
        mustRevalidate: mustRevalidate,
        maxAge: maxAge,
        expiresAt: expiresAt,
        etag: response.value(forHTTPHeaderField: "ETag"),
        lastModified: response.value(forHTTPHeaderField: "Last-Modified")
      )
    }
  }

  /// Metadata stored alongside cached images
  struct ImageMetadata: Codable {
    let etag: String?
    let lastModified: String?
    let expiresAt: Date?
    let mustRevalidate: Bool
    let contentType: String
    let contentLength: Int
    let cachedAt: Date
    var lastAccessedAt: Date

    var isExpired: Bool {
      if let expiresAt = expiresAt {
        return Date() > expiresAt
      }
      // Default TTL if no expiration info
      return Date().timeIntervalSince(cachedAt) > Configuration.Cache.thumbnailDefaultTTL
    }

    var needsRevalidation: Bool {
      return mustRevalidate || isExpired
    }
  }

  /// Index entry for disk cache
  struct IndexEntry: Codable {
    let urlHash: String
    var metadata: ImageMetadata
  }

  /// Cache statistics
  struct Stats {
    let memoryItems: Int
    let diskEntries: Int
    let diskBytes: Int
    let hitRate: Double
  }

  // MARK: - Properties

  private let session: any URLSessionProtocol
  private let directory: URL
  private let maxDiskBytes: Int

  /// Memory cache using NSCache for automatic eviction under memory pressure.
  /// Note: NSCache's countLimit is a soft limit and the OS may evict earlier.
  private let memoryCache = NSCache<NSString, NSData>()

  /// In-memory metadata for memory-cached items (protected by stateQueue)
  private var inMemoryMeta: [String: ImageMetadata] = [:]

  /// Disk index for LRU tracking (protected by diskQueue)
  private var diskIndex: [String: IndexEntry] = [:]

  /// Metrics (protected by stateQueue)
  private var hits = 0
  private var totalRequests = 0

  /// Serial queue for disk operations (index, file I/O)
  private let diskQueue = DispatchQueue(label: "com.mytoob.thumbnailCache.disk")

  /// Serial queue for in-memory state (counters, inMemoryMeta)
  private let stateQueue = DispatchQueue(label: "com.mytoob.thumbnailCache.state")

  /// Debounce timer for index writes
  private var indexWriteWorkItem: DispatchWorkItem?

  // MARK: - Initialization

  private init() {
    self.session = URLSession.shared
    self.maxDiskBytes = Configuration.Cache.thumbnailDiskMaxBytes

    let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
      .appendingPathComponent(Configuration.Cache.cacheRootDirName)
      .appendingPathComponent(Configuration.Cache.thumbnailSubdir, isDirectory: true)
    self.directory = cachesDir

    // Configure memory cache limits (approximate bound)
    memoryCache.countLimit = Configuration.Cache.thumbnailMemoryItemsLimit

    // Ensure directory exists
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    // Load disk index synchronously to ensure cache is ready immediately
    loadDiskIndexSync()
  }

  /// Test-only initializer for dependency injection.
  /// - Parameters:
  ///   - rootDirectory: Cache directory (aliased as rootDirectory for test clarity)
  ///   - maxDiskBytes: Maximum disk cache size
  ///   - session: URLSession-compatible object for network requests (injectable for tests)
  init(
    rootDirectory: URL,
    maxDiskBytes: Int = Configuration.Cache.thumbnailDiskMaxBytes,
    session: any URLSessionProtocol
  ) {
    self.session = session
    self.directory = rootDirectory
    self.maxDiskBytes = maxDiskBytes

    memoryCache.countLimit = Configuration.Cache.thumbnailMemoryItemsLimit

    // Ensure directory exists
    try? FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

    // Load disk index synchronously
    loadDiskIndexSync()
  }

  // MARK: - Public API

  /// Fetch image data for a URL, using cache when available.
  /// - Parameter url: The image URL to load
  /// - Returns: Image data
  /// - Throws: ThumbnailCacheError if the request fails
  func fetchImage(from url: URL) async throws -> Data {
    return try await load(url: url)
  }

  /// Load image data for a URL, using cache when available.
  /// - Parameter url: The image URL to load
  /// - Returns: Image data
  /// - Throws: ThumbnailCacheError if the request fails
  func load(url: URL) async throws -> Data {
    let key = Hashing.canonicalKeyString(from: url)
    let keyNS = key as NSString

    stateQueue.sync { totalRequests += 1 }

    // Check memory cache (NSCache is thread-safe, stateQueue protects inMemoryMeta)
    if let data = memoryCache.object(forKey: keyNS) {
      let meta = stateQueue.sync { inMemoryMeta[key] }
      if let meta = meta, !meta.mustRevalidate && !meta.isExpired {
        stateQueue.sync { hits += 1 }
        LoggingService.shared.network.debug("Thumbnail memory HIT for \(url.absoluteString, privacy: .public)")
        return data as Data
      }
    }

    // Check disk cache
    let diskResult = diskQueue.sync { loadFromDisk(key: key) }

    if let (data, meta) = diskResult {
      if !meta.needsRevalidation {
        // Valid cache - use it
        stateQueue.sync {
          hits += 1
          // Atomic update of memory cache and metadata
          memoryCache.setObject(data as NSData, forKey: keyNS)
          inMemoryMeta[key] = meta
        }

        LoggingService.shared.network.debug("Thumbnail disk HIT for \(url.absoluteString, privacy: .public)")
        return data
      }

      // Needs revalidation - do conditional request
      return try await fetchWithRevalidation(url: url, key: key, cachedMeta: meta, cachedData: data)
    }

    // No cache - fetch fresh
    return try await fetchFresh(url: url, key: key)
  }

  /// Prefetch images for given URLs (fire-and-forget).
  /// - Parameter urls: Array of image URLs to prefetch
  func prefetch(urls: [URL]) async {
    await withTaskGroup(of: Void.self) { group in
      for url in urls {
        group.addTask {
          _ = try? await self.load(url: url)
        }
      }
    }
  }

  /// Clear all cached images (memory and disk).
  ///
  /// - Parameter waitUntilFinished: If true, blocks until clearing completes.
  ///   Defaults to false for non-blocking behavior.
  func clear(waitUntilFinished: Bool = false) {
    let stateWork = { [weak self] in
      guard let self = self else { return }
      self.memoryCache.removeAllObjects()
      self.inMemoryMeta.removeAll()
      self.hits = 0
      self.totalRequests = 0
    }

    let diskWork = { [weak self] in
      guard let self = self else { return }

      let fileManager = FileManager.default
      if let contents = try? fileManager.contentsOfDirectory(at: self.directory, includingPropertiesForKeys: nil) {
        for fileURL in contents {
          try? fileManager.removeItem(at: fileURL)
        }
      }
      self.diskIndex.removeAll()

      LoggingService.shared.network.info("Thumbnail cache cleared - all entries removed")
    }

    if waitUntilFinished {
      stateQueue.sync(execute: stateWork)
      diskQueue.sync(execute: diskWork)
    } else {
      stateQueue.async(execute: stateWork)
      diskQueue.async(execute: diskWork)
    }
  }

  /// Get cache statistics.
  /// - Returns: Cache statistics
  func getStats() -> Stats {
    // Get state metrics
    let (currentHits, currentTotal, memoryCount) = stateQueue.sync {
      (hits, totalRequests, inMemoryMeta.count)
    }

    // Get disk metrics
    let (diskCount, diskBytes) = diskQueue.sync {
      let bytes = diskIndex.values.reduce(0) { $0 + $1.metadata.contentLength }
      return (diskIndex.count, bytes)
    }

    let hitRate = currentTotal > 0 ? Double(currentHits) / Double(currentTotal) * 100.0 : 0.0
    return Stats(
      memoryItems: memoryCount,
      diskEntries: diskCount,
      diskBytes: diskBytes,
      hitRate: hitRate
    )
  }

  /// Force eviction to stay under the disk size limit.
  /// Useful for tests that need to trigger eviction immediately.
  func evictToLimit() {
    diskQueue.sync {
      enforceDiskSizeLimit()
    }
  }

  // MARK: - Private Methods - Fetching

  /// Fetch with conditional request (revalidation).
  private func fetchWithRevalidation(url: URL, key: String, cachedMeta: ImageMetadata, cachedData: Data) async throws -> Data {
    var request = URLRequest(url: url)

    // Add conditional headers
    if let etag = cachedMeta.etag {
      request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }
    if let lastModified = cachedMeta.lastModified {
      request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
    }

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw ThumbnailCacheError.network(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ThumbnailCacheError.invalidResponse
    }

    let keyNS = key as NSString

    switch httpResponse.statusCode {
    case 304:
      // Not modified - update access time and return cached data
      stateQueue.sync {
        hits += 1
        memoryCache.setObject(cachedData as NSData, forKey: keyNS)
        inMemoryMeta[key] = cachedMeta
      }
      touchDiskEntry(key: key)

      LoggingService.shared.network.debug("Thumbnail 304 (revalidated) for \(url.absoluteString, privacy: .public)")
      return cachedData

    case 200:
      // New data - validate and cache
      return try processFreshResponse(url: url, key: key, data: data, response: httpResponse)

    default:
      throw ThumbnailCacheError.httpStatus(httpResponse.statusCode)
    }
  }

  /// Fetch fresh (no cache available).
  private func fetchFresh(url: URL, key: String) async throws -> Data {
    let request = URLRequest(url: url)
    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw ThumbnailCacheError.network(error)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ThumbnailCacheError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      throw ThumbnailCacheError.httpStatus(httpResponse.statusCode)
    }

    return try processFreshResponse(url: url, key: key, data: data, response: httpResponse)
  }

  /// Process a fresh 200 response.
  private func processFreshResponse(url: URL, key: String, data: Data, response: HTTPURLResponse) throws -> Data {
    // Validate Content-Type is image/*
    let contentType = response.value(forHTTPHeaderField: "Content-Type")
    guard let contentType = contentType, contentType.hasPrefix("image/") else {
      // Not an image - throw error (compliance: no stream caching)
      LoggingService.shared.network.warning("Thumbnail not cached (non-image Content-Type) for \(url.absoluteString, privacy: .public)")
      throw ThumbnailCacheError.invalidContentType(actual: contentType)
    }

    // Parse cache policy from response (case-insensitive)
    let policy = CachePolicy.from(response: response)

    // no-store: return data without caching
    if policy.noStore {
      LoggingService.shared.network.debug("Thumbnail not cached (no-store) for \(url.absoluteString, privacy: .public)")
      return data
    }

    // Determine expiration
    let expiresAt: Date?
    if let policyExpires = policy.expiresAt {
      expiresAt = policyExpires
    } else {
      // Default TTL
      expiresAt = Date().addingTimeInterval(Configuration.Cache.thumbnailDefaultTTL)
    }

    // Build metadata
    let meta = ImageMetadata(
      etag: policy.etag,
      lastModified: policy.lastModified,
      expiresAt: expiresAt,
      mustRevalidate: policy.noCache || policy.mustRevalidate,
      contentType: contentType,
      contentLength: data.count,
      cachedAt: Date(),
      lastAccessedAt: Date()
    )

    // Atomically save to memory (stateQueue) and schedule disk write (diskQueue)
    let keyNS = key as NSString
    stateQueue.sync {
      memoryCache.setObject(data as NSData, forKey: keyNS)
      inMemoryMeta[key] = meta
    }

    diskQueue.async { [weak self] in
      self?.saveToDisk(key: key, data: data, metadata: meta)
    }

    LoggingService.shared.network.debug("Thumbnail cached for \(url.absoluteString, privacy: .public)")
    return data
  }

  // MARK: - Private Methods - Disk Operations

  /// Load from disk cache using pre-computed key.
  private func loadFromDisk(key: String) -> (Data, ImageMetadata)? {
    let urlHash = Hashing.sha256Hex(key)

    guard let indexEntry = diskIndex[urlHash] else {
      return nil
    }

    let bodyURL = bodyFileURL(for: urlHash)
    guard let data = try? Data(contentsOf: bodyURL) else {
      // Body file missing - clean up index
      diskIndex.removeValue(forKey: urlHash)
      scheduleIndexWrite()
      return nil
    }

    // Update last accessed
    var updatedEntry = indexEntry
    updatedEntry.metadata.lastAccessedAt = Date()
    diskIndex[urlHash] = updatedEntry
    scheduleIndexWrite()

    return (data, updatedEntry.metadata)
  }

  /// Save to disk cache.
  private func saveToDisk(key: String, data: Data, metadata: ImageMetadata) {
    let urlHash = Hashing.sha256Hex(key)

    // Write body
    let bodyURL = bodyFileURL(for: urlHash)
    do {
      try data.write(to: bodyURL, options: .atomic)
    } catch {
      LoggingService.shared.network.error("Failed to write thumbnail body: \(error.localizedDescription, privacy: .public)")
      return
    }

    // Update index
    let entry = IndexEntry(urlHash: urlHash, metadata: metadata)
    diskIndex[urlHash] = entry
    scheduleIndexWrite()

    // Enforce size limit
    enforceDiskSizeLimit()
  }

  /// Touch disk entry (update lastAccessedAt).
  private func touchDiskEntry(key: String) {
    diskQueue.async { [weak self] in
      guard let self = self else { return }

      let urlHash = Hashing.sha256Hex(key)
      guard var entry = self.diskIndex[urlHash] else { return }

      entry.metadata.lastAccessedAt = Date()
      self.diskIndex[urlHash] = entry
      self.scheduleIndexWrite()
    }
  }

  /// Enforce disk size limit with LRU eviction.
  private func enforceDiskSizeLimit() {
    var totalBytes = diskIndex.values.reduce(0) { $0 + $1.metadata.contentLength }

    while totalBytes > maxDiskBytes, !diskIndex.isEmpty {
      // Find LRU entry
      guard let lruEntry = diskIndex.values.min(by: { $0.metadata.lastAccessedAt < $1.metadata.lastAccessedAt }) else {
        break
      }

      // Remove files
      let bodyURL = bodyFileURL(for: lruEntry.urlHash)
      try? FileManager.default.removeItem(at: bodyURL)

      diskIndex.removeValue(forKey: lruEntry.urlHash)
      totalBytes -= lruEntry.metadata.contentLength

      LoggingService.shared.network.debug("Thumbnail LRU eviction: \(lruEntry.urlHash, privacy: .public)")
    }
  }

  // MARK: - Private Methods - Index Management

  private var indexFileURL: URL {
    return directory.appendingPathComponent("index.json")
  }

  /// Load disk index synchronously during init.
  private func loadDiskIndexSync() {
    diskQueue.sync { [weak self] in
      guard let self = self else { return }

      do {
        let data = try Data(contentsOf: self.indexFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([IndexEntry].self, from: data)
        self.diskIndex = Dictionary(uniqueKeysWithValues: entries.map { ($0.urlHash, $0) })
        LoggingService.shared.network.debug("Thumbnail cache loaded index with \(self.diskIndex.count) entries")
      } catch {
        // Index doesn't exist or is corrupt - start fresh
        self.diskIndex = [:]
      }
    }
  }

  private func scheduleIndexWrite() {
    indexWriteWorkItem?.cancel()

    let workItem = DispatchWorkItem { [weak self] in
      self?.writeIndex()
    }
    indexWriteWorkItem = workItem

    diskQueue.asyncAfter(deadline: .now() + 1.0, execute: workItem)
  }

  private func writeIndex() {
    do {
      let entries = Array(diskIndex.values)
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(entries)
      try data.write(to: indexFileURL, options: .atomic)
    } catch {
      LoggingService.shared.network.error("Failed to write thumbnail index: \(error.localizedDescription, privacy: .public)")
    }
  }

  // MARK: - Private Methods - Utilities

  private func bodyFileURL(for urlHash: String) -> URL {
    return directory.appendingPathComponent("\(urlHash).img")
  }
}

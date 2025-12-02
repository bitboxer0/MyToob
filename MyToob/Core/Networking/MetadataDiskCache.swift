//
//  MetadataDiskCache.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import Foundation
import os

/// Disk-backed persistence layer for API metadata with ETag, TTL, and LRU eviction.
///
/// **Features:**
/// - Persists JSON response bodies + metadata (etag, timestamps)
/// - Enforces TTL (configurable, default 7 days)
/// - LRU eviction when disk size exceeds limit
/// - Thread-safe via serial DispatchQueue
///
/// **On-disk layout:**
/// ```
/// Caches/com.finley.mytoob/MetadataCache/
/// ├── <sha256>.body   (raw response Data)
/// ├── <sha256>.meta   (JSON: etag, cachedAt, lastAccessedAt, contentLength)
/// └── index.json      (index for quick LRU/size computation)
/// ```
///
/// **Usage:**
/// Used internally by `CachingLayer` as a disk tier. Not intended for direct use.
final class MetadataDiskCache {
  // MARK: - Types

  /// Metadata stored alongside each cached response body
  struct EntryMetadata: Codable {
    let etag: String
    let cachedAt: Date
    var lastAccessedAt: Date
    let contentLength: Int
  }

  /// Index entry for tracking all cached items
  struct IndexEntry: Codable {
    let keyHash: String
    let etag: String
    let cachedAt: Date
    var lastAccessedAt: Date
    let contentLength: Int
  }

  /// Statistics about the disk cache
  struct Stats {
    let entries: Int
    let totalBytes: Int
  }

  // MARK: - Properties

  private let directory: URL
  private let maxBytes: Int
  private let defaultTTL: TimeInterval

  /// In-memory index for quick lookups and LRU tracking
  private var index: [String: IndexEntry] = [:]

  /// Serial queue for thread-safe disk operations
  private let queue = DispatchQueue(label: "com.mytoob.metadataDiskCache")

  /// Debounce timer for index writes
  private var indexWriteWorkItem: DispatchWorkItem?

  /// Indicates if cache is ready for use (directory created and index loaded)
  private(set) var isAvailable: Bool = false

  // MARK: - Initialization

  /// Initialize the disk cache.
  /// - Parameters:
  ///   - directory: Base directory for cache files
  ///   - maxBytes: Maximum total bytes on disk before LRU eviction
  ///   - defaultTTL: Time-to-live for cache entries (seconds)
  init(
    directory: URL,
    maxBytes: Int = Configuration.Cache.metadataDiskMaxBytes,
    defaultTTL: TimeInterval = Configuration.Cache.metadataTTL
  ) {
    self.directory = directory
    self.maxBytes = maxBytes
    self.defaultTTL = defaultTTL

    // Ensure directory exists - fail loudly if we can't create it
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    } catch {
      LoggingService.shared.network.error("MetadataDiskCache: Failed to create directory \(directory.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
      // isAvailable remains false - cache will operate as no-op
      return
    }

    // Load existing index synchronously so cache is ready immediately after init
    loadIndexSync()
    isAvailable = true
  }

  // MARK: - Public API

  /// Load a cache entry from disk if valid (not expired).
  /// - Parameter key: The cache key
  /// - Returns: Tuple of (CacheEntry, size) if found and valid, nil otherwise
  func loadEntry(for key: CachingLayer.CacheKey) -> (entry: CachingLayer.CacheEntry, size: Int)? {
    guard isAvailable else { return nil }
    return queue.sync {
      let keyHash = hashKey(key)

      guard let indexEntry = index[keyHash] else {
        return nil
      }

      // Check TTL
      let age = Date().timeIntervalSince(indexEntry.cachedAt)
      if age > defaultTTL {
        // Expired - remove from disk
        removeEntryFiles(keyHash: keyHash)
        index.removeValue(forKey: keyHash)
        scheduleIndexWrite()
        LoggingService.shared.network.debug("Disk cache TTL expired for hash: \(keyHash, privacy: .public)")
        return nil
      }

      // Load body from disk
      let bodyURL = bodyFileURL(for: keyHash)
      guard let data = try? Data(contentsOf: bodyURL) else {
        // Body file missing - clean up index
        index.removeValue(forKey: keyHash)
        scheduleIndexWrite()
        return nil
      }

      // Update last accessed time
      var updatedEntry = indexEntry
      updatedEntry.lastAccessedAt = Date()
      index[keyHash] = updatedEntry
      scheduleIndexWrite()

      // Also update the .meta file
      updateMetaFile(keyHash: keyHash, entry: updatedEntry)

      let cacheEntry = CachingLayer.CacheEntry(
        responseData: data,
        etag: indexEntry.etag,
        cachedAt: indexEntry.cachedAt,
        lastAccessedAt: Date()
      )

      return (cacheEntry, indexEntry.contentLength)
    }
  }

  /// Load a stale cache entry from disk (ignores TTL).
  /// - Parameter key: The cache key
  /// - Returns: Tuple of (CacheEntry, size) if found, nil otherwise
  func loadStaleEntry(for key: CachingLayer.CacheKey) -> (entry: CachingLayer.CacheEntry, size: Int)? {
    guard isAvailable else { return nil }
    return queue.sync {
      let keyHash = hashKey(key)

      guard let indexEntry = index[keyHash] else {
        return nil
      }

      // Load body from disk (ignore TTL)
      let bodyURL = bodyFileURL(for: keyHash)
      guard let data = try? Data(contentsOf: bodyURL) else {
        // Body file missing - clean up index
        index.removeValue(forKey: keyHash)
        scheduleIndexWrite()
        return nil
      }

      // Update last accessed time
      var updatedEntry = indexEntry
      updatedEntry.lastAccessedAt = Date()
      index[keyHash] = updatedEntry
      scheduleIndexWrite()

      let cacheEntry = CachingLayer.CacheEntry(
        responseData: data,
        etag: indexEntry.etag,
        cachedAt: indexEntry.cachedAt,
        lastAccessedAt: Date()
      )

      LoggingService.shared.network.debug("Disk cache loaded stale entry for hash: \(keyHash, privacy: .public)")
      return (cacheEntry, indexEntry.contentLength)
    }
  }

  /// Save a cache entry to disk.
  /// - Parameters:
  ///   - entry: The cache entry to save
  ///   - key: The cache key
  func saveEntry(_ entry: CachingLayer.CacheEntry, for key: CachingLayer.CacheKey) {
    guard isAvailable else { return }
    queue.async { [weak self] in
      guard let self = self else { return }

      let keyHash = self.hashKey(key)
      let contentLength = entry.responseData.count

      // Write body file
      let bodyURL = self.bodyFileURL(for: keyHash)
      do {
        try entry.responseData.write(to: bodyURL, options: .atomic)
      } catch {
        LoggingService.shared.network.error("Failed to write disk cache body: \(error.localizedDescription, privacy: .public)")
        return
      }

      // Write metadata file
      let metadata = EntryMetadata(
        etag: entry.etag,
        cachedAt: entry.cachedAt,
        lastAccessedAt: entry.lastAccessedAt,
        contentLength: contentLength
      )

      let metaURL = self.metaFileURL(for: keyHash)
      do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let metaData = try encoder.encode(metadata)
        try metaData.write(to: metaURL, options: .atomic)
      } catch {
        LoggingService.shared.network.error("Failed to write disk cache meta: \(error.localizedDescription, privacy: .public)")
        // Clean up body file on meta write failure
        try? FileManager.default.removeItem(at: bodyURL)
        return
      }

      // Update index
      let indexEntry = IndexEntry(
        keyHash: keyHash,
        etag: entry.etag,
        cachedAt: entry.cachedAt,
        lastAccessedAt: entry.lastAccessedAt,
        contentLength: contentLength
      )
      self.index[keyHash] = indexEntry
      self.scheduleIndexWrite()

      // Enforce size limit
      self.enforceSizeLimit()

      LoggingService.shared.network.debug("Disk cache saved entry for hash: \(keyHash, privacy: .public) (\(contentLength) bytes)")
    }
  }

  /// Update last accessed time for a key (touch).
  /// - Parameter key: The cache key
  func touch(_ key: CachingLayer.CacheKey) {
    guard isAvailable else { return }
    queue.async { [weak self] in
      guard let self = self else { return }

      let keyHash = self.hashKey(key)
      guard var entry = self.index[keyHash] else { return }

      entry.lastAccessedAt = Date()
      self.index[keyHash] = entry
      self.scheduleIndexWrite()
      self.updateMetaFile(keyHash: keyHash, entry: entry)
    }
  }

  /// Evict expired entries and enforce LRU size limit.
  ///
  /// - Parameter waitUntilFinished: If true, blocks until eviction completes.
  ///   Defaults to false (fire-and-forget) for background maintenance.
  func evictExpiredAndEnforceLRU(waitUntilFinished: Bool = false) {
    guard isAvailable else { return }

    let work = { [weak self] in
      guard let self = self else { return }

      let now = Date()
      var expiredKeys: [String] = []

      // Find expired entries
      for (keyHash, entry) in self.index {
        if now.timeIntervalSince(entry.cachedAt) > self.defaultTTL {
          expiredKeys.append(keyHash)
        }
      }

      // Remove expired entries
      for keyHash in expiredKeys {
        self.removeEntryFiles(keyHash: keyHash)
        self.index.removeValue(forKey: keyHash)
      }

      if !expiredKeys.isEmpty {
        LoggingService.shared.network.info("Disk cache TTL eviction: removed \(expiredKeys.count) expired entries")
      }

      // Enforce size limit
      self.enforceSizeLimit()

      self.scheduleIndexWrite()
    }

    if waitUntilFinished {
      queue.sync(execute: work)
    } else {
      queue.async(execute: work)
    }
  }

  /// Clear all cached entries.
  ///
  /// - Parameter waitUntilFinished: If true, blocks until clearing completes.
  ///   Defaults to false for non-blocking behavior.
  func clear(waitUntilFinished: Bool = false) {
    guard isAvailable else { return }

    let work = { [weak self] in
      guard let self = self else { return }

      // Remove all files in directory
      let fileManager = FileManager.default
      if let contents = try? fileManager.contentsOfDirectory(at: self.directory, includingPropertiesForKeys: nil) {
        for fileURL in contents {
          try? fileManager.removeItem(at: fileURL)
        }
      }

      self.index.removeAll()

      LoggingService.shared.network.info("Disk cache cleared - all entries removed")
    }

    if waitUntilFinished {
      queue.sync(execute: work)
    } else {
      queue.async(execute: work)
    }
  }

  /// Get current cache statistics.
  /// - Returns: Cache stats (entries count, total bytes)
  func getStats() -> Stats {
    guard isAvailable else { return Stats(entries: 0, totalBytes: 0) }
    return queue.sync {
      let totalBytes = index.values.reduce(0) { $0 + $1.contentLength }
      return Stats(entries: index.count, totalBytes: totalBytes)
    }
  }

  // MARK: - Private Methods

  /// Generate a hash for the cache key.
  private func hashKey(_ key: CachingLayer.CacheKey) -> String {
    let canonical = Hashing.canonicalKeyString(url: key.url, queryItems: key.queryItems)
    return Hashing.sha256Hex(canonical)
  }

  /// URL for the body file.
  private func bodyFileURL(for keyHash: String) -> URL {
    return directory.appendingPathComponent("\(keyHash).body")
  }

  /// URL for the metadata file.
  private func metaFileURL(for keyHash: String) -> URL {
    return directory.appendingPathComponent("\(keyHash).meta")
  }

  /// URL for the index file.
  private var indexFileURL: URL {
    return directory.appendingPathComponent("index.json")
  }

  /// Load the index from disk synchronously.
  /// Called during init to ensure cache is ready immediately.
  private func loadIndexSync() {
    queue.sync {
      do {
        let data = try Data(contentsOf: self.indexFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([IndexEntry].self, from: data)

        // Rebuild index dictionary
        self.index = Dictionary(uniqueKeysWithValues: entries.map { ($0.keyHash, $0) })

        LoggingService.shared.network.debug("Disk cache loaded index with \(self.index.count) entries")
      } catch {
        // Index doesn't exist or is corrupt - rebuild from files
        self.rebuildIndexSync()
      }
    }
  }

  /// Rebuild the index by scanning the cache directory (synchronous, called from loadIndexSync).
  /// Must be called from within queue.sync block.
  private func rebuildIndexSync() {
    let fileManager = FileManager.default

    guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
      return
    }

    var newIndex: [String: IndexEntry] = [:]

    // Find all .meta files
    let metaFiles = contents.filter { $0.pathExtension == "meta" }

    for metaURL in metaFiles {
      let keyHash = metaURL.deletingPathExtension().lastPathComponent

      // Check that body file exists
      let bodyURL = bodyFileURL(for: keyHash)
      guard fileManager.fileExists(atPath: bodyURL.path) else {
        // Clean up orphaned meta file
        try? fileManager.removeItem(at: metaURL)
        continue
      }

      // Load metadata
      do {
        let data = try Data(contentsOf: metaURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let metadata = try decoder.decode(EntryMetadata.self, from: data)

        let entry = IndexEntry(
          keyHash: keyHash,
          etag: metadata.etag,
          cachedAt: metadata.cachedAt,
          lastAccessedAt: metadata.lastAccessedAt,
          contentLength: metadata.contentLength
        )
        newIndex[keyHash] = entry
      } catch {
        // Corrupt meta file - remove both files
        try? fileManager.removeItem(at: metaURL)
        try? fileManager.removeItem(at: bodyURL)
      }
    }

    index = newIndex
    // Schedule async write (don't block init)
    scheduleIndexWrite()

    LoggingService.shared.network.info("Disk cache rebuilt index with \(self.index.count) entries")
  }

  /// Schedule a debounced write of the index to disk.
  private func scheduleIndexWrite() {
    indexWriteWorkItem?.cancel()

    let workItem = DispatchWorkItem { [weak self] in
      self?.writeIndex()
    }
    indexWriteWorkItem = workItem

    // Debounce: write after 1 second of inactivity
    queue.asyncAfter(deadline: .now() + 1.0, execute: workItem)
  }

  /// Write the index to disk.
  private func writeIndex() {
    do {
      let entries = Array(index.values)
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(entries)
      try data.write(to: indexFileURL, options: .atomic)
    } catch {
      LoggingService.shared.network.error("Failed to write disk cache index: \(error.localizedDescription, privacy: .public)")
    }
  }

  /// Update the metadata file for an entry.
  private func updateMetaFile(keyHash: String, entry: IndexEntry) {
    let metadata = EntryMetadata(
      etag: entry.etag,
      cachedAt: entry.cachedAt,
      lastAccessedAt: entry.lastAccessedAt,
      contentLength: entry.contentLength
    )

    let metaURL = metaFileURL(for: keyHash)
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(metadata)
      try data.write(to: metaURL, options: .atomic)
    } catch {
      LoggingService.shared.network.error("Failed to update meta file: \(error.localizedDescription, privacy: .public)")
    }
  }

  /// Remove entry files from disk.
  private func removeEntryFiles(keyHash: String) {
    let fileManager = FileManager.default
    try? fileManager.removeItem(at: bodyFileURL(for: keyHash))
    try? fileManager.removeItem(at: metaFileURL(for: keyHash))
  }

  /// Enforce the size limit by evicting LRU entries.
  private func enforceSizeLimit() {
    var totalBytes = index.values.reduce(0) { $0 + $1.contentLength }

    while totalBytes > maxBytes, !index.isEmpty {
      // Find least recently used entry
      guard let lruEntry = index.values.min(by: { $0.lastAccessedAt < $1.lastAccessedAt }) else {
        break
      }

      removeEntryFiles(keyHash: lruEntry.keyHash)
      index.removeValue(forKey: lruEntry.keyHash)
      totalBytes -= lruEntry.contentLength

      LoggingService.shared.network.debug("Disk cache LRU eviction: removed \(lruEntry.keyHash, privacy: .public)")
    }
  }
}

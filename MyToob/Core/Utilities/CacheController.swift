//
//  CacheController.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import Foundation
import os

/// Unified controller for managing all app caches.
///
/// Provides a single entry point for:
/// - Clearing all caches (metadata + thumbnails)
/// - Retrieving aggregate cache statistics
/// - Measuring actual disk usage
///
/// **Usage:**
/// ```swift
/// // Clear all caches (async)
/// await CacheController.shared.clearAllCachesAsync()
///
/// // Clear all caches with completion handler
/// CacheController.shared.clearAllCaches { print("Done!") }
///
/// // Get aggregate stats
/// let stats = CacheController.shared.getAggregateStats()
/// print("Total disk: \(stats.totalDiskBytes) bytes")
/// ```
final class CacheController {
  // MARK: - Singleton

  static let shared = CacheController()

  // MARK: - Types

  /// Aggregate statistics from all caches
  struct AggregateStats {
    let metadata: CachingLayer.CacheStats
    let thumbnails: ThumbnailCache.Stats

    /// Total disk bytes used by all caches
    var totalDiskBytes: Int {
      return metadata.diskBytes + thumbnails.diskBytes
    }

    /// Total number of disk entries across all caches
    var totalDiskEntries: Int {
      return metadata.diskEntries + thumbnails.diskEntries
    }

    /// Human-readable total disk size
    var formattedDiskSize: String {
      return CacheController.formatBytes(totalDiskBytes)
    }
  }

  /// Simple disk usage breakdown
  struct DiskUsage {
    let metadataBytes: Int
    let thumbnailBytes: Int

    var totalBytes: Int {
      return metadataBytes + thumbnailBytes
    }

    var formattedTotal: String {
      return CacheController.formatBytes(totalBytes)
    }
  }

  // MARK: - Initialization

  private init() {}

  // MARK: - Public API

  /// Clear all caches asynchronously.
  ///
  /// This removes:
  /// - In-memory metadata cache entries
  /// - Disk-persisted metadata cache entries
  /// - In-memory thumbnail cache entries
  /// - Disk-persisted thumbnail cache entries
  ///
  /// Does NOT affect:
  /// - User library data (VideoItem, ChannelBlacklist, etc.)
  /// - OAuth tokens
  /// - App settings
  ///
  /// This method returns only after both caches have been fully cleared.
  func clearAllCachesAsync() async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        CachingLayer.shared.clearCache(waitUntilFinished: true)
      }
      group.addTask {
        ThumbnailCache.shared.clear(waitUntilFinished: true)
      }
    }

    LoggingService.shared.app.info("All caches cleared via CacheController (async)")
  }

  /// Clear all caches with completion handler.
  ///
  /// This is an alternative to the async version for use in non-async contexts.
  /// The completion handler is called on the main queue after all caches have been cleared.
  ///
  /// - Parameter completion: Optional completion handler called on main queue when done
  func clearAllCaches(completion: (() -> Void)? = nil) {
    let group = DispatchGroup()

    group.enter()
    DispatchQueue.global(qos: .userInitiated).async {
      CachingLayer.shared.clearCache(waitUntilFinished: true)
      group.leave()
    }

    group.enter()
    DispatchQueue.global(qos: .userInitiated).async {
      ThumbnailCache.shared.clear(waitUntilFinished: true)
      group.leave()
    }

    group.notify(queue: .main) {
      LoggingService.shared.app.info("All caches cleared via CacheController")
      completion?()
    }
  }

  /// Get aggregate statistics from all caches.
  /// - Returns: Combined statistics from metadata and thumbnail caches
  func getAggregateStats() -> AggregateStats {
    let metadataStats = CachingLayer.shared.getCacheStats()
    let thumbnailStats = ThumbnailCache.shared.getStats()

    return AggregateStats(
      metadata: metadataStats,
      thumbnails: thumbnailStats
    )
  }

  /// Get simple disk usage breakdown.
  /// - Returns: Disk usage by cache type
  func getDiskUsage() -> DiskUsage {
    let metaBytes = CachingLayer.shared.getCacheStats().diskBytes
    let thumbBytes = ThumbnailCache.shared.getStats().diskBytes

    return DiskUsage(
      metadataBytes: metaBytes,
      thumbnailBytes: thumbBytes
    )
  }

  /// Calculate total disk usage by enumerating the cache directory.
  ///
  /// This provides an accurate on-disk measurement using file system attributes,
  /// which may differ from the tracked index sizes due to filesystem overhead,
  /// orphaned files, or other discrepancies.
  ///
  /// - Returns: Total bytes used by the cache directory on disk
  func diskUsageBytes() -> Int {
    let fileManager = FileManager.default
    let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first

    guard let cacheRoot = cachesDir?.appendingPathComponent(Configuration.Cache.cacheRootDirName) else {
      return 0
    }

    guard fileManager.fileExists(atPath: cacheRoot.path) else {
      return 0
    }

    var totalBytes: Int = 0
    let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]

    guard let enumerator = fileManager.enumerator(
      at: cacheRoot,
      includingPropertiesForKeys: Array(resourceKeys),
      options: [.skipsHiddenFiles],
      errorHandler: nil
    ) else {
      return 0
    }

    for case let fileURL as URL in enumerator {
      do {
        let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
        if resourceValues.isRegularFile == true {
          totalBytes += resourceValues.fileSize ?? 0
        }
      } catch {
        // Skip files we can't read
        continue
      }
    }

    return totalBytes
  }

  /// Human-readable string for disk usage.
  /// - Returns: Formatted string like "45.2 MB" or "1.2 GB"
  func formattedDiskUsage() -> String {
    return Self.formatBytes(diskUsageBytes())
  }

  // MARK: - Private Helpers

  /// Format bytes into a human-readable string.
  private static func formatBytes(_ bytes: Int) -> String {
    if bytes < 1024 {
      return "\(bytes) B"
    } else if bytes < 1024 * 1024 {
      return String(format: "%.1f KB", Double(bytes) / 1024.0)
    } else if bytes < 1024 * 1024 * 1024 {
      return String(format: "%.1f MB", Double(bytes) / 1024.0 / 1024.0)
    } else {
      return String(format: "%.2f GB", Double(bytes) / 1024.0 / 1024.0 / 1024.0)
    }
  }
}

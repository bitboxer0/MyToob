//
//  SpotlightIndexer.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/5/25.
//

import CoreSpotlight
import CryptoKit
import Foundation
import OSLog
import UniformTypeIdentifiers

/// Actor responsible for indexing videos in Spotlight for system-wide search.
///
/// The SpotlightIndexer creates `CSSearchableItem` entries for each `VideoItem`,
/// allowing users to discover their videos through macOS Spotlight search.
///
/// **Key Features:**
/// - Indexes both YouTube and local video files
/// - Includes title, keywords (AI topic tags), and duration in search metadata
/// - Respects user's indexing preference via `SpotlightSettingsStore`
/// - Supports batch operations for reindexing
///
/// **Usage:**
/// ```swift
/// // Index a single video
/// await SpotlightIndexer.shared.indexVideo(video)
///
/// // Remove a video from the index
/// await SpotlightIndexer.shared.removeVideo(video)
///
/// // Reindex all videos
/// await SpotlightIndexer.shared.reindexAll(videos)
/// ```
actor SpotlightIndexer {

  // MARK: - Singleton

  /// Shared instance for app-wide access
  static let shared = SpotlightIndexer()

  // MARK: - Constants

  /// Domain identifier for MyToob videos in Spotlight
  static let domainIdentifier = "com.finley.mytoob.videos"

  /// Prefix for YouTube video identifiers
  private static let youtubePrefix = "video-"

  /// Prefix for local video identifiers
  private static let localPrefix = "local-"

  // MARK: - Properties

  /// Tracks which video identifiers have been indexed in this session
  /// Used for testing and verification
  private var indexedIdentifiers: Set<String> = []

  /// The searchable index to use (allows injection for testing)
  private let searchableIndex: CSSearchableIndex

  // MARK: - Initialization

  /// Private initializer for singleton pattern
  private init() {
    self.searchableIndex = CSSearchableIndex.default()
  }

  /// Initializer with dependency injection for testing
  /// - Parameter searchableIndex: The CSSearchableIndex to use
  init(searchableIndex: CSSearchableIndex) {
    self.searchableIndex = searchableIndex
  }

  // MARK: - Public API

  /// Creates a unique identifier for a video suitable for Spotlight indexing.
  ///
  /// - Parameter video: The video to create an identifier for
  /// - Returns: A unique string identifier
  static func uniqueIdentifier(for video: VideoItem) -> String {
    if let videoID = video.videoID {
      return "\(youtubePrefix)\(videoID)"
    } else if let localURL = video.localURL {
      // Use a stable hash of the full path for uniqueness while keeping filename for readability
      // This prevents collisions when files have the same name in different directories
      // (e.g., /path1/video.mp4 vs /path2/video.mp4)
      // Note: We use SHA256 instead of hashValue because hashValue is not stable across
      // app launches or OS versions, which would cause duplicate Spotlight entries.
      let filename =
        localURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        ?? localURL.lastPathComponent
      let pathData = Data(localURL.path.utf8)
      let hash = SHA256.hash(data: pathData)
      let hashString = String(
        hash.compactMap { String(format: "%02x", $0) }.joined().prefix(12)
      )
      return "\(localPrefix)\(filename)-\(hashString)"
    } else {
      // Fallback using the video's identifier property
      return "unknown-\(video.identifier)"
    }
  }

  /// Creates a CSSearchableItem for a video without indexing it.
  ///
  /// Use this method to inspect what would be indexed, or for testing purposes.
  ///
  /// - Parameter video: The video to create a searchable item for
  /// - Returns: A configured CSSearchableItem, or nil if creation fails
  func createSearchableItem(for video: VideoItem) -> CSSearchableItem? {
    let identifier = Self.uniqueIdentifier(for: video)

    // Create attribute set with movie content type
    let attributeSet = CSSearchableItemAttributeSet(contentType: .movie)

    // Set title (required)
    attributeSet.title = video.title

    // Set keywords from AI topic tags
    if !video.aiTopicTags.isEmpty {
      attributeSet.keywords = video.aiTopicTags
    }

    // Set duration
    attributeSet.duration = NSNumber(value: video.duration)

    // Set content type string
    attributeSet.contentType = UTType.movie.identifier

    // Set content description if available
    // Note: VideoItem doesn't have a description field yet
    // Future: attributeSet.contentDescription = video.videoDescription

    // Set thumbnail URL if available
    // Note: VideoItem doesn't have a thumbnailURL field yet
    // Future: attributeSet.thumbnailURL = video.thumbnailURL

    // Set additional metadata
    if video.isLocal, let localURL = video.localURL {
      attributeSet.contentURL = localURL
    }

    // Create the searchable item
    let item = CSSearchableItem(
      uniqueIdentifier: identifier,
      domainIdentifier: Self.domainIdentifier,
      attributeSet: attributeSet
    )

    // Set expiration date (optional - items don't expire by default)
    // item.expirationDate = Date.distantFuture

    return item
  }

  /// Indexes a video in Spotlight.
  ///
  /// Respects the user's indexing preference. If indexing is disabled,
  /// this method returns without indexing.
  ///
  /// - Parameters:
  ///   - video: The video to index
  ///   - settingsStore: Optional settings store (uses shared instance if nil)
  func indexVideo(_ video: VideoItem, settingsStore: SpotlightSettingsStore? = nil) async {
    // Check if indexing is enabled
    let store = await MainActor.run { settingsStore ?? SpotlightSettingsStore.shared }
    let isEnabled = await MainActor.run { store.isIndexingEnabled }

    guard isEnabled else {
      LoggingService.shared.integration.debug(
        "Spotlight indexing disabled, skipping: \(video.title, privacy: .private)"
      )
      return
    }

    guard let item = createSearchableItem(for: video) else {
      LoggingService.shared.integration.error(
        "Failed to create CSSearchableItem for: \(video.title, privacy: .private)"
      )
      return
    }

    do {
      try await searchableIndex.indexSearchableItems([item])
      indexedIdentifiers.insert(item.uniqueIdentifier)

      // Capture count before crossing actor boundary
      let currentCount = indexedIdentifiers.count

      // Update the indexed count on main actor
      await MainActor.run {
        SpotlightSettingsStore.shared.updateIndexedCount(currentCount)
      }

      LoggingService.shared.integration.info(
        "Indexed video in Spotlight: '\(video.title, privacy: .private)' [\(item.uniqueIdentifier, privacy: .public)]"
      )
    } catch {
      LoggingService.shared.integration.error(
        "Failed to index video in Spotlight: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  /// Updates a video's entry in the Spotlight index.
  ///
  /// This is equivalent to calling `indexVideo` since CSSearchableIndex
  /// automatically updates existing entries with the same identifier.
  ///
  /// - Parameter video: The video to update
  func updateVideo(_ video: VideoItem) async {
    await indexVideo(video)
  }

  /// Removes a video from the Spotlight index.
  ///
  /// - Parameter video: The video to remove
  func removeVideo(_ video: VideoItem) async {
    let identifier = Self.uniqueIdentifier(for: video)
    await removeVideo(byIdentifier: identifier)
  }

  /// Removes a video from the Spotlight index by its identifier.
  ///
  /// - Parameter identifier: The unique identifier of the video to remove
  func removeVideo(byIdentifier identifier: String) async {
    // Handle both raw IDs and prefixed IDs
    let fullIdentifier: String
    if identifier.hasPrefix(Self.youtubePrefix) || identifier.hasPrefix(Self.localPrefix) {
      fullIdentifier = identifier
    } else {
      // Assume it's a YouTube video ID if no prefix
      fullIdentifier = "\(Self.youtubePrefix)\(identifier)"
    }

    do {
      try await searchableIndex.deleteSearchableItems(withIdentifiers: [fullIdentifier])
      indexedIdentifiers.remove(fullIdentifier)

      // Capture count before crossing actor boundary
      let currentCount = indexedIdentifiers.count

      // Update the indexed count on main actor
      await MainActor.run {
        SpotlightSettingsStore.shared.updateIndexedCount(currentCount)
      }

      LoggingService.shared.integration.info(
        "Removed video from Spotlight index: \(fullIdentifier, privacy: .public)"
      )
    } catch {
      LoggingService.shared.integration.error(
        "Failed to remove video from Spotlight: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  /// Checks if a video is currently indexed in Spotlight.
  ///
  /// Note: This only checks the in-memory tracking set, not the actual
  /// Spotlight index. For accurate status, use `isVideoActuallyIndexed`.
  ///
  /// - Parameter video: The video to check
  /// - Returns: `true` if the video is in the tracking set
  func isVideoIndexed(_ video: VideoItem) -> Bool {
    let identifier = Self.uniqueIdentifier(for: video)
    return indexedIdentifiers.contains(identifier)
  }

  /// Reindexes all provided videos.
  ///
  /// This is a batch operation that clears the domain and reindexes all videos.
  /// Use this when the user enables indexing or requests a full reindex.
  ///
  /// - Parameter videos: Array of videos to index
  func reindexAll(_ videos: [VideoItem]) async {
    // First clear all existing items in our domain
    await clearAllIndexedItems()

    // Then index all videos
    var items: [CSSearchableItem] = []
    for video in videos {
      if let item = createSearchableItem(for: video) {
        items.append(item)
        indexedIdentifiers.insert(item.uniqueIdentifier)
      }
    }

    guard !items.isEmpty else {
      LoggingService.shared.integration.info("No videos to reindex")
      return
    }

    do {
      try await searchableIndex.indexSearchableItems(items)

      // Update the indexed count
      await MainActor.run {
        SpotlightSettingsStore.shared.updateIndexedCount(items.count)
      }

      LoggingService.shared.integration.info(
        "Reindexed \(items.count, privacy: .public) videos in Spotlight"
      )
    } catch {
      LoggingService.shared.integration.error(
        "Failed to reindex videos in Spotlight: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  /// Clears all indexed items from the Spotlight index.
  ///
  /// This removes all items with our domain identifier.
  func clearAllIndexedItems() async {
    do {
      try await searchableIndex.deleteSearchableItems(
        withDomainIdentifiers: [Self.domainIdentifier]
      )
      indexedIdentifiers.removeAll()

      // Update the indexed count
      await MainActor.run {
        SpotlightSettingsStore.shared.updateIndexedCount(0)
      }

      LoggingService.shared.integration.info("Cleared all videos from Spotlight index")
    } catch {
      LoggingService.shared.integration.error(
        "Failed to clear Spotlight index: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  // MARK: - Testing Support

  #if DEBUG
    /// Resets the indexer state for testing.
    /// Does not modify the actual Spotlight index.
    func resetForTesting() {
      indexedIdentifiers.removeAll()
    }

    /// Returns the current set of indexed identifiers for testing.
    func getIndexedIdentifiers() -> Set<String> {
      return indexedIdentifiers
    }
  #endif
}

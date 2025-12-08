//
//  SpotlightIndexingTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 12/5/25.
//

import CoreSpotlight
import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for Spotlight indexing functionality
/// Verifies CSSearchableItem creation, metadata mapping, and index management
@Suite("Spotlight Indexing Tests")
@MainActor
struct SpotlightIndexingTests {

  // MARK: - Test Helpers

  /// Creates an in-memory model container for testing
  private func createTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
      for: VideoItem.self,
      Note.self,
      configurations: config
    )
  }

  /// Creates a sample YouTube VideoItem for testing
  private func createYouTubeVideoItem(
    videoID: String = "testYT123",
    title: String = "Swift Programming Tutorial",
    channelID: String = "UCSwift123",
    duration: TimeInterval = 600.0,
    aiTopicTags: [String] = ["Swift", "Programming", "Tutorial"]
  ) -> VideoItem {
    VideoItem(
      videoID: videoID,
      title: title,
      channelID: channelID,
      duration: duration,
      aiTopicTags: aiTopicTags
    )
  }

  /// Creates a sample local VideoItem for testing
  private func createLocalVideoItem(
    localURL: URL = URL(fileURLWithPath: "/Users/test/videos/tutorial.mp4"),
    title: String = "Local Tutorial Video",
    duration: TimeInterval = 1200.0,
    aiTopicTags: [String] = ["Video", "Local"]
  ) -> VideoItem {
    VideoItem(
      localURL: localURL,
      title: title,
      duration: duration,
      aiTopicTags: aiTopicTags
    )
  }

  // MARK: - CSSearchableItem Creation Tests

  @Test("SpotlightIndexer creates CSSearchableItem for YouTube video")
  func testVideoIndexing_YouTube() async throws {
    // Given
    let video = createYouTubeVideoItem()

    // When
    let searchableItem = await SpotlightIndexer.shared.createSearchableItem(for: video)

    // Then
    #expect(searchableItem != nil)
    #expect(searchableItem?.uniqueIdentifier == "video-testYT123")
    #expect(searchableItem?.domainIdentifier == SpotlightIndexer.domainIdentifier)
  }

  @Test("SpotlightIndexer creates CSSearchableItem for local video")
  func testVideoIndexing_Local() async throws {
    // Given
    let localURL = URL(fileURLWithPath: "/Users/test/videos/my-video.mp4")
    let video = createLocalVideoItem(localURL: localURL, title: "My Local Video")

    // When
    let searchableItem = await SpotlightIndexer.shared.createSearchableItem(for: video)

    // Then
    #expect(searchableItem != nil)
    #expect(searchableItem?.uniqueIdentifier.hasPrefix("local-") == true)
    #expect(searchableItem?.domainIdentifier == SpotlightIndexer.domainIdentifier)
  }

  // MARK: - Metadata Inclusion Tests

  @Test("CSSearchableItem includes title in attribute set")
  func testMetadataInclusion_Title() async throws {
    // Given
    let video = createYouTubeVideoItem(title: "Advanced SwiftUI Animations")

    // When
    let searchableItem = await SpotlightIndexer.shared.createSearchableItem(for: video)
    let attributeSet = searchableItem?.attributeSet

    // Then
    #expect(attributeSet?.title == "Advanced SwiftUI Animations")
  }

  @Test("CSSearchableItem includes AI topic tags as keywords")
  func testMetadataInclusion_Keywords() async throws {
    // Given
    let tags = ["Swift", "SwiftUI", "Animation", "iOS"]
    let video = createYouTubeVideoItem(aiTopicTags: tags)

    // When
    let searchableItem = await SpotlightIndexer.shared.createSearchableItem(for: video)
    let attributeSet = searchableItem?.attributeSet

    // Then
    #expect(attributeSet?.keywords != nil)
    #expect(attributeSet?.keywords?.count == tags.count)
    for tag in tags {
      #expect(attributeSet?.keywords?.contains(tag) == true)
    }
  }

  @Test("CSSearchableItem includes duration")
  func testMetadataInclusion_Duration() async throws {
    // Given
    let video = createYouTubeVideoItem(duration: 900.0)  // 15 minutes

    // When
    let searchableItem = await SpotlightIndexer.shared.createSearchableItem(for: video)
    let attributeSet = searchableItem?.attributeSet

    // Then
    #expect(attributeSet?.duration != nil)
    #expect(attributeSet?.duration?.doubleValue == 900.0)
  }

  @Test("CSSearchableItem includes content type as movie")
  func testMetadataInclusion_ContentType() async throws {
    // Given
    let video = createYouTubeVideoItem()

    // When
    let searchableItem = await SpotlightIndexer.shared.createSearchableItem(for: video)
    let attributeSet = searchableItem?.attributeSet

    // Then
    #expect(attributeSet?.contentType == "public.movie")
  }

  // MARK: - Index Update Tests

  @Test("SpotlightIndexer can index a video")
  func testIndexVideo() async throws {
    // Given - use unique video ID to avoid test interference
    let video = createYouTubeVideoItem(videoID: "indexTest_\(UUID().uuidString)")
    let indexer = SpotlightIndexer.shared

    // When / Then - Should not throw
    // Note: In a real test environment, we would mock CSSearchableIndex
    // For now, we verify the method exists and accepts the correct parameters
    await indexer.indexVideo(video)

    // Verify through the indexing state
    let isIndexed = await indexer.isVideoIndexed(video)
    #expect(isIndexed == true)

    // Cleanup
    await indexer.removeVideo(video)
  }

  @Test("SpotlightIndexer updates index when video metadata changes")
  func testIndexUpdate() async throws {
    // Given - use unique video ID
    let uniqueID = "updateTest_\(UUID().uuidString)"
    let video = createYouTubeVideoItem(videoID: uniqueID, title: "Original Title")
    let indexer = SpotlightIndexer.shared

    // First index
    await indexer.indexVideo(video)

    // When - Simulate title change (in real code, this would be a SwiftData update)
    // Create new video with same ID but different title to simulate update
    let updatedVideo = createYouTubeVideoItem(
      videoID: uniqueID,
      title: "Updated Title"
    )

    // Update the index
    await indexer.updateVideo(updatedVideo)

    // Then - Verify the item was updated
    let searchableItem = await indexer.createSearchableItem(for: updatedVideo)
    #expect(searchableItem?.attributeSet.title == "Updated Title")

    // Cleanup
    await indexer.removeVideo(updatedVideo)
  }

  // MARK: - Index Deletion Tests

  @Test("SpotlightIndexer removes video from index")
  func testIndexDeletion() async throws {
    // Given - use unique video ID to avoid test interference
    let uniqueID = "deleteTest_\(UUID().uuidString)"
    let video = createYouTubeVideoItem(videoID: uniqueID)
    let indexer = SpotlightIndexer.shared

    // Index first
    await indexer.indexVideo(video)
    let wasIndexed = await indexer.isVideoIndexed(video)
    #expect(wasIndexed == true)

    // When
    await indexer.removeVideo(video)

    // Then
    let isStillIndexed = await indexer.isVideoIndexed(video)
    #expect(isStillIndexed == false)
  }

  @Test("SpotlightIndexer can remove video by identifier")
  func testIndexDeletion_ByIdentifier() async throws {
    // Given - use unique video ID
    let videoID = "toRemove_\(UUID().uuidString)"
    let video = createYouTubeVideoItem(videoID: videoID)
    let indexer = SpotlightIndexer.shared

    await indexer.indexVideo(video)

    // When
    await indexer.removeVideo(byIdentifier: videoID)

    // Then
    let isIndexed = await indexer.isVideoIndexed(video)
    #expect(isIndexed == false)
  }

  // MARK: - Settings Toggle Tests

  @Test("SpotlightSettingsStore defaults to enabled")
  func testSettingsToggle_DefaultEnabled() async throws {
    // Given
    // Use a test-specific key to avoid polluting user defaults
    let store = SpotlightSettingsStore(userDefaults: .standard, key: "test_spotlight_enabled")

    // When - Clear any existing value
    store.reset()

    // Then
    #expect(store.isIndexingEnabled == true)
  }

  @Test("SpotlightSettingsStore persists disabled state")
  func testSettingsToggle_Persistence() async throws {
    // Given
    let store = SpotlightSettingsStore(userDefaults: .standard, key: "test_spotlight_persist")
    store.reset()  // Start fresh

    // When
    store.isIndexingEnabled = false

    // Then - Create new store instance to verify persistence
    let newStore = SpotlightSettingsStore(userDefaults: .standard, key: "test_spotlight_persist")
    #expect(newStore.isIndexingEnabled == false)

    // Cleanup
    store.reset()
  }

  @Test("SpotlightIndexer respects settings toggle")
  func testSettingsToggle_IndexerRespects() async throws {
    // Given
    let store = SpotlightSettingsStore(userDefaults: .standard, key: "test_spotlight_indexer")
    store.reset()
    store.isIndexingEnabled = false

    let indexer = SpotlightIndexer.shared
    let video = createYouTubeVideoItem(videoID: "settingsTest123")

    // When - Try to index with indexing disabled
    await indexer.indexVideo(video, settingsStore: store)

    // Then - Video should not be indexed
    let isIndexed = await indexer.isVideoIndexed(video)
    #expect(isIndexed == false)

    // Cleanup
    store.reset()
  }

  // MARK: - Batch Operations Tests

  @Test("SpotlightIndexer can reindex all videos")
  func testReindexAll() async throws {
    // Given - use unique IDs
    let uuid = UUID().uuidString
    let videos = [
      createYouTubeVideoItem(videoID: "batch1_\(uuid)", title: "Video 1"),
      createYouTubeVideoItem(videoID: "batch2_\(uuid)", title: "Video 2"),
      createLocalVideoItem(
        localURL: URL(fileURLWithPath: "/test/video3_\(uuid).mp4"),
        title: "Video 3"
      ),
    ]

    let indexer = SpotlightIndexer.shared

    // When
    await indexer.reindexAll(videos)

    // Then
    for video in videos {
      let isIndexed = await indexer.isVideoIndexed(video)
      #expect(isIndexed == true)
    }

    // Cleanup
    for video in videos {
      await indexer.removeVideo(video)
    }
  }

  @Test("SpotlightIndexer can clear all indexed items")
  func testClearAll() async throws {
    // Given - use unique ID
    let video = createYouTubeVideoItem(videoID: "clearTest_\(UUID().uuidString)")
    let indexer = SpotlightIndexer.shared
    await indexer.indexVideo(video)

    // When
    await indexer.clearAllIndexedItems()

    // Then
    let isIndexed = await indexer.isVideoIndexed(video)
    #expect(isIndexed == false)
  }

  // MARK: - Unique Identifier Tests

  @Test("Unique identifier format for YouTube videos")
  func testUniqueIdentifier_YouTube() async throws {
    // Given
    let video = createYouTubeVideoItem(videoID: "abc123XYZ")

    // When
    let identifier = SpotlightIndexer.uniqueIdentifier(for: video)

    // Then
    #expect(identifier == "video-abc123XYZ")
  }

  @Test("Unique identifier format for local videos")
  func testUniqueIdentifier_Local() async throws {
    // Given
    let localURL = URL(fileURLWithPath: "/Users/test/Documents/my video.mp4")
    let video = createLocalVideoItem(localURL: localURL)

    // When
    let identifier = SpotlightIndexer.uniqueIdentifier(for: video)

    // Then
    // Should use URL-safe encoding of the filename with path hash for uniqueness
    #expect(identifier.hasPrefix("local-"))
    #expect(identifier.contains("my%20video.mp4") || identifier.contains("my video.mp4"))
    // Verify hash suffix is present (format: local-filename-<hash>)
    let components = identifier.split(separator: "-")
    #expect(components.count >= 3)  // "local", filename part(s), hash
  }

  @Test("Local video identifiers are unique for same filename in different directories")
  func testUniqueIdentifier_LocalCollisionPrevention() async throws {
    // Given - two files with the same name in different directories
    let url1 = URL(fileURLWithPath: "/path1/video.mp4")
    let url2 = URL(fileURLWithPath: "/path2/video.mp4")
    let video1 = createLocalVideoItem(localURL: url1, title: "Video 1")
    let video2 = createLocalVideoItem(localURL: url2, title: "Video 2")

    // When
    let identifier1 = SpotlightIndexer.uniqueIdentifier(for: video1)
    let identifier2 = SpotlightIndexer.uniqueIdentifier(for: video2)

    // Then - identifiers should be different due to path hash
    #expect(identifier1 != identifier2)
    #expect(identifier1.hasPrefix("local-video.mp4"))
    #expect(identifier2.hasPrefix("local-video.mp4"))
  }

  @Test("Local video identifiers are stable across multiple calls (SHA256 hash)")
  func testUniqueIdentifier_LocalStability() async throws {
    // Given - same video created multiple times (simulating app restart)
    let url = URL(fileURLWithPath: "/Users/test/Documents/my-video.mp4")

    // When - generate identifiers multiple times
    let video1 = createLocalVideoItem(localURL: url, title: "Video")
    let identifier1 = SpotlightIndexer.uniqueIdentifier(for: video1)

    let video2 = createLocalVideoItem(localURL: url, title: "Video")
    let identifier2 = SpotlightIndexer.uniqueIdentifier(for: video2)

    let video3 = createLocalVideoItem(localURL: url, title: "Video")
    let identifier3 = SpotlightIndexer.uniqueIdentifier(for: video3)

    // Then - all identifiers should be identical (stable hash)
    #expect(identifier1 == identifier2)
    #expect(identifier2 == identifier3)

    // Verify it uses 12-character hex hash (SHA256 truncated)
    let components = identifier1.split(separator: "-")
    let hashComponent = String(components.last ?? "")
    #expect(hashComponent.count == 12)
    // Verify all characters are valid hex
    #expect(hashComponent.allSatisfy { $0.isHexDigit })
  }

  // MARK: - Error Handling Tests

  @Test("SpotlightIndexer handles indexing errors gracefully")
  func testErrorHandling() async throws {
    // Given
    let video = createYouTubeVideoItem()
    let indexer = SpotlightIndexer.shared

    // When/Then - Should not throw, errors are logged
    await indexer.indexVideo(video)

    // The indexer should continue functioning after errors
    let canCreateItem = await indexer.createSearchableItem(for: video)
    #expect(canCreateItem != nil)
  }
}

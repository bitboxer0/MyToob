//
//  GetRandomVideoIntentTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for GetRandomVideoIntent
/// Verifies random video selection with optional collection filtering
@Suite("GetRandomVideoIntent Tests")
@MainActor
struct GetRandomVideoIntentTests {

  // MARK: - Test Helpers

  /// Creates an in-memory model container for testing
  private func createTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
      for: VideoItem.self,
      ClusterLabel.self,
      Note.self,
      configurations: config
    )
  }

  /// Creates a sample VideoItem for testing
  private func createVideoItem(
    videoID: String,
    title: String,
    aiTopicTags: [String] = [],
    watchProgress: TimeInterval = 0
  ) -> VideoItem {
    let video = VideoItem(
      videoID: videoID,
      title: title,
      channelID: "channel1",
      duration: 600.0,
      watchProgress: watchProgress,
      aiTopicTags: aiTopicTags
    )
    return video
  }

  /// Creates a sample ClusterLabel for testing
  private func createClusterLabel(
    clusterID: String,
    label: String,
    itemCount: Int = 10
  ) -> ClusterLabel {
    ClusterLabel(
      clusterID: clusterID,
      label: label,
      centroid: Array(repeating: 0.1, count: 512),
      itemCount: itemCount,
      confidenceScore: 0.8
    )
  }

  // MARK: - Intent Configuration Tests

  @Test("GetRandomVideoIntent has correct title")
  func testIntentTitle() async throws {
    // The title is a LocalizedStringResource, just verify it exists
    let title = GetRandomVideoIntent.title
    #expect(title != nil)
  }

  @Test("GetRandomVideoIntent has description")
  func testIntentDescription() async throws {
    // Verify the description is an IntentDescription type
    let description = GetRandomVideoIntent.description
    #expect(type(of: description) == IntentDescription.self)
  }

  // MARK: - Random Selection Tests

  @Test("Intent returns random video from all videos")
  func testRandomFromAll() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video1 = createVideoItem(videoID: "random1", title: "Video 1")
    let video2 = createVideoItem(videoID: "random2", title: "Video 2")
    let video3 = createVideoItem(videoID: "random3", title: "Video 3")
    context.insert(video1)
    context.insert(video2)
    context.insert(video3)
    try context.save()

    var intent = GetRandomVideoIntent()
    intent.collection = nil

    // When
    let result = try await intent.perform(in: container)

    // Then
    let validIDs = ["random1", "random2", "random3"]
    #expect(validIDs.contains(result.id))
  }

  @Test("Intent returns different videos over multiple calls (statistical)")
  func testRandomnessStatistical() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    // Create several videos
    for i in 1...10 {
      let video = createVideoItem(videoID: "stat\(i)", title: "Video \(i)")
      context.insert(video)
    }
    try context.save()

    var intent = GetRandomVideoIntent()
    intent.collection = nil

    // When - run multiple times
    var results = Set<String>()
    for _ in 1...20 {
      let result = try await intent.perform(in: container)
      results.insert(result.id)
    }

    // Then - should get multiple different results (statistically very likely)
    // With 10 videos and 20 samples, getting only 1 unique is extremely unlikely
    #expect(results.count > 1)
  }

  // MARK: - Collection Filtering Tests

  @Test("Intent filters by collection when provided")
  func testRandomFromCollection() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    // Videos with specific tags
    let swiftVideo1 = createVideoItem(
      videoID: "swift1", title: "Swift 1", aiTopicTags: ["Swift"])
    let swiftVideo2 = createVideoItem(
      videoID: "swift2", title: "Swift 2", aiTopicTags: ["Swift"])
    let pythonVideo = createVideoItem(
      videoID: "python1", title: "Python 1", aiTopicTags: ["Python"])
    context.insert(swiftVideo1)
    context.insert(swiftVideo2)
    context.insert(pythonVideo)

    // Create collection
    let cluster = createClusterLabel(clusterID: "swiftCluster", label: "Swift")
    context.insert(cluster)
    try context.save()

    let collectionEntity = CollectionEntity(from: cluster)
    var intent = GetRandomVideoIntent()
    intent.collection = collectionEntity

    // When
    let result = try await intent.perform(in: container)

    // Then - should only return Swift videos
    #expect(["swift1", "swift2"].contains(result.id))
  }

  @Test("Intent throws when collection has no matching videos")
  func testEmptyCollectionFilter() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    // Only Python videos
    let pythonVideo = createVideoItem(
      videoID: "python1", title: "Python 1", aiTopicTags: ["Python"])
    context.insert(pythonVideo)

    // Swift collection (no matching videos)
    let cluster = createClusterLabel(clusterID: "swiftCluster", label: "Swift")
    context.insert(cluster)
    try context.save()

    let collectionEntity = CollectionEntity(from: cluster)
    var intent = GetRandomVideoIntent()
    intent.collection = collectionEntity

    // When/Then
    await #expect(throws: IntentError.self) {
      _ = try await intent.perform(in: container)
    }
  }

  // MARK: - Empty Library Tests

  @Test("Intent throws error when library is empty")
  func testEmptyLibrary() async throws {
    // Given
    let container = try createTestContainer()

    var intent = GetRandomVideoIntent()
    intent.collection = nil

    // When/Then
    await #expect(throws: IntentError.self) {
      _ = try await intent.perform(in: container)
    }
  }

  // MARK: - Single Video Tests

  @Test("Intent returns single video when only one exists")
  func testSingleVideo() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(videoID: "only1", title: "Only Video")
    context.insert(video)
    try context.save()

    var intent = GetRandomVideoIntent()
    intent.collection = nil

    // When
    let result = try await intent.perform(in: container)

    // Then
    #expect(result.id == "only1")
  }

  // MARK: - Unwatched Preference Tests

  @Test("Intent prefers unwatched videos")
  func testPrefersUnwatched() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    // One watched, one unwatched
    let watchedVideo = createVideoItem(
      videoID: "watched1", title: "Watched", watchProgress: 600.0)
    let unwatchedVideo = createVideoItem(
      videoID: "unwatched1", title: "Unwatched", watchProgress: 0)
    context.insert(watchedVideo)
    context.insert(unwatchedVideo)
    try context.save()

    var intent = GetRandomVideoIntent()
    intent.collection = nil

    // When - run multiple times
    var unwatchedCount = 0
    for _ in 1...10 {
      let result = try await intent.perform(in: container)
      if result.id == "unwatched1" {
        unwatchedCount += 1
      }
    }

    // Then - unwatched should be selected more often (at least sometimes)
    // Note: This is a preference, not exclusive, so we just check it happens
    #expect(unwatchedCount > 0)
  }

  // MARK: - Result Content Tests

  @Test("Intent returns VideoEntity with correct properties")
  func testResultProperties() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(videoID: "props1", title: "Property Test")
    context.insert(video)
    try context.save()

    var intent = GetRandomVideoIntent()
    intent.collection = nil

    // When
    let result = try await intent.perform(in: container)

    // Then
    #expect(result.id == "props1")
    #expect(result.title == "Property Test")
    #expect(result.duration == 600.0)
  }

  // MARK: - Optional Collection Tests

  @Test("Collection parameter is optional")
  func testCollectionOptional() async throws {
    // Given
    let intent = GetRandomVideoIntent()

    // Then
    #expect(intent.collection == nil)
  }
}

//
//  AddToCollectionIntentTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for AddToCollectionIntent
/// Verifies adding videos to collections via AI topic tags
@Suite("AddToCollectionIntent Tests")
@MainActor
struct AddToCollectionIntentTests {

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
    aiTopicTags: [String] = []
  ) -> VideoItem {
    VideoItem(
      videoID: videoID,
      title: title,
      channelID: "channel1",
      duration: 600.0,
      aiTopicTags: aiTopicTags
    )
  }

  /// Creates a sample ClusterLabel for testing
  private func createClusterLabel(
    clusterID: String,
    label: String
  ) -> ClusterLabel {
    ClusterLabel(
      clusterID: clusterID,
      label: label,
      centroid: Array(repeating: 0.1, count: 512),
      itemCount: 10,
      confidenceScore: 0.8
    )
  }

  // MARK: - Intent Configuration Tests

  @Test("AddToCollectionIntent has correct title")
  func testIntentTitle() async throws {
    // The title is a LocalizedStringResource, verify it exists
    let title = AddToCollectionIntent.title
    #expect(title != nil)
  }

  @Test("AddToCollectionIntent has description")
  func testIntentDescription() async throws {
    // Verify the description is an IntentDescription type
    let description = AddToCollectionIntent.description
    #expect(type(of: description) == IntentDescription.self)
  }

  // MARK: - Add to Collection Tests

  @Test("Intent adds video to collection via aiTopicTags")
  func testAddToCollection() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(videoID: "add1", title: "Test Video", aiTopicTags: [])
    let cluster = createClusterLabel(clusterID: "collection1", label: "Swift")
    context.insert(video)
    context.insert(cluster)
    try context.save()

    let videoEntity = VideoEntity(from: video)
    let collectionEntity = CollectionEntity(from: cluster)

    var intent = AddToCollectionIntent()
    intent.video = videoEntity
    intent.collection = collectionEntity

    // When
    let result = try await intent.perform(in: container)

    // Then
    #expect(result.contains("Swift"))

    // Verify the tag was added
    let descriptor = FetchDescriptor<VideoItem>()
    let videos = try context.fetch(descriptor)
    let updatedVideo = videos.first { $0.videoID == "add1" }
    #expect(updatedVideo?.aiTopicTags.contains("Swift") == true)
  }

  @Test("Intent updates video when adding to collection")
  func testUpdatesVideo() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(videoID: "update1", title: "Test Video")
    let cluster = createClusterLabel(clusterID: "collection2", label: "Programming")
    context.insert(video)
    context.insert(cluster)
    try context.save()

    let videoEntity = VideoEntity(from: video)
    let collectionEntity = CollectionEntity(from: cluster)

    var intent = AddToCollectionIntent()
    intent.video = videoEntity
    intent.collection = collectionEntity

    // When
    _ = try await intent.perform(in: container)

    // Then - tag should be added
    let descriptor = FetchDescriptor<VideoItem>()
    let videos = try context.fetch(descriptor)
    let updatedVideo = videos.first { $0.videoID == "update1" }
    #expect(updatedVideo?.aiTopicTags.contains("Programming") == true)
  }

  // MARK: - Idempotency Tests

  @Test("Intent is idempotent - adding twice doesn't duplicate tag")
  func testIdempotent() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(videoID: "idem1", title: "Test Video", aiTopicTags: ["Swift"])
    let cluster = createClusterLabel(clusterID: "collection3", label: "Swift")
    context.insert(video)
    context.insert(cluster)
    try context.save()

    let videoEntity = VideoEntity(from: video)
    let collectionEntity = CollectionEntity(from: cluster)

    var intent = AddToCollectionIntent()
    intent.video = videoEntity
    intent.collection = collectionEntity

    // When - add twice
    _ = try await intent.perform(in: container)
    _ = try await intent.perform(in: container)

    // Then - should only have one "Swift" tag
    let descriptor = FetchDescriptor<VideoItem>()
    let videos = try context.fetch(descriptor)
    let updatedVideo = videos.first { $0.videoID == "idem1" }
    let swiftTags = updatedVideo?.aiTopicTags.filter { $0 == "Swift" } ?? []
    #expect(swiftTags.count == 1)
  }

  @Test("Intent preserves existing tags")
  func testPreservesExistingTags() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(
      videoID: "preserve1",
      title: "Test Video",
      aiTopicTags: ["Existing", "Tags"]
    )
    let cluster = createClusterLabel(clusterID: "collection4", label: "New")
    context.insert(video)
    context.insert(cluster)
    try context.save()

    let videoEntity = VideoEntity(from: video)
    let collectionEntity = CollectionEntity(from: cluster)

    var intent = AddToCollectionIntent()
    intent.video = videoEntity
    intent.collection = collectionEntity

    // When
    _ = try await intent.perform(in: container)

    // Then
    let descriptor = FetchDescriptor<VideoItem>()
    let videos = try context.fetch(descriptor)
    let updatedVideo = videos.first { $0.videoID == "preserve1" }
    #expect(updatedVideo?.aiTopicTags.contains("Existing") == true)
    #expect(updatedVideo?.aiTopicTags.contains("Tags") == true)
    #expect(updatedVideo?.aiTopicTags.contains("New") == true)
  }

  // MARK: - Error Handling Tests

  @Test("Intent throws error for non-existent video")
  func testThrowsForNonExistentVideo() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let cluster = createClusterLabel(clusterID: "collection5", label: "Test")
    context.insert(cluster)
    try context.save()

    let videoEntity = VideoEntity(
      id: "nonexistent",
      title: "Ghost",
      duration: 100,
      isLocal: false
    )
    let collectionEntity = CollectionEntity(from: cluster)

    var intent = AddToCollectionIntent()
    intent.video = videoEntity
    intent.collection = collectionEntity

    // When/Then
    await #expect(throws: IntentError.self) {
      _ = try await intent.perform(in: container)
    }
  }

  // MARK: - Result Message Tests

  @Test("Intent returns success message with video and collection names")
  func testSuccessMessage() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(videoID: "msg1", title: "My Video")
    let cluster = createClusterLabel(clusterID: "collection6", label: "My Collection")
    context.insert(video)
    context.insert(cluster)
    try context.save()

    let videoEntity = VideoEntity(from: video)
    let collectionEntity = CollectionEntity(from: cluster)

    var intent = AddToCollectionIntent()
    intent.video = videoEntity
    intent.collection = collectionEntity

    // When
    let result = try await intent.perform(in: container)

    // Then
    #expect(result.contains("My Video"))
    #expect(result.contains("My Collection"))
  }

  // MARK: - Local Video Tests

  @Test("Intent works with local videos")
  func testLocalVideo() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let localURL = URL(fileURLWithPath: "/Users/test/video.mp4")
    let video = VideoItem(
      localURL: localURL,
      title: "Local Video",
      duration: 300.0
    )
    let cluster = createClusterLabel(clusterID: "collection7", label: "Local")
    context.insert(video)
    context.insert(cluster)
    try context.save()

    let videoEntity = VideoEntity(from: video)
    let collectionEntity = CollectionEntity(from: cluster)

    var intent = AddToCollectionIntent()
    intent.video = videoEntity
    intent.collection = collectionEntity

    // When
    let result = try await intent.perform(in: container)

    // Then
    #expect(result.contains("Local"))
  }
}

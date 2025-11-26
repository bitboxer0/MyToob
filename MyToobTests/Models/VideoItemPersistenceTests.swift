//
//  VideoItemPersistenceTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 11/25/25.
//

import Foundation
import SwiftData
import Testing

@testable import MyToob

@Suite("VideoItem Persistence Tests")
struct VideoItemPersistenceTests {

  // MARK: - Helper: Create In-Memory Container

  private func createTestContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: VideoItem.self, ClusterLabel.self, Note.self, ChannelBlacklist.self,
      configurations: config
    )
    let context = ModelContext(container)
    return (container, context)
  }

  // MARK: - Test Create VideoItem

  @Test("Create and save YouTube video item")
  func testCreateVideoItem() async throws {
    // Arrange
    let (_, context) = try createTestContainer()

    let videoItem = VideoItem(
      videoID: "create_test_123",
      title: "Create Test Video",
      channelID: "UCcreate",
      duration: 300.0,
      watchProgress: 50.0
    )

    // Act
    context.insert(videoItem)
    try context.save()

    // Assert
    let descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "create_test_123" }
    )
    let results = try context.fetch(descriptor)

    #expect(results.count == 1, "Should have exactly one inserted item")
    #expect(results.first?.title == "Create Test Video", "Title should match")
    #expect(results.first?.channelID == "UCcreate", "Channel should match")
    #expect(results.first?.duration == 300.0, "Duration should match")
    #expect(results.first?.watchProgress == 50.0, "Watch progress should match")
    #expect(results.first?.isLocal == false, "Should be YouTube video, not local")
  }

  // MARK: - Test Fetch VideoItem

  @Test("Fetch video item by predicate")
  func testFetchVideoItem() async throws {
    // Arrange
    let (_, context) = try createTestContainer()

    // Insert multiple videos
    let video1 = VideoItem(
      videoID: "fetch_test_1",
      title: "Fetch Test Video 1",
      channelID: "UCfetch",
      duration: 100.0
    )
    let video2 = VideoItem(
      videoID: "fetch_test_2",
      title: "Fetch Test Video 2",
      channelID: "UCfetch",
      duration: 200.0
    )
    let video3 = VideoItem(
      videoID: "fetch_test_3",
      title: "Different Channel Video",
      channelID: "UCother",
      duration: 300.0
    )

    context.insert(video1)
    context.insert(video2)
    context.insert(video3)
    try context.save()

    // Act: Fetch specific video by ID
    let idDescriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "fetch_test_2" }
    )
    let idResults = try context.fetch(idDescriptor)

    // Assert
    #expect(idResults.count == 1, "Should find exactly one video by ID")
    #expect(idResults.first?.title == "Fetch Test Video 2", "Should find correct video")
  }

  // MARK: - Test Update VideoItem

  @Test("Update video item properties")
  func testUpdateVideoItem() async throws {
    // Arrange
    let (_, context) = try createTestContainer()

    let videoItem = VideoItem(
      videoID: "update_test_123",
      title: "Original Title",
      channelID: "UCupdate",
      duration: 300.0,
      watchProgress: 0.0
    )

    context.insert(videoItem)
    try context.save()

    // Act: Update properties
    videoItem.title = "Updated Title"
    videoItem.watchProgress = 150.0
    videoItem.lastWatchedAt = Date()
    try context.save()

    // Assert: Fetch and verify updates persisted
    let descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "update_test_123" }
    )
    let results = try context.fetch(descriptor)

    #expect(results.count == 1, "Should still have exactly one item")
    #expect(results.first?.title == "Updated Title", "Title should be updated")
    #expect(results.first?.watchProgress == 150.0, "Watch progress should be updated")
    #expect(results.first?.lastWatchedAt != nil, "Last watched should be set")
  }

  // MARK: - Test Delete VideoItem

  @Test("Delete video item")
  func testDeleteVideoItem() async throws {
    // Arrange
    let (_, context) = try createTestContainer()

    let videoItem = VideoItem(
      videoID: "delete_test_123",
      title: "Delete Test Video",
      channelID: nil,
      duration: 300.0
    )

    context.insert(videoItem)
    try context.save()

    // Verify item exists
    let beforeDescriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "delete_test_123" }
    )
    let beforeResults = try context.fetch(beforeDescriptor)
    #expect(beforeResults.count == 1, "Item should exist before deletion")

    // Act: Delete the item
    context.delete(videoItem)
    try context.save()

    // Assert: Item no longer exists
    let afterResults = try context.fetch(beforeDescriptor)
    #expect(afterResults.isEmpty, "Item should be deleted")
  }

  // MARK: - Test Query by Channel

  @Test("Query video items by channel ID")
  func testQueryVideoItemsByChannel() async throws {
    // Arrange
    let (_, context) = try createTestContainer()

    // Insert videos with different channels
    let targetChannelID = "UCquery_target"

    let video1 = VideoItem(
      videoID: "channel_query_1",
      title: "Target Channel Video 1",
      channelID: targetChannelID,
      duration: 100.0
    )
    let video2 = VideoItem(
      videoID: "channel_query_2",
      title: "Target Channel Video 2",
      channelID: targetChannelID,
      duration: 200.0
    )
    let video3 = VideoItem(
      videoID: "channel_query_3",
      title: "Other Channel Video",
      channelID: "UCother_channel",
      duration: 300.0
    )
    let video4 = VideoItem(
      localURL: URL(fileURLWithPath: "/test/local.mp4"),
      title: "Local Video (no channel)",
      duration: 400.0
    )

    context.insert(video1)
    context.insert(video2)
    context.insert(video3)
    context.insert(video4)
    try context.save()

    // Act: Query by channel ID
    let descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.channelID == targetChannelID }
    )
    let results = try context.fetch(descriptor)

    // Assert
    #expect(results.count == 2, "Should find exactly 2 videos from target channel")
    #expect(
      results.allSatisfy { $0.channelID == targetChannelID },
      "All results should have target channel ID")
  }

  // MARK: - Test Cascade Delete Notes

  @Test("Video item relationship with notes cascades on delete")
  func testCascadeDeleteNotes() async throws {
    // Arrange
    let (_, context) = try createTestContainer()

    // Create video with notes
    let videoItem = VideoItem(
      videoID: "cascade_test_123",
      title: "Video With Notes",
      channelID: nil,
      duration: 300.0
    )
    context.insert(videoItem)

    let note1 = Note(
      content: "First note content",
      timestamp: 10.0,
      videoItem: videoItem
    )
    let note2 = Note(
      content: "Second note content",
      timestamp: 20.0,
      videoItem: videoItem
    )
    context.insert(note1)
    context.insert(note2)
    try context.save()

    // Verify notes exist
    let beforeNoteDescriptor = FetchDescriptor<Note>()
    let beforeNotes = try context.fetch(beforeNoteDescriptor)
    #expect(beforeNotes.count == 2, "Should have 2 notes before deletion")

    // Act: Delete the video
    context.delete(videoItem)
    try context.save()

    // Assert: Notes should also be deleted via cascade
    let afterNotes = try context.fetch(beforeNoteDescriptor)
    #expect(afterNotes.isEmpty, "Notes should cascade delete with video")
  }

  // MARK: - Test Embedding Persistence

  @Test("Embedding data persists correctly")
  func testEmbeddingPersistence() async throws {
    // Arrange
    let (_, context) = try createTestContainer()

    // Create 384-dimensional embedding (as specified in VideoItem)
    let embedding: [Float] = (0..<384).map { Float($0) / 384.0 }

    let videoItem = VideoItem(
      videoID: "embedding_test_123",
      title: "Video With Embedding",
      channelID: nil,
      duration: 300.0,
      embedding: embedding
    )

    // Act
    context.insert(videoItem)
    try context.save()

    // Assert: Fetch and verify embedding persisted
    let descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "embedding_test_123" }
    )
    let results = try context.fetch(descriptor)

    #expect(results.count == 1, "Should have exactly one item")
    #expect(results.first?.embedding != nil, "Embedding should not be nil")
    #expect(results.first?.embedding?.count == 384, "Embedding should have 384 dimensions")

    // Verify embedding values
    if let fetchedEmbedding = results.first?.embedding {
      #expect(
        abs(fetchedEmbedding[0] - 0.0) < 0.001, "First embedding value should be approximately 0")
      #expect(
        abs(fetchedEmbedding[383] - (383.0 / 384.0)) < 0.001,
        "Last embedding value should be approximately 0.997")
    }
  }

  // MARK: - Test Bookmark Data Persistence

  @Test("Local video file bookmark data persists")
  func testBookmarkDataPersistence() async throws {
    // Arrange
    let (_, context) = try createTestContainer()

    // Create mock bookmark data (simulating security-scoped bookmark)
    let mockBookmarkData = "mock_security_scoped_bookmark_data".data(using: .utf8)!

    let localVideo = VideoItem(
      localURL: URL(fileURLWithPath: "/Users/test/Videos/sample.mp4"),
      title: "Local Video With Bookmark",
      duration: 600.0,
      bookmarkData: mockBookmarkData
    )

    // Act
    context.insert(localVideo)
    try context.save()

    // Assert: Fetch and verify bookmark data persisted
    let descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.isLocal == true }
    )
    let results = try context.fetch(descriptor)

    #expect(results.count == 1, "Should have exactly one local video")
    #expect(results.first?.isLocal == true, "Should be marked as local")
    #expect(results.first?.bookmarkData != nil, "Bookmark data should not be nil")
    #expect(results.first?.bookmarkData == mockBookmarkData, "Bookmark data should match")
    #expect(results.first?.localURL?.path == "/Users/test/Videos/sample.mp4", "Local URL should match")
  }
}

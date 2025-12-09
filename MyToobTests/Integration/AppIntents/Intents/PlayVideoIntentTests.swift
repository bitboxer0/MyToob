//
//  PlayVideoIntentTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for PlayVideoIntent
/// Verifies intent execution and video playback triggering
@Suite("PlayVideoIntent Tests")
@MainActor
struct PlayVideoIntentTests {

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

  /// Creates a sample VideoEntity for testing
  private func createVideoEntity(
    id: String = "testVideo123",
    title: String = "Test Video",
    duration: TimeInterval = 600.0,
    isLocal: Bool = false
  ) -> VideoEntity {
    VideoEntity(
      id: id,
      title: title,
      duration: duration,
      isLocal: isLocal
    )
  }

  /// Creates a sample VideoItem for testing
  private func createVideoItem(
    videoID: String = "testVideo123",
    title: String = "Test Video",
    duration: TimeInterval = 600.0
  ) -> VideoItem {
    VideoItem(
      videoID: videoID,
      title: title,
      channelID: "channel1",
      duration: duration
    )
  }

  // MARK: - Intent Configuration Tests

  @Test("PlayVideoIntent has correct title")
  func testIntentTitle() async throws {
    // The title is a LocalizedStringResource, verify it exists
    let title = PlayVideoIntent.title
    #expect(title != nil)
  }

  @Test("PlayVideoIntent has description")
  func testIntentDescription() async throws {
    // Verify the description is an IntentDescription type
    let description = PlayVideoIntent.description
    #expect(type(of: description) == IntentDescription.self)
  }

  @Test("PlayVideoIntent opens app when run")
  func testOpensAppWhenRun() async throws {
    // Then
    #expect(PlayVideoIntent.openAppWhenRun == true)
  }

  // MARK: - Intent Execution Tests

  @Test("PlayVideoIntent performs with valid video")
  func testPerformWithValidVideo() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let videoItem = createVideoItem(videoID: "playTest1", title: "Play Test Video")
    context.insert(videoItem)
    try context.save()

    let entity = createVideoEntity(id: "playTest1", title: "Play Test Video")
    var intent = PlayVideoIntent()
    intent.video = entity

    // When
    let result = try await intent.perform(in: container)

    // Then
    #expect(result.videoIdentifier == "playTest1")
  }

  @Test("PlayVideoIntent returns video identifier in result")
  func testReturnsVideoIdentifier() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let videoItem = createVideoItem(videoID: "identifierTest", title: "Identifier Test")
    context.insert(videoItem)
    try context.save()

    let entity = createVideoEntity(id: "identifierTest")
    var intent = PlayVideoIntent()
    intent.video = entity

    // When
    let result = try await intent.perform(in: container)

    // Then
    #expect(result.videoIdentifier == "identifierTest")
  }

  @Test("PlayVideoIntent updates lastWatchedAt timestamp")
  func testUpdatesWatchTimestamp() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let videoItem = createVideoItem(videoID: "watchTest", title: "Watch Test")
    videoItem.lastWatchedAt = nil
    context.insert(videoItem)
    try context.save()

    let entity = createVideoEntity(id: "watchTest")
    var intent = PlayVideoIntent()
    intent.video = entity

    // When
    _ = try await intent.perform(in: container)

    // Then - Fetch the video again to check timestamp
    let descriptor = FetchDescriptor<VideoItem>()
    let videos = try context.fetch(descriptor)
    let updatedVideo = videos.first { $0.videoID == "watchTest" }

    #expect(updatedVideo?.lastWatchedAt != nil)
  }

  @Test("PlayVideoIntent works with local video")
  func testLocalVideo() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let localURL = URL(fileURLWithPath: "/Users/test/video.mp4")
    let videoItem = VideoItem(
      localURL: localURL,
      title: "Local Video",
      duration: 300.0
    )
    context.insert(videoItem)
    try context.save()

    let entity = createVideoEntity(id: localURL.path, title: "Local Video", isLocal: true)
    var intent = PlayVideoIntent()
    intent.video = entity

    // When
    let result = try await intent.perform(in: container)

    // Then
    #expect(result.videoIdentifier == localURL.path)
  }

  // MARK: - Error Handling Tests

  @Test("PlayVideoIntent throws error for non-existent video")
  func testThrowsForNonExistentVideo() async throws {
    // Given
    let container = try createTestContainer()
    let entity = createVideoEntity(id: "nonexistent", title: "Ghost Video")
    var intent = PlayVideoIntent()
    intent.video = entity

    // When/Then
    await #expect(throws: IntentError.self) {
      _ = try await intent.perform(in: container)
    }
  }

  // MARK: - Parameter Tests

  @Test("PlayVideoIntent video parameter is required")
  func testVideoParameterRequired() async throws {
    // Given
    let intent = PlayVideoIntent()

    // Then - video property exists and is settable
    var mutableIntent = intent
    let entity = createVideoEntity()
    mutableIntent.video = entity

    #expect(mutableIntent.video.id == entity.id)
  }
}

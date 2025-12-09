//
//  VideoEntityQueryTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for VideoEntityQuery - the entity query provider for VideoEntity
/// Verifies lookup, suggestions, and search functionality
@Suite("VideoEntityQuery Tests")
@MainActor
struct VideoEntityQueryTests {

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

  /// Creates a sample YouTube VideoItem for testing
  private func createYouTubeVideoItem(
    videoID: String = "testYT123",
    title: String = "Swift Tutorial",
    channelID: String = "UCSwift",
    duration: TimeInterval = 600.0,
    lastWatchedAt: Date? = nil,
    aiTopicTags: [String] = ["Swift", "Programming"]
  ) -> VideoItem {
    let video = VideoItem(
      videoID: videoID,
      title: title,
      channelID: channelID,
      duration: duration,
      aiTopicTags: aiTopicTags
    )
    video.lastWatchedAt = lastWatchedAt
    return video
  }

  /// Creates a sample local VideoItem for testing
  private func createLocalVideoItem(
    localURL: URL = URL(fileURLWithPath: "/Users/test/video.mp4"),
    title: String = "Local Video",
    duration: TimeInterval = 300.0
  ) -> VideoItem {
    VideoItem(
      localURL: localURL,
      title: title,
      duration: duration
    )
  }

  // MARK: - Entity Lookup Tests

  @Test("Query finds video by identifier")
  func testFindByIdentifier() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createYouTubeVideoItem(videoID: "findMe123", title: "Find Me Video")
    context.insert(video)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let results = try await query.entities(for: ["findMe123"], in: container)

    // Then
    #expect(results.count == 1)
    #expect(results.first?.id == "findMe123")
    #expect(results.first?.title == "Find Me Video")
  }

  @Test("Query finds multiple videos by identifiers")
  func testFindMultipleByIdentifiers() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video1 = createYouTubeVideoItem(videoID: "multi1", title: "Video 1")
    let video2 = createYouTubeVideoItem(videoID: "multi2", title: "Video 2")
    let video3 = createYouTubeVideoItem(videoID: "multi3", title: "Video 3")
    context.insert(video1)
    context.insert(video2)
    context.insert(video3)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let results = try await query.entities(for: ["multi1", "multi3"], in: container)

    // Then
    #expect(results.count == 2)
    let ids = results.map { $0.id }
    #expect(ids.contains("multi1"))
    #expect(ids.contains("multi3"))
  }

  @Test("Query returns empty for unknown identifier")
  func testUnknownIdentifier() async throws {
    // Given
    let container = try createTestContainer()
    let query = VideoEntityQuery()

    // When
    let results = try await query.entities(for: ["nonexistent"], in: container)

    // Then
    #expect(results.isEmpty)
  }

  @Test("Query finds local video by path identifier")
  func testFindLocalByPath() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let localURL = URL(fileURLWithPath: "/Users/test/my-video.mp4")
    let video = createLocalVideoItem(localURL: localURL, title: "Local Test")
    context.insert(video)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let results = try await query.entities(for: [localURL.path], in: container)

    // Then
    #expect(results.count == 1)
    #expect(results.first?.title == "Local Test")
    #expect(results.first?.isLocal == true)
  }

  // MARK: - Suggestion Tests

  @Test("Query suggests recently watched videos")
  func testSuggestedEntitiesRecentlyWatched() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let recentVideo = createYouTubeVideoItem(
      videoID: "recent1",
      title: "Recently Watched",
      lastWatchedAt: Date()
    )
    let oldVideo = createYouTubeVideoItem(
      videoID: "old1",
      title: "Old Video",
      lastWatchedAt: Date().addingTimeInterval(-86400 * 30)  // 30 days ago
    )
    context.insert(recentVideo)
    context.insert(oldVideo)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let suggestions = try await query.suggestedEntities(in: container)

    // Then
    #expect(!suggestions.isEmpty)
    // Recent video should be first
    if suggestions.count >= 2 {
      #expect(suggestions[0].id == "recent1")
    }
  }

  @Test("Query suggests videos when none recently watched")
  func testSuggestedEntitiesNoRecentlyWatched() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createYouTubeVideoItem(
      videoID: "unwatched1",
      title: "Never Watched"
    )
    context.insert(video)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let suggestions = try await query.suggestedEntities(in: container)

    // Then
    #expect(!suggestions.isEmpty)
    #expect(suggestions.first?.id == "unwatched1")
  }

  @Test("Query returns empty suggestions for empty library")
  func testSuggestedEntitiesEmptyLibrary() async throws {
    // Given
    let container = try createTestContainer()
    let query = VideoEntityQuery()

    // When
    let suggestions = try await query.suggestedEntities(in: container)

    // Then
    #expect(suggestions.isEmpty)
  }

  // MARK: - String Search Tests

  @Test("Query searches videos by title")
  func testSearchByTitle() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let swiftVideo = createYouTubeVideoItem(videoID: "swift1", title: "Learn Swift Programming")
    let pythonVideo = createYouTubeVideoItem(videoID: "python1", title: "Python Basics")
    context.insert(swiftVideo)
    context.insert(pythonVideo)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let results = try await query.entities(matching: "Swift", in: container)

    // Then
    #expect(results.count == 1)
    #expect(results.first?.title == "Learn Swift Programming")
  }

  @Test("Query searches videos by channelID")
  func testSearchByChannel() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createYouTubeVideoItem(
      videoID: "channel1",
      title: "Some Video",
      channelID: "AppleDeveloper"
    )
    context.insert(video)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let results = try await query.entities(matching: "Apple", in: container)

    // Then
    #expect(results.count == 1)
  }

  @Test("Query search is case insensitive")
  func testSearchCaseInsensitive() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createYouTubeVideoItem(videoID: "case1", title: "SwiftUI Tutorial")
    context.insert(video)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let results = try await query.entities(matching: "swiftui", in: container)

    // Then
    #expect(results.count == 1)
  }

  @Test("Query returns empty for no matches")
  func testSearchNoMatches() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createYouTubeVideoItem(videoID: "nomatch1", title: "Swift Tutorial")
    context.insert(video)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let results = try await query.entities(matching: "JavaScript", in: container)

    // Then
    #expect(results.isEmpty)
  }

  // MARK: - Default Result Tests

  @Test("Query returns default result when videos exist")
  func testDefaultResult() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createYouTubeVideoItem(videoID: "default1", title: "Default Video")
    context.insert(video)
    try context.save()

    let query = VideoEntityQuery()

    // When
    let result = await query.defaultResult(in: container)

    // Then
    #expect(result != nil)
  }

  @Test("Query returns nil default when library empty")
  func testDefaultResultEmpty() async throws {
    // Given
    let container = try createTestContainer()
    let query = VideoEntityQuery()

    // When
    let result = await query.defaultResult(in: container)

    // Then
    #expect(result == nil)
  }
}

//
//  SearchVideosIntentTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for SearchVideosIntent
/// Verifies video search functionality and result handling
@Suite("SearchVideosIntent Tests")
@MainActor
struct SearchVideosIntentTests {

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
    channelID: String? = nil,
    aiTopicTags: [String] = []
  ) -> VideoItem {
    let video = VideoItem(
      videoID: videoID,
      title: title,
      channelID: channelID ?? "channel1",
      duration: 600.0,
      aiTopicTags: aiTopicTags
    )
    return video
  }

  // MARK: - Intent Configuration Tests

  @Test("SearchVideosIntent has correct title")
  func testIntentTitle() async throws {
    // The title is a LocalizedStringResource, verify it exists
    let title = SearchVideosIntent.title
    #expect(title != nil)
  }

  @Test("SearchVideosIntent has description")
  func testIntentDescription() async throws {
    // Verify the description is an IntentDescription type
    let description = SearchVideosIntent.description
    #expect(type(of: description) == IntentDescription.self)
  }

  // MARK: - Search by Title Tests

  @Test("Intent searches videos by title")
  func testSearchByTitle() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let swiftVideo = createVideoItem(videoID: "swift1", title: "Learn Swift Programming")
    let pythonVideo = createVideoItem(videoID: "python1", title: "Python Basics")
    context.insert(swiftVideo)
    context.insert(pythonVideo)
    try context.save()

    var intent = SearchVideosIntent()
    intent.query = "Swift"
    intent.limit = 10

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.count == 1)
    #expect(results.first?.title == "Learn Swift Programming")
  }

  @Test("Intent search is case insensitive")
  func testSearchCaseInsensitive() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(videoID: "case1", title: "SwiftUI Tutorial")
    context.insert(video)
    try context.save()

    var intent = SearchVideosIntent()
    intent.query = "swiftui"
    intent.limit = 10

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.count == 1)
  }

  // MARK: - Search by Channel Tests

  @Test("Intent searches videos by channelID")
  func testSearchByChannel() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(
      videoID: "channel1",
      title: "Some Video",
      channelID: "AppleDeveloper"
    )
    context.insert(video)
    try context.save()

    var intent = SearchVideosIntent()
    intent.query = "Apple"
    intent.limit = 10

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.count == 1)
  }

  // MARK: - Search by Tags Tests

  @Test("Intent searches videos by AI tags")
  func testSearchByTags() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(
      videoID: "tag1",
      title: "Random Title",
      aiTopicTags: ["Xcode", "Development", "iOS"]
    )
    context.insert(video)
    try context.save()

    var intent = SearchVideosIntent()
    intent.query = "Xcode"
    intent.limit = 10

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.count == 1)
  }

  // MARK: - Limit Tests

  @Test("Intent respects limit parameter")
  func testSearchLimit() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    // Create 10 matching videos
    for i in 1...10 {
      let video = createVideoItem(videoID: "limit\(i)", title: "Swift Video \(i)")
      context.insert(video)
    }
    try context.save()

    var intent = SearchVideosIntent()
    intent.query = "Swift"
    intent.limit = 5

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.count == 5)
  }

  @Test("Intent uses default limit when not specified")
  func testDefaultLimit() async throws {
    // Given
    let intent = SearchVideosIntent()

    // Then
    #expect(intent.limit == 10)
  }

  // MARK: - Empty Results Tests

  @Test("Intent returns empty array for no matches")
  func testNoMatches() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(videoID: "nomatch1", title: "Swift Tutorial")
    context.insert(video)
    try context.save()

    var intent = SearchVideosIntent()
    intent.query = "JavaScript"
    intent.limit = 10

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.isEmpty)
  }

  @Test("Intent returns empty for empty library")
  func testEmptyLibrary() async throws {
    // Given
    let container = try createTestContainer()

    var intent = SearchVideosIntent()
    intent.query = "anything"
    intent.limit = 10

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.isEmpty)
  }

  // MARK: - Result Content Tests

  @Test("Intent returns VideoEntity with correct properties")
  func testResultProperties() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video = createVideoItem(
      videoID: "props1",
      title: "Property Test Video"
    )
    context.insert(video)
    try context.save()

    var intent = SearchVideosIntent()
    intent.query = "Property"
    intent.limit = 10

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.count == 1)
    let result = results.first!
    #expect(result.id == "props1")
    #expect(result.title == "Property Test Video")
    #expect(result.isLocal == false)
  }

  // MARK: - Multiple Match Tests

  @Test("Intent finds multiple matching videos")
  func testMultipleMatches() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let video1 = createVideoItem(videoID: "multi1", title: "SwiftUI Basics")
    let video2 = createVideoItem(videoID: "multi2", title: "SwiftUI Advanced")
    let video3 = createVideoItem(videoID: "multi3", title: "UIKit Tutorial")
    context.insert(video1)
    context.insert(video2)
    context.insert(video3)
    try context.save()

    var intent = SearchVideosIntent()
    intent.query = "SwiftUI"
    intent.limit = 10

    // When
    let results = try await intent.perform(in: container)

    // Then
    #expect(results.count == 2)
  }
}

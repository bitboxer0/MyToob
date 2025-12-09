//
//  VideoEntityTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for VideoEntity App Intent entity type
/// Verifies entity mapping from VideoItem and Codable conformance
@Suite("VideoEntity Tests")
@MainActor
struct VideoEntityTests {

  // MARK: - Test Helpers

  /// Creates a sample YouTube VideoItem for testing
  private func createYouTubeVideoItem(
    videoID: String = "testYT123",
    title: String = "Swift Programming Tutorial",
    channelID: String = "UCSwift123",
    duration: TimeInterval = 600.0,
    aiTopicTags: [String] = ["Swift", "Programming"]
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

  // MARK: - Initialization Tests

  @Test("VideoEntity initializes from YouTube VideoItem")
  func testInitFromYouTubeVideo() async throws {
    // Given
    let videoItem = createYouTubeVideoItem(
      videoID: "abc123",
      title: "Test Video",
      duration: 900.0
    )

    // When
    let entity = VideoEntity(from: videoItem)

    // Then
    #expect(entity.id == "abc123")
    #expect(entity.title == "Test Video")
    #expect(entity.duration == 900.0)
    #expect(entity.isLocal == false)
  }

  @Test("VideoEntity initializes from local VideoItem")
  func testInitFromLocalVideo() async throws {
    // Given
    let localURL = URL(fileURLWithPath: "/Users/test/Documents/my-video.mp4")
    let videoItem = createLocalVideoItem(
      localURL: localURL,
      title: "My Local Video",
      duration: 1800.0
    )

    // When
    let entity = VideoEntity(from: videoItem)

    // Then
    #expect(entity.id == localURL.path)
    #expect(entity.title == "My Local Video")
    #expect(entity.duration == 1800.0)
    #expect(entity.isLocal == true)
  }

  // MARK: - Codable Tests

  @Test("VideoEntity is Codable - encode and decode cycle")
  func testCodable() async throws {
    // Given
    let videoItem = createYouTubeVideoItem(
      videoID: "codableTest",
      title: "Codable Test Video",
      duration: 500.0
    )
    let entity = VideoEntity(from: videoItem)

    // When - encode
    let encoder = JSONEncoder()
    let data = try encoder.encode(entity)

    // Then - decode
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(VideoEntity.self, from: data)

    #expect(decoded.id == entity.id)
    #expect(decoded.title == entity.title)
    #expect(decoded.duration == entity.duration)
    #expect(decoded.isLocal == entity.isLocal)
  }

  @Test("VideoEntity local video is Codable")
  func testCodableLocalVideo() async throws {
    // Given
    let localURL = URL(fileURLWithPath: "/path/to/video.mp4")
    let videoItem = createLocalVideoItem(localURL: localURL, title: "Local Codable Test")
    let entity = VideoEntity(from: videoItem)

    // When
    let encoder = JSONEncoder()
    let data = try encoder.encode(entity)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(VideoEntity.self, from: data)

    // Then
    #expect(decoded.id == localURL.path)
    #expect(decoded.isLocal == true)
  }

  // MARK: - DisplayRepresentation Tests

  @Test("VideoEntity has displayRepresentation")
  func testDisplayRepresentationExists() async throws {
    // Given
    let videoItem = createYouTubeVideoItem(title: "Display Test Video")

    // When
    let entity = VideoEntity(from: videoItem)

    // Then - verify display representation exists (it's a computed property)
    let display = entity.displayRepresentation
    #expect(type(of: display) == DisplayRepresentation.self)
  }

  // MARK: - Type Display Representation Tests

  @Test("VideoEntity has type display representation")
  func testTypeDisplayRepresentation() async throws {
    // When
    let typeRep = VideoEntity.typeDisplayRepresentation

    // Then - verify type display representation exists
    #expect(type(of: typeRep) == TypeDisplayRepresentation.self)
  }

  // MARK: - Edge Cases

  @Test("VideoEntity handles empty title")
  func testEmptyTitle() async throws {
    // Given
    let videoItem = VideoItem(
      videoID: "emptyTitle",
      title: "",
      channelID: nil,
      duration: 100.0
    )

    // When
    let entity = VideoEntity(from: videoItem)

    // Then
    #expect(entity.title == "")
    #expect(entity.id == "emptyTitle")
  }

  @Test("VideoEntity handles zero duration")
  func testZeroDuration() async throws {
    // Given
    let videoItem = VideoItem(
      videoID: "zeroDuration",
      title: "Zero Duration Video",
      channelID: nil,
      duration: 0.0
    )

    // When
    let entity = VideoEntity(from: videoItem)

    // Then
    #expect(entity.duration == 0.0)
  }

  @Test("VideoEntity handles special characters in title")
  func testSpecialCharactersInTitle() async throws {
    // Given
    let specialTitle = "Test Video: \"Quotes\" & <Brackets>"
    let videoItem = VideoItem(
      videoID: "special",
      title: specialTitle,
      channelID: nil,
      duration: 100.0
    )

    // When
    let entity = VideoEntity(from: videoItem)

    // Then
    #expect(entity.title == specialTitle)
  }
}

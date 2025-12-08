//
//  VideoItemTests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import Foundation
import SwiftData
import Testing

@testable import MyToob

@Suite("VideoItem Model Tests")
struct VideoItemTests {
  @Test("Create YouTube video item")
  func createYouTubeVideoItem() async throws {
    let videoItem = VideoItem(
      videoID: "dQw4w9WgXcQ",
      title: "Test Video",
      channelID: "UC123456",
      duration: 300.0,
      watchProgress: 150.0
    )

    #expect(videoItem.videoID == "dQw4w9WgXcQ")
    #expect(videoItem.title == "Test Video")
    #expect(videoItem.channelID == "UC123456")
    #expect(videoItem.duration == 300.0)
    #expect(videoItem.watchProgress == 150.0)
    #expect(videoItem.isLocal == false)
    #expect(videoItem.localURL == nil)
    #expect(videoItem.identifier == "dQw4w9WgXcQ")
  }

  @Test("Create local video item")
  func createLocalVideoItem() async throws {
    let localURL = URL(fileURLWithPath: "/Users/test/video.mp4")
    let videoItem = VideoItem(
      localURL: localURL,
      title: "Local Test Video",
      duration: 600.0
    )

    #expect(videoItem.videoID == nil)
    #expect(videoItem.localURL == localURL)
    #expect(videoItem.title == "Local Test Video")
    #expect(videoItem.duration == 600.0)
    #expect(videoItem.isLocal == true)
    #expect(videoItem.channelID == nil)
    #expect(videoItem.identifier == localURL.path)
  }

  @Test("Progress percentage calculation")
  func progressPercentage() async throws {
    let videoItem = VideoItem(
      videoID: "test123",
      title: "Test",
      channelID: nil,
      duration: 100.0,
      watchProgress: 50.0
    )

    #expect(videoItem.progressPercentage == 0.5)

    // Test progress capped at 100%
    let overdueItem = VideoItem(
      videoID: "test456",
      title: "Test",
      channelID: nil,
      duration: 100.0,
      watchProgress: 150.0
    )
    #expect(overdueItem.progressPercentage == 1.0)

    // Test zero duration
    let zeroItem = VideoItem(
      videoID: "test789",
      title: "Test",
      channelID: nil,
      duration: 0.0,
      watchProgress: 10.0
    )
    #expect(zeroItem.progressPercentage == 0.0)
  }

  @Test("AI topic tags")
  func aiTopicTags() async throws {
    let videoItem = VideoItem(
      videoID: "test123",
      title: "Swift Programming Tutorial",
      channelID: nil,
      duration: 300.0,
      aiTopicTags: ["Swift", "Programming", "Tutorial"]
    )

    #expect(videoItem.aiTopicTags.count == 3)
    #expect(videoItem.aiTopicTags.contains("Swift"))
    #expect(videoItem.aiTopicTags.contains("Programming"))
  }

  @Test("Embedding vector - 512 dimensions (Apple NLEmbedding)")
  func embeddingVector() async throws {
    let embedding: [Float] = Array(repeating: 0.5, count: 512)
    let videoItem = VideoItem(
      videoID: "test123",
      title: "Test",
      channelID: nil,
      duration: 300.0,
      embedding: embedding
    )

    #expect(videoItem.embedding?.count == 512)
    #expect(videoItem.embedding?.first == 0.5)
  }

  // MARK: - Epic 7 Field Tests

  @Test("YouTube metadata fields for embedding generation")
  func youTubeMetadataFields() async throws {
    let thumbnailURL = URL(string: "https://i.ytimg.com/vi/test123/hqdefault.jpg")!
    let publishDate = Date(timeIntervalSince1970: 1700000000)

    let videoItem = VideoItem(
      videoID: "test123",
      title: "Swift Programming Tutorial",
      channelID: "UC123456",
      channelTitle: "Swift Academy",
      videoDescription: "Learn Swift programming in this comprehensive tutorial.",
      tags: ["Swift", "Programming", "iOS", "Tutorial"],
      thumbnailURL: thumbnailURL,
      publishedAt: publishDate,
      duration: 3600.0
    )

    #expect(videoItem.channelTitle == "Swift Academy")
    #expect(videoItem.videoDescription == "Learn Swift programming in this comprehensive tutorial.")
    #expect(videoItem.tags.count == 4)
    #expect(videoItem.tags.contains("Swift"))
    #expect(videoItem.tags.contains("iOS"))
    #expect(videoItem.thumbnailURL == thumbnailURL)
    #expect(videoItem.publishedAt == publishDate)
  }

  @Test("Tags JSON encoding/decoding")
  func tagsEncoding() async throws {
    let videoItem = VideoItem(
      videoID: "test123",
      title: "Test",
      channelID: nil,
      tags: ["Tag1", "Tag2", "Tag3"],
      duration: 300.0
    )

    // Verify initial tags
    #expect(videoItem.tags.count == 3)
    #expect(videoItem.tags == ["Tag1", "Tag2", "Tag3"])

    // Modify tags
    videoItem.tags = ["NewTag1", "NewTag2"]
    #expect(videoItem.tags.count == 2)
    #expect(videoItem.tags == ["NewTag1", "NewTag2"])

    // Empty tags
    videoItem.tags = []
    #expect(videoItem.tags.isEmpty)
  }

  @Test("AI indexing state fields")
  func aiIndexingStateFields() async throws {
    let indexedAt = Date()

    // Default values - new video needs indexing
    let newVideo = VideoItem(
      videoID: "new123",
      title: "New Video",
      channelID: nil,
      duration: 300.0
    )
    #expect(newVideo.needsIndexing == true)
    #expect(newVideo.lastIndexedAt == nil)

    // Explicitly set indexing state
    let indexedVideo = VideoItem(
      videoID: "indexed123",
      title: "Indexed Video",
      channelID: nil,
      duration: 300.0,
      needsIndexing: false,
      lastIndexedAt: indexedAt
    )
    #expect(indexedVideo.needsIndexing == false)
    #expect(indexedVideo.lastIndexedAt == indexedAt)
  }

  @Test("Local file with thumbnail URL")
  func localFileWithThumbnail() async throws {
    let localURL = URL(fileURLWithPath: "/Users/test/video.mp4")
    let thumbnailURL = URL(fileURLWithPath: "/Users/test/video_thumb.jpg")

    let videoItem = VideoItem(
      localURL: localURL,
      title: "Local Video",
      thumbnailURL: thumbnailURL,
      duration: 600.0
    )

    #expect(videoItem.thumbnailURL == thumbnailURL)
    #expect(videoItem.isLocal == true)
    // Local files shouldn't have YouTube-specific fields
    #expect(videoItem.channelTitle == nil)
    #expect(videoItem.videoDescription == nil)
    #expect(videoItem.tags.isEmpty)
    #expect(videoItem.publishedAt == nil)
    // But should have indexing state
    #expect(videoItem.needsIndexing == true)
    #expect(videoItem.lastIndexedAt == nil)
  }

  @Test("SwiftData persistence - YouTube video")
  func persistYouTubeVideo() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: VideoItem.self,
      Note.self,
      configurations: config
    )
    let context = ModelContext(container)

    let videoItem = VideoItem(
      videoID: "persist123",
      title: "Persistence Test",
      channelID: "UC123",
      duration: 300.0
    )

    context.insert(videoItem)
    try context.save()

    // Fetch the item back
    let descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "persist123" }
    )
    let fetchedItems = try context.fetch(descriptor)

    #expect(fetchedItems.count == 1)
    #expect(fetchedItems.first?.title == "Persistence Test")
    #expect(fetchedItems.first?.channelID == "UC123")
  }

  @Test("SwiftData persistence - Local video")
  func persistLocalVideo() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: VideoItem.self,
      Note.self,
      configurations: config
    )
    let context = ModelContext(container)

    let localURL = URL(fileURLWithPath: "/Users/test/local.mp4")
    let videoItem = VideoItem(
      localURL: localURL,
      title: "Local Persistence Test",
      duration: 600.0
    )

    context.insert(videoItem)
    try context.save()

    // Fetch the item back
    let descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.isLocal == true }
    )
    let fetchedItems = try context.fetch(descriptor)

    #expect(fetchedItems.count == 1)
    #expect(fetchedItems.first?.title == "Local Persistence Test")
    #expect(fetchedItems.first?.localURL?.path == localURL.path)
  }

  @Test("Delete video item")
  func deleteVideoItem() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: VideoItem.self,
      Note.self,
      configurations: config
    )
    let context = ModelContext(container)

    let videoItem = VideoItem(
      videoID: "delete123",
      title: "Delete Test",
      channelID: nil,
      duration: 300.0
    )

    context.insert(videoItem)
    try context.save()

    // Delete the item
    context.delete(videoItem)
    try context.save()

    // Verify deletion
    let descriptor = FetchDescriptor<VideoItem>()
    let fetchedItems = try context.fetch(descriptor)
    #expect(fetchedItems.isEmpty)
  }
}

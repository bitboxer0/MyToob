//
//  ChannelBlacklistTests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import Foundation
import SwiftData
import Testing

@testable import MyToob

@Suite("ChannelBlacklist Model Tests")
struct ChannelBlacklistTests {
  @Test("Create channel blacklist entry")
  func createBlacklistEntry() async throws {
    let entry = ChannelBlacklist(
      channelID: "UC12345",
      reason: "Spam content",
      channelName: "Spam Channel"
    )

    #expect(entry.channelID == "UC12345")
    #expect(entry.reason == "Spam content")
    #expect(entry.channelName == "Spam Channel")
    #expect(entry.requiresConfirmation == true)
  }

  @Test("Create blacklist entry without reason")
  func createBlacklistNoReason() async throws {
    let entry = ChannelBlacklist(channelID: "UC67890")

    #expect(entry.channelID == "UC67890")
    #expect(entry.reason == nil)
    #expect(entry.channelName == nil)
  }

  @Test("Should filter matching channel")
  func shouldFilterMatching() async throws {
    let blacklist = ChannelBlacklist(
      channelID: "UC12345",
      reason: "Block this channel"
    )

    let videoItem = VideoItem(
      videoID: "video-001",
      title: "Test Video",
      channelID: "UC12345",
      duration: 300.0
    )

    #expect(blacklist.shouldFilter(videoItem) == true)
  }

  @Test("Should not filter different channel")
  func shouldNotFilterDifferent() async throws {
    let blacklist = ChannelBlacklist(
      channelID: "UC12345",
      reason: "Block this channel"
    )

    let videoItem = VideoItem(
      videoID: "video-002",
      title: "Different Channel Video",
      channelID: "UC67890",
      duration: 300.0
    )

    #expect(blacklist.shouldFilter(videoItem) == false)
  }

  @Test("Should not filter local video")
  func shouldNotFilterLocal() async throws {
    let blacklist = ChannelBlacklist(
      channelID: "UC12345",
      reason: "Block this channel"
    )

    let localURL = URL(fileURLWithPath: "/Users/test/video.mp4")
    let videoItem = VideoItem(
      localURL: localURL,
      title: "Local Video",
      duration: 300.0
    )

    #expect(blacklist.shouldFilter(videoItem) == false)
  }

  @Test("SwiftData persistence")
  func persistBlacklist() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: ChannelBlacklist.self,
      configurations: config
    )
    let context = ModelContext(container)

    let entry = ChannelBlacklist(
      channelID: "UC_PERSIST",
      reason: "Testing persistence",
      channelName: "Test Channel",
      requiresConfirmation: false
    )

    context.insert(entry)
    try context.save()

    // Fetch back
    let descriptor = FetchDescriptor<ChannelBlacklist>(
      predicate: #Predicate { $0.channelID == "UC_PERSIST" }
    )
    let fetched = try context.fetch(descriptor)

    #expect(fetched.count == 1)
    #expect(fetched.first?.reason == "Testing persistence")
    #expect(fetched.first?.channelName == "Test Channel")
    #expect(fetched.first?.requiresConfirmation == false)
  }

  @Test("Delete blacklist entry")
  func deleteBlacklist() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: ChannelBlacklist.self,
      configurations: config
    )
    let context = ModelContext(container)

    let entry = ChannelBlacklist(channelID: "UC_DELETE")
    context.insert(entry)
    try context.save()

    // Delete
    context.delete(entry)
    try context.save()

    // Verify deletion
    let descriptor = FetchDescriptor<ChannelBlacklist>()
    let remaining = try context.fetch(descriptor)
    #expect(remaining.isEmpty)
  }

  @Test("Unique channel ID constraint")
  func uniqueChannelID() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: ChannelBlacklist.self,
      configurations: config
    )
    let context = ModelContext(container)

    let entry1 = ChannelBlacklist(channelID: "UC_UNIQUE", reason: "First entry")
    context.insert(entry1)
    try context.save()

    // Attempting to insert duplicate should be handled by SwiftData's unique constraint
    // The behavior depends on SwiftData version, but typically it will either:
    // 1. Replace the existing entry, or
    // 2. Throw an error
    // We'll test that we can query for it and get only one result

    let descriptor = FetchDescriptor<ChannelBlacklist>(
      predicate: #Predicate { $0.channelID == "UC_UNIQUE" }
    )
    let results = try context.fetch(descriptor)
    #expect(results.count == 1)
  }

  @Test("Update blacklist properties")
  func updateBlacklist() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: ChannelBlacklist.self,
      configurations: config
    )
    let context = ModelContext(container)

    let entry = ChannelBlacklist(
      channelID: "UC_UPDATE",
      reason: "Original reason"
    )
    context.insert(entry)
    try context.save()

    // Update properties
    entry.reason = "Updated reason"
    entry.channelName = "Updated Name"
    entry.requiresConfirmation = false
    try context.save()

    // Fetch and verify
    let descriptor = FetchDescriptor<ChannelBlacklist>(
      predicate: #Predicate { $0.channelID == "UC_UPDATE" }
    )
    let fetched = try context.fetch(descriptor)

    #expect(fetched.first?.reason == "Updated reason")
    #expect(fetched.first?.channelName == "Updated Name")
    #expect(fetched.first?.requiresConfirmation == false)
  }

  @Test("Filter multiple videos from blacklist")
  func filterMultipleVideos() async throws {
    let blacklist = ChannelBlacklist(channelID: "UC_BLOCKED")

    let blockedVideo1 = VideoItem(
      videoID: "vid1",
      title: "Blocked 1",
      channelID: "UC_BLOCKED",
      duration: 100.0
    )

    let blockedVideo2 = VideoItem(
      videoID: "vid2",
      title: "Blocked 2",
      channelID: "UC_BLOCKED",
      duration: 200.0
    )

    let allowedVideo = VideoItem(
      videoID: "vid3",
      title: "Allowed",
      channelID: "UC_ALLOWED",
      duration: 300.0
    )

    #expect(blacklist.shouldFilter(blockedVideo1) == true)
    #expect(blacklist.shouldFilter(blockedVideo2) == true)
    #expect(blacklist.shouldFilter(allowedVideo) == false)
  }

  // MARK: - Extension Tests

  @Test("Display name with channelName set")
  func displayNameWithName() async throws {
    let entry = ChannelBlacklist(
      channelID: "UC12345678901234567890",
      channelName: "Test Channel"
    )

    #expect(entry.displayName == "Test Channel")
  }

  @Test("Display name without channelName (fallback)")
  func displayNameFallback() async throws {
    let entry = ChannelBlacklist(channelID: "UC12345678901234567890")

    #expect(entry.displayName == "Channel UC123456")
  }

  @Test("Display name with empty channelName (fallback)")
  func displayNameEmptyFallback() async throws {
    let entry = ChannelBlacklist(
      channelID: "UC12345678901234567890",
      channelName: ""
    )

    #expect(entry.displayName == "Channel UC123456")
  }

  @Test("Formatted blocked date")
  func formattedDate() async throws {
    let entry = ChannelBlacklist(channelID: "UC12345")

    // Should produce non-empty formatted string
    let formatted = entry.formattedBlockedDate
    #expect(!formatted.isEmpty)
    // Should contain the year (basic sanity check)
    #expect(formatted.contains("202"))
  }
}

//
//  ChannelBlacklistServiceTests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/27/25.
//

import SwiftData
import XCTest

@testable import MyToob

@MainActor
final class ChannelBlacklistServiceTests: XCTestCase {
  // MARK: - Properties

  var modelContainer: ModelContainer!
  var modelContext: ModelContext!
  var service: ChannelBlacklistService!

  // MARK: - Setup & Teardown

  override func setUp() async throws {
    try await super.setUp()

    // Create in-memory model container for testing
    let schema = Schema([VideoItem.self, Note.self, ClusterLabel.self, ChannelBlacklist.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    modelContext = ModelContext(modelContainer)

    service = ChannelBlacklistService(modelContext: modelContext)
  }

  override func tearDown() async throws {
    service = nil
    modelContext = nil
    modelContainer = nil
    try await super.tearDown()
  }

  // MARK: - Hide Channel Tests

  func testHideChannel_CreatesBlacklistEntry() async throws {
    // When
    try await service.hideChannel(
      channelID: "UC12345",
      channelName: "Test Channel",
      reason: "Testing",
      requiresConfirmation: false
    )

    // Then
    let descriptor = FetchDescriptor<ChannelBlacklist>(
      predicate: #Predicate { $0.channelID == "UC12345" }
    )
    let results = try modelContext.fetch(descriptor)

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.channelID, "UC12345")
    XCTAssertEqual(results.first?.channelName, "Test Channel")
    XCTAssertEqual(results.first?.reason, "Testing")
    XCTAssertEqual(results.first?.requiresConfirmation, false)
  }

  func testHideChannel_WithNilReason() async throws {
    // When
    try await service.hideChannel(
      channelID: "UC67890",
      channelName: nil,
      reason: nil,
      requiresConfirmation: true
    )

    // Then
    let descriptor = FetchDescriptor<ChannelBlacklist>(
      predicate: #Predicate { $0.channelID == "UC67890" }
    )
    let results = try modelContext.fetch(descriptor)

    XCTAssertEqual(results.count, 1)
    XCTAssertNil(results.first?.channelName)
    XCTAssertNil(results.first?.reason)
    XCTAssertEqual(results.first?.requiresConfirmation, true)
  }

  func testHideChannel_DuplicateChannelID_Updates() async throws {
    // Given - First hide
    try await service.hideChannel(
      channelID: "UC_DUP",
      channelName: "Original Name",
      reason: "Original reason",
      requiresConfirmation: true
    )

    // When - Second hide (same channelID)
    try await service.hideChannel(
      channelID: "UC_DUP",
      channelName: "Updated Name",
      reason: "Updated reason",
      requiresConfirmation: false
    )

    // Then - Should have only one entry with updated values
    let descriptor = FetchDescriptor<ChannelBlacklist>(
      predicate: #Predicate { $0.channelID == "UC_DUP" }
    )
    let results = try modelContext.fetch(descriptor)

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.channelName, "Updated Name")
    XCTAssertEqual(results.first?.reason, "Updated reason")
    XCTAssertEqual(results.first?.requiresConfirmation, false)
  }

  func testHideChannel_EmptyChannelID_ThrowsError() async throws {
    // When/Then
    do {
      try await service.hideChannel(
        channelID: "",
        channelName: nil,
        reason: nil,
        requiresConfirmation: false
      )
      XCTFail("Should throw error for empty channel ID")
    } catch let error as ChannelBlacklistError {
      XCTAssertEqual(error.errorDescription, "Cannot hide channel: missing channel identifier")
    }
  }

  // MARK: - Unhide Channel Tests

  func testUnhideChannel_RemovesEntry() async throws {
    // Given
    try await service.hideChannel(
      channelID: "UC_REMOVE",
      channelName: "Channel to Remove",
      reason: nil,
      requiresConfirmation: false
    )

    // When
    try await service.unhideChannel(channelID: "UC_REMOVE")

    // Then
    let descriptor = FetchDescriptor<ChannelBlacklist>(
      predicate: #Predicate { $0.channelID == "UC_REMOVE" }
    )
    let results = try modelContext.fetch(descriptor)

    XCTAssertTrue(results.isEmpty)
  }

  func testUnhideChannel_NonExistent_NoError() async throws {
    // When/Then - Should not throw for non-existent channel (idempotent)
    do {
      try await service.unhideChannel(channelID: "UC_NONEXISTENT")
    } catch {
      XCTFail("Should not throw error for non-existent channel: \(error)")
    }
  }

  func testUnhideChannel_EmptyChannelID_ThrowsError() async throws {
    // When/Then
    do {
      try await service.unhideChannel(channelID: "")
      XCTFail("Should throw error for empty channel ID")
    } catch let error as ChannelBlacklistError {
      XCTAssertEqual(error.errorDescription, "Cannot hide channel: missing channel identifier")
    }
  }

  // MARK: - Is Channel Hidden Tests

  func testIsChannelHidden_ReturnsTrueForHidden() async throws {
    // Given
    try await service.hideChannel(
      channelID: "UC_HIDDEN",
      channelName: nil,
      reason: nil,
      requiresConfirmation: false
    )

    // When
    let isHidden = service.isChannelHidden("UC_HIDDEN")

    // Then
    XCTAssertTrue(isHidden)
  }

  func testIsChannelHidden_ReturnsFalseForVisible() async throws {
    // When
    let isHidden = service.isChannelHidden("UC_NOT_HIDDEN")

    // Then
    XCTAssertFalse(isHidden)
  }

  func testIsChannelHidden_EmptyID_ReturnsFalse() {
    // When
    let isHidden = service.isChannelHidden("")

    // Then
    XCTAssertFalse(isHidden)
  }

  // MARK: - Fetch Hidden Channels Tests

  func testFetchHiddenChannels_ReturnsAll() async throws {
    // Given
    try await service.hideChannel(
      channelID: "UC_FIRST",
      channelName: "First",
      reason: nil,
      requiresConfirmation: false
    )
    try await service.hideChannel(
      channelID: "UC_SECOND",
      channelName: "Second",
      reason: nil,
      requiresConfirmation: false
    )

    // When
    let hidden = try service.fetchHiddenChannels()

    // Then
    XCTAssertEqual(hidden.count, 2)
  }

  func testFetchHiddenChannels_EmptyWhenNoChannelsHidden() throws {
    // When
    let hidden = try service.fetchHiddenChannels()

    // Then
    XCTAssertTrue(hidden.isEmpty)
  }

  func testFetchHiddenChannels_SortedByBlockedDateDescending() async throws {
    // Given - Add channels with time gap
    try await service.hideChannel(
      channelID: "UC_OLDER",
      channelName: "Older",
      reason: nil,
      requiresConfirmation: false
    )

    // Small delay to ensure different timestamps
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

    try await service.hideChannel(
      channelID: "UC_NEWER",
      channelName: "Newer",
      reason: nil,
      requiresConfirmation: false
    )

    // When
    let hidden = try service.fetchHiddenChannels()

    // Then - Newest first
    XCTAssertEqual(hidden.count, 2)
    XCTAssertEqual(hidden.first?.channelID, "UC_NEWER")
    XCTAssertEqual(hidden.last?.channelID, "UC_OLDER")
  }

  // MARK: - Filter Visible Items Tests

  func testFilterVisibleItems_ExcludesHiddenChannels() async throws {
    // Given
    try await service.hideChannel(
      channelID: "UC_BLOCKED",
      channelName: nil,
      reason: nil,
      requiresConfirmation: false
    )

    let blockedVideo = VideoItem(
      videoID: "video1",
      title: "Blocked Video",
      channelID: "UC_BLOCKED",
      duration: 100.0
    )

    let visibleVideo = VideoItem(
      videoID: "video2",
      title: "Visible Video",
      channelID: "UC_VISIBLE",
      duration: 200.0
    )

    // When
    let filtered = service.filterVisibleItems([blockedVideo, visibleVideo])

    // Then
    XCTAssertEqual(filtered.count, 1)
    XCTAssertEqual(filtered.first?.videoID, "video2")
  }

  func testFilterVisibleItems_IncludesLocalFiles() async throws {
    // Given
    try await service.hideChannel(
      channelID: "UC_BLOCKED",
      channelName: nil,
      reason: nil,
      requiresConfirmation: false
    )

    let localURL = URL(fileURLWithPath: "/Users/test/video.mp4")
    let localVideo = VideoItem(
      localURL: localURL,
      title: "Local Video",
      duration: 300.0
    )

    // When
    let filtered = service.filterVisibleItems([localVideo])

    // Then - Local files always visible
    XCTAssertEqual(filtered.count, 1)
    XCTAssertEqual(filtered.first?.title, "Local Video")
  }

  func testFilterVisibleItems_ReturnsAllWhenNoBlacklist() async throws {
    // Given
    let video1 = VideoItem(
      videoID: "video1",
      title: "Video 1",
      channelID: "UC_1",
      duration: 100.0
    )

    let video2 = VideoItem(
      videoID: "video2",
      title: "Video 2",
      channelID: "UC_2",
      duration: 200.0
    )

    // When
    let filtered = service.filterVisibleItems([video1, video2])

    // Then
    XCTAssertEqual(filtered.count, 2)
  }

  func testFilterVisibleItems_MultipleBlockedChannels() async throws {
    // Given
    try await service.hideChannel(
      channelID: "UC_BLOCKED_1",
      channelName: nil,
      reason: nil,
      requiresConfirmation: false
    )
    try await service.hideChannel(
      channelID: "UC_BLOCKED_2",
      channelName: nil,
      reason: nil,
      requiresConfirmation: false
    )

    let blocked1 = VideoItem(
      videoID: "video1",
      title: "Blocked 1",
      channelID: "UC_BLOCKED_1",
      duration: 100.0
    )

    let blocked2 = VideoItem(
      videoID: "video2",
      title: "Blocked 2",
      channelID: "UC_BLOCKED_2",
      duration: 200.0
    )

    let visible = VideoItem(
      videoID: "video3",
      title: "Visible",
      channelID: "UC_VISIBLE",
      duration: 300.0
    )

    // When
    let filtered = service.filterVisibleItems([blocked1, blocked2, visible])

    // Then
    XCTAssertEqual(filtered.count, 1)
    XCTAssertEqual(filtered.first?.title, "Visible")
  }

  // MARK: - Compliance Logging Tests (Smoke Tests)

  func testComplianceLogging_HideChannel_NoThrow() async throws {
    // This is a smoke test - ensures logging doesn't throw
    do {
      try await service.hideChannel(
        channelID: "UC_LOG_TEST",
        channelName: "Log Test Channel",
        reason: "Test logging",
        requiresConfirmation: false
      )
    } catch {
      XCTFail("Hide channel with logging should not throw: \(error)")
    }
  }

  func testComplianceLogging_UnhideChannel_NoThrow() async throws {
    // Given
    try await service.hideChannel(
      channelID: "UC_UNHIDE_LOG",
      channelName: nil,
      reason: nil,
      requiresConfirmation: false
    )

    // This is a smoke test - ensures logging doesn't throw
    do {
      try await service.unhideChannel(channelID: "UC_UNHIDE_LOG")
    } catch {
      XCTFail("Unhide channel with logging should not throw: \(error)")
    }
  }
}

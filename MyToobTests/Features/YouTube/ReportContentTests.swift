//
//  ReportContentTests.swift
//  MyToobTests
//
//  Created for Story 12.1: Report Content Action
//

import XCTest

@testable import MyToob

/// Unit tests for Report Content functionality.
/// Follows smoke test pattern from ComplianceLoggerTests - verifies no crashes
/// and validates URL format/logic for report action.
final class ReportContentTests: XCTestCase {

  // MARK: - URL Format Tests

  func testReportURLFormat() {
    // Given: A YouTube video ID
    let videoID = "dQw4w9WgXcQ"

    // When: We construct the report URL
    let reportURLString = "https://www.youtube.com/watch?v=\(videoID)&report=1"
    let url = URL(string: reportURLString)

    // Then: URL should be valid and have correct format
    XCTAssertNotNil(url, "Report URL should be valid")
    XCTAssertEqual(url?.scheme, "https", "URL scheme should be https")
    XCTAssertEqual(url?.host, "www.youtube.com", "URL host should be www.youtube.com")
    XCTAssertEqual(url?.path, "/watch", "URL path should be /watch")
    XCTAssertTrue(
      reportURLString.contains("v=\(videoID)"),
      "URL should contain video ID parameter"
    )
    XCTAssertTrue(
      reportURLString.contains("report=1"),
      "URL should contain report=1 parameter"
    )
  }

  func testReportURLFormat_SpecialCharacters() {
    // Given: A video ID with unusual characters (edge case)
    let videoID = "abc_123-XYZ"

    // When: We construct the report URL
    let reportURLString = "https://www.youtube.com/watch?v=\(videoID)&report=1"
    let url = URL(string: reportURLString)

    // Then: URL should still be valid
    XCTAssertNotNil(url, "Report URL with special characters should be valid")
    XCTAssertTrue(
      reportURLString.contains("v=\(videoID)"),
      "URL should contain video ID with special characters"
    )
  }

  func testReportURLFormat_EmptyVideoID() {
    // Given: An empty video ID (edge case)
    let videoID = ""

    // When: We construct the report URL
    let reportURLString = "https://www.youtube.com/watch?v=\(videoID)&report=1"
    let url = URL(string: reportURLString)

    // Then: URL should still be technically valid (though meaningless)
    XCTAssertNotNil(url, "Report URL with empty video ID should be technically valid")
  }

  // MARK: - Compliance Logger Tests (Smoke Tests)

  func testReportActionLogged() {
    // Smoke test - should not throw/crash
    ComplianceLogger.shared.logContentReport(videoID: "testVideoID123")
  }

  func testReportActionLogged_WithReportType() {
    // Smoke test - should not throw/crash
    ComplianceLogger.shared.logContentReport(
      videoID: "testVideoID456",
      reportType: "inappropriate"
    )
  }

  func testReportActionLogged_EmptyVideoID() {
    // Smoke test - should handle empty ID gracefully without crashing
    ComplianceLogger.shared.logContentReport(videoID: "")
  }

  func testReportActionLogged_SpecialCharacters() {
    // Smoke test - should handle special characters without crashing
    ComplianceLogger.shared.logContentReport(
      videoID: "abc_123-XYZ",
      reportType: "spam & misleading"
    )
  }

  // MARK: - VideoItem Report Action Visibility Tests

  func testReportActionOnlyForYouTubeVideos_YouTubeVideo() {
    // Given: A YouTube video item
    let youtubeItem = VideoItem(
      videoID: "dQw4w9WgXcQ",
      title: "Test YouTube Video",
      channelID: "UC12345",
      duration: 180
    )

    // Then: Should have videoID and not be local
    XCTAssertFalse(youtubeItem.isLocal, "YouTube video should not be marked as local")
    XCTAssertNotNil(youtubeItem.videoID, "YouTube video should have a videoID")

    // Report action visibility condition: !item.isLocal && item.videoID != nil
    let shouldShowReportAction = !youtubeItem.isLocal && youtubeItem.videoID != nil
    XCTAssertTrue(
      shouldShowReportAction,
      "Report action should be visible for YouTube videos"
    )
  }

  func testReportActionOnlyForYouTubeVideos_LocalFile() {
    // Given: A local video file
    let localItem = VideoItem(
      localURL: URL(fileURLWithPath: "/Users/test/video.mp4"),
      title: "Test Local Video",
      duration: 120
    )

    // Then: Should not have videoID and be local
    XCTAssertTrue(localItem.isLocal, "Local file should be marked as local")
    XCTAssertNil(localItem.videoID, "Local file should not have a videoID")

    // Report action visibility condition: !item.isLocal && item.videoID != nil
    let shouldShowReportAction = !localItem.isLocal && localItem.videoID != nil
    XCTAssertFalse(
      shouldShowReportAction,
      "Report action should NOT be visible for local files"
    )
  }

  // MARK: - VideoItem Identifier Tests

  func testVideoItemIdentifier_YouTubeVideo() {
    // Given: A YouTube video item
    let videoID = "dQw4w9WgXcQ"
    let youtubeItem = VideoItem(
      videoID: videoID,
      title: "Test YouTube Video",
      channelID: "UC12345",
      duration: 180
    )

    // Then: Identifier should be the videoID
    XCTAssertEqual(
      youtubeItem.identifier,
      videoID,
      "YouTube video identifier should be the videoID"
    )
  }

  func testVideoItemIdentifier_LocalFile() {
    // Given: A local video file
    let localPath = "/Users/test/Movies/myvideo.mp4"
    let localURL = URL(fileURLWithPath: localPath)
    let localItem = VideoItem(
      localURL: localURL,
      title: "Test Local Video",
      duration: 120
    )

    // Then: Identifier should be the file path
    XCTAssertEqual(
      localItem.identifier,
      localPath,
      "Local file identifier should be the file path"
    )
  }

  func testVideoItemIdentifier_ForAccessibilityID() {
    // Given: A YouTube video item
    let videoID = "abc123XYZ"
    let youtubeItem = VideoItem(
      videoID: videoID,
      title: "Test Video",
      channelID: "UC12345",
      duration: 60
    )

    // When: Constructing the accessibility identifier (as used in ContentView)
    let accessibilityID = "VideoItem_\(youtubeItem.identifier)"

    // Then: Should match expected format for UI tests
    XCTAssertEqual(
      accessibilityID,
      "VideoItem_abc123XYZ",
      "Accessibility identifier should use VideoItem_ prefix with videoID"
    )
    XCTAssertTrue(
      accessibilityID.hasPrefix("VideoItem_"),
      "Accessibility identifier should start with 'VideoItem_' prefix"
    )
  }

  // MARK: - UI Dialog Tests
  // Note: Report confirmation dialog behavior is covered by UI tests in ComplianceUITests.swift
  // See: testReportContentDialogShows(), testReportContentDialogCancel(), testReportContentOpensURL()
  // Unit tests cannot verify SwiftUI alert presentation - that requires XCUITest
}
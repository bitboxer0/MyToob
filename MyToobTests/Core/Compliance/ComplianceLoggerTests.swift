//
//  ComplianceLoggerTests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/27/25.
//

import XCTest

@testable import MyToob

/// Smoke tests for ComplianceLogger to ensure logging methods don't crash.
/// OSLog doesn't expose logs programmatically in tests, so we verify no exceptions are thrown.
final class ComplianceLoggerTests: XCTestCase {

  // MARK: - Channel Block/Unblock Tests

  func testLogChannelBlock_MinimalParams() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logChannelBlock(
      channelID: "UC12345",
      channelName: nil,
      reason: nil
    )
  }

  func testLogChannelBlock_FullParams() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logChannelBlock(
      channelID: "UC12345678901234567890",
      channelName: "Test Channel Name",
      reason: "Contains spam and misleading content"
    )
  }

  func testLogChannelBlock_EmptyStrings() {
    // Smoke test - should handle empty strings gracefully
    ComplianceLogger.shared.logChannelBlock(
      channelID: "",
      channelName: "",
      reason: ""
    )
  }

  func testLogChannelBlock_SpecialCharacters() {
    // Smoke test - should handle special characters
    ComplianceLogger.shared.logChannelBlock(
      channelID: "UC_special<>&\"'",
      channelName: "Channel with 特殊字符 and émojis 🎬",
      reason: "Reason with\nnewlines\tand\ttabs"
    )
  }

  func testLogChannelUnblock() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logChannelUnblock(channelID: "UC12345")
  }

  func testLogChannelUnblock_EmptyID() {
    // Smoke test - should handle empty ID gracefully
    ComplianceLogger.shared.logChannelUnblock(channelID: "")
  }

  // MARK: - Content Report Tests

  func testLogContentReport_MinimalParams() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logContentReport(
      videoID: "dQw4w9WgXcQ"
    )
  }

  func testLogContentReport_WithReportType() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logContentReport(
      videoID: "dQw4w9WgXcQ",
      reportType: "inappropriate_content"
    )
  }

  // MARK: - Age Gate Tests

  func testLogAgeGateEvent_Dismissed() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logAgeGateEvent(
      videoID: "restricted123",
      userAction: "dismissed"
    )
  }

  func testLogAgeGateEvent_Proceeded() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logAgeGateEvent(
      videoID: "restricted123",
      userAction: "proceeded"
    )
  }

  // MARK: - Singleton Tests

  func testSharedInstance() {
    // Verify singleton returns same instance
    let instance1 = ComplianceLogger.shared
    let instance2 = ComplianceLogger.shared
    XCTAssertTrue(instance1 === instance2)
  }
}

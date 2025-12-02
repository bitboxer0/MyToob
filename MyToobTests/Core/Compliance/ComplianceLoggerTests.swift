//
//  ComplianceLoggerTests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/27/25.
//

import XCTest

@testable import MyToob

/// Tests for ComplianceLogger including smoke tests, format validation, retention, export, and PII checks.
/// Story 12.6 AC: testLogComplianceEvent, testComplianceLogFormat, testLogRetentionPolicy, testExportComplianceLogs, testNoPIIInLogs.
final class ComplianceLoggerTests: XCTestCase {

  /// Temporary directory for test isolation (avoids polluting real Application Support)
  private var testStorageDirectory: URL!

  override func setUp() {
    super.setUp()
    // Create isolated test directory
    testStorageDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("ComplianceLoggerTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: testStorageDirectory, withIntermediateDirectories: true)

    // Redirect ComplianceLogger to test directory
    ComplianceLogger.shared.setStorageDirectoryOverrideForTesting(testStorageDirectory)

    // Ensure a clean slate
    try? ComplianceLogger.shared.clearStoredEvents()
  }

  override func tearDown() {
    // Cleanup test directory
    if let dir = testStorageDirectory {
      try? FileManager.default.removeItem(at: dir)
    }

    // Reset to default storage directory and date provider
    ComplianceLogger.shared.setStorageDirectoryOverrideForTesting(nil)
    ComplianceLogger.shared.setDateProviderForTesting(nil)
    ComplianceLogger.shared.resetPruneCheckForTesting()

    super.tearDown()
  }

  // MARK: - Channel Block/Unblock Tests

  func testLogChannelBlock_MinimalParams() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logChannelBlock(
      channelID: "UC12345",
      channelName: nil,
      reason: nil
    )
    ComplianceLogger.shared.waitForWrites()
  }

  func testLogChannelBlock_FullParams() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logChannelBlock(
      channelID: "UC12345678901234567890",
      channelName: "Test Channel Name",
      reason: "Contains spam and misleading content"
    )
    ComplianceLogger.shared.waitForWrites()
  }

  func testLogChannelBlock_EmptyStrings() {
    // Smoke test - should handle empty strings gracefully
    ComplianceLogger.shared.logChannelBlock(
      channelID: "",
      channelName: "",
      reason: ""
    )
    ComplianceLogger.shared.waitForWrites()
  }

  func testLogChannelBlock_SpecialCharacters() {
    // Smoke test - should handle special characters
    ComplianceLogger.shared.logChannelBlock(
      channelID: "UC_special<>&\"'",
      channelName: "Channel with 特殊字符 and émojis 🎬",
      reason: "Reason with\nnewlines\tand\ttabs"
    )
    ComplianceLogger.shared.waitForWrites()
  }

  func testLogChannelUnblock() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logChannelUnblock(channelID: "UC12345")
    ComplianceLogger.shared.waitForWrites()
  }

  func testLogChannelUnblock_EmptyID() {
    // Smoke test - should handle empty ID gracefully
    ComplianceLogger.shared.logChannelUnblock(channelID: "")
    ComplianceLogger.shared.waitForWrites()
  }

  // MARK: - Content Report Tests

  func testLogContentReport_MinimalParams() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logContentReport(
      videoID: "dQw4w9WgXcQ"
    )
    ComplianceLogger.shared.waitForWrites()
  }

  func testLogContentReport_WithReportType() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logContentReport(
      videoID: "dQw4w9WgXcQ",
      reportType: "inappropriate_content"
    )
    ComplianceLogger.shared.waitForWrites()
  }

  // MARK: - Age Gate Tests

  func testLogAgeGateEvent_Dismissed() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logAgeGateEvent(
      videoID: "restricted123",
      userAction: "dismissed"
    )
    ComplianceLogger.shared.waitForWrites()
  }

  func testLogAgeGateEvent_Proceeded() {
    // Smoke test - should not throw
    ComplianceLogger.shared.logAgeGateEvent(
      videoID: "restricted123",
      userAction: "proceeded"
    )
    ComplianceLogger.shared.waitForWrites()
  }

  // MARK: - Singleton Tests

  func testSharedInstance() {
    // Verify singleton returns same instance
    let instance1 = ComplianceLogger.shared
    let instance2 = ComplianceLogger.shared
    XCTAssertTrue(instance1 === instance2)
  }

  // MARK: - Story 12.6 Required Tests

  func testLogComplianceEvent() throws {
    // Given
    try ComplianceLogger.shared.clearStoredEvents()

    // When
    ComplianceLogger.shared.logContentReport(videoID: "vid_123")
    ComplianceLogger.shared.waitForWrites()

    // Then
    let events = try ComplianceLogger.shared.loadEvents()
    XCTAssertFalse(events.isEmpty, "Events should not be empty after logging")
    XCTAssertEqual(events.last?.action, "report_content")
    XCTAssertEqual(events.last?.videoID, "vid_123")
    XCTAssertNil(events.last?.channelID)
  }

  func testComplianceLogFormat() throws {
    // Given
    try ComplianceLogger.shared.clearStoredEvents()
    ComplianceLogger.shared.logChannelBlock(
      channelID: "UC_ABCDEF", channelName: "Some Name", reason: "Some Reason")
    ComplianceLogger.shared.waitForWrites()

    // When - use loadEvents() to read across all rotated files
    let events = try ComplianceLogger.shared.loadEvents()

    // Then - event should exist with expected structure
    XCTAssertFalse(events.isEmpty, "Should have logged event")
    let lastEvent = events.last!

    // Verify expected fields are present
    XCTAssertEqual(lastEvent.action, "hide_channel")
    XCTAssertEqual(lastEvent.channelID, "UC_ABCDEF")
    XCTAssertNotNil(lastEvent.timestamp)

    // Verify PII is not stored in the Event struct
    // (channelName and reason are intentionally not persisted - they're not even in the Event struct)
    // We verify by encoding and checking the JSON keys
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(lastEvent)
    let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    XCTAssertNotNil(obj, "Event should encode to valid JSON")
    let keys = Set(obj!.keys)
    XCTAssertTrue(keys.isSuperset(of: ["timestamp", "action"]))
    XCTAssertFalse(keys.contains("channelName"), "No PII: channelName should not be in log")
    XCTAssertFalse(keys.contains("reason"), "No PII: reason should not be in log")
  }

  func testLogRetentionPolicy() throws {
    // Given: monthly rotation with file-based pruning
    // We need to test that files for months older than 90 days are deleted
    try ComplianceLogger.shared.clearStoredEvents()

    // Set date provider to 91 days ago to create an "old" event in an old month's file
    let now = Date()
    let oldDate = Calendar.current.date(byAdding: .day, value: -91, to: now)!
    ComplianceLogger.shared.setDateProviderForTesting { oldDate }

    // Log an event - this will go into the old month's file
    ComplianceLogger.shared.logContentReport(videoID: "old_vid")
    ComplianceLogger.shared.waitForWrites()

    // Verify old event was written
    var events = try ComplianceLogger.shared.loadEvents()
    XCTAssertTrue(events.contains(where: { $0.videoID == "old_vid" }), "Old event should exist initially")

    // Reset date provider to "now" and log a fresh event
    ComplianceLogger.shared.setDateProviderForTesting { now }
    ComplianceLogger.shared.logContentReport(videoID: "new_vid")
    ComplianceLogger.shared.waitForWrites()

    // Reset prune check to allow immediate pruning, then trigger prune
    ComplianceLogger.shared.resetPruneCheckForTesting()
    try ComplianceLogger.shared.pruneOldLogFiles()

    // When: load events after pruning
    events = try ComplianceLogger.shared.loadEvents()

    // Then - old file (and its event) should be pruned, new event remains
    XCTAssertTrue(events.contains(where: { $0.videoID == "new_vid" }), "New event should remain")
    XCTAssertFalse(
      events.contains(where: { $0.videoID == "old_vid" }), "Old event should be pruned (file deleted)")
  }

  func testExportComplianceLogs() throws {
    // Given
    try ComplianceLogger.shared.clearStoredEvents()
    ComplianceLogger.shared.logContentReport(videoID: "exp_vid1")
    ComplianceLogger.shared.logChannelBlock(channelID: "UC_EXP", channelName: nil, reason: nil)
    ComplianceLogger.shared.waitForWrites()

    // When
    let url = try ComplianceLogger.shared.exportComplianceLogs(sinceDays: 90)
    let data = try Data(contentsOf: url)
    let arr = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]

    // Then
    XCTAssertNotNil(arr, "Export should produce valid JSON array")
    XCTAssertTrue((arr?.count ?? 0) >= 2, "Export should contain at least 2 events")

    // Cleanup
    try? FileManager.default.removeItem(at: url)
  }

  func testNoPIIInLogs() throws {
    // Given
    try ComplianceLogger.shared.clearStoredEvents()
    ComplianceLogger.shared.logChannelBlock(
      channelID: "UC_NO_PII",
      channelName: "PII Channel Name",
      reason: "PII Reason"
    )
    ComplianceLogger.shared.waitForWrites()

    // When - read the raw file content from the logs directory
    let logsDir = ComplianceLogger.shared.logsDirectoryURL
    let files = try FileManager.default.contentsOfDirectory(
      at: logsDir, includingPropertiesForKeys: nil)
    let logFiles = files.filter {
      $0.lastPathComponent.hasPrefix("compliance-") && $0.pathExtension == "jsonl"
    }
    XCTAssertFalse(logFiles.isEmpty, "Should have at least one log file")

    // Read all log file contents
    var allContent = ""
    for file in logFiles {
      let data = try Data(contentsOf: file)
      allContent += String(data: data, encoding: .utf8) ?? ""
    }

    // Then - ensure raw files don't contain channel names or reasons (PII)
    XCTAssertFalse(
      allContent.contains("PII Channel Name"), "Channel name (PII) should not appear in logs")
    XCTAssertFalse(allContent.contains("PII Reason"), "Reason (PII) should not appear in logs")

    // Also verify via the Event struct
    let events = try ComplianceLogger.shared.loadEvents()
    XCTAssertFalse(events.isEmpty)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    for event in events {
      let data = try encoder.encode(event)
      let json = String(data: data, encoding: .utf8) ?? ""
      XCTAssertFalse(json.contains("PII Channel Name"), "Channel name should not be in event JSON")
      XCTAssertFalse(json.contains("PII Reason"), "Reason should not be in event JSON")
    }
  }

  // MARK: - Additional Coverage Tests

  func testLogContentPolicyAccess() throws {
    // Given
    try ComplianceLogger.shared.clearStoredEvents()

    // When
    ComplianceLogger.shared.logContentPolicyAccess(context: "settings")
    ComplianceLogger.shared.waitForWrites()

    // Then
    let events = try ComplianceLogger.shared.loadEvents()
    XCTAssertFalse(events.isEmpty)
    XCTAssertEqual(events.last?.action, "content_policy_access")
    XCTAssertEqual(events.last?.details?.context, "settings")
  }

  func testLogSupportContact() throws {
    // Given
    try ComplianceLogger.shared.clearStoredEvents()

    // When
    ComplianceLogger.shared.logSupportContact(method: "email")
    ComplianceLogger.shared.waitForWrites()

    // Then
    let events = try ComplianceLogger.shared.loadEvents()
    XCTAssertFalse(events.isEmpty)
    XCTAssertEqual(events.last?.action, "support_contact")
    XCTAssertEqual(events.last?.details?.method, "email")
  }

  func testLogContentPolicyAccessed_BackwardCompatibility() throws {
    // Given
    try ComplianceLogger.shared.clearStoredEvents()

    // When - use the backward compatible method
    ComplianceLogger.shared.logContentPolicyAccessed(source: .external)
    ComplianceLogger.shared.waitForWrites()

    // Then
    let events = try ComplianceLogger.shared.loadEvents()
    XCTAssertFalse(events.isEmpty)
    XCTAssertEqual(events.last?.action, "content_policy_access")
    XCTAssertEqual(events.last?.details?.context, "external")
  }
}

//
//  SupportUITests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import XCTest

/// UI tests for the Support & Diagnostics feature in Settings.
/// Story 12.4: Validates:
/// - Settings window accessibility
/// - Contact Support button visibility and accessibility
/// - Send Diagnostics button visibility and accessibility
/// - Diagnostics privacy note visibility
///
/// Note: We do not actually trigger email composition in tests to avoid
/// interacting with external mail clients in CI environments.
final class SupportUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false

    app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()
  }

  override func tearDown() {
    app = nil
    super.tearDown()
  }

  // MARK: - Helper Methods

  /// Opens the Settings window via keyboard shortcut and waits for the About view to appear
  /// - Parameter timeout: Maximum time to wait for Settings to appear
  /// - Returns: True if Settings opened successfully
  @discardableResult
  private func openSettingsAndWait(timeout: TimeInterval = 5) -> Bool {
    app.typeKey(",", modifierFlags: .command)
    let aboutView = app.otherElements.matching(identifier: "SettingsAboutView").firstMatch
    return aboutView.waitForExistence(timeout: timeout)
  }

  // MARK: - Support & Contact Section Tests

  func testSettingsShowsSupportButtons() throws {
    // Open Settings via keyboard shortcut (Cmd-,)
    XCTAssertTrue(openSettingsAndWait(), "Settings should open with Cmd-,")

    // Verify Contact Support button exists
    let contactSupportButton = app.buttons.matching(identifier: "ContactSupportButton").firstMatch
    XCTAssertTrue(
      contactSupportButton.waitForExistence(timeout: 5),
      "Contact Support button should exist in Settings"
    )

    // Verify Send Diagnostics button exists
    let sendDiagnosticsButton = app.buttons.matching(identifier: "SendDiagnosticsButton").firstMatch
    XCTAssertTrue(
      sendDiagnosticsButton.waitForExistence(timeout: 5),
      "Send Diagnostics button should exist in Settings"
    )
  }

  func testContactSupportButtonAccessibility() throws {
    // Open Settings and wait
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Find Contact Support button
    let contactSupportButton = app.buttons.matching(identifier: "ContactSupportButton").firstMatch
    XCTAssertTrue(
      contactSupportButton.waitForExistence(timeout: 5),
      "Contact Support button should exist"
    )

    // Verify accessibility label
    XCTAssertEqual(
      contactSupportButton.label,
      "Contact Support",
      "Contact Support button should have correct accessibility label"
    )

    // Verify button is enabled and hittable
    XCTAssertTrue(
      contactSupportButton.isEnabled,
      "Contact Support button should be enabled"
    )
    XCTAssertTrue(
      contactSupportButton.isHittable,
      "Contact Support button should be interactive"
    )
  }

  func testSendDiagnosticsButtonAccessibility() throws {
    // Open Settings and wait
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Find Send Diagnostics button
    let sendDiagnosticsButton = app.buttons.matching(identifier: "SendDiagnosticsButton").firstMatch
    XCTAssertTrue(
      sendDiagnosticsButton.waitForExistence(timeout: 5),
      "Send Diagnostics button should exist"
    )

    // Verify accessibility label
    XCTAssertEqual(
      sendDiagnosticsButton.label,
      "Send Diagnostics",
      "Send Diagnostics button should have correct accessibility label"
    )

    // Verify button is enabled and hittable
    XCTAssertTrue(
      sendDiagnosticsButton.isEnabled,
      "Send Diagnostics button should be enabled"
    )
    XCTAssertTrue(
      sendDiagnosticsButton.isHittable,
      "Send Diagnostics button should be interactive"
    )
  }

  func testDiagnosticsPrivacyNoteVisible() throws {
    // Open Settings and wait
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Verify privacy note is visible
    let privacyNote = app.staticTexts.matching(identifier: "DiagnosticsPrivacyNote").firstMatch
    XCTAssertTrue(
      privacyNote.waitForExistence(timeout: 5),
      "Diagnostics privacy note should be visible"
    )

    // Verify note mentions sanitization/no personal data
    let noteText = privacyNote.label
    XCTAssertTrue(
      noteText.lowercased().contains("sanitized") || noteText.lowercased().contains("personal"),
      "Privacy note should mention data sanitization: '\(noteText)'"
    )
  }

  // MARK: - Section Order Tests

  func testSupportSectionAppearsBeforeLegalSection() throws {
    // Open Settings and wait
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Get positions of buttons
    let contactSupportButton = app.buttons.matching(identifier: "ContactSupportButton").firstMatch
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch

    XCTAssertTrue(
      contactSupportButton.waitForExistence(timeout: 5),
      "Contact Support button should exist"
    )
    XCTAssertTrue(
      contentPolicyButton.waitForExistence(timeout: 5),
      "Content Policy button should exist"
    )

    // Support section should appear above Legal section (lower Y value)
    let supportY = contactSupportButton.frame.minY
    let legalY = contentPolicyButton.frame.minY
    XCTAssertLessThan(
      supportY,
      legalY,
      "Support & Contact section should appear before Legal & Policies section"
    )
  }

  // MARK: - Integration Tests

  func testAllSettingsSectionsPresent() throws {
    // Open Settings and wait
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Verify app name (App Information section)
    let appName = app.staticTexts["MyToob"]
    XCTAssertTrue(
      appName.waitForExistence(timeout: 5),
      "App name should be visible in App Information section"
    )

    // Verify Support & Contact section elements
    let contactSupportButton = app.buttons.matching(identifier: "ContactSupportButton").firstMatch
    let sendDiagnosticsButton = app.buttons.matching(identifier: "SendDiagnosticsButton").firstMatch
    XCTAssertTrue(contactSupportButton.exists, "Contact Support button should exist")
    XCTAssertTrue(sendDiagnosticsButton.exists, "Send Diagnostics button should exist")

    // Verify Legal & Policies section elements
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(
      contentPolicyButton.waitForExistence(timeout: 5),
      "Content Policy button should exist"
    )
  }
}

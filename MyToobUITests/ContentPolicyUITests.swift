//
//  ContentPolicyUITests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import XCTest

/// UI tests for the Content Policy feature in Settings.
/// Validates:
/// - Settings window accessibility
/// - Content Policy button visibility and accessibility
/// - Policy view opening behavior
/// - Policy content presence verification
final class ContentPolicyUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false

    app = XCUIApplication()
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

  /// Opens the Settings window and then opens the Content Policy sheet
  /// - Returns: True if the policy sheet opened successfully
  @discardableResult
  private func openPolicyAndWait() -> Bool {
    guard openSettingsAndWait() else {
      return false
    }

    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    guard contentPolicyButton.waitForExistence(timeout: 5) else {
      return false
    }
    contentPolicyButton.click()

    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    return policyWebView.waitForExistence(timeout: 10)
  }

  /// Waits for the Content Policy button to be ready for interaction
  /// - Returns: The Content Policy button element, or nil if not found
  private func waitForContentPolicyButton() -> XCUIElement? {
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    guard contentPolicyButton.waitForExistence(timeout: 5) else {
      return nil
    }
    return contentPolicyButton
  }

  // MARK: - Settings Window Tests

  func testSettingsWindowCanBeOpened() throws {
    // Open Settings via keyboard shortcut (Cmd-,)
    app.typeKey(",", modifierFlags: .command)

    // Wait for settings window to appear
    let settingsView = app.windows.matching(identifier: "SettingsAboutView").firstMatch
    XCTAssertTrue(
      settingsView.waitForExistence(timeout: 5),
      "Settings window should open with Cmd-,"
    )
  }

  func testSettingsWindowContainsAboutView() throws {
    // Open Settings and wait for About view
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Verify app name is displayed
    let appName = app.staticTexts["MyToob"]
    XCTAssertTrue(
      appName.waitForExistence(timeout: 5),
      "About view should display app name 'MyToob'"
    )
  }

  // MARK: - Content Policy Button Tests

  func testContentPolicyButtonExists() throws {
    // Open Settings and wait
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Find Content Policy button
    guard let contentPolicyButton = waitForContentPolicyButton() else {
      XCTFail("Content Policy button should exist in Settings")
      return
    }

    XCTAssertTrue(
      contentPolicyButton.isEnabled,
      "Content Policy button should be enabled"
    )
  }

  func testContentPolicyButtonAccessibility() throws {
    // Open Settings and wait
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Find Content Policy button
    guard let contentPolicyButton = waitForContentPolicyButton() else {
      XCTFail("Content Policy button should exist")
      return
    }

    // Verify accessibility label
    XCTAssertEqual(
      contentPolicyButton.label,
      "Content Policy",
      "Content Policy button should have correct accessibility label"
    )

    // Verify button is hittable (can be clicked)
    XCTAssertTrue(
      contentPolicyButton.isHittable,
      "Content Policy button should be interactive"
    )
  }

  // MARK: - Policy Sheet Tests

  func testContentPolicySheetOpens() throws {
    // Open Settings and click Content Policy button
    XCTAssertTrue(openPolicyAndWait(), "Content Policy sheet should open")

    // Verify web view is present
    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    XCTAssertTrue(policyWebView.exists, "Content Policy web view should be visible")
  }

  func testContentPolicySheetHasTitle() throws {
    // Open Content Policy sheet
    XCTAssertTrue(openPolicyAndWait(), "Content Policy sheet should open")

    // Wait for title to appear
    let policyTitle = app.staticTexts.matching(identifier: "ContentPolicyTitle").firstMatch
    XCTAssertTrue(
      policyTitle.waitForExistence(timeout: 10),
      "Content Policy sheet should have a title"
    )

    // Title should contain "Content Policy" or "MyToob"
    let titleText = policyTitle.label
    XCTAssertTrue(
      titleText.contains("Content Policy") || titleText.contains("MyToob"),
      "Policy title should indicate content policy: '\(titleText)'"
    )
  }

  func testContentPolicySheetShowsSourceLabel() throws {
    // Open Content Policy sheet
    XCTAssertTrue(openPolicyAndWait(), "Content Policy sheet should open")

    // Wait for source label to appear (indicates load completed)
    let sourceLabel = app.staticTexts.matching(identifier: "ContentPolicySourceLabel").firstMatch
    XCTAssertTrue(
      sourceLabel.waitForExistence(timeout: 15),
      "Content Policy sheet should show source label after loading"
    )

    // Verify source label indicates load method
    let sourceLabelText = sourceLabel.label
    XCTAssertTrue(
      sourceLabelText.contains("web") || sourceLabelText.contains("bundle")
        || sourceLabelText.contains("Remote") || sourceLabelText.contains("Local"),
      "Source label should indicate load source: '\(sourceLabelText)'"
    )
  }

  func testContentPolicySheetHasDoneButton() throws {
    // Open Content Policy sheet
    XCTAssertTrue(openPolicyAndWait(), "Content Policy sheet should open")

    // Verify Done button exists
    let doneButton = app.buttons["Done"]
    XCTAssertTrue(
      doneButton.waitForExistence(timeout: 5),
      "Policy sheet should have a Done button"
    )
    XCTAssertTrue(doneButton.isEnabled, "Done button should be enabled")
  }

  func testContentPolicySheetCanBeDismissed() throws {
    // Open Content Policy sheet
    XCTAssertTrue(openPolicyAndWait(), "Content Policy sheet should open")

    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    XCTAssertTrue(policyWebView.exists, "Policy web view should be visible before dismiss")

    // Click Done button
    let doneButton = app.buttons["Done"]
    XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Done button should exist")
    doneButton.click()

    // Verify sheet is dismissed (web view should no longer exist)
    XCTAssertTrue(
      policyWebView.waitForNonExistence(timeout: 5),
      "Policy sheet should be dismissed after clicking Done"
    )

    // Settings should still be visible
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(
      contentPolicyButton.waitForExistence(timeout: 5),
      "Settings view should remain visible after dismissing policy sheet"
    )
  }

  // MARK: - Content Presence Tests

  func testContentPolicyWebViewHasContent() throws {
    // Open Content Policy sheet
    XCTAssertTrue(openPolicyAndWait(), "Content Policy sheet should open")

    // Wait for source label to appear (indicates content loaded)
    let sourceLabel = app.staticTexts.matching(identifier: "ContentPolicySourceLabel").firstMatch
    XCTAssertTrue(
      sourceLabel.waitForExistence(timeout: 15),
      "Policy content should finish loading"
    )

    // Web view should have some content (frame should have non-zero size)
    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    let frame = policyWebView.frame
    XCTAssertTrue(
      frame.width > 100 && frame.height > 100,
      "Web view should have meaningful size indicating content"
    )
  }

  // MARK: - Integration Tests

  func testFullContentPolicyFlow() throws {
    // 1. Launch app (already done in setUp)
    // 2. Open Settings and wait
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // 3. Verify Content Policy button exists
    guard let contentPolicyButton = waitForContentPolicyButton() else {
      XCTFail("Content Policy button should exist")
      return
    }

    // 4. Open Content Policy
    contentPolicyButton.click()

    // 5. Wait for content to load
    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    XCTAssertTrue(policyWebView.waitForExistence(timeout: 10), "Policy sheet should open")

    let sourceLabel = app.staticTexts.matching(identifier: "ContentPolicySourceLabel").firstMatch
    XCTAssertTrue(sourceLabel.waitForExistence(timeout: 15), "Content should load")

    // 6. Dismiss policy
    let doneButton = app.buttons["Done"]
    XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Done button should exist")
    doneButton.click()

    // 7. Verify returned to Settings
    XCTAssertTrue(
      contentPolicyButton.waitForExistence(timeout: 5),
      "Should return to Settings after dismissing policy"
    )
  }
}

// MARK: - XCUIElement Extension for waitForNonExistence

extension XCUIElement {
  /// Wait for the element to no longer exist
  func waitForNonExistence(timeout: TimeInterval) -> Bool {
    let startTime = Date()
    while Date().timeIntervalSince(startTime) < timeout {
      if !exists {
        return true
      }
      Thread.sleep(forTimeInterval: 0.1)
    }
    return !exists
  }
}

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
    // Open Settings
    app.typeKey(",", modifierFlags: .command)

    // Wait for the About view to appear
    let aboutView = app.otherElements.matching(identifier: "SettingsAboutView").firstMatch
    if !aboutView.waitForExistence(timeout: 5) {
      // Try alternative: check for window containing SettingsAboutView
      let settingsWindow = app.windows.firstMatch
      XCTAssertTrue(
        settingsWindow.waitForExistence(timeout: 5),
        "Settings window should appear"
      )
    }

    // Verify app name is displayed
    let appName = app.staticTexts["MyToob"]
    XCTAssertTrue(appName.exists, "About view should display app name 'MyToob'")
  }

  // MARK: - Content Policy Button Tests

  func testContentPolicyButtonExists() throws {
    // Open Settings
    app.typeKey(",", modifierFlags: .command)

    // Wait for settings to load
    sleep(1)

    // Find Content Policy button
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(
      contentPolicyButton.waitForExistence(timeout: 5),
      "Content Policy button should exist in Settings"
    )
    XCTAssertTrue(
      contentPolicyButton.isEnabled,
      "Content Policy button should be enabled"
    )
  }

  func testContentPolicyButtonAccessibility() throws {
    // Open Settings
    app.typeKey(",", modifierFlags: .command)

    // Wait for settings to load
    sleep(1)

    // Find Content Policy button
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(contentPolicyButton.waitForExistence(timeout: 5))

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
    // Open Settings
    app.typeKey(",", modifierFlags: .command)

    // Wait for settings to load
    sleep(1)

    // Click Content Policy button
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(contentPolicyButton.waitForExistence(timeout: 5))
    contentPolicyButton.click()

    // Wait for policy sheet to appear
    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    XCTAssertTrue(
      policyWebView.waitForExistence(timeout: 10),
      "Content Policy web view should appear in sheet"
    )
  }

  func testContentPolicySheetHasTitle() throws {
    // Open Settings
    app.typeKey(",", modifierFlags: .command)
    sleep(1)

    // Click Content Policy button
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(contentPolicyButton.waitForExistence(timeout: 5))
    contentPolicyButton.click()

    // Wait for sheet to appear and check for title
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
    // Open Settings
    app.typeKey(",", modifierFlags: .command)
    sleep(1)

    // Click Content Policy button
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(contentPolicyButton.waitForExistence(timeout: 5))
    contentPolicyButton.click()

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
    // Open Settings
    app.typeKey(",", modifierFlags: .command)
    sleep(1)

    // Click Content Policy button
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(contentPolicyButton.waitForExistence(timeout: 5))
    contentPolicyButton.click()

    // Wait for sheet to appear
    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    XCTAssertTrue(policyWebView.waitForExistence(timeout: 10))

    // Verify Done button exists
    let doneButton = app.buttons["Done"]
    XCTAssertTrue(doneButton.exists, "Policy sheet should have a Done button")
    XCTAssertTrue(doneButton.isEnabled, "Done button should be enabled")
  }

  func testContentPolicySheetCanBeDismissed() throws {
    // Open Settings
    app.typeKey(",", modifierFlags: .command)
    sleep(1)

    // Click Content Policy button
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(contentPolicyButton.waitForExistence(timeout: 5))
    contentPolicyButton.click()

    // Wait for sheet to appear
    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    XCTAssertTrue(policyWebView.waitForExistence(timeout: 10))

    // Click Done button
    let doneButton = app.buttons["Done"]
    XCTAssertTrue(doneButton.exists)
    doneButton.click()

    // Verify sheet is dismissed (web view should no longer exist)
    XCTAssertTrue(
      policyWebView.waitForNonExistence(timeout: 5),
      "Policy sheet should be dismissed after clicking Done"
    )

    // Settings should still be visible
    XCTAssertTrue(
      contentPolicyButton.exists,
      "Settings view should remain visible after dismissing policy sheet"
    )
  }

  // MARK: - Content Presence Tests

  func testContentPolicyWebViewHasContent() throws {
    // Open Settings
    app.typeKey(",", modifierFlags: .command)
    sleep(1)

    // Click Content Policy button
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(contentPolicyButton.waitForExistence(timeout: 5))
    contentPolicyButton.click()

    // Wait for web view to load
    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    XCTAssertTrue(policyWebView.waitForExistence(timeout: 10))

    // Wait for source label to appear (indicates content loaded)
    let sourceLabel = app.staticTexts.matching(identifier: "ContentPolicySourceLabel").firstMatch
    XCTAssertTrue(
      sourceLabel.waitForExistence(timeout: 15),
      "Policy content should finish loading"
    )

    // Web view should have some content (frame should have non-zero size)
    let frame = policyWebView.frame
    XCTAssertTrue(
      frame.width > 100 && frame.height > 100,
      "Web view should have meaningful size indicating content"
    )
  }

  // MARK: - Integration Tests

  func testFullContentPolicyFlow() throws {
    // 1. Launch app (already done in setUp)
    // 2. Open Settings
    app.typeKey(",", modifierFlags: .command)
    sleep(1)

    // 3. Verify Settings opened
    let contentPolicyButton = app.buttons.matching(identifier: "OpenContentPolicyButton").firstMatch
    XCTAssertTrue(contentPolicyButton.waitForExistence(timeout: 5), "Settings should open")

    // 4. Open Content Policy
    contentPolicyButton.click()

    // 5. Wait for content to load
    let policyWebView = app.webViews.matching(identifier: "ContentPolicyWebView").firstMatch
    XCTAssertTrue(policyWebView.waitForExistence(timeout: 10), "Policy sheet should open")

    let sourceLabel = app.staticTexts.matching(identifier: "ContentPolicySourceLabel").firstMatch
    XCTAssertTrue(sourceLabel.waitForExistence(timeout: 15), "Content should load")

    // 6. Dismiss policy
    let doneButton = app.buttons["Done"]
    XCTAssertTrue(doneButton.exists)
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

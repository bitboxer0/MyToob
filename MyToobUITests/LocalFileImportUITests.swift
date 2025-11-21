//
//  LocalFileImportUITests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import XCTest

final class LocalFileImportUITests: XCTestCase {
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

  // MARK: - Import Button Tests

  func testImportLocalFilesButtonExists() throws {
    // Find "Local Files" section header
    let localFilesSection = app.staticTexts["Local Files"]
    XCTAssertTrue(localFilesSection.exists, "Local Files section should exist in sidebar")

    // Find "Import Local Files" button using accessibility identifier
    let importButton = app.buttons.matching(identifier: "ImportLocalFilesButton").firstMatch
    XCTAssertTrue(importButton.exists, "Import Local Files button should exist")
    XCTAssertTrue(importButton.isEnabled, "Import Local Files button should be enabled")
  }

  func testImportLocalFilesButtonAccessibility() throws {
    let importButton = app.buttons.matching(identifier: "ImportLocalFilesButton").firstMatch

    XCTAssertTrue(importButton.exists)

    // Verify accessibility properties
    XCTAssertEqual(importButton.label, "Import Local Files")

    // Note: accessibilityHint is iOS-only. On macOS, use accessibilityHelp instead
    // However, XCUIElement doesn't expose accessibilityHelp directly in UI tests
    // so we verify the button is accessible via VoiceOver-compatible properties
    XCTAssertTrue(importButton.isEnabled, "Button should be enabled and accessible")
    XCTAssertFalse(importButton.label.isEmpty, "Button should have accessible label")
  }

  func testImportButtonInteraction() throws {
    let importButton = app.buttons.matching(identifier: "ImportLocalFilesButton").firstMatch

    XCTAssertTrue(importButton.exists)
    XCTAssertTrue(importButton.isHittable, "Button should be hittable/clickable")

    // Note: We cannot fully test NSOpenPanel in UI tests as it's a system dialog
    // and requires user interaction. This test verifies the button exists and is
    // interactive, but we cannot programmatically interact with the file picker.
  }

  func testLocalFilesSectionStructure() throws {
    // Verify "Local Files" section exists
    XCTAssertTrue(app.staticTexts["Local Files"].exists)

    // Verify "All Local Videos" label exists
    let allLocalVideosLabel = app.staticTexts["All Local Videos"]
    XCTAssertTrue(allLocalVideosLabel.exists, "All Local Videos label should exist in Local Files section")

    // Verify import button exists
    let importButton = app.buttons.matching(identifier: "ImportLocalFilesButton").firstMatch
    XCTAssertTrue(importButton.exists, "Import button should exist in Local Files section")
  }

  // MARK: - Integration Tests

  func testSidebarNavigationStructure() throws {
    // Verify all main sections exist
    XCTAssertTrue(app.staticTexts["Collections"].exists, "Collections section should exist")
    XCTAssertTrue(app.staticTexts["YouTube"].exists, "YouTube section should exist")
    XCTAssertTrue(app.staticTexts["Local Files"].exists, "Local Files section should exist")

    // Verify Local Files section is accessible
    let localFilesSection = app.staticTexts["Local Files"]
    XCTAssertTrue(localFilesSection.exists)
  }
}

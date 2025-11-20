//
//  LocalFileImportUITests.swift
//  MyToobUITests
//
//  UI tests for local file import functionality
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
    // Navigate to sidebar
    let sidebar = app.windows.firstMatch.groups.firstMatch

    // Find "Local Files" section
    let localFilesSection = sidebar.staticTexts["Local Files"]
    XCTAssertTrue(localFilesSection.exists, "Local Files section should exist in sidebar")

    // Find "Import Local Files" button
    let importButton = sidebar.buttons["Import Local Files"]
    XCTAssertTrue(importButton.exists, "Import Local Files button should exist")
    XCTAssertTrue(importButton.isEnabled, "Import Local Files button should be enabled")
  }

  func testImportLocalFilesButtonAccessibility() throws {
    let sidebar = app.windows.firstMatch.groups.firstMatch
    let importButton = sidebar.buttons["Import Local Files"]

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
    let sidebar = app.windows.firstMatch.groups.firstMatch
    let importButton = sidebar.buttons["Import Local Files"]

    XCTAssertTrue(importButton.exists)
    XCTAssertTrue(importButton.isHittable, "Button should be hittable/clickable")

    // Note: We cannot fully test NSOpenPanel in UI tests as it's a system dialog
    // and requires user interaction. This test verifies the button exists and is
    // interactive, but we cannot programmatically interact with the file picker.
  }

  func testLocalFilesSectionStructure() throws {
    let sidebar = app.windows.firstMatch.groups.firstMatch

    // Verify "Local Files" section exists
    XCTAssertTrue(sidebar.staticTexts["Local Files"].exists)

    // Verify "All Videos" label exists in Local Files section
    let allVideosLabel = sidebar.staticTexts["All Videos"]
    XCTAssertTrue(allVideosLabel.exists, "All Videos label should exist in Local Files section")

    // Verify import button exists in same section
    let importButton = sidebar.buttons["Import Local Files"]
    XCTAssertTrue(importButton.exists, "Import button should exist in Local Files section")
  }

  // MARK: - Integration Tests

  func testSidebarNavigationStructure() throws {
    let sidebar = app.windows.firstMatch.groups.firstMatch

    // Verify all main sections exist
    XCTAssertTrue(sidebar.staticTexts["Collections"].exists, "Collections section should exist")
    XCTAssertTrue(sidebar.staticTexts["YouTube"].exists, "YouTube section should exist")
    XCTAssertTrue(sidebar.staticTexts["Local Files"].exists, "Local Files section should exist")

    // Verify Local Files section is accessible
    let localFilesSection = sidebar.staticTexts["Local Files"]
    XCTAssertTrue(localFilesSection.isEnabled)
  }
}

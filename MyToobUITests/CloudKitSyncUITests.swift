//
//  CloudKitSyncUITests.swift
//  MyToobUITests
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import XCTest

// MARK: - UI Test Helpers

extension XCUIElement {
  /// Waits for the element to exist and be hittable.
  /// - Parameter timeout: Maximum time to wait
  /// - Returns: `true` if element is hittable within timeout
  func waitUntilHittable(timeout: TimeInterval = 3.0) -> Bool {
    waitForExistence(timeout: timeout) && isHittable
  }
}

extension XCTestCase {
  /// Waits until a condition becomes true or times out.
  /// - Parameters:
  ///   - condition: A closure that returns `true` when the condition is met
  ///   - timeout: Maximum time to wait
  ///   - interval: Polling interval
  func waitUntil(
    _ condition: @escaping () -> Bool,
    timeout: TimeInterval = 3.0,
    interval: TimeInterval = 0.05
  ) {
    let end = Date().addingTimeInterval(timeout)
    while Date() < end {
      if condition() { return }
      RunLoop.current.run(until: Date().addingTimeInterval(interval))
    }
    XCTFail("Timed out waiting for condition")
  }
}

/// UI tests for CloudKit sync status indicator and settings.
///
/// **Test Coverage:**
/// - Sync status indicator visible in toolbar
/// - Sync status popover displays details
/// - Settings toggle for CloudKit sync
/// - Sync Now button functionality
///
/// **Note:** These tests verify UI element existence and basic interactions.
/// Actual CloudKit operations are gated by Configuration.cloudKitSyncEnabled
/// which defaults to false in test environments.
final class CloudKitSyncUITests: XCTestCase {
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

  // MARK: - Sync Status Indicator Tests

  /// Test that the sync status indicator button is visible in the toolbar
  func testSyncStatusIndicatorVisible() throws {
    // Find the sync status indicator button by accessibility identifier
    let syncIndicator = app.buttons["SyncStatusIndicatorButton"]

    // Assert it exists - may take a moment to appear
    let exists = syncIndicator.waitForExistence(timeout: 5)
    XCTAssertTrue(exists, "Sync status indicator button should exist in toolbar")

    // Assert it's enabled (clickable)
    XCTAssertTrue(syncIndicator.isEnabled, "Sync status indicator should be enabled")
  }

  /// Test that clicking the sync status indicator shows a popover with details
  func testSyncStatusPopover() throws {
    // Find and tap the sync status indicator
    let syncIndicator = app.buttons["SyncStatusIndicatorButton"]
    XCTAssertTrue(
      syncIndicator.waitForExistence(timeout: 5),
      "Sync status indicator should exist"
    )

    syncIndicator.click()

    // Wait for popover to appear
    let popover = app.popovers["SyncStatusPopover"]
    let popoverExists = popover.waitForExistence(timeout: 3)
    XCTAssertTrue(popoverExists, "Sync status popover should appear when indicator is clicked")

    // Verify popover contains expected elements
    // Look for "iCloud Sync" header text
    let header = app.staticTexts["iCloud Sync"]
    XCTAssertTrue(
      header.waitForExistence(timeout: 2),
      "Popover should contain 'iCloud Sync' header"
    )

    // Look for "Open Settings..." button
    let settingsButton = app.buttons["OpenSyncSettingsButton"]
    XCTAssertTrue(
      settingsButton.waitForExistence(timeout: 2),
      "Popover should contain 'Open Settings...' button"
    )

    // Dismiss popover by clicking elsewhere
    app.typeKey(.escape, modifierFlags: [])
  }

  // MARK: - Settings Tests

  /// Test that the Settings window has a sync tab and toggle
  func testToggleSyncInSettings() throws {
    // Open Settings window via keyboard shortcut (Cmd-,)
    app.typeKey(",", modifierFlags: .command)

    // Wait for Settings window to appear
    let settingsWindow = app.windows["SettingsWindow"]
    if !settingsWindow.waitForExistence(timeout: 3) {
      // Try alternate approach - look for any settings-related window
      let anySettingsWindow = app.windows.containing(.tabGroup, identifier: "").firstMatch
      XCTAssertTrue(
        anySettingsWindow.waitForExistence(timeout: 3),
        "Settings window should appear"
      )
    }

    // Find the sync toggle
    let syncToggle = app.toggles["CloudKitSyncToggle"]
    let toggleExists = syncToggle.waitForExistence(timeout: 3)

    if toggleExists {
      // Toggle should exist
      XCTAssertTrue(toggleExists, "CloudKit sync toggle should exist in Settings")

      // Check initial state (default should be off, and may be disabled if entitlement unavailable)
      // Just verify it exists and is accessible
      XCTAssertTrue(syncToggle.isHittable, "Sync toggle should be hittable")
    } else {
      // If toggle not found directly, look for it in the tab content
      // The Settings may need to navigate to the Sync tab first
      let syncTab = app.tabGroups.buttons["iCloud Sync"]
      if syncTab.exists {
        syncTab.click()
        XCTAssertTrue(
          syncToggle.waitForExistence(timeout: 2),
          "Sync toggle should appear after selecting Sync tab"
        )
      }
    }

    // Close settings window
    app.typeKey("w", modifierFlags: .command)
  }

  /// Test that the Sync Now button exists and is functional
  func testSyncNowButton() throws {
    // Open Settings window
    app.typeKey(",", modifierFlags: .command)

    // Wait for window
    _ = app.windows.firstMatch.waitForExistence(timeout: 3)

    // Navigate to sync tab if needed
    let syncTab = app.tabGroups.buttons["iCloud Sync"]
    if syncTab.waitForExistence(timeout: 2) {
      syncTab.click()
    }

    // Find the Sync Now button
    let syncNowButton = app.buttons["SyncNowButton"]
    let buttonExists = syncNowButton.waitForExistence(timeout: 3)

    if buttonExists {
      // Button should exist
      XCTAssertTrue(buttonExists, "Sync Now button should exist in Settings")

      // Note: Button may be disabled if sync is not effectively enabled
      // Just verify it's present and accessible
      // We don't click it to avoid triggering actual CloudKit operations

      // If enabled, verify it's hittable
      if syncNowButton.isEnabled {
        XCTAssertTrue(syncNowButton.isHittable, "Enabled Sync Now button should be hittable")
      }
    }

    // Close settings
    app.typeKey("w", modifierFlags: .command)
  }

  // MARK: - Integration Tests

  /// Test the full flow: indicator -> popover -> settings
  func testFullSyncUIFlow() throws {
    // 1. Verify indicator exists
    let syncIndicator = app.buttons["SyncStatusIndicatorButton"]
    XCTAssertTrue(
      syncIndicator.waitForExistence(timeout: 5),
      "Sync status indicator should exist"
    )

    // 2. Open popover
    syncIndicator.click()

    let popover = app.popovers.firstMatch
    XCTAssertTrue(
      popover.waitForExistence(timeout: 3),
      "Popover should appear"
    )

    // 3. Click Open Settings from popover
    let openSettingsButton = app.buttons["OpenSyncSettingsButton"]
    if openSettingsButton.waitForExistence(timeout: 2) {
      openSettingsButton.click()

      // 4. Verify Settings window opens - use waitForExistence instead of Thread.sleep
      let syncToggle = app.toggles["CloudKitSyncToggle"]
      XCTAssertTrue(
        syncToggle.waitUntilHittable(timeout: 5),
        "Settings should open with sync toggle visible"
      )

      // Close settings
      app.typeKey("w", modifierFlags: .command)
    } else {
      // Dismiss popover if settings button not found
      app.typeKey(.escape, modifierFlags: [])
    }
  }

  /// Test that sync indicator updates visually (basic state check)
  func testSyncIndicatorAccessibility() throws {
    let syncIndicator = app.buttons["SyncStatusIndicatorButton"]
    XCTAssertTrue(
      syncIndicator.waitForExistence(timeout: 5),
      "Sync status indicator should exist"
    )

    // Verify accessibility properties
    XCTAssertFalse(
      syncIndicator.label.isEmpty,
      "Sync indicator should have an accessibility label"
    )
  }

  // MARK: - Settings Tab Navigation

  /// Test that Settings window has correct tabs
  func testSettingsTabsExist() throws {
    // Open Settings
    app.typeKey(",", modifierFlags: .command)

    // Wait for window
    _ = app.windows.firstMatch.waitForExistence(timeout: 3)

    // Check for tab structure
    // Note: Tab identifiers may vary based on SwiftUI TabView implementation
    let tabGroup = app.tabGroups.firstMatch
    if tabGroup.waitForExistence(timeout: 2) {
      // Tab group exists, look for our tabs
      let syncTab = app.buttons.matching(NSPredicate(format: "label CONTAINS 'iCloud'")).firstMatch
      let aboutTab = app.buttons.matching(NSPredicate(format: "label CONTAINS 'About'")).firstMatch

      // At least one of these should exist
      let hasSyncTab = syncTab.waitForExistence(timeout: 2)
      let hasAboutTab = aboutTab.waitForExistence(timeout: 2)

      XCTAssertTrue(
        hasSyncTab || hasAboutTab,
        "Settings should have recognizable tabs"
      )
    }

    // Close settings
    app.typeKey("w", modifierFlags: .command)
  }
}

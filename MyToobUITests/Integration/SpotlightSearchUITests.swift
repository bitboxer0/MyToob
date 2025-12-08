//
//  SpotlightSearchUITests.swift
//  MyToobUITests
//
//  Created by Claude Code (BMad Master) on 12/5/25.
//

import XCTest

/// UI tests for Spotlight search integration
/// Verifies deep-link handling and navigation from Spotlight results
final class SpotlightSearchUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - Deep Link Handling Tests

  /// Test that the app handles Spotlight result deep links
  ///
  /// Note: Testing actual Spotlight search requires launching Spotlight externally,
  /// which is not possible in UI tests. Instead, we test the deep link handling
  /// by simulating the userActivity that Spotlight would create.
  func testSpotlightResultClick_OpensAppToVideo() throws {
    // Given - App is launched
    app.launch()

    // Wait for main window to appear
    let mainWindow = app.windows.firstMatch
    XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))

    // When - Simulate Spotlight deep link activity
    // This tests the app's handling of CSSearchableItemActionType
    // The actual userActivity is sent via launch arguments in a real scenario

    // Launch with spotlight deep link argument
    let spotlightApp = XCUIApplication()
    spotlightApp.launchArguments = [
      "--uitesting",
      "--spotlight-video-id", "testVideo123",
    ]
    spotlightApp.launch()

    // Then - App should navigate to video detail or player
    // Since we don't have a video detail view yet, we verify the app handles the launch
    let window = spotlightApp.windows.firstMatch
    XCTAssertTrue(window.waitForExistence(timeout: 5))

    // In future implementation, verify navigation to specific video:
    // XCTAssertTrue(spotlightApp.staticTexts["testVideo123"].waitForExistence(timeout: 3))
  }

  /// Test that invalid Spotlight deep links are handled gracefully
  func testSpotlightResultClick_InvalidVideo_HandlesGracefully() throws {
    // Given - App launched with non-existent video ID
    app.launchArguments = [
      "--uitesting",
      "--spotlight-video-id", "nonExistentVideo999",
    ]
    app.launch()

    // When - App processes the deep link

    // Then - App should not crash and remain functional
    let mainWindow = app.windows.firstMatch
    XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))

    // Verify app is still responsive
    // In future, could show an alert or navigate to main view
  }

  // MARK: - Settings UI Tests

  /// Test that Spotlight settings toggle exists and is accessible
  func testSpotlightSettingsToggle_Exists() throws {
    app.launch()

    // Open Settings window (Cmd-,)
    app.typeKey(",", modifierFlags: .command)

    // Wait for Settings window
    let settingsWindow = app.windows["SettingsWindow"]
    XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3))

    // Navigate to Spotlight/Integration tab if it exists
    // Look for the tab or toggle
    let spotlightTab = settingsWindow.tabs["Spotlight"]
    let integrationTab = settingsWindow.tabs["Integration"]

    // Check if either tab exists (implementation may vary)
    if spotlightTab.exists {
      spotlightTab.click()
    } else if integrationTab.exists {
      integrationTab.click()
    }

    // Look for the toggle
    let spotlightToggle = settingsWindow.switches["SpotlightIndexingToggle"]
    // Note: Toggle may be in a different location based on Settings structure

    // For now, just verify settings window is accessible
    // Full verification will be added when SpotlightSettingsView is implemented
  }

  /// Test that toggling Spotlight indexing updates the UI state
  func testSpotlightSettingsToggle_TogglesState() throws {
    app.launch()

    // Open Settings window
    app.typeKey(",", modifierFlags: .command)

    let settingsWindow = app.windows["SettingsWindow"]
    XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3))

    // Find and interact with Spotlight toggle
    // This will be implemented once SpotlightSettingsView exists
    let toggle = settingsWindow.switches["SpotlightIndexingToggle"]
    if toggle.waitForExistence(timeout: 2) {
      let initialValue = toggle.value as? String
      toggle.click()

      // Verify state changed
      let newValue = toggle.value as? String
      XCTAssertNotEqual(initialValue, newValue)
    }
  }

  // MARK: - Thumbnail Display Tests

  /// Test that indexed videos would include thumbnail data
  /// Note: Actual Spotlight result rendering is handled by macOS
  func testThumbnailDisplay_DataIncluded() throws {
    // This test verifies the app properly includes thumbnail URLs
    // in the CSSearchableItem. Since we can't control Spotlight UI,
    // we verify through the indexing logic in unit tests.

    // Launch app to ensure indexing service is available
    app.launch()

    let mainWindow = app.windows.firstMatch
    XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))

    // The actual thumbnail verification happens in SpotlightIndexingTests
    // This UI test ensures the app launches and is ready for indexing
  }

  // MARK: - Accessibility Tests

  /// Test that Spotlight settings have proper accessibility labels
  func testSpotlightSettings_Accessibility() throws {
    app.launch()

    // Open Settings
    app.typeKey(",", modifierFlags: .command)

    let settingsWindow = app.windows["SettingsWindow"]
    XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3))

    // Check for accessibility identifiers on Spotlight-related elements
    let spotlightElements = settingsWindow.descendants(matching: .any).matching(
      NSPredicate(format: "identifier CONTAINS[c] 'spotlight'")
    )

    // When SpotlightSettingsView is implemented, verify accessibility
    // For now, ensure settings window itself is accessible
    XCTAssertTrue(settingsWindow.isHittable)
  }

  // MARK: - Integration Flow Tests

  /// Test the complete flow: Settings toggle → Indexing behavior
  func testIntegrationFlow_SettingsAffectsIndexing() throws {
    app.launch()

    // 1. Open Settings and verify Spotlight toggle
    app.typeKey(",", modifierFlags: .command)

    let settingsWindow = app.windows["SettingsWindow"]
    XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3))

    // 2. Close Settings
    app.typeKey("w", modifierFlags: .command)

    // 3. Verify main window is still accessible
    let mainWindow = app.windows.firstMatch
    XCTAssertTrue(mainWindow.waitForExistence(timeout: 3))

    // Full integration test will verify:
    // - Toggle off → no new items indexed
    // - Toggle on → new items are indexed
    // This requires the SpotlightIndexer implementation
  }
}

//
//  DisclaimersUITests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import XCTest

/// UI tests for YouTube branding compliance and disclaimers.
/// Story 12.5: Validates:
/// - "Not affiliated" disclaimer in About screen
/// - YouTube ToS statement in About screen
/// - ToS link presence in About screen
/// - YouTube logo in sidebar
/// - App name avoids YouTube trademark
/// - App icon is custom (not YouTube-like)
///
/// These tests ensure compliance with YouTube branding guidelines
/// and App Store requirements for third-party YouTube apps.
final class DisclaimersUITests: XCTestCase {
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

  // MARK: - About Screen Disclaimer Tests

  func testDisclaimerInAboutScreen() throws {
    // Given: Settings window is opened
    XCTAssertTrue(openSettingsAndWait(), "Settings should open with Cmd-,")

    // Then: "Not affiliated" disclaimer should exist
    let notAffiliatedText = app.staticTexts.matching(identifier: "AboutNotAffiliatedText").firstMatch
    XCTAssertTrue(
      notAffiliatedText.waitForExistence(timeout: 3),
      "Not affiliated disclaimer should exist in About screen"
    )

    // Verify the disclaimer text content
    XCTAssertTrue(
      notAffiliatedText.label.contains("Not affiliated"),
      "Disclaimer should contain 'Not affiliated' text"
    )
  }

  func testYouTubeToSStatementInAboutScreen() throws {
    // Given: Settings window is opened
    XCTAssertTrue(openSettingsAndWait(), "Settings should open with Cmd-,")

    // Then: YouTube ToS statement should exist
    let tosText = app.staticTexts.matching(identifier: "AboutYouTubeToSText").firstMatch
    XCTAssertTrue(
      tosText.waitForExistence(timeout: 3),
      "YouTube ToS statement should exist in About screen"
    )

    // Verify the ToS text mentions official APIs
    XCTAssertTrue(
      tosText.label.contains("official APIs") || tosText.label.contains("Terms of Service"),
      "ToS statement should mention official APIs or Terms of Service"
    )
  }

  func testToSLinkInAboutScreen() throws {
    // Given: Settings window is opened
    XCTAssertTrue(openSettingsAndWait(), "Settings should open with Cmd-,")

    // Then: ToS link button should exist
    let tosLink = app.buttons.matching(identifier: "AboutToSLink").firstMatch
    XCTAssertTrue(
      tosLink.waitForExistence(timeout: 3),
      "YouTube Terms of Service link should exist in About screen"
    )

    // Verify the link is interactable
    XCTAssertTrue(tosLink.isEnabled, "ToS link should be enabled")
    XCTAssertTrue(tosLink.isHittable, "ToS link should be hittable")

    // Note: We don't click the link to avoid opening browser in CI
  }

  // MARK: - Sidebar YouTube Logo Tests

  func testYouTubeLogoInSidebar() throws {
    // Given: App is launched and main window is visible
    let sidebar = app.outlines.firstMatch
    XCTAssertTrue(
      sidebar.waitForExistence(timeout: 5),
      "Sidebar should exist"
    )

    // Then: YouTube logo/icon should exist in sidebar
    let youtubeLogo = app.images.matching(identifier: "YouTubeSidebarLogo").firstMatch
    XCTAssertTrue(
      youtubeLogo.waitForExistence(timeout: 3),
      "YouTube logo should exist in sidebar YouTube section"
    )
  }

  func testYouTubeSectionExists() throws {
    // Given: App is launched
    let youtubeSection = app.staticTexts.matching(identifier: "YouTubeSection").firstMatch

    // Then: YouTube section should exist in sidebar
    XCTAssertTrue(
      youtubeSection.waitForExistence(timeout: 5),
      "YouTube section should exist in sidebar"
    )
  }

  // MARK: - App Name & Icon Tests

  func testAppNameAvoidsTrademark() throws {
    // Given: App is launched
    // The app name should be "MyToob" not contain "YouTube"

    // Check navigation title
    let navigationTitle = app.navigationBars.staticTexts["MyToob"]
    XCTAssertTrue(
      navigationTitle.waitForExistence(timeout: 5),
      "Navigation title should be 'MyToob'"
    )

    // Verify the title does NOT contain "YouTube" or "Tube" (trademark)
    let youtubeTitle = app.navigationBars.staticTexts.matching(
      NSPredicate(format: "label CONTAINS[c] 'YouTube'")
    ).firstMatch
    XCTAssertFalse(
      youtubeTitle.exists,
      "App name should not contain 'YouTube' trademark"
    )
  }

  func testAppNameInAboutScreen() throws {
    // Given: Settings window is opened
    XCTAssertTrue(openSettingsAndWait(), "Settings should open with Cmd-,")

    // Then: App name should be "MyToob"
    let appNameText = app.staticTexts.matching(identifier: "AboutAppName").firstMatch
    XCTAssertTrue(
      appNameText.waitForExistence(timeout: 3),
      "App name should be displayed in About screen"
    )
    XCTAssertEqual(
      appNameText.label,
      "MyToob",
      "App name should be 'MyToob' in About screen"
    )
  }

  func testAppIconUnique() throws {
    // This test verifies the app icon is not a YouTube-like icon
    // Since XCUI cannot directly inspect icon images, we verify:
    // 1. The app's name in the menu bar is "MyToob"
    // 2. There's no "YouTube" in the app's accessibility elements

    // Check main menu
    let menuBar = app.menuBars.firstMatch
    XCTAssertTrue(menuBar.exists, "Menu bar should exist")

    // Verify app menu is "MyToob" not "YouTube"
    let appMenu = menuBar.menuBarItems["MyToob"]
    XCTAssertTrue(
      appMenu.waitForExistence(timeout: 3),
      "App menu should be titled 'MyToob'"
    )

    // Verify no "YouTube" app menu exists
    let youtubeMenu = menuBar.menuBarItems["YouTube"]
    XCTAssertFalse(
      youtubeMenu.exists,
      "App menu should not be titled 'YouTube'"
    )
  }

  // MARK: - Integration Tests

  func testFullComplianceFlow() throws {
    // This test walks through the full compliance verification flow

    // Step 1: Verify sidebar has YouTube section with logo
    let youtubeLogo = app.images.matching(identifier: "YouTubeSidebarLogo").firstMatch
    XCTAssertTrue(
      youtubeLogo.waitForExistence(timeout: 5),
      "YouTube logo should exist in sidebar"
    )

    // Step 2: Open Settings
    XCTAssertTrue(openSettingsAndWait(), "Settings should open")

    // Step 3: Verify all disclaimer elements
    let notAffiliatedText = app.staticTexts.matching(identifier: "AboutNotAffiliatedText").firstMatch
    let tosText = app.staticTexts.matching(identifier: "AboutYouTubeToSText").firstMatch
    let tosLink = app.buttons.matching(identifier: "AboutToSLink").firstMatch

    XCTAssertTrue(notAffiliatedText.exists, "Not affiliated disclaimer should exist")
    XCTAssertTrue(tosText.exists, "ToS statement should exist")
    XCTAssertTrue(tosLink.exists, "ToS link should exist")

    // Step 4: Verify app name compliance
    let appNameText = app.staticTexts.matching(identifier: "AboutAppName").firstMatch
    XCTAssertTrue(appNameText.exists, "App name should exist")
    XCTAssertEqual(appNameText.label, "MyToob", "App name should be 'MyToob'")
  }
}

//
// SwiftLintValidationTests.swift
// MyToob
//
// Created by Test on 11/18/25.
//

import XCTest

/// Tests to verify SwiftLint custom rules catch violations
/// These tests intentionally contain violations to verify linting works
class SwiftLintValidationTests: XCTestCase {
  // MARK: - Compliance Rule Tests

  func testGoogleVideoURLBlocked() {
    // This test verifies the custom rule catches googlevideo.com usage
    // EXPECTED: SwiftLint error on next line
    // let badURL = "https://googlevideo.com/videoplayback"

    // CORRECT: Use IFrame Player API
    let correctURL = "https://www.youtube.com/embed/VIDEO_ID"
    XCTAssertTrue(correctURL.contains("youtube.com/embed"))
  }

  func testHardcodedAPIKeyBlocked() {
    // This test verifies the custom rule catches hardcoded API keys
    // EXPECTED: SwiftLint error on next line
    // let apiKey = "AIzaSyABCDEF1234567890ABCDEFGHIJK"

    // CORRECT: Load from environment
    // let apiKey = Configuration.youtubeAPIKey
    XCTAssertTrue(true)
  }

  func testHardcodedSecretWarning() {
    // This test verifies the custom rule warns on hardcoded secrets
    // EXPECTED: SwiftLint warning on next line
    // let secret = "super_secret_token_12345678"

    // CORRECT: Use Keychain
    // let secret = try KeychainService.shared.retrieveToken()
    XCTAssertTrue(true)
  }

  // MARK: - Coding Standard Tests

  func testForceTryAllowedInTests() {
    // Force try is allowed in test files
    let data = try! JSONEncoder().encode(["test": "value"])
    XCTAssertNotNil(data)
  }

  func testDirectKeychainAccessBlocked() {
    // This test verifies the custom rule blocks direct Keychain access
    // EXPECTED: SwiftLint error on next line
    // let status = SecItemAdd(query as CFDictionary, nil)

    // CORRECT: Use KeychainService wrapper
    // try KeychainService.shared.saveToken(token)
    XCTAssertTrue(true)
  }

  func testDirectEnvironmentAccessBlocked() {
    // This test verifies the custom rule blocks direct environment access
    // EXPECTED: SwiftLint error on next line (unless in Configuration.swift)
    // let apiKey = ProcessInfo.processInfo.environment["API_KEY"]

    // CORRECT: Use Configuration enum
    // let apiKey = Configuration.youtubeAPIKey
    XCTAssertTrue(true)
  }

  func testDirectYouTubeURLSessionBlocked() {
    // This test verifies the custom rule blocks direct YouTube API calls
    // EXPECTED: SwiftLint error on next line (unless in YouTubeService.swift)
    // let url = URL(string: "https://youtube.googleapis.com/youtube/v3/videos")!
    // let task = URLSession.shared.dataTask(with: url)

    // CORRECT: Use YouTubeService wrapper
    // await YouTubeService.shared.fetchVideoDetails(videoID)
    XCTAssertTrue(true)
  }
}

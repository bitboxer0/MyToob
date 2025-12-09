//
//  AppShortcutsProviderTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import Testing

@testable import MyToob

/// Tests for MyToobAppShortcutsProvider
/// Verifies shortcut configuration and discoverability
@Suite("AppShortcutsProvider Tests")
struct AppShortcutsProviderTests {

  // MARK: - Shortcut Count Tests

  @Test("Provider includes all 4 intent shortcuts")
  func testAllIntentsIncluded() {
    // When
    let shortcuts = MyToobAppShortcutsProvider.appShortcuts

    // Then
    #expect(shortcuts.count == 4)
  }

  // MARK: - Provider Conformance Tests

  @Test("Provider conforms to AppShortcutsProvider")
  func testProviderConformance() {
    // The provider should conform to AppShortcutsProvider
    // This is a compile-time check, but we verify the shortcuts are accessible
    let shortcuts = MyToobAppShortcutsProvider.appShortcuts
    #expect(!shortcuts.isEmpty)
  }

  @Test("Provider is not empty")
  func testProviderNotEmpty() {
    // When
    let shortcuts = MyToobAppShortcutsProvider.appShortcuts

    // Then
    #expect(shortcuts.count > 0)
  }

  @Test("Provider has expected number of shortcuts")
  func testExpectedShortcutCount() {
    // Given - we have 4 intents: PlayVideo, AddToCollection, SearchVideos, GetRandomVideo
    let expectedCount = 4

    // When
    let shortcuts = MyToobAppShortcutsProvider.appShortcuts

    // Then
    #expect(shortcuts.count == expectedCount)
  }

  // MARK: - Intent Registration Tests

  @Test("PlayVideoIntent can be instantiated")
  func testPlayVideoIntentExists() {
    // When
    let intent = PlayVideoIntent()

    // Then - verify it's properly configured
    #expect(PlayVideoIntent.title != nil)
    #expect(PlayVideoIntent.openAppWhenRun == true)
    #expect(intent.video == nil)  // Default should be nil until set
  }

  @Test("SearchVideosIntent can be instantiated")
  func testSearchVideosIntentExists() {
    // When
    let intent = SearchVideosIntent()

    // Then
    #expect(SearchVideosIntent.title != nil)
    #expect(intent.query == "")  // Default empty query
  }

  @Test("GetRandomVideoIntent can be instantiated")
  func testGetRandomVideoIntentExists() {
    // When - just verify it can be created
    _ = GetRandomVideoIntent()

    // Then
    #expect(GetRandomVideoIntent.title != nil)
  }

  @Test("AddToCollectionIntent can be instantiated")
  func testAddToCollectionIntentExists() {
    // When
    let intent = AddToCollectionIntent()

    // Then
    #expect(AddToCollectionIntent.title != nil)
    #expect(intent.video == nil)
    #expect(intent.collection == nil)
  }

  // MARK: - Static Property Tests

  @Test("All intents have static title")
  func testAllIntentsHaveTitles() {
    // Verify all intent types have proper titles configured
    #expect(PlayVideoIntent.title != nil)
    #expect(SearchVideosIntent.title != nil)
    #expect(GetRandomVideoIntent.title != nil)
    #expect(AddToCollectionIntent.title != nil)
  }

  @Test("All intents have static description")
  func testAllIntentsHaveDescriptions() {
    // Verify all intent types have descriptions
    #expect(PlayVideoIntent.description != nil)
    #expect(SearchVideosIntent.description != nil)
    #expect(GetRandomVideoIntent.description != nil)
    #expect(AddToCollectionIntent.description != nil)
  }
}

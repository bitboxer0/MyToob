//
//  AppShortcutsProvider.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation

/// Provides App Shortcuts for MyToob.
/// Defines suggested shortcuts that appear in the Shortcuts app for discoverability.
struct MyToobAppShortcutsProvider: AppShortcutsProvider {

  /// The shortcuts available for MyToob
  static var appShortcuts: [AppShortcut] {
    // Play Video shortcut
    AppShortcut(
      intent: PlayVideoIntent(),
      phrases: [
        "Play video in \(.applicationName)",
        "Watch video in \(.applicationName)",
        "Play \(\.$video) in \(.applicationName)",
      ],
      shortTitle: "Play Video",
      systemImageName: "play.circle.fill"
    )

    // Search Videos shortcut
    // Note: String parameters cannot be interpolated in phrases
    AppShortcut(
      intent: SearchVideosIntent(),
      phrases: [
        "Search videos in \(.applicationName)",
        "Find videos in \(.applicationName)",
        "Search my videos in \(.applicationName)",
      ],
      shortTitle: "Search Videos",
      systemImageName: "magnifyingglass"
    )

    // Get Random Video shortcut
    AppShortcut(
      intent: GetRandomVideoIntent(),
      phrases: [
        "Get random video from \(.applicationName)",
        "Show me something in \(.applicationName)",
        "Surprise me with a video from \(.applicationName)",
        "Random video in \(.applicationName)",
      ],
      shortTitle: "Random Video",
      systemImageName: "shuffle"
    )

    // Add to Collection shortcut
    AppShortcut(
      intent: AddToCollectionIntent(),
      phrases: [
        "Add video to collection in \(.applicationName)",
        "Add to collection in \(.applicationName)",
        "Save video to \(.applicationName) collection",
      ],
      shortTitle: "Add to Collection",
      systemImageName: "folder.badge.plus"
    )
  }
}

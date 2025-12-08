//
//  SpotlightSettingsStore.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/5/25.
//

import Combine
import Foundation
import OSLog

/// Manages user preferences for Spotlight indexing functionality.
///
/// This store provides a user-facing toggle for Spotlight indexing.
/// When enabled (default), videos are indexed in Spotlight for system-wide search.
///
/// **Pro Feature Consideration:**
/// While Story 13.1 mentions this as a Pro feature, the basic toggle is available
/// to all users. Pro gating can be added later by checking a license manager.
///
/// Usage:
/// ```swift
/// let store = SpotlightSettingsStore.shared
///
/// // Check if indexing is enabled
/// if store.isIndexingEnabled {
///     await SpotlightIndexer.shared.indexVideo(video)
/// }
///
/// // Toggle indexing
/// store.isIndexingEnabled = false
/// ```
@MainActor
final class SpotlightSettingsStore: ObservableObject {

  // MARK: - Singleton

  /// Shared instance for app-wide access
  static let shared = SpotlightSettingsStore()

  // MARK: - Properties

  /// UserDefaults instance for persistence
  private let userDefaults: UserDefaults

  /// Key for storing the preference
  private let key: String

  /// Default key for Spotlight indexing preference
  private static let defaultKey = "spotlight.indexing.enabled"

  // MARK: - Published Properties

  /// Whether Spotlight indexing is enabled.
  /// Defaults to `true` for new users.
  @Published var isIndexingEnabled: Bool {
    didSet {
      guard oldValue != isIndexingEnabled else { return }
      userDefaults.set(isIndexingEnabled, forKey: key)
      LoggingService.shared.integration.notice(
        "Spotlight indexing preference changed to \(self.isIndexingEnabled, privacy: .public)"
      )
    }
  }

  // MARK: - Computed Properties

  /// Number of videos currently indexed in Spotlight.
  /// This is a cached count that should be updated by SpotlightIndexer.
  @Published private(set) var indexedVideoCount: Int = 0

  // MARK: - Initialization

  /// Private initializer for singleton pattern
  private convenience init() {
    self.init(userDefaults: .standard, key: Self.defaultKey)
  }

  /// Initializer with dependency injection for testing
  /// - Parameters:
  ///   - userDefaults: UserDefaults instance to use
  ///   - key: Key for storing the preference
  init(userDefaults: UserDefaults, key: String) {
    self.userDefaults = userDefaults
    self.key = key

    // Load persisted preference, defaulting to true (enabled by default)
    // Use object(forKey:) to detect if a value was ever set
    if userDefaults.object(forKey: key) != nil {
      self.isIndexingEnabled = userDefaults.bool(forKey: key)
    } else {
      // First launch: default to enabled
      self.isIndexingEnabled = true
      userDefaults.set(true, forKey: key)
    }

    LoggingService.shared.integration.debug(
      "SpotlightSettingsStore initialized - indexing enabled: \(self.isIndexingEnabled, privacy: .public)"
    )
  }

  // MARK: - Public Methods

  /// Updates the indexed video count.
  /// Called by SpotlightIndexer after indexing operations.
  /// - Parameter count: The new count of indexed videos
  func updateIndexedCount(_ count: Int) {
    indexedVideoCount = count
  }

  /// Resets the settings to defaults.
  /// Useful for testing or when resetting app state.
  func reset() {
    userDefaults.removeObject(forKey: key)
    isIndexingEnabled = true
    indexedVideoCount = 0
    LoggingService.shared.integration.info("SpotlightSettingsStore reset to defaults")
  }

  #if DEBUG
    /// Resets the store for testing purposes.
    /// This method ensures tests start with a clean state.
    func resetForTesting() {
      userDefaults.removeObject(forKey: key)
      isIndexingEnabled = true
      indexedVideoCount = 0
    }
  #endif
}

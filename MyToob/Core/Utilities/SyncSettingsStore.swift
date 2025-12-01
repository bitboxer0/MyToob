//
//  SyncSettingsStore.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import Combine
import Foundation
import OSLog

/// Manages user preferences for CloudKit sync functionality.
///
/// This store provides a user-facing toggle for CloudKit sync, separate from
/// the deployment/entitlement gate in `Configuration.cloudKitSyncEnabled`.
///
/// **Two-level gating:**
/// - **Deployment gate** (`Configuration.cloudKitSyncEnabled`): Hard gate based on
///   environment/entitlements. If false, CloudKit is globally unavailable.
/// - **User preference** (`isUserEnabled`): User's choice to enable/disable sync.
///
/// Effective enablement requires both gates to be true:
/// `effectiveCloudKitEnabled = isUserEnabled && Configuration.cloudKitSyncEnabled`
///
/// Usage:
/// ```swift
/// let store = SyncSettingsStore.shared
///
/// // Check effective state
/// if store.effectiveCloudKitEnabled {
///     // CloudKit sync is fully enabled
/// }
///
/// // Toggle user preference
/// store.setUserEnabled(true)
/// ```
@MainActor
final class SyncSettingsStore: ObservableObject {

  // MARK: - Singleton

  /// Shared instance for app-wide access
  static let shared = SyncSettingsStore()

  // MARK: - Constants

  /// UserDefaults key for the sync preference
  private let defaultsKey = "cloudkit.sync.userEnabled"

  // MARK: - Published Properties

  /// User's preference for CloudKit sync.
  /// - Note: This is independent of the deployment gate in `Configuration.cloudKitSyncEnabled`.
  @Published private(set) var isUserEnabled: Bool

  // MARK: - Computed Properties

  /// Whether CloudKit sync is effectively enabled.
  ///
  /// Returns `true` only if:
  /// 1. The deployment/entitlement gate (`Configuration.cloudKitSyncEnabled`) is true
  /// 2. The user has enabled sync (`isUserEnabled` is true)
  ///
  /// Use this property to determine if CloudKit operations should proceed.
  var effectiveCloudKitEnabled: Bool {
    isUserEnabled && Configuration.cloudKitSyncEnabled
  }

  /// Whether the entitlement gate allows CloudKit sync.
  ///
  /// If this is false, the user cannot enable sync regardless of their preference.
  /// UI should disable the toggle and explain why.
  var isEntitlementAvailable: Bool {
    Configuration.cloudKitSyncEnabled
  }

  // MARK: - Initialization

  private init() {
    // Load persisted preference, defaulting to false
    self.isUserEnabled = UserDefaults.standard.bool(forKey: defaultsKey)

    LoggingService.shared.sync.debug(
      "SyncSettingsStore initialized - userEnabled: \(self.isUserEnabled, privacy: .public), entitlementAvailable: \(Configuration.cloudKitSyncEnabled, privacy: .public)"
    )
  }

  // MARK: - Public Methods

  /// Sets the user's CloudKit sync preference.
  ///
  /// This updates the persisted preference and publishes the change.
  /// The actual CloudKit enablement depends on both this setting and
  /// the deployment gate.
  ///
  /// - Parameter enabled: Whether the user wants CloudKit sync enabled
  func setUserEnabled(_ enabled: Bool) {
    guard isUserEnabled != enabled else { return }

    isUserEnabled = enabled
    UserDefaults.standard.set(enabled, forKey: defaultsKey)

    LoggingService.shared.sync.notice(
      "User set CloudKit sync preference to \(enabled, privacy: .public) (effective: \(self.effectiveCloudKitEnabled, privacy: .public))"
    )
  }

  /// Resets the user preference to the default (disabled).
  ///
  /// Use this for testing or when resetting app state.
  func reset() {
    setUserEnabled(false)
    LoggingService.shared.sync.info("SyncSettingsStore reset to defaults")
  }
}

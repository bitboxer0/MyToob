//
//  SyncStatusViewModel.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import CloudKit
import Combine
import Foundation
import OSLog

/// ViewModel managing CloudKit sync status, user preferences, and sync actions.
///
/// This ViewModel centralizes:
/// - Sync state machine (disabled, syncing, synced, failed)
/// - Sync details (account status, container ID, timestamps)
/// - User preference toggle binding
/// - Manual sync trigger
///
/// Usage:
/// ```swift
/// @StateObject var syncVM = SyncStatusViewModel()
///
/// // Check status
/// Text("Status: \(syncVM.state.displayName)")
///
/// // Toggle sync
/// Toggle("Enable Sync", isOn: $syncVM.toggleOn)
///
/// // Manual sync
/// Button("Sync Now") {
///     Task { await syncVM.syncNow() }
/// }
/// ```
@MainActor
final class SyncStatusViewModel: ObservableObject {

  // MARK: - Types

  /// Represents the current sync operation state.
  enum SyncState: Equatable {
    /// Sync is disabled (either entitlement unavailable or user disabled)
    case disabled

    /// A sync operation is in progress
    case syncing

    /// Last sync operation succeeded
    case synced

    /// Last sync operation failed with the given error message
    case failed(String)

    /// Human-readable display name for the state
    var displayName: String {
      switch self {
      case .disabled:
        return "Disabled"
      case .syncing:
        return "Syncing..."
      case .synced:
        return "Synced"
      case .failed(let message):
        return "Failed: \(message)"
      }
    }

    /// SF Symbol name representing this state
    var symbolName: String {
      switch self {
      case .disabled:
        return "icloud.slash"
      case .syncing:
        return "arrow.triangle.2.circlepath.icloud"
      case .synced:
        return "checkmark.icloud"
      case .failed:
        return "xmark.icloud"
      }
    }

    /// Color to use for the state indicator
    var symbolColor: String {
      switch self {
      case .disabled:
        return "secondary"
      case .syncing:
        return "accentColor"
      case .synced:
        return "green"
      case .failed:
        return "red"
      }
    }
  }

  /// Detailed information about the sync configuration and status.
  struct SyncDetails: Equatable {
    /// Human-readable description of the iCloud account status
    var accountStatusDescription: String

    /// The CloudKit container identifier
    var containerIdentifier: String

    /// Timestamp of the last successful sync operation
    var lastSyncedAt: Date?

    /// Whether the entitlement/deployment gate allows CloudKit
    var isEntitlementAvailable: Bool

    /// Whether the user has enabled sync
    var isUserEnabled: Bool

    /// Whether sync is effectively enabled (entitlement AND user preference)
    var isEffectiveEnabled: Bool

    /// Default details for initial state
    static var `default`: SyncDetails {
      SyncDetails(
        accountStatusDescription: "Unknown",
        containerIdentifier: Configuration.cloudKitContainerIdentifier,
        lastSyncedAt: nil,
        isEntitlementAvailable: Configuration.cloudKitSyncEnabled,
        isUserEnabled: false,
        isEffectiveEnabled: false
      )
    }
  }

  // MARK: - Published Properties

  /// Current sync state
  @Published private(set) var state: SyncState = .disabled

  /// Detailed sync information
  @Published private(set) var details: SyncDetails = .default

  /// Binding for the sync toggle in UI.
  /// Use `setSyncEnabled(_:)` to update from UI; do not set directly to avoid recursion.
  @Published var toggleOn: Bool = false

  // MARK: - Dependencies

  private let service: CloudKitSyncing
  private let settings: SyncSettingsStore
  private var cancellables = Set<AnyCancellable>()

  /// Guard flag to prevent recursion when updating toggle programmatically
  private var isUpdatingFromSettings = false

  /// Task handle for refresh operations to allow cancellation
  private var refreshTask: Task<Void, Never>?

  // MARK: - Initialization

  /// Creates a SyncStatusViewModel with the specified dependencies.
  ///
  /// - Parameters:
  ///   - service: The CloudKit service for sync operations (default: CloudKitService.shared)
  ///   - settings: The settings store for user preferences (must be injected explicitly)
  ///
  /// - Note: `settings` parameter has no default to enforce explicit injection from `MyToobApp`,
  ///   ensuring proper initialization ordering of the singleton.
  init(
    service: CloudKitSyncing = CloudKitService.shared,
    settings: SyncSettingsStore
  ) {
    self.service = service
    self.settings = settings

    // Initialize toggle state from settings
    self.toggleOn = settings.isUserEnabled

    // Initialize details
    self.details = SyncDetails(
      accountStatusDescription: service.statusDescription(service.accountStatus),
      containerIdentifier: Configuration.cloudKitContainerIdentifier,
      lastSyncedAt: nil,
      isEntitlementAvailable: Configuration.cloudKitSyncEnabled,
      isUserEnabled: settings.isUserEnabled,
      isEffectiveEnabled: settings.effectiveCloudKitEnabled
    )

    // Set initial state based on effective enablement
    if !settings.effectiveCloudKitEnabled {
      self.state = .disabled
    }

    // Observe settings changes
    settings.$isUserEnabled
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newValue in
        self?.handleSettingsChange(isUserEnabled: newValue)
      }
      .store(in: &cancellables)

    LoggingService.shared.sync.debug(
      "SyncStatusViewModel initialized - state: \(self.state.displayName, privacy: .public)"
    )
  }

  // MARK: - Public Methods

  /// Refreshes the sync status by checking account status and container access.
  ///
  /// This method:
  /// 1. Checks if sync is effectively enabled
  /// 2. Queries iCloud account status
  /// 3. Verifies container access
  /// 4. Updates state and details accordingly
  func refreshStatus() async {
    LoggingService.shared.sync.debug("Refreshing sync status")

    // Update details from current settings
    updateDetailsFromSettings()

    // If not effectively enabled, stay disabled
    guard settings.effectiveCloudKitEnabled else {
      state = .disabled
      LoggingService.shared.sync.debug("Sync disabled - skipping status refresh")
      return
    }

    // Set syncing state while checking
    state = .syncing

    // Check account status
    let accountStatus = await service.checkAccountStatus()
    details.accountStatusDescription = service.statusDescription(accountStatus)

    // Verify container access
    let accessVerified = await service.verifyContainerAccess()

    if accessVerified {
      state = .synced
      details.lastSyncedAt = Date()
      LoggingService.shared.sync.info("Sync status refresh completed - synced")
    } else {
      if accountStatus != .available {
        state = .failed("iCloud account not available")
      } else {
        state = .failed("Container access failed")
      }
      LoggingService.shared.sync.notice(
        "Sync status refresh completed - failed: \(self.state.displayName, privacy: .public)"
      )
    }
  }

  /// Sets the user's sync preference.
  ///
  /// This method updates the settings store, which will trigger a container rebuild
  /// in the app. The state will be updated accordingly.
  ///
  /// Call this from UI bindings instead of setting `toggleOn` directly.
  ///
  /// - Parameter enabled: Whether the user wants sync enabled
  func setSyncEnabled(_ enabled: Bool) {
    // Guard against recursion from programmatic updates
    guard !isUpdatingFromSettings else { return }

    LoggingService.shared.sync.debug("Setting sync enabled: \(enabled, privacy: .public)")

    settings.setUserEnabled(enabled)
    // Note: handleSettingsChange will be called via the publisher
  }

  /// Updates the toggle to reflect settings changes without triggering setSyncEnabled.
  ///
  /// - Parameter value: The new toggle value from settings
  private func updateToggle(fromSettings value: Bool) {
    guard toggleOn != value else { return }
    isUpdatingFromSettings = true
    toggleOn = value
    isUpdatingFromSettings = false
  }

  /// Triggers a manual sync operation.
  ///
  /// This method:
  /// 1. Checks if sync is enabled
  /// 2. Sets state to syncing
  /// 3. Calls the service's syncNow()
  /// 4. Updates state based on result
  func syncNow() async {
    guard settings.effectiveCloudKitEnabled else {
      LoggingService.shared.sync.debug("Sync disabled - syncNow skipped")
      return
    }

    LoggingService.shared.sync.info("Manual sync triggered via ViewModel")
    state = .syncing

    let success = await service.syncNow()

    if success {
      state = .synced
      details.lastSyncedAt = Date()
      LoggingService.shared.sync.info("Manual sync completed successfully")
    } else {
      state = .failed("Sync operation failed")
      LoggingService.shared.sync.notice("Manual sync failed")
    }
  }

  // MARK: - Private Methods

  /// Schedules a refresh operation, canceling any in-progress refresh.
  ///
  /// This prevents races from rapid toggling or multiple refresh triggers.
  private func scheduleRefresh() {
    refreshTask?.cancel()
    refreshTask = Task { [weak self] in
      guard let self else { return }
      await self.refreshStatus()
    }
  }

  /// Handles changes to the user's sync preference.
  private func handleSettingsChange(isUserEnabled: Bool) {
    LoggingService.shared.sync.debug(
      "Settings changed - isUserEnabled: \(isUserEnabled, privacy: .public)"
    )

    // Update toggle without triggering setSyncEnabled
    updateToggle(fromSettings: isUserEnabled)

    // Update details
    updateDetailsFromSettings()

    // Update state based on new effective enablement
    if !settings.effectiveCloudKitEnabled {
      state = .disabled
    } else if state == .disabled {
      // Transition from disabled to checking - use scheduled refresh
      scheduleRefresh()
    }
  }

  /// Updates details from current settings.
  private func updateDetailsFromSettings() {
    details.isUserEnabled = settings.isUserEnabled
    details.isEffectiveEnabled = settings.effectiveCloudKitEnabled
    details.isEntitlementAvailable = settings.isEntitlementAvailable
  }
}

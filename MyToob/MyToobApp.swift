//
//  MyToobApp.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import CoreSpotlight
import OSLog
import SwiftData
import SwiftUI

@main
struct MyToobApp: App {
  /// User sync settings (observed for container rebuilding)
  @StateObject private var syncSettings = SyncSettingsStore.shared

  /// Shared sync status ViewModel for UI binding - explicitly injected with settings
  @StateObject private var syncViewModel: SyncStatusViewModel

  /// Dynamic model container that responds to sync settings changes
  @State private var sharedModelContainer: ModelContainer

  /// Video identifier from Spotlight deep link (if any)
  @State private var spotlightVideoIdentifier: String?

  init() {
    // Initialize syncViewModel with explicit settings injection to ensure proper init ordering
    _syncViewModel = StateObject(
      wrappedValue: SyncStatusViewModel(settings: SyncSettingsStore.shared)
    )
    // Log app launch with version info
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    LoggingService.shared.app.info(
      "MyToob launched - Version: \(appVersion, privacy: .public) (\(buildNumber, privacy: .public))")

    // Initialize container based on current effective enablement
    let initialContainer = Self.buildModelContainer(
      cloudKitEnabled: SyncSettingsStore.shared.effectiveCloudKitEnabled
    )
    _sharedModelContainer = State(initialValue: initialContainer)
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(syncViewModel)
        .frame(minWidth: 1024, minHeight: 768)
        .onAppear {
          LoggingService.shared.app.debug("Main window created")
          // Refresh sync status on app appear
          Task {
            await syncViewModel.refreshStatus()
          }
          // Handle launch arguments for testing
          handleLaunchArguments()
        }
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
          handleSpotlightActivity(userActivity)
        }
    }
    .modelContainer(sharedModelContainer)
    .defaultSize(width: 1280, height: 800)
    .onChange(of: syncSettings.isUserEnabled) { _, _ in
      // Observe the @Published property (not computed) for reliable change detection
      let effectiveEnabled = syncSettings.effectiveCloudKitEnabled
      rebuildModelContainer(cloudKitEnabled: effectiveEnabled)
      // Trigger a status refresh when user changes preference
      Task {
        await syncViewModel.refreshStatus()
      }
    }

    // Settings window (Cmd-,) with tabbed interface
    Settings {
      TabView {
        // iCloud Sync tab
        SyncSettingsView()
          .environmentObject(syncViewModel)
          .tabItem {
            Label("iCloud Sync", systemImage: "icloud")
          }
          .tag("sync")
          .accessibilityIdentifier("SettingsSyncTab")

        // Spotlight Integration tab
        SpotlightSettingsView()
          .tabItem {
            Label("Spotlight", systemImage: "magnifyingglass")
          }
          .tag("spotlight")
          .accessibilityIdentifier("SettingsSpotlightTab")

        // About tab (Content Policy, etc.)
        AboutView()
          .tabItem {
            Label("About", systemImage: "info.circle")
          }
          .tag("about")
          .accessibilityIdentifier("SettingsAboutTab")
      }
      .frame(width: 500, height: 400)
      .accessibilityIdentifier("SettingsWindow")
    }
    .modelContainer(sharedModelContainer)
  }

  // MARK: - Model Container Management

  /// Builds a ModelContainer with the specified CloudKit configuration.
  ///
  /// - Parameter cloudKitEnabled: Whether to enable CloudKit sync
  /// - Returns: A configured ModelContainer
  @MainActor
  private static func buildModelContainer(cloudKitEnabled: Bool) -> ModelContainer {
    // Use the latest versioned schema for data persistence.
    // Currently SchemaV2 - uses VideoItem with lastAccessedAt property.
    // Migration plan is available but disabled until we have users who need migration.
    let schema = latestSchema

    // Configure CloudKit sync if enabled
    let modelConfiguration: ModelConfiguration
    if cloudKitEnabled {
      // CloudKit-enabled configuration with private database
      modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .private(Configuration.cloudKitContainerIdentifier)
      )
      LoggingService.shared.cloudKit.info(
        "Building ModelContainer with CloudKit: \(Configuration.cloudKitContainerIdentifier, privacy: .public)"
      )
    } else {
      // Local-only configuration (no CloudKit sync)
      modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
      )
      LoggingService.shared.cloudKit.info("Building ModelContainer with local-only storage")
    }

    do {
      // Note: Migration plan is disabled until we have actual users who need migration.
      // The versioned schema infrastructure is in place for future use.
      // When ready to enable migrations, uncomment migrationPlan parameter below.
      let container = try ModelContainer(
        for: schema,
        // migrationPlan: MyToobMigrationPlan.self,
        configurations: [modelConfiguration]
      )
      LoggingService.shared.persistence.info(
        "ModelContainer initialized (schema v\(CurrentSchemaVersion.versionIdentifier.description, privacy: .public))"
      )
      return container
    } catch {
      LoggingService.shared.persistence.fault(
        "Failed to create ModelContainer: \(error.localizedDescription, privacy: .public)")
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  /// Rebuilds the ModelContainer when sync settings change.
  ///
  /// - Parameter cloudKitEnabled: Whether CloudKit sync should be enabled
  @MainActor
  private func rebuildModelContainer(cloudKitEnabled: Bool) {
    LoggingService.shared.persistence.notice(
      "Rebuilding ModelContainer - CloudKit enabled: \(cloudKitEnabled, privacy: .public)"
    )

    sharedModelContainer = Self.buildModelContainer(cloudKitEnabled: cloudKitEnabled)

    LoggingService.shared.persistence.info("ModelContainer rebuilt successfully")
  }

  // MARK: - Spotlight Deep Link Handling

  /// Handles Spotlight search result click activity
  ///
  /// When a user clicks on a Spotlight result for a MyToob video,
  /// this method extracts the video identifier and navigates to it.
  ///
  /// - Parameter userActivity: The NSUserActivity from Spotlight
  private func handleSpotlightActivity(_ userActivity: NSUserActivity) {
    guard
      let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
    else {
      LoggingService.shared.integration.error(
        "Spotlight activity missing video identifier"
      )
      return
    }

    LoggingService.shared.integration.info(
      "Received Spotlight deep link for: \(identifier, privacy: .public)"
    )

    // Extract the actual video ID from the prefixed identifier
    let videoID: String
    if identifier.hasPrefix("video-") {
      videoID = String(identifier.dropFirst("video-".count))
    } else if identifier.hasPrefix("local-") {
      videoID = String(identifier.dropFirst("local-".count))
    } else {
      videoID = identifier
    }

    // Store the identifier for navigation
    spotlightVideoIdentifier = videoID

    // TODO: Navigate to video detail view when implemented
    // For now, log and store the identifier for future use
    LoggingService.shared.integration.debug(
      "Spotlight navigation target: \(videoID, privacy: .private)"
    )
  }

  /// Handles launch arguments for UI testing
  ///
  /// Looks for `--spotlight-video-id` argument to simulate Spotlight deep links.
  private func handleLaunchArguments() {
    let arguments = ProcessInfo.processInfo.arguments

    // Check for Spotlight test argument
    if let spotlightIndex = arguments.firstIndex(of: "--spotlight-video-id"),
      spotlightIndex + 1 < arguments.count
    {
      let videoID = arguments[spotlightIndex + 1]
      LoggingService.shared.integration.debug(
        "Test launch with Spotlight video ID: \(videoID, privacy: .private)"
      )
      spotlightVideoIdentifier = videoID
    }
  }

  // MARK: - DEBUG Test Support

  #if DEBUG
    /// Container mode for testing - indicates whether CloudKit was requested
    enum ContainerMode {
      case localOnly
      case cloudKit
    }

    /// DEBUG-only API to build a container and return its mode for testing.
    ///
    /// This allows tests to verify the container factory logic without needing
    /// to introspect the ModelContainer's CloudKit configuration.
    ///
    /// - Parameter cloudKitEnabled: Whether to request CloudKit sync
    /// - Returns: Tuple of container and the mode that was selected
    @MainActor
    static func buildModelContainerWithMode(
      cloudKitEnabled: Bool
    ) -> (container: ModelContainer, mode: ContainerMode) {
      let container = buildModelContainer(cloudKitEnabled: cloudKitEnabled)
      let mode: ContainerMode = cloudKitEnabled ? .cloudKit : .localOnly
      return (container, mode)
    }
  #endif
}

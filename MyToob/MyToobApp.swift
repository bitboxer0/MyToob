//
//  MyToobApp.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

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
  }

  // MARK: - Model Container Management

  /// Builds a ModelContainer with the specified CloudKit configuration.
  ///
  /// - Parameter cloudKitEnabled: Whether to enable CloudKit sync
  /// - Returns: A configured ModelContainer
  @MainActor
  private static func buildModelContainer(cloudKitEnabled: Bool) -> ModelContainer {
    // Use versioned schema with migration plan for safe schema upgrades
    let schema = Schema(versionedSchema: SchemaV2.self)

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
      let container = try ModelContainer(
        for: schema,
        migrationPlan: MyToobMigrationPlan.self,
        configurations: [modelConfiguration]
      )
      LoggingService.shared.persistence.info(
        "ModelContainer initialized with migration plan (schema v\(SchemaV2.versionIdentifier.description, privacy: .public))"
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

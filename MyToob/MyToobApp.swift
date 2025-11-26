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
  init() {
    // Log app launch with version info
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    LoggingService.shared.app.info(
      "MyToob launched - Version: \(appVersion, privacy: .public) (\(buildNumber, privacy: .public))")
  }

  var sharedModelContainer: ModelContainer = {
    // Use versioned schema with migration plan for safe schema upgrades
    let schema = Schema(versionedSchema: SchemaV2.self)
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 1024, minHeight: 768)
        .onAppear {
          LoggingService.shared.app.debug("Main window created")
        }
    }
    .modelContainer(sharedModelContainer)
    .defaultSize(width: 1280, height: 800)
  }
}

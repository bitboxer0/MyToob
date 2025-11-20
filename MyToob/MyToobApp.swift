//
//  MyToobApp.swift
//  MyToob
//
//  Created by Daniel Finley on 11/17/25.
//  Updated by Claude Code (BMad Master) - Story 1.4: SwiftData Core Models
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
    LoggingService.shared.app.info("MyToob launched - Version: \(appVersion, privacy: .public) (\(buildNumber, privacy: .public))")
  }
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      VideoItem.self,
      ClusterLabel.self,
      Note.self,
      ChannelBlacklist.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      LoggingService.shared.app.info("ModelContainer initialized successfully")
      return container
    } catch {
      LoggingService.shared.app.fault("Failed to create ModelContainer: \(error.localizedDescription, privacy: .public)")
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

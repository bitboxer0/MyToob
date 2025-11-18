//
//  MyToobApp.swift
//  MyToob
//
//  Created by Daniel Finley on 11/17/25.
//  Updated by Claude Code (BMad Master) - Story 1.4: SwiftData Core Models
//

import SwiftUI
import SwiftData

@main
struct MyToobApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VideoItem.self,
            ClusterLabel.self,
            Note.self,
            ChannelBlacklist.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

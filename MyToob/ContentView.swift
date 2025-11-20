//
//  ContentView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import SwiftData
import SwiftUI

/// Placeholder content view
/// Will be replaced with full YouTube + local file UI in later stories (Epic F)
struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var videoItems: [VideoItem]

  @State private var isImporting = false
  @State private var importError: Error?
  @State private var showImportError = false

  var body: some View {
    NavigationSplitView {
      List {
        Section("Collections") {
          Label("All Videos", systemImage: "play.rectangle.on.rectangle")
          Label("Recently Watched", systemImage: "clock")
          Label("Favorites", systemImage: "star")
        }

        Section("YouTube") {
          Label("Subscriptions", systemImage: "person.2")
          Label("Playlists", systemImage: "list.bullet")
        }

        Section("Local Files") {
          Label("All Videos", systemImage: "folder")

          Button(action: importLocalFiles) {
            Label("Import Local Files", systemImage: "plus.circle")
          }
          .disabled(isImporting)
          .accessibilityLabel("Import Local Files")
          .accessibilityHint("Opens file picker to select video files to import")
        }

        if !videoItems.isEmpty {
          Section("Library (\(videoItems.count) items)") {
            ForEach(videoItems, id: \.identifier) { item in
              HStack {
                Image(systemName: item.isLocal ? "film" : "play.rectangle")
                VStack(alignment: .leading) {
                  Text(item.title)
                    .font(.headline)
                  if let channelID = item.channelID {
                    Text("Channel: \(channelID)")
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }
              }
            }
          }
        }
      }
      .navigationSplitViewColumnWidth(min: 180, ideal: 200)
      .navigationTitle("MyToob")
    } detail: {
      VStack {
        Image(systemName: "play.rectangle.on.rectangle.fill")
          .font(.system(size: 72))
          .foregroundStyle(.secondary)
        Text("Select an item from the sidebar")
          .font(.title2)
          .foregroundStyle(.secondary)
        Text("Full UI coming in Epic F")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
    .alert("Import Error", isPresented: $showImportError, presenting: importError) { _ in
      Button("OK") {}
    } message: { error in
      Text(error.localizedDescription)
    }
  }

  // MARK: - Actions

  private func importLocalFiles() {
    Task {
      isImporting = true
      defer { isImporting = false }

      do {
        let importService = LocalFileImportService(modelContext: modelContext)
        let count = try await importService.importFiles()
        print("Successfully imported \(count) file(s)")
      } catch {
        importError = error
        showImportError = true
        print("Import failed: \(error.localizedDescription)")
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: VideoItem.self, inMemory: true)
}

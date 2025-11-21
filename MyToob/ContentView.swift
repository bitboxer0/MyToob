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

  @StateObject private var oauth = OAuth2Handler.shared

  @State private var isImporting = false
  @State private var importError: Error?
  @State private var showImportError = false
  @State private var showOAuthConsent = false
  @State private var showSubscriptionsImport = false

  var body: some View {
    NavigationSplitView {
      List {
        Section {
          Label("All Videos", systemImage: "play.rectangle.on.rectangle")
          Label("Recently Watched", systemImage: "clock")
          Label("Favorites", systemImage: "star")
        } header: {
          Text("Collections")
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("CollectionsSection")
        }

        Section {
          if oauth.isAuthenticated {
            Label("Subscriptions", systemImage: "person.2")
            Label("Playlists", systemImage: "list.bullet")

            Button {
              showSubscriptionsImport = true
            } label: {
              Label("Import Subscriptions", systemImage: "arrow.down.circle")
            }
            .accessibilityLabel("Import Subscriptions")
            .accessibilityHint("Opens dialog to import YouTube subscriptions")

            Button {
              Task {
                try? oauth.signOut()
              }
            } label: {
              Label("Sign Out", systemImage: "person.crop.circle.badge.xmark")
            }
            .foregroundStyle(.red)
          } else {
            Button {
              showOAuthConsent = true
            } label: {
              Label("Connect YouTube Account", systemImage: "person.crop.circle.badge.plus")
            }
            .accessibilityLabel("Connect YouTube Account")
            .accessibilityHint("Opens consent screen to authorize YouTube access")
          }
        } header: {
          Text("YouTube")
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("YouTubeSection")
        }

        Section {
          Label("All Local Videos", systemImage: "folder")
            .accessibilityIdentifier("AllLocalVideos")

          Button(action: importLocalFiles) {
            Label("Import Local Files", systemImage: "plus.circle")
          }
          .disabled(isImporting)
          .accessibilityLabel("Import Local Files")
          .accessibilityIdentifier("ImportLocalFilesButton")
          .accessibilityHint("Opens file picker to select video files to import")
        } header: {
          Text("Local Files")
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("LocalFilesSection")
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
    .sheet(isPresented: $showOAuthConsent) {
      OAuthConsentView()
    }
    .sheet(isPresented: $showSubscriptionsImport) {
      SubscriptionsImportView(modelContext: modelContext)
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

//
//  SpotlightSettingsView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/5/25.
//

import OSLog
import SwiftData
import SwiftUI

/// Settings view for Spotlight indexing configuration.
///
/// Provides:
/// - Toggle to enable/disable Spotlight indexing
/// - Status display showing indexed video count
/// - Reindex All button for manual reindexing
/// - Clear Index button to remove all items
///
/// Usage (in Settings scene):
/// ```swift
/// Settings {
///     SpotlightSettingsView()
/// }
/// ```
struct SpotlightSettingsView: View {
  @StateObject private var settings = SpotlightSettingsStore.shared
  @State private var isReindexing = false
  @State private var showClearConfirmation = false

  /// Model context for fetching videos to reindex
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    Form {
      // MARK: - Indexing Toggle Section
      Section {
        Toggle(
          "Index in Spotlight",
          isOn: $settings.isIndexingEnabled
        )
        .accessibilityIdentifier("SpotlightIndexingToggle")
        .accessibilityHint(
          settings.isIndexingEnabled
            ? "Disables Spotlight indexing. Videos will not appear in system search."
            : "Enables Spotlight indexing. Videos will appear in system search."
        )
        .onChange(of: settings.isIndexingEnabled) { _, newValue in
          handleToggleChange(enabled: newValue)
        }
      } header: {
        Text("Spotlight Search")
      } footer: {
        Text(
          "When enabled, your videos are indexed in Spotlight, allowing you to find them using macOS system search (⌘ Space)."
        )
      }

      // MARK: - Status Section
      Section("Status") {
        LabeledContent("Indexed Videos") {
          HStack(spacing: 6) {
            if isReindexing {
              ProgressView()
                .controlSize(.small)
            } else {
              Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            }
            Text("\(settings.indexedVideoCount)")
              .monospacedDigit()
          }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Indexed Videos: \(settings.indexedVideoCount)")
      }

      // MARK: - Actions Section
      Section {
        Button {
          Task {
            await reindexAllVideos()
          }
        } label: {
          HStack {
            Text("Reindex All Videos")
            Spacer()
            if isReindexing {
              ProgressView()
                .controlSize(.small)
            }
          }
        }
        .accessibilityIdentifier("ReindexAllButton")
        .disabled(!settings.isIndexingEnabled || isReindexing)
        .accessibilityHint("Rebuilds the Spotlight index for all videos")

        Button(role: .destructive) {
          showClearConfirmation = true
        } label: {
          Text("Clear Spotlight Index")
        }
        .accessibilityIdentifier("ClearIndexButton")
        .disabled(isReindexing || settings.indexedVideoCount == 0)
        .accessibilityHint("Removes all videos from Spotlight search")
      } header: {
        Text("Actions")
      } footer: {
        Text(
          "Reindexing updates Spotlight with the latest video information. Clearing removes all videos from Spotlight search."
        )
      }
    }
    .formStyle(.grouped)
    .frame(minWidth: 400, minHeight: 250)
    .navigationTitle("Spotlight")
    .accessibilityIdentifier("SpotlightSettingsView")
    .confirmationDialog(
      "Clear Spotlight Index?",
      isPresented: $showClearConfirmation,
      titleVisibility: .visible
    ) {
      Button("Clear Index", role: .destructive) {
        Task {
          await clearIndex()
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will remove all videos from Spotlight search. You can reindex them later.")
    }
  }

  // MARK: - Actions

  /// Handles toggle state changes
  private func handleToggleChange(enabled: Bool) {
    Task {
      if enabled {
        // Reindex all videos when enabling
        await reindexAllVideos()
      } else {
        // Clear index when disabling
        await clearIndex()
      }
    }
  }

  /// Reindexes all videos in Spotlight
  private func reindexAllVideos() async {
    isReindexing = true
    defer { isReindexing = false }

    do {
      // Fetch all videos from SwiftData
      let descriptor = FetchDescriptor<VideoItem>()
      let videos = try modelContext.fetch(descriptor)

      LoggingService.shared.integration.info(
        "Reindexing \(videos.count, privacy: .public) videos in Spotlight"
      )

      await SpotlightIndexer.shared.reindexAll(videos)
    } catch {
      LoggingService.shared.integration.error(
        "Failed to fetch videos for reindexing: \(error.localizedDescription, privacy: .public)"
      )
    }
  }

  /// Clears all videos from the Spotlight index
  private func clearIndex() async {
    isReindexing = true
    defer { isReindexing = false }

    await SpotlightIndexer.shared.clearAllIndexedItems()
  }
}

// MARK: - Preview

#Preview {
  SpotlightSettingsView()
}

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
  @EnvironmentObject var syncViewModel: SyncStatusViewModel
  @Query private var videoItems: [VideoItem]
  @Query private var hiddenChannels: [ChannelBlacklist]

  @StateObject private var oauth = OAuth2Handler.shared

  @State private var isImporting = false
  @State private var importError: Error?
  @State private var showImportError = false
  @State private var showOAuthConsent = false
  @State private var showSubscriptionsImport = false

  // Hide channel state
  @State private var showHideChannelDialog = false
  @State private var channelToHide: (id: String, name: String?)? = nil
  @State private var hideChannelReason = ""
  @State private var hideChannelError: Error?
  @State private var showHideChannelError = false

  // MARK: - Computed Properties

  /// Filtered video items excluding hidden channels
  private var visibleVideoItems: [VideoItem] {
    let hiddenChannelIDs = Set(hiddenChannels.map(\.channelID))
    return videoItems.filter { item in
      // Always show local files
      guard let channelID = item.channelID else { return true }
      // Filter out hidden channels
      return !hiddenChannelIDs.contains(channelID)
    }
  }

  /// Display name for the channel being hidden
  private var channelDisplayName: String {
    if let name = channelToHide?.name, !name.isEmpty {
      return name
    }
    if let id = channelToHide?.id {
      return "Channel \(String(id.prefix(8)))"
    }
    return "this channel"
  }

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

            NavigationLink {
              HiddenChannelsView()
            } label: {
              Label("Manage Hidden Channels", systemImage: "eye.slash.fill")
            }
            .accessibilityIdentifier("ManageHiddenChannels")
            .accessibilityLabel("Manage Hidden Channels")
            .accessibilityHint("View and unhide blocked YouTube channels")

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

        if !visibleVideoItems.isEmpty {
          Section("Library (\(visibleVideoItems.count) items)") {
            ForEach(visibleVideoItems, id: \.identifier) { item in
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
              .contextMenu {
                // Hide Channel action (YouTube videos only)
                if !item.isLocal, let channelID = item.channelID {
                  Button {
                    initiateHideChannel(channelID: channelID, channelName: nil)
                  } label: {
                    Label("Hide Channel", systemImage: "eye.slash")
                  }
                  .accessibilityIdentifier("HideChannelAction")
                }

                // Report Content action (YouTube videos only)
                if !item.isLocal, let videoID = item.videoID {
                  Button {
                    reportContent(videoID: videoID)
                  } label: {
                    Label("Report Content", systemImage: "exclamationmark.triangle")
                  }
                  .accessibilityIdentifier("ReportContentAction")
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
    .toolbar {
      ToolbarItem(placement: .automatic) {
        SyncStatusIndicatorView()
          .environmentObject(syncViewModel)
      }
    }
    .alert("Import Error", isPresented: $showImportError, presenting: importError) { _ in
      Button("OK") {}
    } message: { error in
      Text(error.localizedDescription)
    }
    .alert("Hide Channel?", isPresented: $showHideChannelDialog) {
      TextField("Reason (optional)", text: $hideChannelReason)
        .accessibilityIdentifier("HideChannelReasonField")
      Button("Hide", role: .destructive) {
        performHideChannel()
      }
      Button("Cancel", role: .cancel) {
        resetHideChannelState()
      }
    } message: {
      Text("Videos from \(channelDisplayName) will no longer appear in your library.")
    }
    .alert("Error", isPresented: $showHideChannelError, presenting: hideChannelError) { _ in
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

  /// Initiate the hide channel flow with confirmation
  private func initiateHideChannel(channelID: String, channelName: String?) {
    channelToHide = (id: channelID, name: channelName)
    hideChannelReason = ""
    showHideChannelDialog = true
  }

  /// Perform the actual channel hide operation
  private func performHideChannel() {
    guard let channel = channelToHide else { return }

    Task {
      do {
        let service = ChannelBlacklistService(modelContext: modelContext)
        try await service.hideChannel(
          channelID: channel.id,
          channelName: channel.name,
          reason: hideChannelReason.isEmpty ? nil : hideChannelReason,
          requiresConfirmation: false
        )
        resetHideChannelState()
      } catch {
        hideChannelError = error
        showHideChannelError = true
      }
    }
  }

  /// Reset hide channel state
  private func resetHideChannelState() {
    channelToHide = nil
    hideChannelReason = ""
  }

  /// Report content to YouTube
  private func reportContent(videoID: String) {
    // Open YouTube's report URL for the video
    let reportURLString = "https://www.youtube.com/watch?v=\(videoID)&report=1"
    if let url = URL(string: reportURLString) {
      NSWorkspace.shared.open(url)
      ComplianceLogger.shared.logContentReport(videoID: videoID)
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(SyncStatusViewModel())
    .modelContainer(for: [VideoItem.self, ChannelBlacklist.self], inMemory: true)
}

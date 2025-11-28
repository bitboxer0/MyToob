//
//  HiddenChannelsView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/27/25.
//

import SwiftData
import SwiftUI

/// Management view for hidden/blocked YouTube channels
/// Allows users to view and unhide previously hidden channels
struct HiddenChannelsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \ChannelBlacklist.blockedAt, order: .reverse) private var hiddenChannels: [ChannelBlacklist]

  @State private var channelToUnhide: ChannelBlacklist?
  @State private var showUnhideConfirmation = false
  @State private var unhideError: Error?
  @State private var showUnhideError = false

  var body: some View {
    Group {
      if hiddenChannels.isEmpty {
        emptyStateView
      } else {
        channelListView
      }
    }
    .navigationTitle("Hidden Channels")
    .accessibilityIdentifier("HiddenChannelsView")
    .alert("Error", isPresented: $showUnhideError, presenting: unhideError) { _ in
      Button("OK") {}
    } message: { error in
      Text(error.localizedDescription)
    }
    .alert("Unhide Channel?", isPresented: $showUnhideConfirmation, presenting: channelToUnhide) { channel in
      Button("Unhide", role: .destructive) {
        performUnhide(channel)
      }
      Button("Cancel", role: .cancel) {}
    } message: { channel in
      Text("Videos from \(channel.displayName) will appear in your library again.")
    }
  }

  // MARK: - Subviews

  private var emptyStateView: some View {
    ContentUnavailableView(
      "No Hidden Channels",
      systemImage: "eye.slash",
      description: Text("Channels you hide will appear here")
    )
    .accessibilityIdentifier("EmptyStateHiddenChannels")
  }

  private var channelListView: some View {
    List {
      ForEach(hiddenChannels, id: \.channelID) { entry in
        ChannelBlacklistRowView(entry: entry)
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              channelToUnhide = entry
              showUnhideConfirmation = true
            } label: {
              Label("Unhide", systemImage: "eye")
            }
            .tint(.green)
            .accessibilityIdentifier("UnhideChannelButton_\(entry.channelID)")
          }
          .contextMenu {
            Button {
              channelToUnhide = entry
              showUnhideConfirmation = true
            } label: {
              Label("Unhide Channel", systemImage: "eye")
            }
            .accessibilityIdentifier("UnhideChannelContextMenu_\(entry.channelID)")
          }
      }
    }
    .accessibilityIdentifier("HiddenChannelsList")
  }

  // MARK: - Actions

  private func performUnhide(_ entry: ChannelBlacklist) {
    Task {
      do {
        let service = ChannelBlacklistService(modelContext: modelContext)
        try await service.unhideChannel(channelID: entry.channelID)
      } catch {
        unhideError = error
        showUnhideError = true
      }
    }
  }
}

// MARK: - Row View

/// Row view for displaying a single hidden channel entry
struct ChannelBlacklistRowView: View {
  let entry: ChannelBlacklist

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.displayName)
        .font(.headline)
        .accessibilityLabel("Channel: \(entry.displayName)")

      HStack {
        Image(systemName: "calendar")
          .foregroundStyle(.secondary)
          .font(.caption)
        Text("Hidden \(entry.formattedBlockedDate)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("Hidden on \(entry.formattedBlockedDate)")

      if let reason = entry.reason, !reason.isEmpty {
        HStack(alignment: .top) {
          Image(systemName: "text.quote")
            .foregroundStyle(.secondary)
            .font(.caption)
          Text(reason)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reason: \(reason)")
      }
    }
    .padding(.vertical, 4)
    .accessibilityIdentifier("ChannelBlacklistRow_\(entry.channelID)")
  }
}

// MARK: - Preview

#Preview("Hidden Channels List") {
  NavigationStack {
    HiddenChannelsView()
  }
  .modelContainer(for: ChannelBlacklist.self, inMemory: true)
}

#Preview("Empty State") {
  NavigationStack {
    HiddenChannelsView()
  }
  .modelContainer(for: ChannelBlacklist.self, inMemory: true)
}

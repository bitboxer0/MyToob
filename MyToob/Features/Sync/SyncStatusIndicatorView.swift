//
//  SyncStatusIndicatorView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import SwiftUI

/// Toolbar indicator showing CloudKit sync status with popover details.
///
/// Displays a compact icon button that:
/// - Shows visual sync state (disabled, syncing, synced, failed)
/// - Opens a popover with status details on click
/// - Provides quick access to Settings
///
/// Usage (in toolbar):
/// ```swift
/// .toolbar {
///     ToolbarItem(placement: .automatic) {
///         SyncStatusIndicatorView()
///     }
/// }
/// ```
struct SyncStatusIndicatorView: View {
  @EnvironmentObject var viewModel: SyncStatusViewModel
  @State private var showPopover = false

  var body: some View {
    Button {
      showPopover.toggle()
    } label: {
      statusIcon
    }
    .buttonStyle(.borderless)
    .accessibilityIdentifier("SyncStatusIndicatorButton")
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint("Shows iCloud sync status. Click for details.")
    .popover(isPresented: $showPopover, arrowEdge: .bottom) {
      SyncStatusPopoverView()
        .environmentObject(viewModel)
        .accessibilityIdentifier("SyncStatusPopover")
    }
  }

  // MARK: - Status Icon

  @ViewBuilder
  private var statusIcon: some View {
    switch viewModel.state {
    case .disabled:
      Image(systemName: "icloud.slash")
        .foregroundStyle(.secondary)
        .accessibilityLabel("iCloud sync disabled")

    case .syncing:
      ProgressView()
        .controlSize(.small)
        .accessibilityLabel("Syncing")

    case .synced:
      Image(systemName: "checkmark.icloud")
        .foregroundStyle(.green)
        .accessibilityLabel("iCloud synced")

    case .failed:
      Image(systemName: "xmark.icloud")
        .foregroundStyle(.red)
        .accessibilityLabel("iCloud sync failed")
    }
  }

  // MARK: - Accessibility

  private var accessibilityLabel: String {
    switch viewModel.state {
    case .disabled:
      return "iCloud sync disabled"
    case .syncing:
      return "iCloud syncing"
    case .synced:
      return "iCloud synced"
    case .failed(let message):
      return "iCloud sync failed: \(message)"
    }
  }
}

// MARK: - Popover Content

/// Popover view showing detailed sync status and quick actions.
struct SyncStatusPopoverView: View {
  @EnvironmentObject var viewModel: SyncStatusViewModel
  @Environment(\.openSettings) private var openSettings

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack {
        Image(systemName: "icloud")
          .font(.title2)
        Text("iCloud Sync")
          .font(.headline)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("iCloud Sync Status")

      Divider()

      // Status details
      VStack(alignment: .leading, spacing: 8) {
        statusRow(
          label: "Status",
          value: viewModel.state.displayName,
          valueColor: statusColor
        )

        statusRow(
          label: "Account",
          value: viewModel.details.accountStatusDescription
        )

        statusRow(
          label: "Container",
          value: viewModel.details.containerIdentifier
        )

        if let lastSynced = viewModel.details.lastSyncedAt {
          statusRow(
            label: "Last synced",
            value: lastSynced.formatted(date: .abbreviated, time: .shortened)
          )
        }

        // Entitlement warning if applicable
        if !viewModel.details.isEntitlementAvailable {
          HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
            Text("CloudKit entitlement not configured")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Warning: CloudKit entitlement not configured")
        }
      }

      Divider()

      // Actions
      HStack {
        Button("Open Settings...") {
          openSettingsWindow()
        }
        .accessibilityIdentifier("OpenSyncSettingsButton")
        .accessibilityHint("Opens the app settings to configure sync")

        Spacer()

        if viewModel.details.isEffectiveEnabled {
          Button("Sync Now") {
            Task {
              await viewModel.syncNow()
            }
          }
          .disabled(viewModel.state == .syncing)
          .accessibilityIdentifier("PopoverSyncNowButton")
          .accessibilityHint("Triggers a manual sync operation")
        }
      }
    }
    .padding()
    .frame(minWidth: 280)
  }

  // MARK: - Helper Views

  private func statusRow(label: String, value: String, valueColor: Color = .primary) -> some View {
    HStack {
      Text(label + ":")
        .foregroundStyle(.secondary)
        .frame(width: 80, alignment: .leading)
      Text(value)
        .foregroundStyle(valueColor)
    }
    .font(.callout)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(label): \(value)")
  }

  private var statusColor: Color {
    switch viewModel.state {
    case .disabled:
      return .secondary
    case .syncing:
      return Color.accentColor
    case .synced:
      return .green
    case .failed:
      return .red
    }
  }

  // MARK: - Actions

  private func openSettingsWindow() {
    // On macOS, open the Settings window using NSApp
    #if os(macOS)
    if #available(macOS 14.0, *) {
      openSettings()
    } else {
      // Fallback for older macOS versions
      NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    #endif
  }
}

// MARK: - Preview

#Preview("Synced State") {
  SyncStatusIndicatorView()
    .environmentObject(SyncStatusViewModel())
    .padding()
}

//
//  SyncSettingsView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import SwiftUI

/// Settings view for CloudKit sync configuration.
///
/// Provides:
/// - Toggle to enable/disable iCloud sync
/// - Sync Now button for manual sync
/// - Status display (state, account, container, last sync)
/// - Error messaging for failed states
///
/// Usage (in Settings scene):
/// ```swift
/// Settings {
///     SyncSettingsView()
///         .environmentObject(syncViewModel)
/// }
/// ```
struct SyncSettingsView: View {
  @EnvironmentObject var viewModel: SyncStatusViewModel

  var body: some View {
    Form {
      // MARK: - Sync Toggle Section
      Section {
        Toggle(
          "Enable iCloud Sync",
          isOn: Binding(
            get: { viewModel.toggleOn },
            set: { viewModel.setSyncEnabled($0) }
          )
        )
        .accessibilityIdentifier("CloudKitSyncToggle")
        .disabled(!viewModel.details.isEntitlementAvailable)
        .accessibilityHint(toggleHint)

        if !viewModel.details.isEntitlementAvailable {
          Label {
            Text("CloudKit sync is not available. Entitlement configuration required.")
              .font(.caption)
              .foregroundStyle(.secondary)
          } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Warning: CloudKit sync is not available. Entitlement configuration required.")
        }
      } header: {
        Text("iCloud Sync")
      } footer: {
        Text("When enabled, your library and preferences sync across all your devices signed into the same iCloud account.")
      }

      // MARK: - Sync Actions Section
      Section {
        Button {
          Task {
            await viewModel.syncNow()
          }
        } label: {
          HStack {
            Text("Sync Now")
            Spacer()
            if viewModel.state == .syncing {
              ProgressView()
                .controlSize(.small)
            }
          }
        }
        .accessibilityIdentifier("SyncNowButton")
        .disabled(!viewModel.details.isEffectiveEnabled || viewModel.state == .syncing)
        .accessibilityHint("Manually triggers a sync operation")
      }

      // MARK: - Status Section
      Section("Status") {
        LabeledContent("Sync Status") {
          HStack(spacing: 6) {
            statusIcon
            Text(viewModel.state.displayName)
              .foregroundStyle(statusColor)
          }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sync Status: \(viewModel.state.displayName)")

        LabeledContent("iCloud Account") {
          Text(viewModel.details.accountStatusDescription)
        }

        LabeledContent("Container") {
          Text(viewModel.details.containerIdentifier)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        if let lastSynced = viewModel.details.lastSyncedAt {
          LabeledContent("Last Synced") {
            Text(lastSynced.formatted(date: .abbreviated, time: .shortened))
          }
        }
      }

      // MARK: - Error Section
      if case .failed(let message) = viewModel.state {
        Section {
          Label {
            VStack(alignment: .leading, spacing: 4) {
              Text("Sync Error")
                .font(.headline)
              Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.red)
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Sync Error: \(message)")
        }
      }
    }
    .formStyle(.grouped)
    .frame(minWidth: 400, minHeight: 300)
    .navigationTitle("iCloud Sync")
    .accessibilityIdentifier("SyncSettingsView")
    .task {
      // Refresh status when view appears
      await viewModel.refreshStatus()
    }
  }

  // MARK: - Helper Views

  @ViewBuilder
  private var statusIcon: some View {
    switch viewModel.state {
    case .disabled:
      Image(systemName: "icloud.slash")
        .foregroundStyle(.secondary)
    case .syncing:
      Image(systemName: "arrow.triangle.2.circlepath.icloud")
        .foregroundStyle(Color.accentColor)
    case .synced:
      Image(systemName: "checkmark.icloud")
        .foregroundStyle(.green)
    case .failed:
      Image(systemName: "xmark.icloud")
        .foregroundStyle(.red)
    }
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

  private var toggleHint: String {
    if viewModel.details.isEntitlementAvailable {
      return viewModel.toggleOn
        ? "Disables iCloud sync. Your data will remain local only."
        : "Enables iCloud sync to sync your library across devices."
    } else {
      return "CloudKit sync is not available. Entitlement configuration required."
    }
  }
}

// MARK: - Preview

#Preview {
  SyncSettingsView()
    .environmentObject(SyncStatusViewModel(settings: SyncSettingsStore.shared))
}

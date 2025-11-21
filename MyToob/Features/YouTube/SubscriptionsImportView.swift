//
//  SubscriptionsImportView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

import SwiftUI
import SwiftData

/// UI for importing YouTube subscriptions
///
/// **Features:**
/// - Progress bar with percentage indicator
/// - Start/Pause/Resume/Cancel controls
/// - Real-time progress updates
/// - Error display with retry option
/// - Success confirmation
///
/// **Usage:**
/// ```swift
/// SubscriptionsImportView(modelContext: modelContext)
///   .frame(width: 500, height: 300)
/// ```
struct SubscriptionsImportView: View {
  // MARK: - Properties

  @StateObject private var importService: SubscriptionsImportService
  @Environment(\.dismiss) private var dismiss

  @State private var showError = false
  @State private var errorMessage = ""

  // MARK: - Initialization

  init(modelContext: ModelContext) {
    _importService = StateObject(wrappedValue: SubscriptionsImportService(modelContext: modelContext))
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 20) {
      // Header
      HStack {
        Image(systemName: "person.2.fill")
          .font(.title2)
          .foregroundColor(.blue)

        Text("Import YouTube Subscriptions")
          .font(.title2)
          .fontWeight(.bold)

        Spacer()
      }

      Divider()

      // Progress section
      if case .idle = importService.state {
        idleView
      } else if case .completed = importService.state {
        completedView
      } else if case .failed(let error) = importService.state {
        failedView(error: error)
      } else {
        progressView
      }

      Spacer()

      // Action buttons
      actionButtons
    }
    .padding()
    .frame(minWidth: 500, minHeight: 300)
    .alert("Import Error", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  // MARK: - Subviews

  private var idleView: some View {
    VStack(spacing: 16) {
      Image(systemName: "arrow.down.circle")
        .font(.system(size: 64))
        .foregroundColor(.blue)

      Text("Import your YouTube subscriptions")
        .font(.headline)

      Text("This will fetch all channels you're subscribed to and add them to MyToob for easier organization and discovery.")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 400)

      Text("Note: This requires an active YouTube account connection.")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var progressView: some View {
    VStack(spacing: 16) {
      // Progress indicator
      if let percentage = importService.progress.percentage {
        ProgressView(value: percentage, total: 100.0) {
          Text("Importing subscriptions...")
            .font(.headline)
        } currentValueLabel: {
          Text("\(Int(percentage))%")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .progressViewStyle(.linear)
      } else {
        ProgressView {
          Text("Fetching subscription count...")
            .font(.headline)
        }
        .progressViewStyle(.linear)
      }

      // Status text
      HStack {
        if let total = importService.progress.total {
          Text("\(importService.progress.imported) / \(total) channels")
            .font(.body)
            .foregroundColor(.primary)
        } else {
          Text("\(importService.progress.imported) channels imported")
            .font(.body)
            .foregroundColor(.primary)
        }

        Spacer()

        if case .fetching(let page) = importService.state {
          Text("Page \(page)")
            .font(.caption)
            .foregroundColor(.secondary)
        } else if case .paused = importService.state {
          HStack(spacing: 4) {
            Image(systemName: "pause.circle.fill")
              .foregroundColor(.orange)
            Text("Paused")
              .font(.caption)
              .foregroundColor(.orange)
          }
        }
      }
    }
  }

  private var completedView: some View {
    VStack(spacing: 16) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 64))
        .foregroundColor(.green)

      Text("Import Complete!")
        .font(.headline)

      if let total = importService.progress.total {
        Text("Successfully imported \(total) channels")
          .font(.body)
          .foregroundColor(.secondary)
      } else {
        Text("Successfully imported \(importService.progress.imported) channels")
          .font(.body)
          .foregroundColor(.secondary)
      }
    }
  }

  private func failedView(error: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 64))
        .foregroundColor(.red)

      Text("Import Failed")
        .font(.headline)

      Text(error)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 400)

      if importService.progress.imported > 0 {
        Text("Imported \(importService.progress.imported) channels before error occurred")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }

  private var actionButtons: some View {
    HStack {
      // Cancel/Close button
      Button(action: handleCancel) {
        Text(closeButtonTitle)
          .frame(minWidth: 80)
      }
      .buttonStyle(.bordered)

      Spacer()

      // Primary action button
      if case .idle = importService.state {
        Button(action: handleStart) {
          Label("Start Import", systemImage: "arrow.down.circle")
            .frame(minWidth: 120)
        }
        .buttonStyle(.borderedProminent)
      } else if case .fetching = importService.state {
        Button(action: handlePause) {
          Label("Pause", systemImage: "pause.circle")
            .frame(minWidth: 120)
        }
        .buttonStyle(.bordered)
      } else if case .paused = importService.state {
        Button(action: handleResume) {
          Label("Resume", systemImage: "play.circle")
            .frame(minWidth: 120)
        }
        .buttonStyle(.borderedProminent)
      } else if case .failed = importService.state {
        Button(action: handleRetry) {
          Label("Retry", systemImage: "arrow.clockwise")
            .frame(minWidth: 120)
        }
        .buttonStyle(.borderedProminent)
      } else if case .completed = importService.state {
        Button(action: { dismiss() }) {
          Text("Done")
            .frame(minWidth: 120)
        }
        .buttonStyle(.borderedProminent)
      }
    }
  }

  // MARK: - Computed Properties

  private var closeButtonTitle: String {
    switch importService.state {
    case .idle, .completed, .failed:
      return "Close"
    case .fetching, .paused:
      return "Cancel"
    }
  }

  // MARK: - Actions

  private func handleStart() {
    Task {
      do {
        try await importService.startImport()
      } catch {
        errorMessage = error.localizedDescription
        showError = true
      }
    }
  }

  private func handlePause() {
    importService.pause()
  }

  private func handleResume() {
    Task {
      do {
        try await importService.resume()
      } catch {
        errorMessage = error.localizedDescription
        showError = true
      }
    }
  }

  private func handleRetry() {
    Task {
      do {
        // Reset to idle first
        importService.cancel()
        try await importService.startImport()
      } catch {
        errorMessage = error.localizedDescription
        showError = true
      }
    }
  }

  private func handleCancel() {
    if case .fetching = importService.state {
      importService.cancel()
    } else if case .paused = importService.state {
      importService.cancel()
    }

    dismiss()
  }
}

// MARK: - Previews

#Preview("Idle State") {
  SubscriptionsImportView(modelContext: ModelContext(try! ModelContainer(for: VideoItem.self)))
    .frame(width: 600, height: 400)
}

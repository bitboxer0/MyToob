//
//  AboutView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import OSLog
import SwiftData
import SwiftUI

/// About view displayed in the macOS Settings window.
/// Contains app information, support/contact actions, and legal/policy links.
///
/// Story 12.4: Provides accessible support/contact info and Send Diagnostics flow.
/// Required for App Store Guideline 1.2 (UGC safeguards) - Content Policy visibility.
struct AboutView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var showContentPolicy = false
  @State private var isExportingDiagnostics = false
  @State private var showingError = false
  @State private var errorMessage = ""

  var body: some View {
    Form {
      Section("App Information") {
        HStack {
          Text("MyToob")
            .font(.headline)
            .accessibilityIdentifier("AboutAppName")
          Spacer()
          Text(appVersion)
            .foregroundStyle(.secondary)
        }
      }

      Section("Support & Contact") {
        // Contact Support button - opens mailto with prefilled subject/body
        Button {
          contactSupport()
        } label: {
          HStack {
            Label("Contact Support", systemImage: "envelope")
            Spacer()
            Image(systemName: "arrow.up.forward")
              .foregroundStyle(.secondary)
          }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ContactSupportButton")
        .accessibilityLabel("Contact Support")
        .accessibilityHint("Opens email to send a support request")

        // Send Diagnostics button - exports diagnostics and composes email with attachment
        Button {
          sendDiagnostics()
        } label: {
          HStack {
            Label("Send Diagnostics", systemImage: "ladybug")
            Spacer()
            if isExportingDiagnostics {
              ProgressView()
                .controlSize(.small)
            } else {
              Image(systemName: "arrow.up.forward")
                .foregroundStyle(.secondary)
            }
          }
        }
        .buttonStyle(.plain)
        .disabled(isExportingDiagnostics)
        .accessibilityIdentifier("SendDiagnosticsButton")
        .accessibilityLabel("Send Diagnostics")
        .accessibilityHint("Exports diagnostic information and opens email to send to support")

        Text("Diagnostics are sanitized and contain no personal data.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("DiagnosticsPrivacyNote")
      }

      Section("Legal & Policies") {
        Button {
          showContentPolicy = true
        } label: {
          HStack {
            Label("Content Policy", systemImage: "doc.text")
            Spacer()
            Image(systemName: "arrow.up.forward.square")
              .foregroundStyle(.secondary)
          }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("OpenContentPolicyButton")
        .accessibilityLabel("Content Policy")
        .accessibilityHint("Opens the MyToob content policy page")
      }
    }
    .formStyle(.grouped)
    .frame(minWidth: 400, minHeight: 280)
    .accessibilityIdentifier("SettingsAboutView")
    .sheet(isPresented: $showContentPolicy) {
      PolicyWebView(
        hostedURL: Configuration.contentPolicyURL,
        localHTMLResourceName: "ContentPolicy"
      )
      .frame(minWidth: 600, minHeight: 500)
    }
    .alert("Error", isPresented: $showingError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  // MARK: - Actions

  /// Opens the default mail client with a pre-filled support email
  private func contactSupport() {
    LoggingService.shared.ui.info("User tapped Contact Support")
    SupportContactService.openSupportEmail()
  }

  /// Exports diagnostics and composes an email with the attachment
  private func sendDiagnostics() {
    LoggingService.shared.ui.info("User tapped Send Diagnostics")

    Task { @MainActor in
      isExportingDiagnostics = true
      defer { isExportingDiagnostics = false }

      do {
        // Export diagnostics (last 24 hours of logs)
        let diagnosticsURL = try await DiagnosticsService.shared.exportDiagnostics(
          modelContext: modelContext,
          hours: 24
        )

        // Compose email with attachment
        try await SupportContactService.composeDiagnosticsEmail(with: diagnosticsURL)

        LoggingService.shared.ui.notice("User exported diagnostics successfully")
      } catch {
        errorMessage = error.localizedDescription
        showingError = true
        LoggingService.shared.ui.error(
          "Diagnostics export failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  // MARK: - Computed Properties

  /// App version string from bundle
  private var appVersion: String {
    let version =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    return "\(version) (\(build))"
  }
}

#Preview {
  AboutView()
}

//
//  OAuthConsentView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import os
import SwiftUI

/// Pre-authorization consent view explaining OAuth permissions to users.
///
/// **App Store Compliance:** Shows users exactly what data will be accessed
/// before presenting the Google authorization screen.
///
/// Displays:
/// - Clear explanation of requested permissions
/// - Minimal scope (YouTube read-only)
/// - Data privacy commitment
/// - Option to cancel authorization
struct OAuthConsentView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var oauth = OAuth2Handler.shared

  @State private var isAuthenticating = false
  @State private var errorMessage: String?

  var body: some View {
    VStack(spacing: 24) {
      // Header
      VStack(spacing: 12) {
        Image(systemName: "person.badge.key.fill")
          .font(.system(size: 60))
          .foregroundStyle(.blue)

        Text("Connect Your YouTube Account")
          .font(.title)
          .fontWeight(.semibold)

        Text("MyToob needs your permission to access your YouTube data")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding(.top, 32)

      // What we'll access
      VStack(alignment: .leading, spacing: 16) {
        SectionHeader(title: "What we'll access:")

        PermissionRow(
          icon: "video.fill",
          title: "Your YouTube videos",
          description: "View your uploaded videos and watch history"
        )

        PermissionRow(
          icon: "folder.fill",
          title: "Your playlists",
          description: "Organize and discover your saved playlists"
        )

        PermissionRow(
          icon: "chart.bar.fill",
          title: "Watch statistics",
          description: "Help you track and organize what you watch"
        )
      }
      .padding(.horizontal, 20)

      Divider()
        .padding(.horizontal, 20)

      // What we won't do
      VStack(alignment: .leading, spacing: 16) {
        SectionHeader(title: "We will NOT:")

        PrivacyCommitment(
          icon: "xmark.shield.fill",
          text: "Store video files locally",
          color: .red
        )

        PrivacyCommitment(
          icon: "lock.shield.fill",
          text: "Share your data with third parties",
          color: .green
        )

        PrivacyCommitment(
          icon: "icloud.slash.fill",
          text: "Store data outside your device and iCloud",
          color: .blue
        )
      }
      .padding(.horizontal, 20)

      // Technical details
      VStack(spacing: 8) {
        Text("Technical details:")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        Text("Scope: youtube.readonly • OAuth 2.0 • Secure keychain storage")
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .multilineTextAlignment(.center)
      }
      .padding(.top, 8)

      Spacer()

      // Error message
      if let errorMessage = errorMessage {
        Text(errorMessage)
          .font(.callout)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)
      }

      // Action buttons
      VStack(spacing: 12) {
        Button {
          Task {
            await authenticate()
          }
        } label: {
          if isAuthenticating {
            ProgressView()
              .progressViewStyle(.circular)
              .controlSize(.small)
              .frame(maxWidth: .infinity)
              .frame(height: 44)
          } else {
            Text("Continue to Google")
              .frame(maxWidth: .infinity)
              .frame(height: 44)
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isAuthenticating)

        Button("Cancel") {
          dismiss()
        }
        .buttonStyle(.bordered)
        .disabled(isAuthenticating)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
    .frame(width: 500, height: 700)
  }

  // MARK: - Actions

  private func authenticate() async {
    isAuthenticating = true
    errorMessage = nil

    do {
      try await oauth.authenticate()
      dismiss()
    } catch OAuth2Error.userCancelled {
      errorMessage = "Authorization cancelled. You can try again anytime."
    } catch OAuth2Error.invalidConfiguration {
      errorMessage = "OAuth configuration error. Please check your setup."
    } catch {
      LoggingService.shared.network.error(
        "OAuth authentication failed: \(error.localizedDescription, privacy: .public)"
      )
      errorMessage = "Authentication failed: \(error.localizedDescription)"
    }

    isAuthenticating = false
  }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
  let title: String

  var body: some View {
    Text(title)
      .font(.headline)
      .fontWeight(.semibold)
  }
}

private struct PermissionRow: View {
  let icon: String
  let title: String
  let description: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundStyle(.blue)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)

        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct PrivacyCommitment: View {
  let icon: String
  let text: String
  let color: Color

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundStyle(color)
        .frame(width: 24)

      Text(text)
        .font(.body)
    }
  }
}

// MARK: - Preview

#Preview {
  OAuthConsentView()
}

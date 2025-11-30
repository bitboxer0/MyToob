//
//  AboutView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import SwiftUI

/// About view displayed in the macOS Settings window.
/// Contains app information and legal/policy links.
/// Required for App Store Guideline 1.2 (UGC safeguards) - Content Policy visibility.
struct AboutView: View {
  @State private var showContentPolicy = false

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
    .frame(minWidth: 400, minHeight: 200)
    .accessibilityIdentifier("SettingsAboutView")
    .sheet(isPresented: $showContentPolicy) {
      PolicyWebView(
        hostedURL: URL(string: "https://yourwebsite.com/mytoob/content-policy")!,
        localHTMLResourceName: "ContentPolicy"
      )
      .frame(minWidth: 600, minHeight: 500)
    }
  }

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

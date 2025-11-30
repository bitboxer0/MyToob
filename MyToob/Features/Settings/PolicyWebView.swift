//
//  PolicyWebView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import OSLog
import SwiftUI
import WebKit

/// View that displays the content policy page using WKWebView.
/// First attempts to load from the hosted URL, falls back to bundled HTML on failure.
/// Logs compliance events when the policy is successfully rendered.
struct PolicyWebView: View {
  let hostedURL: URL
  let localHTMLResourceName: String

  @Environment(\.dismiss) private var dismiss
  @State private var pageTitle: String = "MyToob Content Policy"
  @State private var loadSource: ComplianceLogger.PolicyAccessSource? = nil
  @State private var isLoading: Bool = true

  var body: some View {
    VStack(spacing: 0) {
      // Header bar
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(pageTitle)
            .font(.headline)
            .accessibilityIdentifier("ContentPolicyTitle")

          if let source = loadSource {
            Text(source == .external ? "Loaded from web" : "Loaded from app bundle")
              .font(.caption)
              .foregroundStyle(.secondary)
              .accessibilityIdentifier("ContentPolicySourceLabel")
          }
        }

        Spacer()

        if isLoading {
          ProgressView()
            .controlSize(.small)
        }

        Button("Done") {
          dismiss()
        }
        .keyboardShortcut(.defaultAction)
      }
      .padding()
      .background(.bar)

      Divider()

      // Web content
      PolicyWKWebViewRepresentable(
        hostedURL: hostedURL,
        localHTMLResourceName: localHTMLResourceName,
        onTitleChange: { newTitle in
          if !newTitle.isEmpty {
            pageTitle = newTitle
          }
        },
        onLoadSourceResolved: { source in
          if loadSource != source {
            loadSource = source
            // Log compliance event when content is rendered
            ComplianceLogger.shared.logContentPolicyAccessed(source: source)
          }
          isLoading = false
        },
        onLoadingChanged: { loading in
          isLoading = loading
        }
      )
      .accessibilityIdentifier("ContentPolicyWebView")
    }
  }
}

// MARK: - WebView NSViewRepresentable

/// NSViewRepresentable wrapper for WKWebView on macOS (Settings-specific)
struct PolicyWKWebViewRepresentable: NSViewRepresentable {
  let hostedURL: URL
  let localHTMLResourceName: String
  let onTitleChange: (String) -> Void
  let onLoadSourceResolved: (ComplianceLogger.PolicyAccessSource) -> Void
  let onLoadingChanged: (Bool) -> Void

  func makeNSView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = context.coordinator

    // Start loading the hosted URL
    let request = URLRequest(url: hostedURL, timeoutInterval: 10.0)
    webView.load(request)
    onLoadingChanged(true)

    return webView
  }

  func updateNSView(_ nsView: WKWebView, context: Context) {
    // No updates needed
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  // MARK: - Coordinator (WKNavigationDelegate)

  final class Coordinator: NSObject, WKNavigationDelegate {
    let parent: PolicyWKWebViewRepresentable

    init(_ parent: PolicyWKWebViewRepresentable) {
      self.parent = parent
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      parent.onLoadingChanged(false)
      parent.onTitleChange(webView.title ?? "MyToob Content Policy")
      parent.onLoadSourceResolved(.external)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      loadLocalFallback(into: webView, error: error)
    }

    func webView(
      _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      loadLocalFallback(into: webView, error: error)
    }

    /// Logger for policy web view operations using dynamic bundle identifier
    private static let logger = Logger(
      subsystem: Bundle.main.bundleIdentifier ?? "MyToob",
      category: "compliance"
    )

    private func loadLocalFallback(into webView: WKWebView, error: Error) {
      let resourceName = parent.localHTMLResourceName
      Self.logger.warning(
        "Failed to load remote policy URL, falling back to bundled HTML: \(error.localizedDescription, privacy: .public)"
      )

      guard
        let url = Bundle.main.url(
          forResource: resourceName, withExtension: "html"),
        let data = try? Data(contentsOf: url)
      else {
        Self.logger.error(
          "Failed to load bundled policy HTML resource: \(resourceName, privacy: .public)"
        )
        parent.onLoadingChanged(false)
        return
      }

      webView.load(
        data,
        mimeType: "text/html",
        characterEncodingName: "utf-8",
        baseURL: url.deletingLastPathComponent()
      )
      parent.onTitleChange("MyToob Content Policy")
      parent.onLoadSourceResolved(.local)
      parent.onLoadingChanged(false)
    }
  }
}

#Preview {
  PolicyWebView(
    hostedURL: Configuration.contentPolicyURL,
    localHTMLResourceName: "ContentPolicy"
  )
  .frame(width: 600, height: 500)
}

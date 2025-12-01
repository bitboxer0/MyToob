//
//  SupportContactService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import AppKit
import Foundation
import OSLog

/// Service for composing support emails and diagnostics submissions.
/// Centralizes email composition logic for testability and consistency.
///
/// Usage:
/// ```swift
/// // Open plain support email
/// SupportContactService.openSupportEmail()
///
/// // Send diagnostics with attachment
/// let url = try await DiagnosticsService.shared.exportDiagnostics(hours: 24)
/// try await SupportContactService.composeDiagnosticsEmail(with: url)
/// ```
enum SupportContactService {
  // MARK: - Email Content

  /// Returns the support email address
  static func supportEmail() -> String {
    Configuration.supportEmail
  }

  /// Returns the subject line for a diagnostics email
  static func diagnosticsEmailSubject() -> String {
    "MyToob Diagnostics Report"
  }

  /// Returns the body text for a diagnostics email
  /// Includes instructions for the user and privacy notice
  static func diagnosticsEmailBody() -> String {
    """
    Please describe the issue you're experiencing:

    [Describe your issue here]

    ---

    Diagnostics Information:
    - The attached file contains sanitized diagnostic information.
    - No personal data (API keys, tokens, file paths) is included.
    - We typically respond within \(Configuration.supportResponseTime).

    Thank you for helping us improve MyToob!
    """
  }

  /// Returns the subject line for a general support email
  static func supportEmailSubject() -> String {
    "MyToob Support Request"
  }

  /// Returns the body text for a general support email
  static func supportEmailBody() -> String {
    """
    Please describe your question or issue:

    [Describe your request here]

    ---

    App Version: \(appVersionString())
    macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)

    We typically respond within \(Configuration.supportResponseTime).
    """
  }

  // MARK: - Email Actions

  /// Opens the default mail client with a pre-filled support email (no attachment)
  /// Falls back to mailto: URL if NSSharingService is unavailable
  /// - Parameters:
  ///   - subject: Optional custom subject line
  ///   - body: Optional custom body text
  static func openSupportEmail(subject: String? = nil, body: String? = nil) {
    let emailSubject = subject ?? supportEmailSubject()
    let emailBody = body ?? supportEmailBody()

    // Try mailto: URL (most universal approach)
    if let mailtoURL = buildMailtoURL(
      to: supportEmail(),
      subject: emailSubject,
      body: emailBody
    ) {
      NSWorkspace.shared.open(mailtoURL)
      LoggingService.shared.ui.info("User initiated contact support via mailto")
    } else {
      LoggingService.shared.ui.error("Failed to build mailto URL for support email")
    }
  }

  /// Composes a diagnostics email with the specified attachment
  /// Uses NSSharingService to allow attaching the diagnostics zip file
  /// - Parameter attachmentURL: URL of the diagnostics .zip file to attach
  /// - Throws: `SupportContactError.mailServiceUnavailable` if no mail client is configured
  @MainActor
  static func composeDiagnosticsEmail(with attachmentURL: URL) async throws {
    guard let service = NSSharingService(named: .composeEmail) else {
      LoggingService.shared.ui.error("Mail service unavailable for diagnostics email")
      throw SupportContactError.mailServiceUnavailable
    }

    service.recipients = [supportEmail()]
    service.subject = diagnosticsEmailSubject()

    // NSSharingService.perform expects items: the body text and the attachment
    let bodyText = diagnosticsEmailBody()
    service.perform(withItems: [bodyText, attachmentURL])

    LoggingService.shared.ui.notice("User initiated send diagnostics via NSSharingService")
  }

  // MARK: - Errors

  /// Errors that can occur during support contact operations
  enum SupportContactError: LocalizedError {
    case mailServiceUnavailable
    case invalidEmailConfiguration

    var errorDescription: String? {
      switch self {
      case .mailServiceUnavailable:
        return "No email client is configured. Please set up Mail.app or another email client in System Settings."
      case .invalidEmailConfiguration:
        return "Support email is not properly configured."
      }
    }
  }

  // MARK: - Private Helpers

  /// Builds a mailto: URL with proper encoding
  private static func buildMailtoURL(to recipient: String, subject: String, body: String) -> URL? {
    var components = URLComponents()
    components.scheme = "mailto"
    components.path = recipient
    components.queryItems = [
      URLQueryItem(name: "subject", value: subject),
      URLQueryItem(name: "body", value: body),
    ]
    return components.url
  }

  /// Returns the app version string for inclusion in support emails
  private static func appVersionString() -> String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    return "\(version) (\(build))"
  }
}

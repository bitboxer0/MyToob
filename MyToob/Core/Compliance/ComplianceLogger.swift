//
//  ComplianceLogger.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/27/25.
//

import Foundation
import OSLog

/// Singleton logger for compliance-related events.
/// Logs user content moderation actions with appropriate privacy protections.
/// Required for App Store Guideline 1.2 (UGC safeguards) compliance.
final class ComplianceLogger {
  /// Shared singleton instance
  static let shared = ComplianceLogger()

  /// Logger using OSLog for privacy-preserving, structured logging
  private let logger: Logger

  /// ISO8601 date formatter for consistent timestamp format
  private let dateFormatter: ISO8601DateFormatter

  private init() {
    self.logger = Logger(subsystem: "com.yourcompany.mytoob", category: "compliance")
    self.dateFormatter = ISO8601DateFormatter()
    self.dateFormatter.formatOptions = [.withInternetDateTime]
  }

  // MARK: - Channel Block/Unblock Events

  /// Log when a user blocks/hides a YouTube channel
  /// - Parameters:
  ///   - channelID: The YouTube channel ID being blocked
  ///   - channelName: Optional display name of the channel
  ///   - reason: Optional user-provided reason for blocking
  func logChannelBlock(
    channelID: String,
    channelName: String?,
    reason: String?
  ) {
    let timestamp = dateFormatter.string(from: Date())

    logger.notice(
      """
      User blocked channel: action=block_channel \
      channelID=\(channelID, privacy: .private) \
      channelName=\(channelName ?? "unknown", privacy: .private) \
      reason=\(reason ?? "none", privacy: .private) \
      timestamp=\(timestamp, privacy: .public)
      """
    )
  }

  /// Log when a user unblocks/unhides a YouTube channel
  /// - Parameter channelID: The YouTube channel ID being unblocked
  func logChannelUnblock(channelID: String) {
    let timestamp = dateFormatter.string(from: Date())

    logger.notice(
      """
      User unblocked channel: action=unblock_channel \
      channelID=\(channelID, privacy: .private) \
      timestamp=\(timestamp, privacy: .public)
      """
    )
  }

  // MARK: - Content Report Events

  /// Log when a user reports content to YouTube
  /// - Parameters:
  ///   - videoID: The YouTube video ID being reported
  ///   - reportType: The type of report (e.g., "inappropriate", "spam")
  func logContentReport(
    videoID: String,
    reportType: String? = nil
  ) {
    let timestamp = dateFormatter.string(from: Date())

    logger.notice(
      """
      User reported content: action=report_content \
      videoID=\(videoID, privacy: .private) \
      reportType=\(reportType ?? "unspecified", privacy: .public) \
      timestamp=\(timestamp, privacy: .public)
      """
    )
  }

  // MARK: - Age Gate Events

  /// Log when age-gated content is encountered
  /// - Parameters:
  ///   - videoID: The YouTube video ID that requires age verification
  ///   - userAction: What action the user took (e.g., "dismissed", "proceeded")
  func logAgeGateEvent(
    videoID: String,
    userAction: String
  ) {
    let timestamp = dateFormatter.string(from: Date())

    logger.notice(
      """
      Age gate event: action=age_gate \
      videoID=\(videoID, privacy: .private) \
      userAction=\(userAction, privacy: .public) \
      timestamp=\(timestamp, privacy: .public)
      """
    )
  }
}

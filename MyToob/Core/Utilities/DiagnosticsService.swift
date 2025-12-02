//
//  DiagnosticsService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import AppKit
import Foundation
import OSLog
import SwiftData
import System

/// Service for collecting diagnostic information and exporting it for troubleshooting.
final class DiagnosticsService {
  /// Shared singleton instance
  static let shared = DiagnosticsService()

  private init() {}

  // MARK: - Diagnostic Report

  /// Diagnostic report structure
  struct DiagnosticReport: Codable {
    let timestamp: Date
    let appInfo: AppInfo
    let systemInfo: SystemInfo
    let modelContainerStats: ModelContainerStats?
    let recentLogs: [LogEntry]

    struct AppInfo: Codable {
      let version: String
      let buildNumber: String
      let bundleIdentifier: String
    }

    struct SystemInfo: Codable {
      let osVersion: String
      let deviceModel: String
      let processorCount: Int
      let memorySize: UInt64
    }

    struct ModelContainerStats: Codable {
      let videoItemCount: Int
      let clusterLabelCount: Int
      let noteCount: Int
      let channelBlacklistCount: Int
    }

    struct LogEntry: Codable {
      let timestamp: Date
      let level: String
      let category: String
      let message: String
    }
  }

  // MARK: - Export Diagnostics

  /// Export diagnostics to a .zip file
  /// - Parameters:
  ///   - modelContext: Optional ModelContext for collecting statistics
  ///   - hours: Number of hours of logs to include (default: 24)
  /// - Returns: URL of the exported .zip file
  func exportDiagnostics(
    modelContext: ModelContext? = nil,
    hours: Int = 24
  ) async throws -> URL {
    // Collect diagnostic data
    let report = try await collectDiagnostics(modelContext: modelContext, hours: hours)

    // Create temporary directory for diagnostic files
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("MyToob-Diagnostics-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    // Write diagnostic report as JSON
    let reportURL = tempDir.appendingPathComponent("diagnostic-report.json")
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let reportData = try encoder.encode(report)
    try reportData.write(to: reportURL)

    // Write logs as text file (more readable)
    let logsURL = tempDir.appendingPathComponent("logs.txt")
    let logsText = formatLogsAsText(report.recentLogs)
    try logsText.write(to: logsURL, atomically: true, encoding: .utf8)

    // Include compliance logs directory (monthly rotated JSONL files)
    let complianceLogsDir = ComplianceLogger.shared.logsDirectoryURL
    if FileManager.default.fileExists(atPath: complianceLogsDir.path) {
      let complianceLogsDest = tempDir.appendingPathComponent("compliance-logs", isDirectory: true)
      do {
        try FileManager.default.createDirectory(at: complianceLogsDest, withIntermediateDirectories: true)
        let files = try FileManager.default.contentsOfDirectory(
          at: complianceLogsDir, includingPropertiesForKeys: nil)
        for file in files
        where file.lastPathComponent.hasPrefix("compliance-") && file.pathExtension == "jsonl" {
          try FileManager.default.copyItem(
            at: file, to: complianceLogsDest.appendingPathComponent(file.lastPathComponent))
        }
      } catch {
        // Non-fatal; proceed without compliance logs if copy fails
        let logger = Logger(subsystem: "com.mytoob.app", category: "diagnostics")
        logger.debug(
          "Failed to include compliance logs directory in diagnostics: \(error.localizedDescription, privacy: .public)"
        )
      }
    }

    // Create README
    let readmeURL = tempDir.appendingPathComponent("README.txt")
    let readme = """
      MyToob Diagnostic Report
      Generated: \(ISO8601DateFormatter().string(from: report.timestamp))

      Contents:
      - diagnostic-report.json: Complete diagnostic data in JSON format
      - logs.txt: Recent application logs (last \(hours) hours)
      - compliance-logs/: Directory containing monthly compliance audit logs (JSONL)
        - compliance-YYYY-MM.jsonl: Compliance events for each month (90-day retention)

      App Information:
      - Version: \(report.appInfo.version) (\(report.appInfo.buildNumber))
      - Bundle ID: \(report.appInfo.bundleIdentifier)

      System Information:
      - macOS: \(report.systemInfo.osVersion)
      - Device: \(report.systemInfo.deviceModel)

      Privacy Notice:
      This diagnostic report has been sanitized to remove sensitive information
      such as API keys, tokens, and user file paths. Video IDs and titles may
      be included for debugging purposes.

      """
    try readme.write(to: readmeURL, atomically: true, encoding: .utf8)

    // Create .zip file
    let zipURL = tempDir.deletingLastPathComponent()
      .appendingPathComponent("MyToob-Diagnostics-\(formatDateForFilename(report.timestamp)).zip")
    try await createZipArchive(from: tempDir, to: zipURL)

    // Clean up temporary directory
    try? FileManager.default.removeItem(at: tempDir)

    return zipURL
  }

  // MARK: - Private Methods

  private func collectDiagnostics(
    modelContext: ModelContext?,
    hours: Int
  ) async throws -> DiagnosticReport {
    let appInfo = collectAppInfo()
    let systemInfo = collectSystemInfo()
    let modelStats = modelContext.map { collectModelContainerStats(from: $0) }
    let logs = try await collectRecentLogs(hours: hours)

    return DiagnosticReport(
      timestamp: Date(),
      appInfo: appInfo,
      systemInfo: systemInfo,
      modelContainerStats: modelStats,
      recentLogs: logs
    )
  }

  private func collectAppInfo() -> DiagnosticReport.AppInfo {
    let bundle = Bundle.main
    return DiagnosticReport.AppInfo(
      version: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
      buildNumber: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
      bundleIdentifier: bundle.bundleIdentifier ?? "Unknown"
    )
  }

  private func collectSystemInfo() -> DiagnosticReport.SystemInfo {
    let processInfo = ProcessInfo.processInfo
    return DiagnosticReport.SystemInfo(
      osVersion: processInfo.operatingSystemVersionString,
      deviceModel: getDeviceModel(),
      processorCount: processInfo.processorCount,
      memorySize: processInfo.physicalMemory
    )
  }

  private func collectModelContainerStats(from context: ModelContext) -> DiagnosticReport.ModelContainerStats {
    // Count each model type
    let videoItemCount = (try? context.fetch(FetchDescriptor<VideoItem>()).count) ?? 0
    let clusterLabelCount = (try? context.fetch(FetchDescriptor<ClusterLabel>()).count) ?? 0
    let noteCount = (try? context.fetch(FetchDescriptor<Note>()).count) ?? 0
    let channelBlacklistCount = (try? context.fetch(FetchDescriptor<ChannelBlacklist>()).count) ?? 0

    return DiagnosticReport.ModelContainerStats(
      videoItemCount: videoItemCount,
      clusterLabelCount: clusterLabelCount,
      noteCount: noteCount,
      channelBlacklistCount: channelBlacklistCount
    )
  }

  private func collectRecentLogs(hours: Int) async throws -> [DiagnosticReport.LogEntry] {
    let store = try OSLogStore(scope: .currentProcessIdentifier)
    let timeInterval = TimeInterval(-hours * 3600)
    let startDate = Date(timeIntervalSinceNow: timeInterval)

    let position = store.position(date: startDate)
    let entries = try store.getEntries(at: position)

    var logEntries: [DiagnosticReport.LogEntry] = []

    for entry in entries {
      // Only process log entries (not signposts, activities, etc.)
      guard let logEntry = entry as? OSLogEntryLog else { continue }

      // Only include logs from our subsystem
      guard logEntry.subsystem == "com.yourcompany.mytoob" else { continue }

      let sanitizedMessage = sanitizeMessage(logEntry.composedMessage)

      logEntries.append(
        DiagnosticReport.LogEntry(
          timestamp: logEntry.date,
          level: levelString(from: logEntry.level),
          category: logEntry.category,
          message: sanitizedMessage
        )
      )
    }

    return logEntries
  }

  // MARK: - Sanitization

  private func sanitizeMessage(_ message: String) -> String {
    var sanitized = message

    // Redact common token patterns
    sanitized = sanitized.replacingOccurrences(
      of: "token[:\\s]+[A-Za-z0-9_-]+",
      with: "token: [REDACTED]",
      options: .regularExpression
    )

    // Redact API keys
    sanitized = sanitized.replacingOccurrences(
      of: "key[:\\s]+[A-Za-z0-9_-]+",
      with: "key: [REDACTED]",
      options: .regularExpression
    )

    // Redact file paths containing username
    sanitized = sanitized.replacingOccurrences(
      of: "/Users/[^/]+/",
      with: "/Users/[USER]/",
      options: .regularExpression
    )

    return sanitized
  }

  // MARK: - Utility Methods

  private func getDeviceModel() -> String {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &machine, &size, nil, 0)
    return String(cString: machine)
  }

  private func levelString(from level: OSLogEntryLog.Level) -> String {
    switch level {
    case .debug: return "DEBUG"
    case .info: return "INFO"
    case .notice: return "NOTICE"
    case .error: return "ERROR"
    case .fault: return "FAULT"
    default: return "UNKNOWN"
    }
  }

  private func formatLogsAsText(_ logs: [DiagnosticReport.LogEntry]) -> String {
    let formatter = ISO8601DateFormatter()
    return logs.map { entry in
      "[\(formatter.string(from: entry.timestamp))] [\(entry.level)] [\(entry.category)] \(entry.message)"
    }
    .joined(separator: "\n")
  }

  private func formatDateForFilename(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd-HHmmss"
    return formatter.string(from: date)
  }

  private func createZipArchive(from sourceURL: URL, to destinationURL: URL) async throws {
    // Use NSFileCoordinator and NSFileWrapper for safe file operations
    let coordinator = NSFileCoordinator()
    var error: NSError?

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      coordinator.coordinate(
        readingItemAt: sourceURL,
        options: .forUploading,
        error: &error
      ) { zipURL in
        do {
          // NSFileCoordinator creates a .zip when using .forUploading
          try FileManager.default.copyItem(at: zipURL, to: destinationURL)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }

      if let error = error {
        continuation.resume(throwing: error)
      }
    }
  }
}

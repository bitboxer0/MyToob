//
//  ComplianceLogger.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/27/25.
//

import Foundation
import OSLog

/// Singleton logger for compliance-related events.
/// - Dedicated OSLog subsystem: com.mytoob.compliance
/// - JSONL (newline-delimited JSON) persistence under Application Support
/// - 90-day retention, export to JSON, no PII (only IDs and coarse metadata)
/// Required for App Store Guideline 1.2 (UGC safeguards) compliance.
final class ComplianceLogger {
  // MARK: - Types

  /// Machine-readable event model persisted as JSON
  struct Event: Codable, Equatable {
    let timestamp: Date
    let action: String  // e.g., "report_content", "hide_channel", "unhide_channel", "content_policy_access", "support_contact", "age_gate"
    let videoID: String?  // YouTube video ID (if applicable)
    let channelID: String?  // YouTube channel ID (if applicable)
    let details: Details?  // Auxiliary non-PII metadata

    struct Details: Codable, Equatable {
      let method: String?  // e.g., support contact method: "email", "web"
      let context: String?  // e.g., "settings", "menu"
      let userAction: String?  // e.g., age gate user action "dismissed", "proceeded"
      // Note: intentionally excludes channel names, video titles, usernames (PII)
    }
  }

  /// Source from which the content policy was loaded (for backward compatibility)
  enum PolicyAccessSource: String {
    case external  // Loaded from hosted URL
    case local  // Loaded from bundled HTML fallback
  }

  // MARK: - Singleton

  static let shared = ComplianceLogger()

  // MARK: - Private

  /// Dedicated compliance OSLog subsystem and category
  private let logger = Logger(subsystem: "com.mytoob.compliance", category: "audit")

  /// ISO8601 for human-readable timestamps inside textual OSLog messages (not for JSON encoding)
  private let dateFormatter: ISO8601DateFormatter

  /// Serial queue for file I/O to ensure consistency
  private let ioQueue = DispatchQueue(label: "com.mytoob.compliance.log-queue", qos: .utility)

  /// Retention window in days per AC
  private let retentionDays = 90

  /// FileManager convenience
  private let fileManager = FileManager.default

  /// Storage directory provider (allows test override in DEBUG builds)
  private var storageDirectoryProvider: () -> URL

  /// Date provider for current time (allows test override in DEBUG builds)
  private var dateProvider: () -> Date = { Date() }

  /// Tracks when we last ran file-based prune (avoid scanning on every write)
  private var lastPruneCheck: Date?

  /// Interval between prune checks (once per day)
  private let pruneCheckInterval: TimeInterval = 24 * 60 * 60

  // MARK: - Directory & File URLs

  /// Directory containing monthly rotated log files
  var logsDirectoryURL: URL {
    applicationSupportDirectory()
      .appendingPathComponent("MyToob", isDirectory: true)
      .appendingPathComponent("Compliance", isDirectory: true)
      .appendingPathComponent("logs", isDirectory: true)
  }

  /// Legacy single-file log URL (for migration)
  private var legacySingleLogFileURL: URL {
    applicationSupportDirectory()
      .appendingPathComponent("MyToob", isDirectory: true)
      .appendingPathComponent("Compliance", isDirectory: true)
      .appendingPathComponent("compliance-logs.jsonl", isDirectory: false)
  }

  /// Returns the log file URL for a given date's month (UTC)
  /// - Parameter date: The date to determine the month bucket
  /// - Returns: URL like ".../logs/compliance-2025-12.jsonl"
  private func currentLogFileURL(for date: Date) -> URL {
    let fmt = DateFormatter()
    fmt.calendar = Calendar(identifier: .iso8601)
    fmt.timeZone = TimeZone(secondsFromGMT: 0)
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM"
    let stamp = fmt.string(from: date)
    return logsDirectoryURL.appendingPathComponent("compliance-\(stamp).jsonl")
  }

  /// Parses "YYYY-MM" from a compliance log filename
  /// - Parameter filename: e.g., "compliance-2025-12.jsonl"
  /// - Returns: Date representing the first day of that month, or nil if parse fails
  private func monthDate(from filename: String) -> Date? {
    // Extract "YYYY-MM" from "compliance-YYYY-MM.jsonl"
    guard filename.hasPrefix("compliance-"),
      filename.hasSuffix(".jsonl")
    else { return nil }
    let start = filename.index(filename.startIndex, offsetBy: 11)  // after "compliance-"
    let end = filename.index(filename.endIndex, offsetBy: -6)  // before ".jsonl"
    guard start < end else { return nil }
    let monthStr = String(filename[start..<end])

    let fmt = DateFormatter()
    fmt.calendar = Calendar(identifier: .iso8601)
    fmt.timeZone = TimeZone(secondsFromGMT: 0)
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM"
    return fmt.date(from: monthStr)
  }

  private init() {
    // Default storage directory provider
    let fm = fileManager
    storageDirectoryProvider = {
      #if os(macOS)
        return fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      #else
        let base = fm.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Application Support", isDirectory: true)
      #endif
    }
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime]
    self.dateFormatter = fmt

    // Ensure log directory exists on init (best-effort)
    _ = ensureLogsDirectory()

    // Migrate legacy single-file logs to monthly rotation (best-effort)
    migrateLegacySingleLogIfNeeded()
  }

  // MARK: - Public API (Logging)

  /// Log when a user hides/blocks a YouTube channel.
  /// - Parameters:
  ///   - channelID: The YouTube channel ID being blocked
  ///   - channelName: Retained for API compatibility but intentionally not persisted (PII avoidance)
  ///   - reason: Retained for API compatibility but intentionally not persisted (PII avoidance)
  func logChannelBlock(
    channelID: String,
    channelName _: String?,
    reason _: String?
  ) {
    let timestamp = dateFormatter.string(from: Date())
    logger.notice(
      """
      User hid channel: action=hide_channel \
      channelID=\(channelID, privacy: .private) \
      timestamp=\(timestamp, privacy: .public)
      """
    )

    let event = Event(
      timestamp: Date(),
      action: "hide_channel",
      videoID: nil,
      channelID: channelID,
      details: nil
    )
    appendEventAndPrune(event)
  }

  /// Log when a user unblocks/unhides a YouTube channel
  /// - Parameter channelID: The YouTube channel ID being unblocked
  func logChannelUnblock(channelID: String) {
    let timestamp = dateFormatter.string(from: Date())
    logger.notice(
      """
      User unhid channel: action=unhide_channel \
      channelID=\(channelID, privacy: .private) \
      timestamp=\(timestamp, privacy: .public)
      """
    )

    let event = Event(
      timestamp: Date(),
      action: "unhide_channel",
      videoID: nil,
      channelID: channelID,
      details: nil
    )
    appendEventAndPrune(event)
  }

  /// Log when a user reports content to YouTube
  /// - Parameters:
  ///   - videoID: The YouTube video ID being reported
  ///   - reportType: The type of report (e.g., "inappropriate", "spam") - not persisted to JSON to avoid potential PII or over-collection
  func logContentReport(
    videoID: String,
    reportType: String? = nil
  ) {
    _ = reportType  // Intentionally not persisted

    let timestamp = dateFormatter.string(from: Date())
    logger.notice(
      """
      User reported content: action=report_content \
      videoID=\(videoID, privacy: .private) \
      timestamp=\(timestamp, privacy: .public)
      """
    )

    let event = Event(
      timestamp: Date(),
      action: "report_content",
      videoID: videoID,
      channelID: nil,
      details: nil
    )
    appendEventAndPrune(event)
  }

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

    let details = Event.Details(method: nil, context: nil, userAction: userAction)
    let event = Event(
      timestamp: Date(),
      action: "age_gate",
      videoID: videoID,
      channelID: nil,
      details: details
    )
    appendEventAndPrune(event)
  }

  /// Log when the user opens the Content Policy (backward compatible)
  /// - Parameter source: Whether the policy was loaded from external URL or local bundle
  func logContentPolicyAccessed(source: PolicyAccessSource) {
    logContentPolicyAccess(context: source.rawValue)
  }

  /// Log when the user opens the Content Policy
  func logContentPolicyAccess(context: String? = nil) {
    let timestamp = dateFormatter.string(from: Date())
    logger.notice(
      """
      Content policy accessed: action=content_policy_access \
      timestamp=\(timestamp, privacy: .public)
      """
    )

    // Only create details if context is provided (avoid empty Details objects)
    let details: Event.Details? = context.map { Event.Details(method: nil, context: $0, userAction: nil) }
    let event = Event(
      timestamp: Date(),
      action: "content_policy_access",
      videoID: nil,
      channelID: nil,
      details: details
    )
    appendEventAndPrune(event)
  }

  /// Log when the user initiates support contact
  /// - Parameter method: e.g., "email", "web", "github"
  func logSupportContact(method: String) {
    let timestamp = dateFormatter.string(from: Date())
    logger.notice(
      """
      Support contact initiated: action=support_contact \
      method=\(method, privacy: .public) \
      timestamp=\(timestamp, privacy: .public)
      """
    )

    let details = Event.Details(method: method, context: nil, userAction: nil)
    let event = Event(
      timestamp: Date(),
      action: "support_contact",
      videoID: nil,
      channelID: nil,
      details: details
    )
    appendEventAndPrune(event)
  }

  // MARK: - Export

  /// Export compliance logs into a standalone JSON file (array of events).
  /// - Parameters:
  ///   - start: Optional start date for the export range (inclusive)
  ///   - end: Optional end date for the export range (inclusive)
  /// - Returns: URL of the exported JSON file
  func exportComplianceLogs(from start: Date? = nil, to end: Date? = nil) throws -> URL {
    let range: DateInterval?
    if let start = start, let end = end {
      range = DateInterval(start: start, end: end)
    } else if let start = start {
      range = DateInterval(start: start, end: dateProvider())
    } else if let end = end {
      range = DateInterval(start: Date.distantPast, end: end)
    } else {
      range = nil
    }

    let events = try loadEvents(in: range)

    let dir = fileManager.temporaryDirectory
    // ISO8601-like filename (filesystem-safe: no colons)
    let fileDateFormatter = DateFormatter()
    fileDateFormatter.dateFormat = "yyyy-MM-dd-HHmmss'Z'"
    fileDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    let outURL = dir.appendingPathComponent(
      "compliance-logs-\(fileDateFormatter.string(from: dateProvider())).json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(events)
    try data.write(to: outURL, options: .atomic)
    return outURL
  }

  /// Export compliance logs into a standalone JSON file (array of events).
  /// - Parameter sinceDays: Optional filter window in days (default: nil = all stored)
  /// - Returns: URL of the exported JSON file
  /// - Note: This is a backward-compatible wrapper around `exportComplianceLogs(from:to:)`.
  func exportComplianceLogs(sinceDays: Int? = nil) throws -> URL {
    if let days = sinceDays {
      let start = Calendar.current.date(byAdding: .day, value: -days, to: dateProvider()) ?? dateProvider()
      return try exportComplianceLogs(from: start, to: dateProvider())
    } else {
      return try exportComplianceLogs(from: nil, to: nil)
    }
  }

  // MARK: - Internal (used by tests and diagnostics)

  /// Location of the JSONL compliance log file for the current month
  /// - Note: For backward compatibility with tests that reference this property.
  ///         New code should use `logsDirectoryURL` to access all rotated files.
  var logFileURL: URL {
    currentLogFileURL(for: dateProvider())
  }

  /// Remove all stored events (deletes all rotated log files).
  /// - Throws: File I/O errors if files cannot be removed.
  func clearStoredEvents() throws {
    var caught: Error?
    ioQueue.sync {
      do {
        if fileManager.fileExists(atPath: logsDirectoryURL.path) {
          let contents = try fileManager.contentsOfDirectory(
            at: logsDirectoryURL, includingPropertiesForKeys: nil)
          for url in contents
          where url.lastPathComponent.hasPrefix("compliance-") && url.pathExtension == "jsonl" {
            try fileManager.removeItem(at: url)
          }
        }
        // Also remove legacy single file if it exists
        if fileManager.fileExists(atPath: legacySingleLogFileURL.path) {
          try fileManager.removeItem(at: legacySingleLogFileURL)
        }
        _ = ensureLogsDirectory()
      } catch {
        caught = error
      }
    }
    if let error = caught {
      throw error
    }
  }

  /// Synchronously wait for pending writes to drain (tests use this to avoid races)
  func waitForWrites() {
    ioQueue.sync { /* barrier */ }
  }

  /// Load all stored events from all rotated JSONL files
  /// - Parameter range: Optional date range to filter events
  /// - Returns: Array of events, optionally filtered by date range
  func loadEvents(in range: DateInterval? = nil) throws -> [Event] {
    var result = [Event]()
    var loadError: Error?
    ioQueue.sync {
      do {
        result = try self._loadEventsFromAllFilesUnsafe(in: range)
      } catch {
        loadError = error
      }
    }
    if let error = loadError {
      throw error
    }
    return result
  }

  /// Load all stored events (backward compatible, no date filtering)
  func loadEvents() throws -> [Event] {
    try loadEvents(in: nil)
  }

  /// Prune old log files (deletes files for months older than retention window)
  /// - Note: This replaces the old line-by-line pruning with O(1) file deletion.
  func pruneOldLogFiles() throws {
    var pruneError: Error?
    ioQueue.sync {
      do {
        try self._pruneOldLogFilesUnsafe(now: self.dateProvider())
      } catch {
        pruneError = error
      }
    }
    if let error = pruneError {
      throw error
    }
  }

  // MARK: - Private (non-locking) implementations

  /// Internal: Load events from all rotated files without acquiring lock (caller must be on ioQueue)
  /// - Parameter range: Optional date range to filter events
  private func _loadEventsFromAllFilesUnsafe(in range: DateInterval? = nil) throws -> [Event] {
    var result = [Event]()
    guard fileManager.fileExists(atPath: logsDirectoryURL.path) else { return result }

    let contents = try fileManager.contentsOfDirectory(
      at: logsDirectoryURL, includingPropertiesForKeys: nil)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    // Sort files by name to get chronological order
    let logFiles = contents
      .filter { $0.lastPathComponent.hasPrefix("compliance-") && $0.pathExtension == "jsonl" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }

    for fileURL in logFiles {
      // Optimization: skip files outside the range if we can determine from filename
      if let range = range, let fileMonth = monthDate(from: fileURL.lastPathComponent) {
        // File month is first day of month; file contains events for that whole month
        let fileMonthEnd = Calendar.current.date(byAdding: .month, value: 1, to: fileMonth) ?? fileMonth
        // Skip if file's month is entirely before or after the range
        if fileMonthEnd <= range.start || fileMonth > range.end {
          continue
        }
      }

      let data = try Data(contentsOf: fileURL)
      guard let content = String(data: data, encoding: .utf8), !content.isEmpty else { continue }

      for line in content.split(separator: "\n") {
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
        if let jsonData = line.data(using: .utf8),
          let event = try? decoder.decode(Event.self, from: jsonData)
        {
          // Apply date filter if provided
          if let range = range {
            if event.timestamp >= range.start && event.timestamp <= range.end {
              result.append(event)
            }
          } else {
            result.append(event)
          }
        }
      }
    }
    return result
  }

  /// Internal: Prune old log files (delete entire files for months older than retention)
  /// - Parameter now: The current date (allows testing with injected dates)
  private func _pruneOldLogFilesUnsafe(now: Date) throws {
    guard fileManager.fileExists(atPath: logsDirectoryURL.path) else { return }

    // Calculate cutoff: first day of the month that is `retentionDays` ago
    let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: now) ?? now
    let cutoffComponents = Calendar.current.dateComponents([.year, .month], from: cutoffDate)
    guard let cutoffMonthStart = Calendar.current.date(from: cutoffComponents) else { return }

    let contents = try fileManager.contentsOfDirectory(
      at: logsDirectoryURL, includingPropertiesForKeys: nil)

    for fileURL in contents
    where fileURL.lastPathComponent.hasPrefix("compliance-") && fileURL.pathExtension == "jsonl" {
      guard let fileMonth = monthDate(from: fileURL.lastPathComponent) else { continue }
      // Delete if the file's month is strictly before the cutoff month
      if fileMonth < cutoffMonthStart {
        try fileManager.removeItem(at: fileURL)
        logger.notice(
          "Pruned old compliance log file: \(fileURL.lastPathComponent, privacy: .public)")
      }
    }
  }

  /// Check if prune should run (at most once per day) and run if needed
  private func maybePruneOldLogFiles() {
    let now = dateProvider()
    if let last = lastPruneCheck, now.timeIntervalSince(last) < pruneCheckInterval {
      return
    }
    do {
      try _pruneOldLogFilesUnsafe(now: now)
      lastPruneCheck = now
    } catch {
      logger.error(
        "Prune old compliance log files failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  // MARK: - Private helpers

  private func appendEventAndPrune(_ event: Event) {
    ioQueue.async {
      do {
        // Determine the target file based on current date (for rotation)
        let targetFile = self.currentLogFileURL(for: self.dateProvider())

        // Ensure directory exists
        if self.ensureLogsDirectory() {
          if !self.fileManager.fileExists(atPath: targetFile.path) {
            self.fileManager.createFile(atPath: targetFile.path, contents: nil)
          }
        }

        // Append JSON line
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        if let fh = try? FileHandle(forWritingTo: targetFile) {
          try fh.seekToEnd()
          try fh.write(contentsOf: data)
          try fh.write(contentsOf: Data("\n".utf8))
          try fh.close()
        } else {
          // Attempt to create and reopen (avoids full-file rewrite)
          self.fileManager.createFile(atPath: targetFile.path, contents: nil)
          if let fh2 = try? FileHandle(forWritingTo: targetFile) {
            self.logger.warning("FileHandle reopen path used for compliance log append")
            try fh2.seekToEnd()
            try fh2.write(contentsOf: data)
            try fh2.write(contentsOf: Data("\n".utf8))
            try fh2.close()
          } else {
            // Extreme failure: drop event from JSONL (OSLog still has it)
            self.logger.error("Compliance log append failed after create+reopen; dropping event")
            return
          }
        }
        // Maybe prune old files (at most once per day)
        self.maybePruneOldLogFiles()
      } catch {
        // If file I/O fails, we still keep OSLog record; no crash
        self.logger.error(
          "Failed to append/prune compliance event: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  /// Migrate legacy single-file compliance log to monthly rotation (best-effort, non-fatal)
  private func migrateLegacySingleLogIfNeeded() {
    ioQueue.async {
      guard self.fileManager.fileExists(atPath: self.legacySingleLogFileURL.path) else { return }
      do {
        _ = self.ensureLogsDirectory()
        let targetFile = self.currentLogFileURL(for: self.dateProvider())

        // Read legacy content and append to current month's file
        let legacyData = try Data(contentsOf: self.legacySingleLogFileURL)
        if let legacyContent = String(data: legacyData, encoding: .utf8), !legacyContent.isEmpty {
          // Create target file if needed
          if !self.fileManager.fileExists(atPath: targetFile.path) {
            self.fileManager.createFile(atPath: targetFile.path, contents: nil)
          }

          // Append legacy content to target
          if let fh = try? FileHandle(forWritingTo: targetFile) {
            try fh.seekToEnd()
            // Ensure content ends with newline
            let content = legacyContent.hasSuffix("\n") ? legacyContent : legacyContent + "\n"
            try fh.write(contentsOf: Data(content.utf8))
            try fh.close()
          }
        }

        // Remove legacy file
        try self.fileManager.removeItem(at: self.legacySingleLogFileURL)
        self.logger.notice("Migrated legacy compliance log to monthly rotation")
      } catch {
        self.logger.error(
          "Failed legacy compliance log migration: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  @discardableResult
  private func ensureLogsDirectory() -> Bool {
    let dir = logsDirectoryURL
    if !fileManager.fileExists(atPath: dir.path) {
      do {
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
      } catch {
        logger.error(
          "Failed to create compliance logs directory: \(error.localizedDescription, privacy: .public)"
        )
        return false
      }
    }
    return true
  }

  private func applicationSupportDirectory() -> URL {
    storageDirectoryProvider()
  }

  // MARK: - Test Support

  #if DEBUG
    /// Override the storage directory for testing.
    /// Pass `nil` to reset to the default Application Support directory.
    /// - Important: Only available in DEBUG builds to prevent accidental production use.
    func setStorageDirectoryOverrideForTesting(_ url: URL?) {
      let fm = fileManager
      if let url = url {
        storageDirectoryProvider = { url }
      } else {
        // Reset to default
        storageDirectoryProvider = {
          #if os(macOS)
            return fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
          #else
            let base = fm.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            return base.appendingPathComponent("Application Support", isDirectory: true)
          #endif
        }
      }
    }

    /// Override the date provider for testing (allows simulating different months for rotation).
    /// Pass `nil` to reset to the default (current date).
    /// - Important: Only available in DEBUG builds to prevent accidental production use.
    func setDateProviderForTesting(_ provider: (() -> Date)?) {
      if let provider = provider {
        dateProvider = provider
      } else {
        dateProvider = { Date() }
      }
    }

    /// Reset the prune check timer (for testing)
    func resetPruneCheckForTesting() {
      lastPruneCheck = nil
    }
  #endif
}

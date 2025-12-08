//
//  LoggingService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import Foundation
import OSLog

/// Centralized logging service using OSLog for privacy-preserving, structured logging.
///
/// Usage Examples:
/// ```swift
/// // App lifecycle events (public data)
/// LoggingService.shared.app.info("App launched, version: \(appVersion)")
///
/// // Network requests (public error types, private details)
/// LoggingService.shared.network.error("API request failed: \(error.localizedDescription, privacy: .public)")
///
/// // AI operations (private data)
/// LoggingService.shared.ai.debug("Processing video: \(videoID, privacy: .private)")
///
/// // Player events (private video IDs)
/// LoggingService.shared.player.info("Playing video: \(videoID, privacy: .private)")
///
/// // Sensitive data (always redacted)
/// LoggingService.shared.network.error("Auth failed, token: \(token, privacy: .sensitive)")
/// ```
///
/// Privacy Levels:
/// - `.public` - Non-sensitive data (error codes, counts, app version)
/// - `.private` - Sensitive data visible to developers (video IDs, titles, search queries)
/// - `.sensitive` - Highly sensitive data (tokens, passwords) - always redacted
///
final class LoggingService {
  /// Shared singleton instance
  static let shared = LoggingService()

  /// Application subsystem identifier
  private let subsystem = "com.yourcompany.mytoob"

  // MARK: - Logger Instances

  /// Logger for application lifecycle events
  /// Use for: app launch, initialization, configuration, state changes
  let app: Logger

  /// Logger for network operations
  /// Use for: API requests, responses, network errors, quota tracking
  let network: Logger

  /// Logger for AI/ML operations
  /// Use for: embeddings generation, vector search, clustering, ranking
  let ai: Logger

  /// Logger for video playback events
  /// Use for: player state changes, playback errors, seek operations
  let player: Logger

  /// Logger for CloudKit synchronization
  /// Use for: sync operations, conflict resolution, CloudKit errors
  let sync: Logger

  /// Logger for CloudKit container operations
  /// Use for: account status, container access, record CRUD operations
  let cloudKit: Logger

  /// Logger for user interface events
  /// Use for: view lifecycle, user interactions, navigation
  let ui: Logger

  /// Logger for data persistence operations
  /// Use for: SwiftData operations, model migrations, storage errors
  let persistence: Logger

  /// Logger for macOS system integrations
  /// Use for: Spotlight indexing, App Intents, Handoff, system services
  let integration: Logger

  // MARK: - Initialization

  private init() {
    // Initialize Logger instances for each category
    self.app = Logger(subsystem: subsystem, category: "app")
    self.network = Logger(subsystem: subsystem, category: "network")
    self.ai = Logger(subsystem: subsystem, category: "ai")
    self.player = Logger(subsystem: subsystem, category: "player")
    self.sync = Logger(subsystem: subsystem, category: "sync")
    self.cloudKit = Logger(subsystem: subsystem, category: "cloudkit")
    self.ui = Logger(subsystem: subsystem, category: "ui")
    self.persistence = Logger(subsystem: subsystem, category: "persistence")
    self.integration = Logger(subsystem: subsystem, category: "integration")
  }

  // MARK: - Log Level Guidelines

  /*
  Log Levels (from Logger documentation):

  .debug    - Detailed information for debugging (not in production logs)
  Use for: Development-only diagnostics, verbose state dumps

  .info     - Informational messages about normal operations
  Use for: App launched, feature used, successful operations

  .notice   - Important but not error conditions
  Use for: Configuration changes, significant state transitions

  .error    - Error conditions that don't crash the app
  Use for: Recoverable errors, failed operations with fallback

  .fault    - Critical errors that may crash the app
  Use for: Unrecoverable errors, data corruption, crashes
  */
}

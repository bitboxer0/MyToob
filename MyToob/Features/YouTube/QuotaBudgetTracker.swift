//
//  QuotaBudgetTracker.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

import Foundation
import Combine
import os

/// Tracks YouTube Data API quota consumption and enforces budget limits
///
/// **Features:**
/// - Per-endpoint quota cost tracking
/// - Daily budget limit (10,000 units default, resets at midnight Pacific Time)
/// - Exponential backoff on 429 rate limit errors
/// - Circuit breaker pattern (opens after 5 consecutive 429s, blocks for 1 hour)
///
/// **Quota Costs:**
/// - search.list: 100 units
/// - videos.list, channels.list, playlists.list, playlistItems.list, subscriptions.list: 1 unit each
///
/// Usage:
/// ```swift
/// // Before making request
/// guard QuotaBudgetTracker.shared.canMakeRequest(endpoint: .search) else {
///   throw YouTubeAPIError.quotaBudgetExceeded
/// }
///
/// // After successful 200 response
/// QuotaBudgetTracker.shared.recordRequest(endpoint: .search)
///
/// // On 429 response
/// try await QuotaBudgetTracker.shared.handle429Response(endpoint: .search)
/// ```
@MainActor
final class QuotaBudgetTracker: ObservableObject {
  // MARK: - Singleton

  static let shared = QuotaBudgetTracker()

  // MARK: - Types

  enum Endpoint: String, CaseIterable {
    case search = "search"
    case videos = "videos"
    case channels = "channels"
    case playlists = "playlists"
    case playlistItems = "playlistItems"
    case subscriptions = "subscriptions"

    var quotaCost: Int {
      switch self {
      case .search:
        return 100
      case .videos, .channels, .playlists, .playlistItems, .subscriptions:
        return 1
      }
    }
  }

  enum CircuitState: Equatable {
    case closed    // Normal operation
    case open      // Blocking all requests
    case halfOpen  // Testing service recovery

    var description: String {
      switch self {
      case .closed:
        return "Closed (Normal)"
      case .halfOpen:
        return "Half-Open (Testing)"
      case .open:
        return "Open (Blocking)"
      }
    }
  }

  struct QuotaStats {
    let totalConsumed: Int
    let dailyLimit: Int
    let endpointBreakdown: [String: Int]
    let circuitState: CircuitState
    let resetTime: Date
  }

  // MARK: - Properties

  @Published private(set) var circuitState: CircuitState = .closed

  private var consumed: [String: Int] = [:]
  private var totalConsumed: Int = 0
  private let dailyLimit: Int = 10_000

  private var lastResetDate: Date
  private var consecutiveFailures: Int = 0
  private let circuitOpenThreshold: Int = 5
  private var circuitOpenedAt: Date?
  private let circuitRecoveryDuration: TimeInterval = 3600 // 1 hour

  // MARK: - Initialization

  private init() {
    // Initialize with current date (will trigger reset check on first use)
    self.lastResetDate = Date()
    checkAndResetIfNeeded()
  }

  // MARK: - Public API

  /// Check if request can be made (checks quota budget and circuit breaker state)
  /// - Parameter endpoint: API endpoint to check
  /// - Returns: True if request is allowed, false if over budget or circuit is open
  func canMakeRequest(endpoint: Endpoint) -> Bool {
    // Check daily reset first
    checkAndResetIfNeeded()

    // Check circuit breaker state
    if circuitState == .open {
      checkCircuitRecovery()
      if circuitState == .open {
        LoggingService.shared.network.warning(
          "Request blocked - circuit breaker OPEN"
        )
        return false
      }
    }

    // Check quota budget
    let cost = endpoint.quotaCost
    if totalConsumed + cost > dailyLimit {
      LoggingService.shared.network.warning(
        "Request blocked - quota budget would be exceeded: \(self.totalConsumed + cost)/\(self.dailyLimit) units"
      )
      return false
    }

    return true
  }

  /// Record successful API request (increments quota counter)
  /// - Parameter endpoint: API endpoint that was called
  func recordRequest(endpoint: Endpoint) {
    let cost = endpoint.quotaCost
    let key = endpoint.rawValue

    consumed[key, default: 0] += cost
    totalConsumed += cost

    // Reset consecutive failures on successful request
    consecutiveFailures = 0
    if circuitState == .halfOpen {
      // Successful request in half-open state → close circuit
      circuitState = .closed
      LoggingService.shared.network.info("Circuit breaker CLOSED after successful request")
    }

    LoggingService.shared.network.debug(
      "Quota recorded: +\(cost) units for \(key, privacy: .public) (total: \(self.totalConsumed)/\(self.dailyLimit))"
    )
  }

  /// Handle 429 rate limit response (implements exponential backoff and circuit breaker)
  /// - Parameter endpoint: API endpoint that returned 429
  /// - Throws: YouTubeAPIError.rateLimitExceeded or .circuitBreakerOpen
  func handle429Response(endpoint: Endpoint) async throws {
    consecutiveFailures += 1

    LoggingService.shared.network.error(
      "429 Rate Limited - consecutive failure #\(self.consecutiveFailures, privacy: .public)"
    )

    // Check if circuit breaker should open
    if consecutiveFailures >= circuitOpenThreshold {
      circuitState = .open
      circuitOpenedAt = Date()
      LoggingService.shared.network.error(
        "Circuit breaker OPENED after \(self.consecutiveFailures) consecutive 429s"
      )
      throw YouTubeAPIError.circuitBreakerOpen
    }

    // Exponential backoff with max 3 retries
    let retryDelays: [TimeInterval] = [1.0, 2.0, 4.0, 8.0]
    guard consecutiveFailures <= retryDelays.count else {
      LoggingService.shared.network.error("Max retry attempts exceeded (3)")
      throw YouTubeAPIError.rateLimitExceeded
    }

    let delay = retryDelays[min(consecutiveFailures - 1, retryDelays.count - 1)]
    LoggingService.shared.network.warning(
      "Exponential backoff: waiting \(delay, privacy: .public)s before retry (attempt \(self.consecutiveFailures))"
    )

    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
  }

  /// Get current quota statistics
  /// - Returns: QuotaStats with consumption breakdown and circuit state
  func getQuotaStats() -> QuotaStats {
    checkAndResetIfNeeded()

    // Calculate next reset time (midnight PT)
    let calendar = Calendar(identifier: .gregorian)
    let pacificTZ = TimeZone(identifier: "America/Los_Angeles")!
    var components = calendar.dateComponents(in: pacificTZ, from: Date())
    components.hour = 0
    components.minute = 0
    components.second = 0
    components.day! += 1 // Next midnight

    let resetTime = calendar.date(from: components) ?? Date()

    return QuotaStats(
      totalConsumed: totalConsumed,
      dailyLimit: dailyLimit,
      endpointBreakdown: consumed,
      circuitState: circuitState,
      resetTime: resetTime
    )
  }

  /// Reset quota counters (for testing or manual reset)
  func resetQuota() {
    consumed.removeAll()
    totalConsumed = 0
    consecutiveFailures = 0
    circuitState = .closed
    lastResetDate = Date()
    LoggingService.shared.network.info("Quota manually reset to 0/\(self.dailyLimit) units")
  }

  // MARK: - Private Methods

  /// Check if quota should reset (midnight Pacific Time)
  private func checkAndResetIfNeeded() {
    let calendar = Calendar(identifier: .gregorian)
    let pacificTZ = TimeZone(identifier: "America/Los_Angeles")!

    let now = Date()

    // Get midnight (start of day) in Pacific Time for both dates
    var lastResetComponents = calendar.dateComponents(in: pacificTZ, from: lastResetDate)
    lastResetComponents.hour = 0
    lastResetComponents.minute = 0
    lastResetComponents.second = 0
    let lastMidnight = calendar.date(from: lastResetComponents) ?? lastResetDate

    var currentComponents = calendar.dateComponents(in: pacificTZ, from: now)
    currentComponents.hour = 0
    currentComponents.minute = 0
    currentComponents.second = 0
    let currentMidnight = calendar.date(from: currentComponents) ?? now

    // Reset if we've crossed midnight
    if currentMidnight > lastMidnight {
      consumed.removeAll()
      totalConsumed = 0
      consecutiveFailures = 0
      circuitState = .closed
      circuitOpenedAt = nil
      lastResetDate = now

      LoggingService.shared.network.info(
        "Quota budget RESET at midnight PT: 0/\(self.dailyLimit) units"
      )
    }
  }

  /// Check if circuit breaker can recover (after 1 hour in open state)
  private func checkCircuitRecovery() {
    guard circuitState == .open, let openedAt = circuitOpenedAt else {
      return
    }

    let timeSinceOpened = Date().timeIntervalSince(openedAt)
    if timeSinceOpened >= circuitRecoveryDuration {
      circuitState = .halfOpen
      consecutiveFailures = 0
      LoggingService.shared.network.info(
        "Circuit breaker entering HALF-OPEN state after \(Int(timeSinceOpened))s"
      )
    }
  }
}

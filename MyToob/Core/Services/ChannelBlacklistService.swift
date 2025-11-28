//
//  ChannelBlacklistService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/27/25.
//

import Foundation
import OSLog
import SwiftData

/// Centralized service for managing channel blacklist operations.
/// Handles hiding/unhiding channels, library filtering, and compliance logging.
@MainActor
final class ChannelBlacklistService {
  // MARK: - Properties

  private let modelContext: ModelContext

  // MARK: - Initialization

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  // MARK: - Public API

  /// Hide a YouTube channel from the user's library
  /// - Parameters:
  ///   - channelID: The YouTube channel ID to hide
  ///   - channelName: Optional display name of the channel
  ///   - reason: Optional user-provided reason for hiding
  ///   - requiresConfirmation: Whether this entry requires confirmation (default: false after initial confirm)
  /// - Throws: `ChannelBlacklistError` if the operation fails
  func hideChannel(
    channelID: String,
    channelName: String?,
    reason: String?,
    requiresConfirmation: Bool = false
  ) async throws {
    guard !channelID.isEmpty else {
      throw ChannelBlacklistError.channelIDMissing
    }

    // Log warning for unexpected channel ID format
    if !channelID.hasPrefix("UC") || channelID.count != 24 {
      LoggingService.shared.app.warning(
        "Hiding channel with unexpected ID format: \(channelID, privacy: .private)"
      )
    }

    // Check if channel is already hidden
    let existingEntry = try fetchEntry(for: channelID)

    if let existing = existingEntry {
      // Update existing entry
      existing.reason = reason
      existing.channelName = channelName ?? existing.channelName
      existing.requiresConfirmation = requiresConfirmation
      existing.blockedAt = Date()
    } else {
      // Create new entry
      let entry = ChannelBlacklist(
        channelID: channelID,
        reason: reason,
        blockedAt: Date(),
        channelName: channelName,
        requiresConfirmation: requiresConfirmation
      )
      modelContext.insert(entry)
    }

    do {
      try modelContext.save()
    } catch {
      throw ChannelBlacklistError.persistenceFailed(underlying: error)
    }

    // Log compliance event
    ComplianceLogger.shared.logChannelBlock(
      channelID: channelID,
      channelName: channelName,
      reason: reason
    )
  }

  /// Unhide a previously blocked YouTube channel
  /// - Parameter channelID: The YouTube channel ID to unhide
  /// - Throws: `ChannelBlacklistError` if the operation fails
  func unhideChannel(channelID: String) async throws {
    guard !channelID.isEmpty else {
      throw ChannelBlacklistError.channelIDMissing
    }

    guard let entry = try fetchEntry(for: channelID) else {
      // Channel not in blacklist - operation is idempotent, no error
      return
    }

    modelContext.delete(entry)

    do {
      try modelContext.save()
    } catch {
      throw ChannelBlacklistError.persistenceFailed(underlying: error)
    }

    // Log compliance event
    ComplianceLogger.shared.logChannelUnblock(channelID: channelID)
  }

  /// Check if a specific channel is currently hidden
  /// - Parameter channelID: The YouTube channel ID to check
  /// - Returns: `true` if the channel is hidden, `false` otherwise
  func isChannelHidden(_ channelID: String) -> Bool {
    guard !channelID.isEmpty else { return false }

    do {
      return try fetchEntry(for: channelID) != nil
    } catch {
      LoggingService.shared.persistence.error(
        "Failed to check if channel is hidden: \(error.localizedDescription, privacy: .public)"
      )
      return false
    }
  }

  /// Fetch all hidden channels for the management UI
  /// - Returns: Array of `ChannelBlacklist` entries, sorted by blocked date (newest first)
  /// - Throws: `ChannelBlacklistError` if the fetch fails
  func fetchHiddenChannels() throws -> [ChannelBlacklist] {
    let descriptor = FetchDescriptor<ChannelBlacklist>(
      sortBy: [SortDescriptor(\.blockedAt, order: .reverse)]
    )

    do {
      return try modelContext.fetch(descriptor)
    } catch {
      throw ChannelBlacklistError.fetchFailed(underlying: error)
    }
  }

  /// Filter video items to exclude hidden channels
  /// - Parameter items: Array of `VideoItem` to filter
  /// - Returns: Filtered array excluding videos from hidden channels
  func filterVisibleItems(_ items: [VideoItem]) -> [VideoItem] {
    let hiddenChannelIDs: Set<String>

    do {
      let descriptor = FetchDescriptor<ChannelBlacklist>()
      let hiddenChannels = try modelContext.fetch(descriptor)
      hiddenChannelIDs = Set(hiddenChannels.map(\.channelID))
    } catch {
      LoggingService.shared.persistence.error(
        "Failed to fetch hidden channels for filtering: \(error.localizedDescription, privacy: .public)"
      )
      // Return all items if we can't fetch blacklist
      return items
    }

    return items.filter { item in
      // Always show local files (no channelID)
      guard let channelID = item.channelID else { return true }
      // Filter out hidden channels
      return !hiddenChannelIDs.contains(channelID)
    }
  }

  // MARK: - Private Helpers

  /// Fetch a single blacklist entry by channel ID
  private func fetchEntry(for channelID: String) throws -> ChannelBlacklist? {
    let descriptor = FetchDescriptor<ChannelBlacklist>(
      predicate: #Predicate { $0.channelID == channelID }
    )

    let results = try modelContext.fetch(descriptor)
    return results.first
  }
}

// MARK: - Error Types

/// Errors that can occur during channel blacklist operations
enum ChannelBlacklistError: LocalizedError {
  case channelIDMissing
  case persistenceFailed(underlying: Error)
  case fetchFailed(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .channelIDMissing:
      return "Cannot hide channel: missing channel identifier"
    case .persistenceFailed(let error):
      return "Failed to save channel preference: \(error.localizedDescription)"
    case .fetchFailed(let error):
      return "Failed to load hidden channels: \(error.localizedDescription)"
    }
  }
}

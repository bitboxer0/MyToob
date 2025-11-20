//
//  ChannelBlacklist.swift
//  MyToob
//
//  Created by Claude Code (BMad Master)
//

import Foundation
import SwiftData

/// User content moderation preferences.
/// Allows users to hide or block specific YouTube channels from appearing in their library.
/// Part of UGC safeguards required by App Store Guidelines 1.2.
@Model
final class ChannelBlacklist {
  /// YouTube channel ID (unique identifier)
  @Attribute(.unique) var channelID: String

  /// Optional user-provided reason for blocking
  /// Helps users remember why they blocked a channel
  var reason: String?

  /// When this channel was added to the blacklist
  var blockedAt: Date

  /// Channel display name (cached for UI display, may be stale)
  var channelName: String?

  /// Whether to show a confirmation before permanently blocking
  /// Set to false after initial confirmation
  var requiresConfirmation: Bool

  init(
    channelID: String,
    reason: String? = nil,
    blockedAt: Date = Date(),
    channelName: String? = nil,
    requiresConfirmation: Bool = true
  ) {
    self.channelID = channelID
    self.reason = reason
    self.blockedAt = blockedAt
    self.channelName = channelName
    self.requiresConfirmation = requiresConfirmation
  }

  /// Check if a video item should be filtered based on this blacklist entry
  func shouldFilter(_ videoItem: VideoItem) -> Bool {
    guard let itemChannelID = videoItem.channelID else { return false }
    return itemChannelID == self.channelID
  }
}

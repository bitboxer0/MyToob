//
//  CloudKitRecordTypes.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import Foundation

/// Centralized registry of CloudKit record type names.
///
/// Use these constants instead of string literals to avoid typos and ensure
/// consistency between the app code and CloudKit schema.
///
/// ## Usage
///
/// ```swift
/// if recordType == CloudKitRecordTypes.note {
///   // Handle Note-specific logic
/// }
/// ```
enum CloudKitRecordTypes {
  /// Note records for user-created notes attached to videos.
  static let note = "Note"

  /// VideoItem records representing YouTube or local videos.
  static let videoItem = "VideoItem"

  /// ClusterLabel records for AI-generated topic clusters.
  static let clusterLabel = "ClusterLabel"

  /// ChannelBlacklist records for user content moderation.
  static let channelBlacklist = "ChannelBlacklist"

  // Add more record types as they are synced via CloudKit
}

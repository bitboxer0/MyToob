//
//  SyncNotifications.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import Foundation

// MARK: - CloudKit Sync Notifications

extension Notification.Name {
  /// Posted when CloudKit sync conflicts have been resolved.
  ///
  /// UI components can observe this notification to present non-blocking messages
  /// like "Sync completed with N conflicts resolved".
  ///
  /// ## Threading Guarantee
  ///
  /// This notification is **always posted on the main thread**. The guarantee is
  /// enforced by `CloudKitService.postConflictNotification` via:
  /// 1. `CloudKitService` being marked `@MainActor`
  /// 2. `dispatchPrecondition(.onQueue(.main))` which validates at runtime in release builds
  ///
  /// Observers can safely update UI directly without dispatching to main.
  ///
  /// ## UserInfo Keys
  ///
  /// - `CloudKitSyncNotificationKey.count`: Number of conflicts resolved (`Int`)
  /// - `CloudKitSyncNotificationKey.recordTypes`: Types of records affected (`[String]`)
  /// - `CloudKitSyncNotificationKey.recordIDs`: Record names that had conflicts (`[String]`)
  static let cloudKitSyncConflictsResolved = Notification.Name("CloudKitSyncConflictsResolved")
}

// MARK: - Notification Payload Keys

/// Keys for accessing data in CloudKit sync notification userInfo dictionaries.
enum CloudKitSyncNotificationKey {
  /// Number of conflicts that were resolved.
  /// - Type: `Int`
  static let count = "count"

  /// Types of records that had conflicts.
  /// - Type: `[String]`
  static let recordTypes = "recordTypes"

  /// Record names (IDs) of records that had conflicts.
  /// - Type: `[String]`
  static let recordIDs = "recordIDs"
}

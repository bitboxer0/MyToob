//
//  SchemaVersions.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/26/25.
//

import Foundation
import SwiftData

// MARK: - Current Schema

/// The current app schema version.
///
/// Uses the production models: VideoItem, ClusterLabel, Note, ChannelBlacklist.
/// The schema version identifier is used for potential future migrations.
///
/// ## Schema History
/// - V1 (1.0.0): Initial release with VideoItem, ClusterLabel, Note, ChannelBlacklist
/// - V2 (2.0.0): Added `lastAccessedAt` property to VideoItem
///
/// ## Migration Strategy
/// Migration plan is currently disabled since there are no existing users.
/// When migration is needed, re-enable `MyToobMigrationPlan` in MyToobApp.swift
/// and create versioned model classes (VideoItemV1, etc.) as needed.
enum CurrentSchema: VersionedSchema {
  static var versionIdentifier = Schema.Version(2, 0, 0)

  static var models: [any PersistentModel.Type] {
    [VideoItem.self, ClusterLabel.self, Note.self, ChannelBlacklist.self]
  }
}

// MARK: - Schema Convenience

/// The current app schema version typealias for backward compatibility.
typealias CurrentSchemaVersion = CurrentSchema

/// The latest schema for use in ModelContainer initialization.
///
/// Uses the current production models with all features enabled:
/// - VideoItem with `lastAccessedAt` tracking
/// - 512-dimensional embeddings (Apple NLEmbedding)
/// - Full relationship support with Notes
let latestSchema = Schema(versionedSchema: CurrentSchemaVersion.self)

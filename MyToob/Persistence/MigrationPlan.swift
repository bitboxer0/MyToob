//
//  MigrationPlan.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/26/25.
//

import Foundation
import os.log
import SwiftData

/// Migration plan orchestrating schema upgrades from V1 to latest version.
///
/// Usage:
/// ```swift
/// let container = try ModelContainer(
///     for: Schema(versionedSchema: SchemaV2.self),
///     migrationPlan: MyToobMigrationPlan.self,
///     configurations: [modelConfiguration]
/// )
/// ```
///
/// ## Migration Stages
/// - **V1 → V2**: Lightweight migration adding optional `lastAccessedAt` property to VideoItem.
///
/// ## Embedding Dimension Change (384 → 512)
/// The embedding dimension change from 384 (Core ML) to 512 (Apple NLEmbedding) is a
/// semantic change only - the Data storage format remains the same. No schema migration
/// is required. Existing 384-dim embeddings can be regenerated as 512-dim when videos
/// are re-processed by the AppleSentenceEmbeddingService.
enum MyToobMigrationPlan: SchemaMigrationPlan {

  // MARK: - Schema History

  /// All schemas in chronological order (oldest first).
  /// SwiftData uses this to determine the migration path.
  static var schemas: [any VersionedSchema.Type] {
    [SchemaV1.self, SchemaV2.self]
  }

  // MARK: - Migration Stages

  /// All migration stages in order of execution.
  static var stages: [MigrationStage] {
    [migrateV1toV2]
  }

  /// V1 → V2: Lightweight migration adding `lastAccessedAt: Date?` to VideoItem.
  /// - Lightweight because: new property is optional with nil default
  /// - No data transformation required
  /// - SwiftData handles schema update automatically
  static let migrateV1toV2 = MigrationStage.lightweight(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self
  )
}

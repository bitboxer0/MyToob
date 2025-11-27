//
//  MigrationPlan.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/26/25.
//

import Foundation
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
/// ## Future Extensions
/// For complex data transformations, use `MigrationStage.custom`:
/// ```swift
/// static let migrateV2toV3 = MigrationStage.custom(
///     fromVersion: SchemaV2.self,
///     toVersion: SchemaV3.self,
///     willMigrate: { context in
///         // Pre-migration logic (backup, validation)
///     },
///     didMigrate: { context in
///         // Post-migration logic (data transformation, cleanup)
///     }
/// )
/// ```
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

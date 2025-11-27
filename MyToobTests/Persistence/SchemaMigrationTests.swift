//
//  SchemaMigrationTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 11/26/25.
//

import Foundation
import SwiftData
import Testing

@testable import MyToob

@Suite("Schema Migration Tests")
struct SchemaMigrationTests {

  // MARK: - Test Helpers

  /// Creates a V1 container with in-memory configuration for testing.
  private func makeV1Container(inMemory: Bool = true) throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
    return try ModelContainer(
      for: Schema(versionedSchema: SchemaV1.self),
      migrationPlan: MyToobMigrationPlan.self,
      configurations: [config]
    )
  }

  /// Creates a V2 (latest) container with in-memory configuration for testing.
  private func makeV2Container(inMemory: Bool = true) throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
    return try ModelContainer(
      for: Schema(versionedSchema: SchemaV2.self),
      migrationPlan: MyToobMigrationPlan.self,
      configurations: [config]
    )
  }

  /// Creates a V1 container with file-based storage at specified URL.
  private func makeV1Container(at url: URL) throws -> ModelContainer {
    let config = ModelConfiguration(
      schema: Schema(versionedSchema: SchemaV1.self),
      url: url,
      allowsSave: true
    )
    return try ModelContainer(
      for: Schema(versionedSchema: SchemaV1.self),
      migrationPlan: MyToobMigrationPlan.self,
      configurations: [config]
    )
  }

  /// Creates a V2 container with file-based storage at specified URL.
  private func makeV2Container(at url: URL) throws -> ModelContainer {
    let config = ModelConfiguration(
      schema: Schema(versionedSchema: SchemaV2.self),
      url: url,
      allowsSave: true
    )
    return try ModelContainer(
      for: Schema(versionedSchema: SchemaV2.self),
      migrationPlan: MyToobMigrationPlan.self,
      configurations: [config]
    )
  }

  /// Seeds a V1 VideoItem into the given context.
  private func seedV1Video(context: ModelContext, videoID: String = "test_video_123") throws
    -> VideoItem
  {
    let video = VideoItem(
      videoID: videoID,
      title: "Test Video for Migration",
      channelID: "UCtest_channel",
      duration: 300.0,
      watchProgress: 100.0,
      aiTopicTags: ["tag1", "tag2", "tag3"],
      addedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
    context.insert(video)
    try context.save()
    return video
  }

  // MARK: - Test: Migration Plan V1 to V2 Executes

  @Test("Migration plan V1 to V2 executes successfully")
  func testMigrationPlan_V1toV2_executes() async throws {
    // Arrange & Act: Create container targeting V2 with migration plan
    let container = try makeV2Container(inMemory: true)

    // Assert: Container initialized successfully
    let context = ModelContext(container)
    #expect(context.container === container, "Context should reference the created container")

    // Verify we can query V2 models
    let descriptor = FetchDescriptor<VideoItemV2>()
    let results = try context.fetch(descriptor)
    #expect(results.isEmpty, "Fresh container should have no data")
  }

  // MARK: - Test: Lightweight Migration Adds Optional Property

  @Test("Lightweight migration adds optional lastAccessedAt property")
  func testLightweightMigration_addsOptionalProperty() async throws {
    // Arrange: Create temporary file URL for persistent storage
    let tempDirectory = FileManager.default.temporaryDirectory
    let storeURL = tempDirectory.appendingPathComponent(
      "migration_test_\(UUID().uuidString).sqlite")

    defer {
      // Cleanup
      try? FileManager.default.removeItem(at: storeURL)
    }

    // Step 1: Create V1 container and seed data
    let v1Container = try makeV1Container(at: storeURL)
    let v1Context = ModelContext(v1Container)
    _ = try seedV1Video(context: v1Context, videoID: "migration_optional_test")

    // Verify V1 data exists
    let v1Descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "migration_optional_test" }
    )
    let v1Results = try v1Context.fetch(v1Descriptor)
    #expect(v1Results.count == 1, "V1 video should exist")

    // Step 2: Reopen with V2 schema + migration plan
    let v2Container = try makeV2Container(at: storeURL)
    let v2Context = ModelContext(v2Container)

    // Act: Fetch as V2 model
    let v2Descriptor = FetchDescriptor<VideoItemV2>(
      predicate: #Predicate { $0.videoID == "migration_optional_test" }
    )
    let v2Results = try v2Context.fetch(v2Descriptor)

    // Assert: Data migrated and lastAccessedAt defaults to nil
    #expect(v2Results.count == 1, "Migrated video should exist")
    #expect(v2Results.first?.lastAccessedAt == nil, "lastAccessedAt should default to nil")
    #expect(v2Results.first?.title == "Test Video for Migration", "Title should be preserved")
  }

  // MARK: - Test: Data Integrity Across Versions

  @Test("Data integrity preserved across schema versions")
  func testDataIntegrityAcrossVersions() async throws {
    // Arrange: Create temporary file URL
    let tempDirectory = FileManager.default.temporaryDirectory
    let storeURL = tempDirectory.appendingPathComponent(
      "integrity_test_\(UUID().uuidString).sqlite")

    defer {
      try? FileManager.default.removeItem(at: storeURL)
    }

    // Step 1: Seed V1 data with all fields populated
    let v1Container = try makeV1Container(at: storeURL)
    let v1Context = ModelContext(v1Container)

    let originalVideo = VideoItem(
      videoID: "integrity_test_video",
      title: "Integrity Test Video",
      channelID: "UCintegrity_channel",
      duration: 600.0,
      watchProgress: 250.0,
      aiTopicTags: ["swift", "swiftdata", "migration"],
      addedAt: Date(timeIntervalSince1970: 1_700_000_000),
      lastWatchedAt: Date(timeIntervalSince1970: 1_700_100_000)
    )
    v1Context.insert(originalVideo)
    try v1Context.save()

    // Step 2: Migrate to V2
    let v2Container = try makeV2Container(at: storeURL)
    let v2Context = ModelContext(v2Container)

    // Act: Fetch migrated data
    let descriptor = FetchDescriptor<VideoItemV2>(
      predicate: #Predicate { $0.videoID == "integrity_test_video" }
    )
    let results = try v2Context.fetch(descriptor)

    // Assert: All fields preserved
    #expect(results.count == 1, "Video should exist after migration")

    let migrated = results.first!
    #expect(migrated.videoID == "integrity_test_video", "videoID preserved")
    #expect(migrated.title == "Integrity Test Video", "title preserved")
    #expect(migrated.channelID == "UCintegrity_channel", "channelID preserved")
    #expect(migrated.duration == 600.0, "duration preserved")
    #expect(migrated.watchProgress == 250.0, "watchProgress preserved")
    #expect(migrated.aiTopicTags == ["swift", "swiftdata", "migration"], "aiTopicTags preserved")
    #expect(migrated.addedAt.timeIntervalSince1970 == 1_700_000_000, "addedAt preserved")
    #expect(migrated.lastWatchedAt?.timeIntervalSince1970 == 1_700_100_000, "lastWatchedAt preserved")
    #expect(migrated.isLocal == false, "isLocal preserved")

    // Verify computed properties work
    #expect(migrated.identifier == "integrity_test_video", "identifier computed correctly")
    #expect(
      abs(migrated.progressPercentage - (250.0 / 600.0)) < 0.001,
      "progressPercentage computed correctly")
  }

  // MARK: - Test: Migration Rollback on Failure

  @Test("Migration rollback preserves data on failure")
  func testMigrationRollback_OnFailure() async throws {
    // Arrange: Create temporary file URL
    let tempDirectory = FileManager.default.temporaryDirectory
    let storeURL = tempDirectory.appendingPathComponent(
      "rollback_test_\(UUID().uuidString).sqlite")

    defer {
      try? FileManager.default.removeItem(at: storeURL)
    }

    // Step 1: Create V1 container and seed data
    let v1Container = try makeV1Container(at: storeURL)
    let v1Context = ModelContext(v1Container)
    _ = try seedV1Video(context: v1Context, videoID: "rollback_test_video")

    // Define a failing migration plan (local to this test)
    enum FailingMigrationPlan: SchemaMigrationPlan {
      static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
      }

      static var stages: [MigrationStage] {
        [
          MigrationStage.custom(
            fromVersion: SchemaV1.self,
            toVersion: SchemaV2.self,
            willMigrate: { _ in
              // Simulate migration failure
              throw MigrationError.migrationFailed
            },
            didMigrate: nil
          )
        ]
      }
    }

    // Step 2: Attempt migration with failing plan
    let failingConfig = ModelConfiguration(
      schema: Schema(versionedSchema: SchemaV2.self),
      url: storeURL,
      allowsSave: true
    )

    var migrationFailed = false
    do {
      _ = try ModelContainer(
        for: Schema(versionedSchema: SchemaV2.self),
        migrationPlan: FailingMigrationPlan.self,
        configurations: [failingConfig]
      )
    } catch {
      migrationFailed = true
    }

    // Assert: Migration should fail
    #expect(migrationFailed, "Migration should have failed")

    // Step 3: Verify original V1 data is still readable
    let recoveryContainer = try makeV1Container(at: storeURL)
    let recoveryContext = ModelContext(recoveryContainer)

    let descriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "rollback_test_video" }
    )
    let results = try recoveryContext.fetch(descriptor)

    // Assert: Data intact after failed migration
    #expect(results.count == 1, "Original data should be preserved after failed migration")
    #expect(
      results.first?.title == "Test Video for Migration", "Data should be intact after rollback")
  }

  // MARK: - Test: Custom Migration Data Transformation

  @Test("Custom migration can transform data")
  func testCustomMigration_DataTransformation() async throws {
    // Arrange: Create temporary file URL
    let tempDirectory = FileManager.default.temporaryDirectory
    let storeURL = tempDirectory.appendingPathComponent(
      "custom_migration_\(UUID().uuidString).sqlite")

    defer {
      try? FileManager.default.removeItem(at: storeURL)
    }

    // Step 1: Create V1 container and seed data
    let v1Container = try makeV1Container(at: storeURL)
    let v1Context = ModelContext(v1Container)
    _ = try seedV1Video(context: v1Context, videoID: "custom_migration_test")

    // Define a custom migration plan that sets lastAccessedAt = addedAt
    enum TransformingMigrationPlan: SchemaMigrationPlan {
      static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
      }

      static var stages: [MigrationStage] {
        [
          MigrationStage.custom(
            fromVersion: SchemaV1.self,
            toVersion: SchemaV2.self,
            willMigrate: nil,
            didMigrate: { context in
              // Transform data: set lastAccessedAt = addedAt for all videos
              let descriptor = FetchDescriptor<VideoItemV2>()
              let videos = try context.fetch(descriptor)
              for video in videos {
                video.lastAccessedAt = video.addedAt
              }
              try context.save()
            }
          )
        ]
      }
    }

    // Step 2: Apply custom migration
    let transformConfig = ModelConfiguration(
      schema: Schema(versionedSchema: SchemaV2.self),
      url: storeURL,
      allowsSave: true
    )

    let transformContainer = try ModelContainer(
      for: Schema(versionedSchema: SchemaV2.self),
      migrationPlan: TransformingMigrationPlan.self,
      configurations: [transformConfig]
    )
    let transformContext = ModelContext(transformContainer)

    // Act: Fetch transformed data
    let descriptor = FetchDescriptor<VideoItemV2>(
      predicate: #Predicate { $0.videoID == "custom_migration_test" }
    )
    let results = try transformContext.fetch(descriptor)

    // Assert: lastAccessedAt was set to addedAt by custom migration
    #expect(results.count == 1, "Video should exist after custom migration")
    #expect(results.first?.lastAccessedAt != nil, "lastAccessedAt should be set")
    #expect(
      results.first?.lastAccessedAt == results.first?.addedAt,
      "lastAccessedAt should equal addedAt after transformation")
  }
}

// MARK: - Migration Error

/// Custom error for testing migration failures.
enum MigrationError: Error {
  case migrationFailed
}

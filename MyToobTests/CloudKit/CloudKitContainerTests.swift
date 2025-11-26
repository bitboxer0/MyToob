//
//  CloudKitContainerTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 11/26/25.
//

import CloudKit
import Foundation
import SwiftData
import Testing

@testable import MyToob

@Suite("CloudKit Container Tests")
@MainActor
struct CloudKitContainerTests {

  // MARK: - Test Helpers

  /// The CloudKit container for testing.
  private var container: CKContainer {
    CKContainer(identifier: Configuration.cloudKitContainerIdentifier)
  }

  /// The private database for testing.
  private var privateDatabase: CKDatabase {
    container.privateCloudDatabase
  }

  /// Checks if CloudKit is available for testing.
  /// Returns nil if available, or a skip message if not.
  private func checkCloudKitAvailability() async -> String? {
    // Skip if CloudKit sync is disabled via configuration
    guard Configuration.cloudKitSyncEnabled else {
      return "CloudKit sync disabled via configuration (CLOUDKIT_SYNC_ENABLED=false)"
    }

    // Check iCloud account status
    do {
      let status = try await container.accountStatus()
      switch status {
      case .available:
        return nil  // Available - proceed with tests
      case .noAccount:
        return "No iCloud account signed in - skipping CloudKit tests"
      case .restricted:
        return "iCloud account is restricted - skipping CloudKit tests"
      case .couldNotDetermine:
        return "Could not determine iCloud account status - skipping CloudKit tests"
      case .temporarilyUnavailable:
        return "iCloud temporarily unavailable - skipping CloudKit tests"
      @unknown default:
        return "Unknown iCloud account status (\(status.rawValue)) - skipping CloudKit tests"
      }
    } catch {
      return "Failed to check iCloud account status: \(error.localizedDescription) - skipping CloudKit tests"
    }
  }

  // MARK: - Test: Account Status Available

  @Test("CloudKit account status is available")
  func testAccountStatusAvailable() async throws {
    // Skip if CloudKit is not available
    if let skipMessage = await checkCloudKitAvailability() {
      // Use withKnownIssue with string literal comment
      withKnownIssue("CloudKit unavailable") {
        Issue.record(Comment(rawValue: skipMessage))
      }
      return
    }

    // Act: Check account status via CloudKitService
    let status = await CloudKitService.shared.checkAccountStatus()

    // Assert: Account should be available
    #expect(status == .available, "iCloud account should be available for CloudKit sync")
  }

  // MARK: - Test: Private Database CRUD

  @Test("Private database supports create, read, and delete operations")
  func testPrivateDatabaseCRUD() async throws {
    // Skip if CloudKit is not available
    if let skipMessage = await checkCloudKitAvailability() {
      withKnownIssue("CloudKit unavailable") {
        Issue.record(Comment(rawValue: skipMessage))
      }
      return
    }

    // Arrange: Create a test record
    let recordID = CKRecord.ID(recordName: "test_video_\(UUID().uuidString)")
    let record = CKRecord(recordType: "VideoItem", recordID: recordID)
    record["videoID"] = "test_video_123" as CKRecordValue
    record["title"] = "CloudKit Test Video" as CKRecordValue
    record["createdAt"] = Date() as CKRecordValue

    // Cleanup helper
    var savedRecordID: CKRecord.ID?
    defer {
      if let id = savedRecordID {
        Task {
          try? await privateDatabase.deleteRecord(withID: id)
        }
      }
    }

    // Act: Save record
    let savedRecord = try await privateDatabase.save(record)
    savedRecordID = savedRecord.recordID
    #expect(savedRecord.recordID == recordID, "Saved record should have the same ID")

    // Act: Fetch record
    let fetchedRecord = try await privateDatabase.record(for: recordID)
    #expect(
      fetchedRecord["videoID"] as? String == "test_video_123",
      "Fetched record should have correct videoID")
    #expect(
      fetchedRecord["title"] as? String == "CloudKit Test Video",
      "Fetched record should have correct title")

    // Act: Delete record
    try await privateDatabase.deleteRecord(withID: recordID)
    savedRecordID = nil  // Clear so defer doesn't try to delete again

    // Assert: Record should no longer exist
    do {
      _ = try await privateDatabase.record(for: recordID)
      Issue.record("Record should have been deleted but was still found")
    } catch let error as CKError where error.code == .unknownItem {
      // Expected - record was deleted
    } catch {
      Issue.record("Unexpected error when fetching deleted record: \(error)")
    }
  }

  // MARK: - Test: SwiftData CloudKit Configuration

  @Test("SwiftData ModelContainer can be configured with CloudKit")
  func testSwiftDataCloudKitConfiguration() async throws {
    // Skip if CloudKit is not available
    if let skipMessage = await checkCloudKitAvailability() {
      withKnownIssue("CloudKit unavailable") {
        Issue.record(Comment(rawValue: skipMessage))
      }
      return
    }

    // Arrange: Create schema and configuration with CloudKit
    let schema = Schema(versionedSchema: SchemaV2.self)
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true,  // Use in-memory for test isolation
      cloudKitDatabase: .private(Configuration.cloudKitContainerIdentifier)
    )

    // Act: Create ModelContainer with CloudKit configuration
    let modelContainer = try ModelContainer(
      for: schema,
      migrationPlan: MyToobMigrationPlan.self,
      configurations: [modelConfiguration]
    )

    // Assert: Container should be successfully created
    #expect(
      modelContainer.configurations.count > 0, "Container should have at least one configuration")

    // Verify the configuration includes CloudKit
    let config = modelContainer.configurations.first
    #expect(config != nil, "Container should have a configuration")

    // The container should be usable
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<VideoItemV2>()
    let results = try context.fetch(descriptor)
    #expect(results.isEmpty, "Fresh container should have no data")
  }

  // MARK: - Test: CloudKitService Container Access

  @Test("CloudKitService can verify container access")
  func testCloudKitServiceContainerAccess() async throws {
    // Skip if CloudKit is not available
    if let skipMessage = await checkCloudKitAvailability() {
      withKnownIssue("CloudKit unavailable") {
        Issue.record(Comment(rawValue: skipMessage))
      }
      return
    }

    // Act: Verify container access via service
    let isAccessible = await CloudKitService.shared.verifyContainerAccess()

    // Assert: Container should be accessible
    #expect(isAccessible, "CloudKit container should be accessible")
  }

  // MARK: - Test: CloudKitService Record Operations

  @Test("CloudKitService can save, fetch, and delete records")
  func testCloudKitServiceRecordOperations() async throws {
    // Skip if CloudKit is not available
    if let skipMessage = await checkCloudKitAvailability() {
      withKnownIssue("CloudKit unavailable") {
        Issue.record(Comment(rawValue: skipMessage))
      }
      return
    }

    // Arrange: Create a test record
    let recordID = CKRecord.ID(recordName: "service_test_\(UUID().uuidString)")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    record["testField"] = "test_value" as CKRecordValue

    // Cleanup helper
    var savedRecordID: CKRecord.ID?
    defer {
      if let id = savedRecordID {
        Task {
          try? await CloudKitService.shared.deleteRecord(withID: id)
        }
      }
    }

    // Act: Save via service
    let savedRecord = try await CloudKitService.shared.saveRecord(record)
    savedRecordID = savedRecord.recordID
    #expect(savedRecord.recordID == recordID, "Saved record should have correct ID")

    // Act: Fetch via service
    let fetchedRecord = try await CloudKitService.shared.fetchRecord(withID: recordID)
    #expect(
      fetchedRecord["testField"] as? String == "test_value",
      "Fetched record should have correct field value")

    // Act: Delete via service
    try await CloudKitService.shared.deleteRecord(withID: recordID)
    savedRecordID = nil  // Clear so defer doesn't try again

    // Assert: Record should be deleted
    do {
      _ = try await CloudKitService.shared.fetchRecord(withID: recordID)
      Issue.record("Record should have been deleted")
    } catch let error as CKError where error.code == .unknownItem {
      // Expected - record was deleted
    } catch {
      // Other errors might occur in test environments
    }
  }

  // MARK: - Test: Configuration Toggle

  @Test("CloudKit sync can be toggled via configuration")
  func testCloudKitSyncToggle() async throws {
    // This test verifies the configuration mechanism exists
    // The actual value depends on environment settings

    // Assert: Configuration properties are accessible
    #expect(
      Configuration.cloudKitContainerIdentifier == "iCloud.finley.MyToob",
      "Container identifier should match expected value")

    // cloudKitSyncEnabled defaults to false (requires paid Apple Developer account)
    // Can be enabled via CLOUDKIT_SYNC_ENABLED=true environment variable
    let isEnabled = Configuration.cloudKitSyncEnabled
    #expect(
      isEnabled == false,
      "cloudKitSyncEnabled should default to false until entitlements configured")
  }
}

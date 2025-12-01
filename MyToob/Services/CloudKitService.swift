//
//  CloudKitService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/26/25.
//

import CloudKit
import Foundation
import OSLog

/// Service for managing CloudKit container access and sync operations.
///
/// Provides utilities for:
/// - Checking iCloud account availability
/// - Accessing the private CloudKit database
/// - Verifying CloudKit container accessibility
/// - Health check with round-trip latency measurement
/// - Manual sync trigger via `syncNow()`
///
/// Usage:
/// ```swift
/// let service = CloudKitService.shared
/// let status = await service.checkAccountStatus()
/// if status == .available {
///     // CloudKit sync is available
///     let health = try await service.verifyHealth()
///     print("Round-trip latency: \(health.roundTripLatency)s")
/// }
/// ```
@MainActor
final class CloudKitService: CloudKitSyncing {

  // MARK: - Singleton

  /// Shared CloudKitService instance
  static let shared = CloudKitService()

  // MARK: - Types

  /// Result of a CloudKit health check operation.
  struct Health: Sendable {
    /// The CloudKit container identifier being checked.
    public let containerIdentifier: String

    /// Current iCloud account status.
    public let accountStatus: CKAccountStatus

    /// Whether write operations succeeded during the health check.
    public let canWrite: Bool

    /// Round-trip latency for a write/read/delete cycle (seconds).
    /// Zero if health check failed before measuring latency.
    public let roundTripLatency: TimeInterval

    /// Human-readable summary of the health check result.
    public var summary: String {
      if canWrite {
        return "CloudKit healthy - latency: \(String(format: "%.2f", roundTripLatency * 1000))ms"
      } else {
        return "CloudKit unavailable - account status: \(accountStatusDescription)"
      }
    }

    private var accountStatusDescription: String {
      switch accountStatus {
      case .available: return "available"
      case .noAccount: return "no account"
      case .restricted: return "restricted"
      case .couldNotDetermine: return "could not determine"
      case .temporarilyUnavailable: return "temporarily unavailable"
      @unknown default: return "unknown"
      }
    }
  }

  // MARK: - Properties

  /// The CloudKit container for this app
  var container: CKContainer {
    CKContainer(identifier: Configuration.cloudKitContainerIdentifier)
  }

  /// The private database for user data
  var privateDatabase: CKDatabase {
    container.privateCloudDatabase
  }

  // MARK: - Account Status

  /// Current iCloud account status
  private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

  /// Error from last account status check, if any
  private(set) var accountStatusError: Error?

  /// Whether CloudKit is available for sync operations.
  /// Returns true only if account status is `.available` and sync is effectively enabled
  /// (both entitlement gate and user preference).
  var isCloudKitAvailable: Bool {
    accountStatus == .available && SyncSettingsStore.shared.effectiveCloudKitEnabled
  }

  // MARK: - Initialization

  private init() {}

  // MARK: - Account Status Methods

  /// Checks the current iCloud account status.
  ///
  /// - Returns: The current `CKAccountStatus`
  /// - Note: Updates internal `accountStatus` and `accountStatusError` properties
  @discardableResult
  func checkAccountStatus() async -> CKAccountStatus {
    do {
      let status = try await container.accountStatus()
      accountStatus = status
      accountStatusError = nil

      LoggingService.shared.cloudKit.info(
        "CloudKit account status: \(self.statusDescription(status), privacy: .public)")

      return status
    } catch {
      accountStatus = .couldNotDetermine
      accountStatusError = error

      LoggingService.shared.cloudKit.error(
        "Failed to check CloudKit account status: \(error.localizedDescription, privacy: .public)")

      return .couldNotDetermine
    }
  }

  /// Returns a human-readable description of the account status.
  func statusDescription(_ status: CKAccountStatus) -> String {
    switch status {
    case .available:
      return "Available"
    case .noAccount:
      return "No iCloud Account"
    case .restricted:
      return "Restricted"
    case .couldNotDetermine:
      return "Could Not Determine"
    case .temporarilyUnavailable:
      return "Temporarily Unavailable"
    @unknown default:
      return "Unknown (\(status.rawValue))"
    }
  }

  // MARK: - Container Verification

  /// Verifies that the CloudKit container is accessible by performing a simple operation.
  ///
  /// - Returns: `true` if the container is accessible, `false` otherwise
  /// - Note: This performs a lightweight zone fetch to verify connectivity
  func verifyContainerAccess() async -> Bool {
    // Gate by effective enablement (both entitlement and user preference)
    guard SyncSettingsStore.shared.effectiveCloudKitEnabled else {
      LoggingService.shared.cloudKit.debug("CloudKit sync disabled - skipping container verification")
      return false
    }

    do {
      // Attempt to fetch default zone to verify access
      _ = try await privateDatabase.allRecordZones()
      LoggingService.shared.cloudKit.info("CloudKit container access verified successfully")
      return true
    } catch {
      LoggingService.shared.cloudKit.error(
        "CloudKit container access verification failed: \(error.localizedDescription, privacy: .public)"
      )
      return false
    }
  }

  // MARK: - Sync Operations

  /// Triggers a manual sync operation.
  ///
  /// This method performs a lightweight CloudKit operation to verify connectivity
  /// and prompt SwiftData/CloudKit synchronization. It fetches all record zones
  /// as a sync "tickle."
  ///
  /// - Returns: `true` if the sync operation completed successfully, `false` otherwise
  func syncNow() async -> Bool {
    // Gate by effective enablement
    guard SyncSettingsStore.shared.effectiveCloudKitEnabled else {
      LoggingService.shared.cloudKit.debug("Sync disabled - syncNow skipped")
      return false
    }

    LoggingService.shared.sync.info("Manual sync triggered")

    do {
      // Perform a lightweight operation to tickle CloudKit/SwiftData sync
      _ = try await privateDatabase.allRecordZones()
      LoggingService.shared.cloudKit.info("Sync Now completed (zones fetched)")
      return true
    } catch {
      LoggingService.shared.cloudKit.error(
        "Sync Now failed: \(error.localizedDescription, privacy: .public)")
      return false
    }
  }

  // MARK: - Health Check

  /// Performs a comprehensive health check of CloudKit connectivity.
  ///
  /// The health check:
  /// 1. Verifies iCloud account status
  /// 2. Creates a transient `SyncHealth` record
  /// 3. Fetches the record back
  /// 4. Deletes the record
  /// 5. Measures round-trip latency
  ///
  /// - Returns: A `Health` struct containing the results
  /// - Throws: `CKError` if any CloudKit operation fails
  ///
  /// - Note: The transient record is always cleaned up, leaving no residue in the user's private database.
  func verifyHealth() async throws -> Health {
    let start = Date()
    let containerID = Configuration.cloudKitContainerIdentifier

    // Check account status first
    let status = await checkAccountStatus()

    guard status == .available else {
      LoggingService.shared.cloudKit.info(
        "CloudKit health check skipped - account status: \(self.statusDescription(status), privacy: .public)"
      )
      return Health(
        containerIdentifier: containerID,
        accountStatus: status,
        canWrite: false,
        roundTripLatency: 0
      )
    }

    // Create a transient health check record
    let healthRecordID = CKRecord.ID(recordName: "SyncHealth_\(UUID().uuidString)")
    let healthRecord = CKRecord(recordType: "SyncHealth", recordID: healthRecordID)
    healthRecord["timestamp"] = Date() as CKRecordValue
    healthRecord["checkID"] = UUID().uuidString as CKRecordValue

    do {
      // Write → Read → Delete cycle
      _ = try await saveRecord(healthRecord)
      _ = try await fetchRecord(withID: healthRecordID)
      try await deleteRecord(withID: healthRecordID)

      let latency = Date().timeIntervalSince(start)

      LoggingService.shared.cloudKit.info(
        "CloudKit health check passed - round-trip latency: \(String(format: "%.2f", latency * 1000), privacy: .public)ms"
      )

      return Health(
        containerIdentifier: containerID,
        accountStatus: status,
        canWrite: true,
        roundTripLatency: latency
      )
    } catch {
      LoggingService.shared.cloudKit.error(
        "CloudKit health check failed: \(error.localizedDescription, privacy: .public)")

      // Attempt cleanup even on failure
      try? await deleteRecord(withID: healthRecordID)

      throw error
    }
  }

  // MARK: - User Record

  /// Fetches the current user's CloudKit record ID.
  ///
  /// - Returns: The user's `CKRecord.ID`
  /// - Throws: `CKError` if the fetch fails
  func fetchUserRecordID() async throws -> CKRecord.ID {
    let userRecordID = try await container.userRecordID()
    LoggingService.shared.cloudKit.debug(
      "Fetched user record ID: \(userRecordID.recordName, privacy: .private)")
    return userRecordID
  }

  // MARK: - Record Operations

  /// Saves a record to the private database.
  ///
  /// - Parameter record: The record to save
  /// - Returns: The saved record
  /// - Throws: `CKError` if the save fails
  func saveRecord(_ record: CKRecord) async throws -> CKRecord {
    let savedRecord = try await privateDatabase.save(record)
    LoggingService.shared.cloudKit.debug(
      "Saved record: \(savedRecord.recordID.recordName, privacy: .public)")
    return savedRecord
  }

  /// Fetches a record from the private database.
  ///
  /// - Parameter recordID: The ID of the record to fetch
  /// - Returns: The fetched record
  /// - Throws: `CKError` if the fetch fails
  func fetchRecord(withID recordID: CKRecord.ID) async throws -> CKRecord {
    let record = try await privateDatabase.record(for: recordID)
    LoggingService.shared.cloudKit.debug(
      "Fetched record: \(recordID.recordName, privacy: .public)")
    return record
  }

  /// Deletes a record from the private database.
  ///
  /// - Parameter recordID: The ID of the record to delete
  /// - Throws: `CKError` if the delete fails
  func deleteRecord(withID recordID: CKRecord.ID) async throws {
    try await privateDatabase.deleteRecord(withID: recordID)
    LoggingService.shared.cloudKit.debug(
      "Deleted record: \(recordID.recordName, privacy: .public)")
  }
}

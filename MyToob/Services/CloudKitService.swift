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

  // MARK: - Constants

  /// Maximum number of retry attempts for cascading conflicts.
  /// This prevents infinite loops when concurrent writes keep causing conflicts.
  private static let maxConflictRetryAttempts = 3

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

  /// Result of a batch save operation with partial failure support.
  struct BatchSaveResult {
    /// Records that were successfully saved.
    let savedRecords: [CKRecord]

    /// Errors that occurred during saving, keyed by record ID.
    let failedRecords: [CKRecord.ID: Error]

    /// Number of conflicts that were resolved.
    let conflictsResolved: Int

    /// Record types that had conflicts.
    let conflictRecordTypes: Set<String>

    /// Whether all records were saved successfully.
    var isComplete: Bool { failedRecords.isEmpty }
  }

  // MARK: - Properties

  /// Shared conflict resolver instance, reused by all save flows.
  /// Stateless but reduces redundant allocations.
  private let resolver = CloudKitConflictResolver()

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

  // MARK: - Conflict-Aware Record Operations

  /// Saves a record with automatic conflict resolution.
  ///
  /// If a `serverRecordChanged` conflict occurs, this method:
  /// 1. Resolves the conflict using Last-Write-Wins by timestamp
  /// 2. For Note records, creates a "conflict copy" of the losing version
  /// 3. Logs the resolution
  /// 4. Optionally posts a notification for UI to display
  ///
  /// Includes retry logic with max attempts to handle cascading conflicts
  /// (when saving the resolved record causes another conflict).
  ///
  /// - Parameters:
  ///   - record: The record to save
  ///   - notify: Whether to post a notification if conflicts are resolved (default: true)
  /// - Returns: The saved (possibly conflict-resolved) record
  /// - Throws: `CKError` if the save fails for non-conflict reasons or max retries exceeded
  func saveRecordResolvingConflicts(_ record: CKRecord, notify: Bool = true) async throws
    -> CKRecord
  {
    do {
      return try await saveRecord(record)
    } catch let error as CKError where error.code == .serverRecordChanged {
      return try await resolveAndSaveConflict(error: error, notify: notify, attempt: 1)
    }
  }

  /// Saves multiple records with automatic conflict resolution and partial failure handling.
  ///
  /// Records are saved individually with conflict resolution. Conflict copies
  /// (e.g., Note conflict copies) are batched and saved together at the end
  /// for efficiency. A single aggregated notification is posted if any
  /// conflicts occurred.
  ///
  /// ## Partial Failure Handling
  ///
  /// If some records fail to save, this method continues with remaining records
  /// and returns a `BatchSaveResult` containing both successes and failures.
  /// Callers can inspect `failedRecords` to handle partial failures appropriately.
  ///
  /// - Parameters:
  ///   - records: The records to save
  ///   - notify: Whether to post a notification if conflicts are resolved (default: true)
  /// - Returns: `BatchSaveResult` containing saved records, failed records, and conflict stats
  func saveRecordsResolvingConflictsWithResult(_ records: [CKRecord], notify: Bool = true) async
    -> BatchSaveResult
  {
    var savedRecords: [CKRecord] = []
    var failedRecords: [CKRecord.ID: Error] = [:]
    var conflictCount = 0
    var conflictRecordTypes: Set<String> = []
    var conflictRecordIDs: [String] = []
    var pendingConflictCopies: [CKRecord] = []

    for record in records {
      do {
        let saved = try await saveRecordWithRetry(
          record,
          resolver: resolver,
          conflictCount: &conflictCount,
          conflictRecordTypes: &conflictRecordTypes,
          conflictRecordIDs: &conflictRecordIDs,
          pendingConflictCopies: &pendingConflictCopies
        )
        savedRecords.append(saved)
      } catch {
        failedRecords[record.recordID] = error
        LoggingService.shared.cloudKit.error(
          "Failed to save record \(record.recordID.recordName, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
      }
    }

    // Batch save all conflict copies, accumulating failures
    for copy in pendingConflictCopies {
      do {
        let savedCopy = try await saveRecord(copy)
        savedRecords.append(savedCopy)
        LoggingService.shared.cloudKit.debug(
          "Saved conflict copy: \(savedCopy.recordID.recordName, privacy: .public)")
      } catch {
        failedRecords[copy.recordID] = error
        LoggingService.shared.cloudKit.error(
          "Failed to save conflict copy \(copy.recordID.recordName, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
      }
    }

    // Post aggregated notification if conflicts occurred
    if notify && conflictCount > 0 {
      postConflictNotification(
        count: conflictCount,
        recordTypes: Array(conflictRecordTypes),
        recordIDs: conflictRecordIDs
      )
    }

    return BatchSaveResult(
      savedRecords: savedRecords,
      failedRecords: failedRecords,
      conflictsResolved: conflictCount,
      conflictRecordTypes: conflictRecordTypes
    )
  }

  /// Saves multiple records with automatic conflict resolution.
  ///
  /// This is a convenience wrapper around `saveRecordsResolvingConflictsWithResult`
  /// that throws on any failure for simpler error handling when partial success
  /// is not acceptable.
  ///
  /// - Parameters:
  ///   - records: The records to save
  ///   - notify: Whether to post a notification if conflicts are resolved (default: true)
  /// - Returns: Array of saved records (includes conflict copies if any)
  /// - Throws: First error encountered if any record fails to save
  func saveRecordsResolvingConflicts(_ records: [CKRecord], notify: Bool = true) async throws
    -> [CKRecord]
  {
    let result = await saveRecordsResolvingConflictsWithResult(records, notify: notify)

    // If any records failed, throw the first error
    if let firstFailure = result.failedRecords.first {
      throw firstFailure.value
    }

    return result.savedRecords
  }

  // MARK: - Conflict Resolution Helpers

  /// Saves a record with retry logic for cascading conflicts.
  ///
  /// - Parameters:
  ///   - record: The record to save
  ///   - resolver: The conflict resolver to use
  ///   - conflictCount: Counter for conflicts resolved (mutated)
  ///   - conflictRecordTypes: Set of record types with conflicts (mutated)
  ///   - conflictRecordIDs: List of record IDs with conflicts (mutated)
  ///   - pendingConflictCopies: Array of conflict copies to save later (mutated)
  ///   - attempt: Current attempt number (for retry logic)
  /// - Returns: The saved record
  private func saveRecordWithRetry(
    _ record: CKRecord,
    resolver: CloudKitConflictResolver,
    conflictCount: inout Int,
    conflictRecordTypes: inout Set<String>,
    conflictRecordIDs: inout [String],
    pendingConflictCopies: inout [CKRecord],
    attempt: Int = 1
  ) async throws -> CKRecord {
    do {
      return try await saveRecord(record)
    } catch let error as CKError where error.code == .serverRecordChanged {
      guard attempt <= Self.maxConflictRetryAttempts else {
        LoggingService.shared.cloudKit.error(
          "Max conflict retry attempts (\(Self.maxConflictRetryAttempts, privacy: .public)) exceeded for record: \(record.recordID.recordName, privacy: .public)"
        )
        throw error
      }

      // Build resolution plan
      let plan = try resolver.makeResolutionPlan(from: error)

      // Log the resolution
      LoggingService.shared.sync.notice(
        "Resolved conflict (attempt \(attempt, privacy: .public)) for \(plan.affectedRecordType, privacy: .public), recordID: \(plan.resolvedRecordForOriginalID.recordID.recordName, privacy: .public), loser: \(plan.conflictLoserDescription, privacy: .public)"
      )
      LoggingService.shared.cloudKit.debug(
        "Conflict detail: \(plan.description, privacy: .public)")

      // Recursively try to save the resolved winner
      let savedWinner = try await saveRecordWithRetry(
        plan.resolvedRecordForOriginalID,
        resolver: resolver,
        conflictCount: &conflictCount,
        conflictRecordTypes: &conflictRecordTypes,
        conflictRecordIDs: &conflictRecordIDs,
        pendingConflictCopies: &pendingConflictCopies,
        attempt: attempt + 1
      )

      LoggingService.shared.cloudKit.debug(
        "Saved conflict winner: \(savedWinner.recordID.recordName, privacy: .public)")

      // Collect conflict copies for batched save
      pendingConflictCopies.append(contentsOf: plan.additionalRecordsToCreate)

      conflictCount += 1
      conflictRecordTypes.insert(record.recordType)
      conflictRecordIDs.append(record.recordID.recordName)

      return savedWinner
    }
  }

  /// Resolves a conflict error and saves the resolved record with retry logic.
  ///
  /// - Parameters:
  ///   - error: The `serverRecordChanged` error to resolve
  ///   - notify: Whether to post a notification
  ///   - attempt: Current attempt number (for retry logic)
  /// - Returns: The saved resolved record
  private func resolveAndSaveConflict(
    error: CKError,
    notify: Bool,
    attempt: Int
  ) async throws -> CKRecord {
    guard attempt <= Self.maxConflictRetryAttempts else {
      LoggingService.shared.cloudKit.error(
        "Max conflict retry attempts (\(Self.maxConflictRetryAttempts, privacy: .public)) exceeded"
      )
      throw error
    }

    let plan = try resolver.makeResolutionPlan(from: error)

    // Log the resolution
    LoggingService.shared.sync.notice(
      "Resolved conflict (attempt \(attempt, privacy: .public)) for \(plan.affectedRecordType, privacy: .public), recordID: \(plan.resolvedRecordForOriginalID.recordID.recordName, privacy: .public), loser: \(plan.conflictLoserDescription, privacy: .public)"
    )
    LoggingService.shared.cloudKit.debug(
      "Conflict detail: \(plan.description, privacy: .public)")

    // Save the resolved record with retry for cascading conflicts
    let savedWinner: CKRecord
    do {
      savedWinner = try await saveRecord(plan.resolvedRecordForOriginalID)
    } catch let cascadingError as CKError where cascadingError.code == .serverRecordChanged {
      // Cascading conflict - retry with incremented attempt counter
      return try await resolveAndSaveConflict(
        error: cascadingError,
        notify: notify,
        attempt: attempt + 1
      )
    }

    LoggingService.shared.cloudKit.debug(
      "Saved conflict winner: \(savedWinner.recordID.recordName, privacy: .public)")

    // Save any additional records (e.g., Note conflict copies)
    // Don't throw after winner is saved - aligns with batch behavior (partial success)
    for copy in plan.additionalRecordsToCreate {
      do {
        let savedCopy = try await saveRecord(copy)
        LoggingService.shared.cloudKit.debug(
          "Saved conflict copy: \(savedCopy.recordID.recordName, privacy: .public)")
      } catch {
        LoggingService.shared.cloudKit.error(
          "Failed to save conflict copy \(copy.recordID.recordName, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
        // Intentionally not throwing — winner already saved
      }
    }

    // Post notification if requested
    if notify {
      postConflictNotification(
        count: 1,
        recordTypes: [plan.affectedRecordType],
        recordIDs: [plan.resolvedRecordForOriginalID.recordID.recordName]
      )
    }

    return savedWinner
  }

  /// Posts a notification about resolved conflicts on the main thread.
  ///
  /// This method is guaranteed to post on the main thread because:
  /// 1. `CloudKitService` is marked `@MainActor`
  /// 2. A dispatch precondition verifies main thread execution at runtime (including release builds)
  ///
  /// - Parameters:
  ///   - count: Number of conflicts resolved
  ///   - recordTypes: Types of records that had conflicts
  ///   - recordIDs: Record names that had conflicts
  private func postConflictNotification(
    count: Int,
    recordTypes: [String],
    recordIDs: [String]
  ) {
    // Verify we're on the main thread (should always be true due to @MainActor)
    // Use dispatchPrecondition for release-build safety instead of assert
    dispatchPrecondition(condition: .onQueue(.main))

    NotificationCenter.default.post(
      name: .cloudKitSyncConflictsResolved,
      object: nil,
      userInfo: [
        CloudKitSyncNotificationKey.count: count,
        CloudKitSyncNotificationKey.recordTypes: recordTypes,
        CloudKitSyncNotificationKey.recordIDs: recordIDs,
      ]
    )

    LoggingService.shared.sync.info(
      "Posted conflict notification: \(count, privacy: .public) conflict(s) in \(recordTypes, privacy: .public)"
    )
  }
}

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
///
/// Usage:
/// ```swift
/// let service = CloudKitService.shared
/// let status = await service.checkAccountStatus()
/// if status == .available {
///     // CloudKit sync is available
/// }
/// ```
actor CloudKitService {

  // MARK: - Singleton

  /// Shared CloudKitService instance
  static let shared = CloudKitService()

  // MARK: - Properties

  /// The CloudKit container for this app
  nonisolated var container: CKContainer {
    CKContainer(identifier: Configuration.cloudKitContainerIdentifier)
  }

  /// The private database for user data
  nonisolated var privateDatabase: CKDatabase {
    container.privateCloudDatabase
  }

  // MARK: - Account Status

  /// Current iCloud account status
  private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

  /// Error from last account status check, if any
  private(set) var accountStatusError: Error?

  /// Whether CloudKit is available for sync operations.
  /// Returns true only if account status is `.available` and sync is enabled.
  var isCloudKitAvailable: Bool {
    accountStatus == .available && Configuration.cloudKitSyncEnabled
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
  nonisolated func statusDescription(_ status: CKAccountStatus) -> String {
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
    guard Configuration.cloudKitSyncEnabled else {
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

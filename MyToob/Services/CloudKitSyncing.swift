//
//  CloudKitSyncing.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import CloudKit
import Foundation

/// Protocol defining CloudKit sync operations for dependency injection.
///
/// This protocol abstracts CloudKit operations to enable:
/// - Unit testing with mock implementations
/// - Consistent interface for the SyncStatusViewModel
/// - Decoupling of UI from CloudKit implementation details
///
/// Usage:
/// ```swift
/// // Production code uses CloudKitService
/// let viewModel = SyncStatusViewModel(service: CloudKitService.shared)
///
/// // Tests use a mock
/// let mockService = MockCloudKitService()
/// let testViewModel = SyncStatusViewModel(service: mockService)
/// ```
@MainActor
protocol CloudKitSyncing: AnyObject {

  /// Whether CloudKit is currently available for sync operations.
  ///
  /// Returns `true` if:
  /// - iCloud account status is `.available`
  /// - CloudKit sync is enabled (both entitlement and user preference)
  var isCloudKitAvailable: Bool { get }

  /// Current iCloud account status from the last check.
  var accountStatus: CKAccountStatus { get }

  /// Error from the last account status check, if any.
  var accountStatusError: Error? { get }

  /// Checks the current iCloud account status.
  ///
  /// This method queries the CloudKit container for the account status
  /// and updates the `accountStatus` property.
  ///
  /// - Returns: The current `CKAccountStatus`
  @discardableResult
  func checkAccountStatus() async -> CKAccountStatus

  /// Returns a human-readable description of the given account status.
  ///
  /// - Parameter status: The CloudKit account status to describe
  /// - Returns: A localized description string
  func statusDescription(_ status: CKAccountStatus) -> String

  /// Verifies that the CloudKit container is accessible.
  ///
  /// Performs a lightweight operation (zone fetch) to verify connectivity.
  ///
  /// - Returns: `true` if the container is accessible, `false` otherwise
  func verifyContainerAccess() async -> Bool

  /// Triggers a manual sync operation.
  ///
  /// This is a user-initiated action to force a sync check/refresh.
  /// The actual behavior may vary based on sync engine implementation.
  ///
  /// - Returns: `true` if the sync operation completed successfully
  func syncNow() async -> Bool
}

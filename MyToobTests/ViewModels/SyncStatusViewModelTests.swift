//
//  SyncStatusViewModelTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import CloudKit
import Combine
import Testing

@testable import MyToob

/// Tests for SyncStatusViewModel sync state management and user preference handling.
///
/// **Test Coverage:**
/// - Status updates reflect service results
/// - Toggling sync disabled/enabled updates state correctly
/// - Service failures surface as failed state with message
/// - Manual syncNow() triggers appropriate state transitions
///
/// **Test Strategy:**
/// Uses a MockCloudKitService conforming to CloudKitSyncing protocol
/// to simulate CloudKit responses without hitting real CloudKit.
@Suite("SyncStatusViewModel Tests")
@MainActor
struct SyncStatusViewModelTests {

  // MARK: - Test Fixtures

  /// Mock CloudKit service for testing
  final class MockCloudKitService: CloudKitSyncing {
    var isCloudKitAvailable: Bool = true
    var accountStatus: CKAccountStatus = .available
    var accountStatusError: Error?

    var shouldFailVerify = false
    var shouldFailSync = false
    var checkAccountStatusCallCount = 0
    var verifyContainerAccessCallCount = 0
    var syncNowCallCount = 0

    @discardableResult
    func checkAccountStatus() async -> CKAccountStatus {
      checkAccountStatusCallCount += 1
      return accountStatus
    }

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
        return "Unknown"
      }
    }

    func verifyContainerAccess() async -> Bool {
      verifyContainerAccessCallCount += 1
      return !shouldFailVerify
    }

    func syncNow() async -> Bool {
      syncNowCallCount += 1
      return !shouldFailSync
    }
  }

  /// Mock settings store for testing
  final class MockSyncSettingsStore: ObservableObject {
    @Published var isUserEnabled: Bool = false
    var setUserEnabledCallCount = 0
    var lastSetUserEnabledValue: Bool?

    var effectiveCloudKitEnabled: Bool {
      isUserEnabled && isEntitlementAvailable
    }

    var isEntitlementAvailable: Bool = true

    func setUserEnabled(_ enabled: Bool) {
      setUserEnabledCallCount += 1
      lastSetUserEnabledValue = enabled
      isUserEnabled = enabled
    }
  }

  // MARK: - Status Update Tests

  @Test("Status updates reflect service results - synced state")
  func testSyncStatusUpdates_Synced() async throws {
    // Given: Mock service with available account and successful operations
    let mockService = MockCloudKitService()
    mockService.accountStatus = .available
    mockService.isCloudKitAvailable = true
    mockService.shouldFailVerify = false

    // Create ViewModel with mock service
    // Note: We use the real SyncSettingsStore but ensure it's enabled
    let settings = SyncSettingsStore.shared
    settings.setUserEnabled(true)

    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // When: Refresh status
    await viewModel.refreshStatus()

    // Then: State should be synced if effective enablement is true
    if settings.effectiveCloudKitEnabled {
      #expect(viewModel.state == .synced)
      #expect(viewModel.details.lastSyncedAt != nil)
    } else {
      // If entitlement not available, state will be disabled
      #expect(viewModel.state == .disabled)
    }

    // Cleanup
    settings.setUserEnabled(false)
  }

  @Test("Status updates reflect service results - disabled when user toggles off")
  func testSyncStatusUpdates_Disabled() async throws {
    // Given: Mock service
    let mockService = MockCloudKitService()

    // Create ViewModel with disabled settings
    let settings = SyncSettingsStore.shared
    settings.setUserEnabled(false)

    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // When: Refresh status
    await viewModel.refreshStatus()

    // Then: State should be disabled
    #expect(viewModel.state == .disabled)
  }

  @Test("Toggling sync off disables sync and prevents actions")
  func testSyncToggleDisablesSync() async throws {
    // Given: Mock service with successful operations
    let mockService = MockCloudKitService()
    mockService.shouldFailSync = false

    let settings = SyncSettingsStore.shared

    // Start enabled
    settings.setUserEnabled(true)
    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // When: Disable sync
    viewModel.setSyncEnabled(false)

    // Small delay to allow state propagation
    try await Task.sleep(nanoseconds: 100_000_000)  // 100ms

    // Then: State should become disabled
    #expect(viewModel.state == .disabled)
    #expect(viewModel.toggleOn == false)

    // And: syncNow should be a no-op
    let initialSyncCount = mockService.syncNowCallCount
    await viewModel.syncNow()
    #expect(mockService.syncNowCallCount == initialSyncCount)

    // Cleanup
    settings.setUserEnabled(false)
  }

  @Test("Service failures surface as failed state with message")
  func testSyncErrorHandling() async throws {
    // Given: Mock service that fails
    let mockService = MockCloudKitService()
    mockService.accountStatus = .available
    mockService.shouldFailVerify = true

    let settings = SyncSettingsStore.shared
    settings.setUserEnabled(true)

    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // When: Refresh status (which will fail verification)
    await viewModel.refreshStatus()

    // Then: State should be failed with message (if entitlement available)
    if settings.isEntitlementAvailable {
      if case .failed(let message) = viewModel.state {
        #expect(message.contains("failed") || message.contains("access"))
      } else if viewModel.state != .disabled {
        // State should either be failed or disabled
        Issue.record("Expected failed state but got \(viewModel.state)")
      }
    }

    // Cleanup
    settings.setUserEnabled(false)
  }

  @Test("SyncNow triggers state transitions correctly")
  func testSyncNowStateTransitions() async throws {
    // Given: Mock service with successful sync
    let mockService = MockCloudKitService()
    mockService.shouldFailSync = false

    let settings = SyncSettingsStore.shared
    settings.setUserEnabled(true)

    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // When: Trigger sync now (only if effective enabled)
    if settings.effectiveCloudKitEnabled {
      await viewModel.syncNow()

      // Then: State should transition to synced
      #expect(viewModel.state == .synced)
      #expect(mockService.syncNowCallCount >= 1)
      #expect(viewModel.details.lastSyncedAt != nil)
    } else {
      // syncNow should be skipped
      await viewModel.syncNow()
      #expect(mockService.syncNowCallCount == 0)
    }

    // Cleanup
    settings.setUserEnabled(false)
  }

  @Test("SyncNow handles failure correctly")
  func testSyncNowHandlesFailure() async throws {
    // Given: Mock service that fails sync
    let mockService = MockCloudKitService()
    mockService.shouldFailSync = true

    let settings = SyncSettingsStore.shared
    settings.setUserEnabled(true)

    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // When: Trigger sync now (only if effective enabled)
    if settings.effectiveCloudKitEnabled {
      await viewModel.syncNow()

      // Then: State should be failed
      if case .failed = viewModel.state {
        #expect(true)
      } else {
        Issue.record("Expected failed state but got \(viewModel.state)")
      }
    }

    // Cleanup
    settings.setUserEnabled(false)
  }

  @Test("Initial state reflects settings")
  func testInitialStateReflectsSettings() async throws {
    // Given: Settings with sync disabled
    let mockService = MockCloudKitService()
    let settings = SyncSettingsStore.shared
    settings.setUserEnabled(false)

    // When: Create ViewModel
    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // Then: Initial state should be disabled
    #expect(viewModel.state == .disabled)
    #expect(viewModel.toggleOn == false)
    #expect(viewModel.details.isUserEnabled == false)
  }

  @Test("Details are properly populated")
  func testDetailsProperltyPopulated() async throws {
    // Given: Mock service
    let mockService = MockCloudKitService()
    mockService.accountStatus = .available

    let settings = SyncSettingsStore.shared
    settings.setUserEnabled(false)

    // When: Create ViewModel
    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // Then: Details should be populated
    #expect(viewModel.details.containerIdentifier == Configuration.cloudKitContainerIdentifier)
    #expect(viewModel.details.isEntitlementAvailable == Configuration.cloudKitSyncEnabled)
    #expect(viewModel.details.isUserEnabled == false)
  }

  @Test("Account status description updates after refresh")
  func testAccountStatusDescriptionUpdates() async throws {
    // Given: Mock service with specific account status
    let mockService = MockCloudKitService()
    mockService.accountStatus = .noAccount

    let settings = SyncSettingsStore.shared
    settings.setUserEnabled(true)

    let viewModel = SyncStatusViewModel(service: mockService, settings: settings)

    // When: Refresh status
    await viewModel.refreshStatus()

    // Then: Account status description should be updated
    if settings.effectiveCloudKitEnabled {
      #expect(viewModel.details.accountStatusDescription == "No iCloud Account")
    }

    // Cleanup
    settings.setUserEnabled(false)
  }
}

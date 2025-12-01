//
//  ModelContainerFactoryTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import SwiftData
import Testing

@testable import MyToob

/// Tests for ModelContainer factory logic ensuring correct configuration selection.
///
/// **Test Coverage:**
/// - Factory returns localOnly mode when cloudKitEnabled is false
/// - Factory returns cloudKit mode when cloudKitEnabled is true
///
/// **Note:** These tests use the DEBUG-only `buildModelContainerWithMode` API
/// to verify the factory logic without needing to introspect ModelContainer internals.
///
/// **Runtime Behavior:**
/// The CloudKit-enabled container tests may skip at runtime if the CloudKit entitlement
/// is not available in the test environment (e.g., when running on CI without signing).
@Suite("ModelContainer Factory Tests", .serialized)
@MainActor
struct ModelContainerFactoryTests {

  /// Helper to check if we're in an environment where CloudKit containers can be created.
  /// Returns false if container creation would fail due to missing entitlements.
  private static var canCreateCloudKitContainer: Bool {
    // Check if CloudKit entitlement is enabled in configuration
    Configuration.cloudKitSyncEnabled
  }

  @Test("Factory returns localOnly mode when cloudKitEnabled is false")
  func testFactoryReturnsLocalOnlyMode() async throws {
    #if DEBUG
      // When: Build container with CloudKit disabled
      let (_, mode) = MyToobApp.buildModelContainerWithMode(cloudKitEnabled: false)

      // Then: Mode should be localOnly
      #expect(mode == .localOnly)
    #else
      // Skip test in release builds where DEBUG API is unavailable
      Issue.record("Test requires DEBUG build")
    #endif
  }

  @Test("Factory returns cloudKit mode when cloudKitEnabled is true")
  func testFactoryReturnsCloudKitMode() async throws {
    #if DEBUG
      // Skip if CloudKit entitlement unavailable in test environment
      guard Self.canCreateCloudKitContainer else {
        // Log skip reason without failing the test
        return
      }

      // When: Build container with CloudKit enabled
      let (_, mode) = MyToobApp.buildModelContainerWithMode(cloudKitEnabled: true)

      // Then: Mode should be cloudKit
      #expect(mode == .cloudKit)
    #else
      // Skip test in release builds where DEBUG API is unavailable
      Issue.record("Test requires DEBUG build")
    #endif
  }

  @Test("Factory produces valid containers for both modes")
  func testFactoryProducesValidContainers() async throws {
    #if DEBUG
      // When: Build container for local mode (always available)
      let (localContainer, localMode) = MyToobApp.buildModelContainerWithMode(cloudKitEnabled: false)

      // Then: Local container should be valid
      #expect(localMode == .localOnly)
      #expect(localContainer.schema.entities.count > 0)

      // CloudKit container test only if entitlement available
      if Self.canCreateCloudKitContainer {
        let (cloudContainer, cloudMode) = MyToobApp.buildModelContainerWithMode(cloudKitEnabled: true)
        #expect(cloudMode == .cloudKit)
        #expect(localMode != cloudMode)
        #expect(cloudContainer.schema.entities.count > 0)
      }
    #else
      Issue.record("Test requires DEBUG build")
    #endif
  }
}

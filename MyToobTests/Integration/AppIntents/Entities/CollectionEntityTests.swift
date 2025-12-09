//
//  CollectionEntityTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for CollectionEntity App Intent entity type
/// Verifies entity mapping from ClusterLabel and Codable conformance
@Suite("CollectionEntity Tests")
@MainActor
struct CollectionEntityTests {

  // MARK: - Test Helpers

  /// Creates a sample ClusterLabel for testing
  private func createClusterLabel(
    clusterID: String = "cluster123",
    label: String = "Swift Tutorials",
    centroid: [Float] = Array(repeating: 0.1, count: 512),
    itemCount: Int = 25,
    updatedAt: Date = Date(),
    confidenceScore: Double = 0.85
  ) -> ClusterLabel {
    ClusterLabel(
      clusterID: clusterID,
      label: label,
      centroid: centroid,
      itemCount: itemCount,
      updatedAt: updatedAt,
      confidenceScore: confidenceScore
    )
  }

  // MARK: - Initialization Tests

  @Test("CollectionEntity initializes from ClusterLabel")
  func testInitFromClusterLabel() async throws {
    // Given
    let updatedAt = Date()
    let cluster = createClusterLabel(
      clusterID: "test-cluster-1",
      label: "Programming Videos",
      itemCount: 42,
      updatedAt: updatedAt,
      confidenceScore: 0.92
    )

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.id == "test-cluster-1")
    #expect(entity.label == "Programming Videos")
    #expect(entity.itemCount == 42)
    #expect(entity.confidenceScore == 0.92)
    #expect(entity.updatedAt == updatedAt)
  }

  @Test("CollectionEntity handles zero item count")
  func testZeroItemCount() async throws {
    // Given
    let cluster = createClusterLabel(itemCount: 0)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.itemCount == 0)
  }

  @Test("CollectionEntity handles large item count")
  func testLargeItemCount() async throws {
    // Given
    let cluster = createClusterLabel(itemCount: 10000)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.itemCount == 10000)
  }

  @Test("CollectionEntity handles low confidence score")
  func testLowConfidenceScore() async throws {
    // Given
    let cluster = createClusterLabel(confidenceScore: 0.1)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.confidenceScore == 0.1)
  }

  @Test("CollectionEntity handles zero confidence score")
  func testZeroConfidenceScore() async throws {
    // Given
    let cluster = createClusterLabel(confidenceScore: 0.0)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.confidenceScore == 0.0)
  }

  // MARK: - Codable Tests

  @Test("CollectionEntity is Codable - encode and decode cycle")
  func testCodable() async throws {
    // Given
    let updatedAt = Date()
    let cluster = createClusterLabel(
      clusterID: "codable-cluster",
      label: "Codable Test Collection",
      itemCount: 15,
      updatedAt: updatedAt,
      confidenceScore: 0.75
    )
    let entity = CollectionEntity(from: cluster)

    // When - encode
    let encoder = JSONEncoder()
    let data = try encoder.encode(entity)

    // Then - decode
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(CollectionEntity.self, from: data)

    #expect(decoded.id == entity.id)
    #expect(decoded.label == entity.label)
    #expect(decoded.itemCount == entity.itemCount)
    #expect(decoded.confidenceScore == entity.confidenceScore)
    // Date comparison with tolerance for encoding precision
    #expect(abs(decoded.updatedAt.timeIntervalSince(entity.updatedAt)) < 1.0)
  }

  @Test("CollectionEntity Codable preserves all properties")
  func testCodablePreservesAllProperties() async throws {
    // Given
    let entity = CollectionEntity(from: createClusterLabel(
      clusterID: "full-test",
      label: "Full Property Test",
      itemCount: 99,
      confidenceScore: 0.999
    ))

    // When
    let data = try JSONEncoder().encode(entity)
    let decoded = try JSONDecoder().decode(CollectionEntity.self, from: data)

    // Then
    #expect(decoded.id == "full-test")
    #expect(decoded.label == "Full Property Test")
    #expect(decoded.itemCount == 99)
    #expect(decoded.confidenceScore == 0.999)
  }

  // MARK: - DisplayRepresentation Tests

  @Test("CollectionEntity has displayRepresentation")
  func testDisplayRepresentationExists() async throws {
    // Given
    let cluster = createClusterLabel(label: "Music Videos")

    // When
    let entity = CollectionEntity(from: cluster)

    // Then - verify display representation exists (it's a computed property)
    let display = entity.displayRepresentation
    // DisplayRepresentation is a struct that always exists
    #expect(type(of: display) == DisplayRepresentation.self)
  }

  // MARK: - Type Display Representation Tests

  @Test("CollectionEntity has type display representation")
  func testTypeDisplayRepresentation() async throws {
    // When
    let typeRep = CollectionEntity.typeDisplayRepresentation

    // Then - verify type display representation exists
    #expect(type(of: typeRep) == TypeDisplayRepresentation.self)
  }

  // MARK: - Edge Cases

  @Test("CollectionEntity handles empty label")
  func testEmptyLabel() async throws {
    // Given
    let cluster = createClusterLabel(label: "")

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.label == "")
  }

  @Test("CollectionEntity handles special characters in label")
  func testSpecialCharactersInLabel() async throws {
    // Given
    let specialLabel = "Videos: \"Tutorials\" & <Advanced> 🎓"
    let cluster = createClusterLabel(label: specialLabel)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.label == specialLabel)
  }

  @Test("CollectionEntity handles Unicode in label")
  func testUnicodeLabel() async throws {
    // Given
    let unicodeLabel = "日本語チュートリアル"
    let cluster = createClusterLabel(label: unicodeLabel)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.label == unicodeLabel)
  }

  @Test("CollectionEntity handles very long label")
  func testVeryLongLabel() async throws {
    // Given
    let longLabel = String(repeating: "A", count: 1000)
    let cluster = createClusterLabel(label: longLabel)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.label == longLabel)
    #expect(entity.label.count == 1000)
  }

  @Test("CollectionEntity handles distant past date")
  func testDistantPastDate() async throws {
    // Given
    let pastDate = Date.distantPast
    let cluster = createClusterLabel(updatedAt: pastDate)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.updatedAt == pastDate)
  }

  @Test("CollectionEntity handles future date")
  func testFutureDate() async throws {
    // Given
    let futureDate = Date.distantFuture
    let cluster = createClusterLabel(updatedAt: futureDate)

    // When
    let entity = CollectionEntity(from: cluster)

    // Then
    #expect(entity.updatedAt == futureDate)
  }
}

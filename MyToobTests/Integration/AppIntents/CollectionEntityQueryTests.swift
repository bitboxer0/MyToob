//
//  CollectionEntityQueryTests.swift
//  MyToobTests
//
//  Created by Claude Code on 12/8/25.
//

import Foundation
import SwiftData
import Testing

@testable import MyToob

/// Tests for CollectionEntityQuery - the entity query provider for CollectionEntity
/// Verifies lookup, suggestions, and search functionality
@Suite("CollectionEntityQuery Tests")
@MainActor
struct CollectionEntityQueryTests {

  // MARK: - Test Helpers

  /// Creates an in-memory model container for testing
  private func createTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
      for: VideoItem.self,
      ClusterLabel.self,
      Note.self,
      configurations: config
    )
  }

  /// Creates a sample ClusterLabel for testing
  private func createClusterLabel(
    clusterID: String = "cluster123",
    label: String = "Swift Tutorials",
    itemCount: Int = 25,
    confidenceScore: Double = 0.85,
    updatedAt: Date = Date()
  ) -> ClusterLabel {
    ClusterLabel(
      clusterID: clusterID,
      label: label,
      centroid: Array(repeating: 0.1, count: 512),
      itemCount: itemCount,
      updatedAt: updatedAt,
      confidenceScore: confidenceScore
    )
  }

  // MARK: - Entity Lookup Tests

  @Test("Query finds collection by identifier")
  func testFindByIdentifier() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let cluster = createClusterLabel(clusterID: "findCluster", label: "Test Collection")
    context.insert(cluster)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let results = try await query.entities(for: ["findCluster"], in: container)

    // Then
    #expect(results.count == 1)
    #expect(results.first?.id == "findCluster")
    #expect(results.first?.label == "Test Collection")
  }

  @Test("Query finds multiple collections by identifiers")
  func testFindMultipleByIdentifiers() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let cluster1 = createClusterLabel(clusterID: "multi1", label: "Collection 1")
    let cluster2 = createClusterLabel(clusterID: "multi2", label: "Collection 2")
    let cluster3 = createClusterLabel(clusterID: "multi3", label: "Collection 3")
    context.insert(cluster1)
    context.insert(cluster2)
    context.insert(cluster3)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let results = try await query.entities(for: ["multi1", "multi3"], in: container)

    // Then
    #expect(results.count == 2)
    let ids = results.map { $0.id }
    #expect(ids.contains("multi1"))
    #expect(ids.contains("multi3"))
  }

  @Test("Query returns empty for unknown identifier")
  func testUnknownIdentifier() async throws {
    // Given
    let container = try createTestContainer()
    let query = CollectionEntityQuery()

    // When
    let results = try await query.entities(for: ["nonexistent"], in: container)

    // Then
    #expect(results.isEmpty)
  }

  // MARK: - Suggestion Tests

  @Test("Query suggests collections sorted by item count")
  func testSuggestedEntitiesByItemCount() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let smallCollection = createClusterLabel(clusterID: "small", label: "Small", itemCount: 5)
    let largeCollection = createClusterLabel(clusterID: "large", label: "Large", itemCount: 100)
    let mediumCollection = createClusterLabel(
      clusterID: "medium", label: "Medium", itemCount: 50)
    context.insert(smallCollection)
    context.insert(largeCollection)
    context.insert(mediumCollection)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let suggestions = try await query.suggestedEntities(in: container)

    // Then
    #expect(suggestions.count == 3)
    // Largest collection should be first
    #expect(suggestions[0].id == "large")
    #expect(suggestions[1].id == "medium")
    #expect(suggestions[2].id == "small")
  }

  @Test("Query filters out low confidence collections from suggestions")
  func testSuggestedEntitiesFiltersLowConfidence() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let highConfidence = createClusterLabel(
      clusterID: "high",
      label: "High Confidence",
      itemCount: 20,
      confidenceScore: 0.9
    )
    let lowConfidence = createClusterLabel(
      clusterID: "low",
      label: "Low Confidence",
      itemCount: 30,
      confidenceScore: 0.2
    )
    context.insert(highConfidence)
    context.insert(lowConfidence)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let suggestions = try await query.suggestedEntities(in: container)

    // Then - only high confidence collection should be suggested
    #expect(suggestions.count == 1)
    #expect(suggestions.first?.id == "high")
  }

  @Test("Query returns empty suggestions for empty database")
  func testSuggestedEntitiesEmpty() async throws {
    // Given
    let container = try createTestContainer()
    let query = CollectionEntityQuery()

    // When
    let suggestions = try await query.suggestedEntities(in: container)

    // Then
    #expect(suggestions.isEmpty)
  }

  // MARK: - String Search Tests

  @Test("Query searches collections by label")
  func testSearchByLabel() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let swiftCluster = createClusterLabel(clusterID: "swift", label: "Swift Programming")
    let pythonCluster = createClusterLabel(clusterID: "python", label: "Python Basics")
    context.insert(swiftCluster)
    context.insert(pythonCluster)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let results = try await query.entities(matching: "Swift", in: container)

    // Then
    #expect(results.count == 1)
    #expect(results.first?.label == "Swift Programming")
  }

  @Test("Query search is case insensitive")
  func testSearchCaseInsensitive() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let cluster = createClusterLabel(clusterID: "case", label: "SwiftUI Tutorials")
    context.insert(cluster)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let results = try await query.entities(matching: "swiftui", in: container)

    // Then
    #expect(results.count == 1)
  }

  @Test("Query returns empty for no matches")
  func testSearchNoMatches() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let cluster = createClusterLabel(clusterID: "nomatch", label: "Swift Videos")
    context.insert(cluster)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let results = try await query.entities(matching: "JavaScript", in: container)

    // Then
    #expect(results.isEmpty)
  }

  @Test("Query search handles partial matches")
  func testSearchPartialMatch() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let cluster = createClusterLabel(clusterID: "partial", label: "Programming Tutorials")
    context.insert(cluster)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let results = try await query.entities(matching: "Program", in: container)

    // Then
    #expect(results.count == 1)
  }

  // MARK: - Default Result Tests

  @Test("Query returns default result when collections exist")
  func testDefaultResult() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let cluster = createClusterLabel(clusterID: "default", label: "Default Collection")
    context.insert(cluster)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let result = await query.defaultResult(in: container)

    // Then
    #expect(result != nil)
  }

  @Test("Query returns nil default when no collections exist")
  func testDefaultResultEmpty() async throws {
    // Given
    let container = try createTestContainer()
    let query = CollectionEntityQuery()

    // When
    let result = await query.defaultResult(in: container)

    // Then
    #expect(result == nil)
  }

  @Test("Query returns largest collection as default")
  func testDefaultResultLargest() async throws {
    // Given
    let container = try createTestContainer()
    let context = ModelContext(container)

    let small = createClusterLabel(
      clusterID: "small", label: "Small", itemCount: 10, confidenceScore: 0.8)
    let large = createClusterLabel(
      clusterID: "large", label: "Large", itemCount: 100, confidenceScore: 0.8)
    context.insert(small)
    context.insert(large)
    try context.save()

    let query = CollectionEntityQuery()

    // When
    let result = await query.defaultResult(in: container)

    // Then
    #expect(result?.id == "large")
  }
}

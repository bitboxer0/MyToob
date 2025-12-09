//
//  CollectionEntityQuery.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import OSLog
import SwiftData

/// Entity query provider for CollectionEntity.
/// Provides lookup, suggestions, and search functionality for collections in the Shortcuts app.
struct CollectionEntityQuery: EntityQuery {

  typealias Entity = CollectionEntity

  // MARK: - Configuration

  /// Minimum confidence score for collections to be suggested
  private static let minimumConfidenceScore: Double = 0.5

  // MARK: - Logging

  private static let logger = Logger(subsystem: "com.mytoob.app", category: "CollectionEntityQuery")

  // MARK: - EntityQuery Protocol

  /// Find collections by their identifiers
  /// - Parameter identifiers: Array of cluster IDs
  /// - Returns: Array of CollectionEntity matching the identifiers
  func entities(for identifiers: [CollectionEntity.ID]) async throws -> [CollectionEntity] {
    Self.logger.debug("Looking up collections for \(identifiers.count) identifiers")

    let container = try getModelContainer()
    return try await entities(for: identifiers, in: container)
  }

  /// Provide suggested collections for the Shortcuts picker
  /// - Returns: Array of suggested CollectionEntity, sorted by item count
  func suggestedEntities() async throws -> [CollectionEntity] {
    Self.logger.debug("Fetching suggested collections")

    let container = try getModelContainer()
    return try await suggestedEntities(in: container)
  }

  /// Provide a default result when no specific collection is selected
  /// - Returns: The largest collection with sufficient confidence, or nil if none exist
  func defaultResult() async -> CollectionEntity? {
    Self.logger.debug("Getting default collection result")

    guard let container = try? getModelContainer() else {
      return nil
    }
    return await defaultResult(in: container)
  }

  // MARK: - Internal Methods (for testing with custom container)

  /// Find collections by identifiers using a specific container
  @MainActor
  func entities(for identifiers: [CollectionEntity.ID], in container: ModelContainer) throws
    -> [CollectionEntity]
  {
    let context = ModelContext(container)

    // Fetch all clusters and filter by ID
    let descriptor = FetchDescriptor<ClusterLabel>()
    let allClusters = try context.fetch(descriptor)

    let identifierSet = Set(identifiers)
    let matchingClusters = allClusters.filter { identifierSet.contains($0.clusterID) }

    return matchingClusters.map { CollectionEntity(from: $0) }
  }

  /// Get suggested collections using a specific container
  @MainActor
  func suggestedEntities(in container: ModelContainer) throws -> [CollectionEntity] {
    let context = ModelContext(container)

    // Fetch clusters sorted by item count (largest first)
    var descriptor = FetchDescriptor<ClusterLabel>(
      sortBy: [
        SortDescriptor(\.itemCount, order: .reverse)
      ]
    )
    descriptor.fetchLimit = 20

    let clusters = try context.fetch(descriptor)

    // Filter by minimum confidence score
    let qualityClusters = clusters.filter { $0.confidenceScore >= Self.minimumConfidenceScore }

    return qualityClusters.map { CollectionEntity(from: $0) }
  }

  /// Get default result using a specific container
  @MainActor
  func defaultResult(in container: ModelContainer) -> CollectionEntity? {
    let context = ModelContext(container)

    // Get the largest collection with sufficient confidence
    var descriptor = FetchDescriptor<ClusterLabel>(
      sortBy: [
        SortDescriptor(\.itemCount, order: .reverse)
      ]
    )
    descriptor.fetchLimit = 10

    guard let clusters = try? context.fetch(descriptor) else {
      return nil
    }

    // Return first with sufficient confidence
    guard
      let bestCluster = clusters.first(where: {
        $0.confidenceScore >= Self.minimumConfidenceScore
      })
    else {
      // Fall back to any cluster if none meet confidence threshold
      return clusters.first.map { CollectionEntity(from: $0) }
    }

    return CollectionEntity(from: bestCluster)
  }

  // MARK: - Private Helpers

  /// Get the shared ModelContainer
  private func getModelContainer() throws -> ModelContainer {
    let schema = Schema([VideoItem.self, ClusterLabel.self, Note.self])
    let config = ModelConfiguration(schema: schema)
    return try ModelContainer(for: schema, configurations: [config])
  }
}

// MARK: - EntityStringQuery

extension CollectionEntityQuery: EntityStringQuery {
  /// Search for collections matching a query string
  /// - Parameter string: The search query
  /// - Returns: Array of CollectionEntity matching the query
  func entities(matching string: String) async throws -> [CollectionEntity] {
    Self.logger.debug("Searching collections for: \(string)")

    let container = try getModelContainer()
    return try await entities(matching: string, in: container)
  }

  /// Search for collections using a specific container
  @MainActor
  func entities(matching string: String, in container: ModelContainer) throws -> [CollectionEntity]
  {
    let context = ModelContext(container)

    // Fetch all clusters
    var descriptor = FetchDescriptor<ClusterLabel>(
      sortBy: [
        SortDescriptor(\.itemCount, order: .reverse)
      ]
    )
    descriptor.fetchLimit = 50

    let allClusters = try context.fetch(descriptor)

    // Filter in memory for case-insensitive matching
    let searchLower = string.lowercased()
    let matchingClusters = allClusters.filter { cluster in
      cluster.label.lowercased().contains(searchLower)
    }

    return matchingClusters.map { CollectionEntity(from: $0) }
  }
}

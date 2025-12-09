//
//  CollectionEntity.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation

/// App Intent entity representing a collection (cluster) in the MyToob library.
/// Maps from ClusterLabel model for use in Shortcuts and Siri.
struct CollectionEntity: AppEntity, Identifiable, Hashable, Codable, Sendable {

  // MARK: - AppEntity Protocol

  typealias DefaultQuery = CollectionEntityQuery

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Collection")
  }

  static var defaultQuery = CollectionEntityQuery()

  // MARK: - Properties

  /// Unique identifier for this collection (cluster ID)
  let id: String

  /// Human-readable label for the collection
  let label: String

  /// Number of videos in this collection
  let itemCount: Int

  /// Confidence score of the cluster (0.0 to 1.0)
  let confidenceScore: Double

  /// When this collection was last updated
  let updatedAt: Date

  // MARK: - Display Representation

  var displayRepresentation: DisplayRepresentation {
    let subtitle: String
    if itemCount == 1 {
      subtitle = "1 video"
    } else {
      subtitle = "\(itemCount) videos"
    }

    return DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: label),
      subtitle: LocalizedStringResource(stringLiteral: subtitle)
    )
  }

  // MARK: - Initialization

  /// Initialize from a ClusterLabel model
  /// - Parameter cluster: The ClusterLabel to convert to an entity
  init(from cluster: ClusterLabel) {
    self.id = cluster.clusterID
    self.label = cluster.label
    self.itemCount = cluster.itemCount
    self.confidenceScore = cluster.confidenceScore
    self.updatedAt = cluster.updatedAt
  }

  /// Initialize directly with values (for testing and Codable)
  init(
    id: String,
    label: String,
    itemCount: Int,
    confidenceScore: Double = 0.0,
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.label = label
    self.itemCount = itemCount
    self.confidenceScore = confidenceScore
    self.updatedAt = updatedAt
  }

  // MARK: - Hashable

  static func == (lhs: CollectionEntity, rhs: CollectionEntity) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

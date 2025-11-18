//
//  ClusterLabel.swift
//  MyToob
//
//  Created by Claude Code (BMad Master)
//

import Foundation
import SwiftData

/// Represents an AI-generated topic cluster for organizing videos.
/// Clusters group semantically similar videos using kNN graph + Leiden/Louvain community detection.
@Model
final class ClusterLabel {
    /// Unique identifier for this cluster
    @Attribute(.unique) var clusterID: String

    /// Human-readable label for the cluster (e.g., "Swift Programming", "Cooking Tutorials")
    /// Generated via keyword extraction + centroid terms
    var label: String

    /// 384-dimensional centroid vector representing the cluster's semantic center
    @Attribute(.transformable) var centroid: [Float]

    /// Number of items in this cluster
    var itemCount: Int

    /// When this cluster was created/last updated
    var updatedAt: Date

    /// Cluster confidence score (0.0 to 1.0)
    /// Higher scores indicate more cohesive clusters
    var confidenceScore: Double

    init(
        clusterID: String,
        label: String,
        centroid: [Float],
        itemCount: Int,
        updatedAt: Date = Date(),
        confidenceScore: Double = 0.0
    ) {
        self.clusterID = clusterID
        self.label = label
        self.centroid = centroid
        self.itemCount = itemCount
        self.updatedAt = updatedAt
        self.confidenceScore = confidenceScore
    }

    /// Compute cosine similarity between this cluster's centroid and a given embedding
    func similarity(to embedding: [Float]) -> Double {
        guard centroid.count == embedding.count else { return 0.0 }

        var dotProduct: Float = 0.0
        var centroidMagnitude: Float = 0.0
        var embeddingMagnitude: Float = 0.0

        for i in 0..<centroid.count {
            dotProduct += centroid[i] * embedding[i]
            centroidMagnitude += centroid[i] * centroid[i]
            embeddingMagnitude += embedding[i] * embedding[i]
        }

        let magnitude = sqrt(centroidMagnitude) * sqrt(embeddingMagnitude)
        guard magnitude > 0 else { return 0.0 }

        return Double(dotProduct / magnitude)
    }
}

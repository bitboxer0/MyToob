//
//  ClusterLabelTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) - Story 1.4
//

import Testing
import Foundation
import SwiftData
@testable import MyToob

@Suite("ClusterLabel Model Tests")
struct ClusterLabelTests {

    @Test("Create cluster label")
    func createClusterLabel() async throws {
        let centroid: [Float] = Array(repeating: 0.5, count: 384)
        let cluster = ClusterLabel(
            clusterID: "cluster-001",
            label: "Swift Programming",
            centroid: centroid,
            itemCount: 42,
            confidenceScore: 0.85
        )

        #expect(cluster.clusterID == "cluster-001")
        #expect(cluster.label == "Swift Programming")
        #expect(cluster.centroid.count == 384)
        #expect(cluster.itemCount == 42)
        #expect(cluster.confidenceScore == 0.85)
    }

    @Test("Cosine similarity calculation - identical vectors")
    func cosineSimilarityIdentical() async throws {
        let vector: [Float] = [1.0, 0.0, 0.0, 1.0]
        let cluster = ClusterLabel(
            clusterID: "test-001",
            label: "Test",
            centroid: vector,
            itemCount: 1
        )

        let similarity = cluster.similarity(to: vector)
        #expect(abs(similarity - 1.0) < 0.0001) // Should be 1.0 (identical)
    }

    @Test("Cosine similarity calculation - orthogonal vectors")
    func cosineSimilarityOrthogonal() async throws {
        let centroid: [Float] = [1.0, 0.0, 0.0, 0.0]
        let embedding: [Float] = [0.0, 1.0, 0.0, 0.0]

        let cluster = ClusterLabel(
            clusterID: "test-002",
            label: "Test",
            centroid: centroid,
            itemCount: 1
        )

        let similarity = cluster.similarity(to: embedding)
        #expect(abs(similarity) < 0.0001) // Should be 0.0 (orthogonal)
    }

    @Test("Cosine similarity calculation - opposite vectors")
    func cosineSimilarityOpposite() async throws {
        let centroid: [Float] = [1.0, 0.0, 0.0, 0.0]
        let embedding: [Float] = [-1.0, 0.0, 0.0, 0.0]

        let cluster = ClusterLabel(
            clusterID: "test-003",
            label: "Test",
            centroid: centroid,
            itemCount: 1
        )

        let similarity = cluster.similarity(to: embedding)
        #expect(abs(similarity - (-1.0)) < 0.0001) // Should be -1.0 (opposite)
    }

    @Test("Cosine similarity - dimension mismatch")
    func cosineSimilarityMismatch() async throws {
        let centroid: [Float] = [1.0, 0.0, 0.0]
        let embedding: [Float] = [1.0, 0.0] // Different dimension

        let cluster = ClusterLabel(
            clusterID: "test-004",
            label: "Test",
            centroid: centroid,
            itemCount: 1
        )

        let similarity = cluster.similarity(to: embedding)
        #expect(similarity == 0.0) // Should return 0 for mismatch
    }

    @Test("Cosine similarity - zero magnitude")
    func cosineSimilarityZeroMagnitude() async throws {
        let centroid: [Float] = [0.0, 0.0, 0.0]
        let embedding: [Float] = [1.0, 0.0, 0.0]

        let cluster = ClusterLabel(
            clusterID: "test-005",
            label: "Test",
            centroid: centroid,
            itemCount: 1
        )

        let similarity = cluster.similarity(to: embedding)
        #expect(similarity == 0.0) // Should handle zero magnitude
    }

    @Test("SwiftData persistence")
    func persistClusterLabel() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ClusterLabel.self,
            configurations: config
        )
        let context = ModelContext(container)

        let centroid: [Float] = Array(repeating: 0.75, count: 384)
        let cluster = ClusterLabel(
            clusterID: "persist-001",
            label: "SwiftUI Tutorials",
            centroid: centroid,
            itemCount: 15,
            confidenceScore: 0.92
        )

        context.insert(cluster)
        try context.save()

        // Fetch back
        let descriptor = FetchDescriptor<ClusterLabel>(
            predicate: #Predicate { $0.clusterID == "persist-001" }
        )
        let fetchedClusters = try context.fetch(descriptor)

        #expect(fetchedClusters.count == 1)
        #expect(fetchedClusters.first?.label == "SwiftUI Tutorials")
        #expect(fetchedClusters.first?.itemCount == 15)
        #expect(fetchedClusters.first?.confidenceScore == 0.92)
        #expect(fetchedClusters.first?.centroid.count == 384)
    }

    @Test("Delete cluster label")
    func deleteClusterLabel() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ClusterLabel.self,
            configurations: config
        )
        let context = ModelContext(container)

        let centroid: [Float] = [0.5, 0.5]
        let cluster = ClusterLabel(
            clusterID: "delete-001",
            label: "Test Cluster",
            centroid: centroid,
            itemCount: 5
        )

        context.insert(cluster)
        try context.save()

        // Delete
        context.delete(cluster)
        try context.save()

        // Verify deletion
        let descriptor = FetchDescriptor<ClusterLabel>()
        let fetchedClusters = try context.fetch(descriptor)
        #expect(fetchedClusters.isEmpty)
    }

    @Test("Update cluster properties")
    func updateClusterProperties() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ClusterLabel.self,
            configurations: config
        )
        let context = ModelContext(container)

        let centroid: [Float] = [0.5, 0.5]
        let cluster = ClusterLabel(
            clusterID: "update-001",
            label: "Original Label",
            centroid: centroid,
            itemCount: 10
        )

        context.insert(cluster)
        try context.save()

        // Update properties
        cluster.label = "Updated Label"
        cluster.itemCount = 20
        cluster.confidenceScore = 0.95
        try context.save()

        // Fetch and verify
        let descriptor = FetchDescriptor<ClusterLabel>(
            predicate: #Predicate { $0.clusterID == "update-001" }
        )
        let fetchedClusters = try context.fetch(descriptor)

        #expect(fetchedClusters.first?.label == "Updated Label")
        #expect(fetchedClusters.first?.itemCount == 20)
        #expect(fetchedClusters.first?.confidenceScore == 0.95)
    }
}

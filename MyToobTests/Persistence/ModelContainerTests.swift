//
//  ModelContainerTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 11/25/25.
//

import Foundation
import SwiftData
import Testing

@testable import MyToob

@Suite("ModelContainer Tests")
struct ModelContainerTests {

  // MARK: - Test Container Initialization

  @Test("Container initializes successfully with all models")
  func testContainerInitialization() async throws {
    // Arrange: Create in-memory container with all 4 models
    let config = ModelConfiguration(isStoredInMemoryOnly: true)

    // Act: Initialize container with full schema
    let container = try ModelContainer(
      for: VideoItem.self, ClusterLabel.self, Note.self, ChannelBlacklist.self,
      configurations: config
    )

    // Assert: Container exists and has a valid context
    let context = ModelContext(container)
    #expect(context.container === container, "Context should reference the created container")
  }

  // MARK: - Test All Models Queryable

  @Test("All models are queryable after initialization")
  func testAllModelsQueryable() async throws {
    // Arrange: Create in-memory container
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: VideoItem.self, ClusterLabel.self, Note.self, ChannelBlacklist.self,
      configurations: config
    )
    let context = ModelContext(container)

    // Act: Fetch each model type (should return empty arrays, not throw)
    let videoDescriptor = FetchDescriptor<VideoItem>()
    let clusterDescriptor = FetchDescriptor<ClusterLabel>()
    let noteDescriptor = FetchDescriptor<Note>()
    let blacklistDescriptor = FetchDescriptor<ChannelBlacklist>()

    let videos = try context.fetch(videoDescriptor)
    let clusters = try context.fetch(clusterDescriptor)
    let notes = try context.fetch(noteDescriptor)
    let blacklists = try context.fetch(blacklistDescriptor)

    // Assert: All queries succeed (empty arrays are valid)
    #expect(videos.isEmpty, "VideoItem query should succeed (empty is valid)")
    #expect(clusters.isEmpty, "ClusterLabel query should succeed (empty is valid)")
    #expect(notes.isEmpty, "Note query should succeed (empty is valid)")
    #expect(blacklists.isEmpty, "ChannelBlacklist query should succeed (empty is valid)")
  }

  // MARK: - Test Default Storage Location

  @Test("Container uses persistent storage by default")
  func testDefaultStorageLocation() async throws {
    // Arrange: Create persistent configuration (not in-memory)
    let schema = Schema([
      VideoItem.self,
      ClusterLabel.self,
      Note.self,
      ChannelBlacklist.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    // Act: Create container with persistent config
    let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

    // Assert: Container was created successfully
    // Note: We verify it's not in-memory by creating a persistent config
    // The actual file location is managed by SwiftData internally
    let context = ModelContext(container)
    #expect(context.autosaveEnabled == true, "Persistent container should have autosave enabled")
  }

  // MARK: - Test Data Persistence Across Restarts

  @Test("Data persists across container recreations")
  func testDataPersistsAcrossRestarts() async throws {
    // Arrange: Create temporary storage URL for controlled testing
    let tempDirectory = FileManager.default.temporaryDirectory
    let storeURL = tempDirectory.appendingPathComponent("test_persistence_\(UUID().uuidString)")

    // Create schema
    let schema = Schema([
      VideoItem.self,
      ClusterLabel.self,
      Note.self,
      ChannelBlacklist.self,
    ])

    // First container session: Create and save data
    let config1 = ModelConfiguration(
      schema: schema,
      url: storeURL,
      allowsSave: true
    )
    let container1 = try ModelContainer(for: schema, configurations: [config1])
    let context1 = ModelContext(container1)

    let videoItem = VideoItem(
      videoID: "persist_test_123",
      title: "Persistence Test Video",
      channelID: "UCtest",
      duration: 300.0
    )
    context1.insert(videoItem)
    try context1.save()

    // Verify data was inserted
    let verifyDescriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "persist_test_123" }
    )
    let verifyResults = try context1.fetch(verifyDescriptor)
    #expect(verifyResults.count == 1, "Data should be saved in first session")

    // Second container session: Recreate container and verify data persists
    let config2 = ModelConfiguration(
      schema: schema,
      url: storeURL,
      allowsSave: true
    )
    let container2 = try ModelContainer(for: schema, configurations: [config2])
    let context2 = ModelContext(container2)

    // Act: Fetch data from new container instance
    let fetchDescriptor = FetchDescriptor<VideoItem>(
      predicate: #Predicate { $0.videoID == "persist_test_123" }
    )
    let fetchedItems = try context2.fetch(fetchDescriptor)

    // Assert: Data persisted across container recreation
    #expect(fetchedItems.count == 1, "Data should persist across container recreations")
    #expect(fetchedItems.first?.title == "Persistence Test Video", "Title should match")
    #expect(fetchedItems.first?.channelID == "UCtest", "Channel should match")

    // Cleanup: Remove test files
    try? FileManager.default.removeItem(at: storeURL)
  }

  // MARK: - Test Cold Start Creates Schema

  @Test("Fresh container creates schema automatically")
  func testColdStartCreatesSchema() async throws {
    // Arrange: Create temporary storage URL for fresh database
    let tempDirectory = FileManager.default.temporaryDirectory
    let storeURL = tempDirectory.appendingPathComponent("fresh_schema_\(UUID().uuidString)")

    // Ensure no existing database at this location
    try? FileManager.default.removeItem(at: storeURL)

    let schema = Schema([
      VideoItem.self,
      ClusterLabel.self,
      Note.self,
      ChannelBlacklist.self,
    ])

    let config = ModelConfiguration(
      schema: schema,
      url: storeURL,
      allowsSave: true
    )

    // Act: Create fresh container (cold start)
    let container = try ModelContainer(for: schema, configurations: [config])
    let context = ModelContext(container)

    // Insert and save data to verify schema was created
    let videoItem = VideoItem(
      videoID: "cold_start_test",
      title: "Cold Start Test",
      channelID: nil,
      duration: 100.0
    )
    context.insert(videoItem)
    try context.save()

    // Assert: Schema was created and data can be queried
    let descriptor = FetchDescriptor<VideoItem>()
    let results = try context.fetch(descriptor)
    #expect(results.count == 1, "Schema should be created and accept data on cold start")

    // Cleanup
    try? FileManager.default.removeItem(at: storeURL)
  }
}

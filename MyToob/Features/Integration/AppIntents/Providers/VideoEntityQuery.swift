//
//  VideoEntityQuery.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import OSLog
import SwiftData

/// Entity query provider for VideoEntity.
/// Provides lookup, suggestions, and search functionality for videos in the Shortcuts app.
struct VideoEntityQuery: EntityQuery {

  typealias Entity = VideoEntity

  // MARK: - Logging

  private static let logger = Logger(subsystem: "com.mytoob.app", category: "VideoEntityQuery")

  // MARK: - EntityQuery Protocol

  /// Find videos by their identifiers
  /// - Parameter identifiers: Array of video identifiers (videoID or local file path)
  /// - Returns: Array of VideoEntity matching the identifiers
  func entities(for identifiers: [VideoEntity.ID]) async throws -> [VideoEntity] {
    Self.logger.debug("Looking up videos for \(identifiers.count) identifiers")

    let container = try getModelContainer()
    return try await entities(for: identifiers, in: container)
  }

  /// Provide suggested videos for the Shortcuts picker
  /// - Returns: Array of suggested VideoEntity, sorted by recency
  func suggestedEntities() async throws -> [VideoEntity] {
    Self.logger.debug("Fetching suggested videos")

    let container = try getModelContainer()
    return try await suggestedEntities(in: container)
  }

  /// Provide a default result when no specific video is selected
  /// - Returns: The most recently watched video, or nil if library is empty
  func defaultResult() async -> VideoEntity? {
    Self.logger.debug("Getting default video result")

    guard let container = try? getModelContainer() else {
      return nil
    }
    return await defaultResult(in: container)
  }

  // MARK: - Internal Methods (for testing with custom container)

  /// Find videos by identifiers using a specific container
  @MainActor
  func entities(for identifiers: [VideoEntity.ID], in container: ModelContainer) throws
    -> [VideoEntity]
  {
    let context = ModelContext(container)

    // Fetch all videos and filter by identifier
    // Note: SwiftData predicates don't support computed properties,
    // so we fetch all and filter in memory
    let descriptor = FetchDescriptor<VideoItem>()
    let allVideos = try context.fetch(descriptor)

    let identifierSet = Set(identifiers)
    let matchingVideos = allVideos.filter { identifierSet.contains($0.identifier) }

    return matchingVideos.map { VideoEntity(from: $0) }
  }

  /// Get suggested videos using a specific container
  @MainActor
  func suggestedEntities(in container: ModelContainer) throws -> [VideoEntity] {
    let context = ModelContext(container)

    // Fetch videos sorted by last watched date (most recent first)
    var descriptor = FetchDescriptor<VideoItem>(
      sortBy: [
        SortDescriptor(\VideoItem.lastWatchedAt, order: .reverse),
        SortDescriptor(\VideoItem.addedAt, order: .reverse),
      ]
    )
    descriptor.fetchLimit = 20

    let videos = try context.fetch(descriptor)
    return videos.map { VideoEntity(from: $0) }
  }

  /// Get default result using a specific container
  @MainActor
  func defaultResult(in container: ModelContainer) -> VideoEntity? {
    let context = ModelContext(container)

    var descriptor = FetchDescriptor<VideoItem>(
      sortBy: [
        SortDescriptor(\VideoItem.lastWatchedAt, order: .reverse),
        SortDescriptor(\VideoItem.addedAt, order: .reverse),
      ]
    )
    descriptor.fetchLimit = 1

    guard let video = try? context.fetch(descriptor).first else {
      return nil
    }

    return VideoEntity(from: video)
  }

  // MARK: - Private Helpers

  /// Get the shared ModelContainer
  private func getModelContainer() throws -> ModelContainer {
    // Use the app's schema for the container
    let schema = Schema([VideoItem.self, ClusterLabel.self, Note.self])
    let config = ModelConfiguration(schema: schema)
    return try ModelContainer(for: schema, configurations: [config])
  }
}

// MARK: - EntityStringQuery

extension VideoEntityQuery: EntityStringQuery {
  /// Search for videos matching a query string
  /// - Parameter string: The search query
  /// - Returns: Array of VideoEntity matching the query
  func entities(matching string: String) async throws -> [VideoEntity] {
    Self.logger.debug("Searching videos for: \(string)")

    let container = try getModelContainer()
    return try await entities(matching: string, in: container)
  }

  /// Search for videos using a specific container
  @MainActor
  func entities(matching string: String, in container: ModelContainer) throws -> [VideoEntity] {
    let context = ModelContext(container)

    // Fetch all videos (SwiftData predicates don't support localizedStandardContains directly)
    var descriptor = FetchDescriptor<VideoItem>(
      sortBy: [
        SortDescriptor(\VideoItem.lastWatchedAt, order: .reverse),
        SortDescriptor(\VideoItem.addedAt, order: .reverse),
      ]
    )
    descriptor.fetchLimit = 100

    let allVideos = try context.fetch(descriptor)

    // Filter in memory for case-insensitive matching
    let searchLower = string.lowercased()
    let matchingVideos = allVideos.filter { video in
      video.title.lowercased().contains(searchLower)
        || (video.channelID?.lowercased().contains(searchLower) ?? false)
        || video.aiTopicTags.contains { $0.lowercased().contains(searchLower) }
    }

    return matchingVideos.map { VideoEntity(from: $0) }
  }
}

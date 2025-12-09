//
//  SearchVideosIntent.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import OSLog
import SwiftData

/// App Intent to search for videos in the MyToob library.
/// Returns matching videos that can be chained with other shortcuts.
struct SearchVideosIntent: AppIntent {

  // MARK: - Intent Metadata

  static var title: LocalizedStringResource = "Search Videos"
  static var description = IntentDescription("Search for videos in your MyToob library")

  // MARK: - Parameters

  @Parameter(title: "Search Query")
  var query: String

  @Parameter(title: "Limit", default: 10)
  var limit: Int

  // MARK: - Logging

  private static let logger = Logger(subsystem: "com.mytoob.app", category: "SearchVideosIntent")

  // MARK: - Perform

  /// Execute the intent
  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<[VideoEntity]> {
    Self.logger.info("Searching videos for: \(query, privacy: .private)")

    let container = try getModelContainer()
    let results = try await perform(in: container)

    Self.logger.debug("Found \(results.count) videos matching query")
    return .result(value: results)
  }

  /// Execute the intent with a specific container (for testing)
  @MainActor
  func perform(in container: ModelContainer) async throws -> [VideoEntity] {
    let context = ModelContext(container)

    // Fetch all videos
    var descriptor = FetchDescriptor<VideoItem>(
      sortBy: [
        SortDescriptor(\VideoItem.lastWatchedAt, order: .reverse),
        SortDescriptor(\VideoItem.addedAt, order: .reverse),
      ]
    )
    // Fetch more than limit to account for filtering
    descriptor.fetchLimit = limit * 10

    let allVideos = try context.fetch(descriptor)

    // Filter in memory for case-insensitive matching
    let searchLower = query.lowercased()
    let matchingVideos = allVideos.filter { video in
      video.title.lowercased().contains(searchLower)
        || (video.channelID?.lowercased().contains(searchLower) ?? false)
        || video.aiTopicTags.contains { $0.lowercased().contains(searchLower) }
    }

    // Apply limit and convert to entities
    let limitedVideos = Array(matchingVideos.prefix(limit))
    return limitedVideos.map { VideoEntity(from: $0) }
  }

  // MARK: - Private Helpers

  private func getModelContainer() throws -> ModelContainer {
    let schema = Schema([VideoItem.self, ClusterLabel.self, Note.self])
    let config = ModelConfiguration(schema: schema)
    return try ModelContainer(for: schema, configurations: [config])
  }
}

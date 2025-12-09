//
//  GetRandomVideoIntent.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import OSLog
import SwiftData

/// App Intent to get a random video from the MyToob library.
/// Optionally filters by collection and prefers unwatched videos.
struct GetRandomVideoIntent: AppIntent {

  // MARK: - Intent Metadata

  static var title: LocalizedStringResource = "Get Random Video"
  static var description = IntentDescription("Get a random video from your MyToob library")

  // MARK: - Parameters

  @Parameter(title: "From Collection", default: nil)
  var collection: CollectionEntity?

  // MARK: - Logging

  private static let logger = Logger(subsystem: "com.mytoob.app", category: "GetRandomVideoIntent")

  // MARK: - Perform

  /// Execute the intent
  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<VideoEntity> {
    Self.logger.info(
      "Getting random video from collection: \(collection?.label ?? "all", privacy: .public)")

    let container = try getModelContainer()
    let result = try await perform(in: container)

    Self.logger.debug("Selected random video: \(result.id, privacy: .private)")
    return .result(value: result)
  }

  /// Execute the intent with a specific container (for testing)
  @MainActor
  func perform(in container: ModelContainer) async throws -> VideoEntity {
    let context = ModelContext(container)

    // Fetch all videos
    let descriptor = FetchDescriptor<VideoItem>()
    var allVideos = try context.fetch(descriptor)

    // Filter by collection if specified
    if let collection = collection {
      allVideos = allVideos.filter { video in
        video.aiTopicTags.contains(collection.label)
      }
    }

    guard !allVideos.isEmpty else {
      Self.logger.warning("No videos found for random selection")
      throw IntentError.noVideosFound
    }

    // Prefer unwatched videos (watchProgress == 0)
    let unwatchedVideos = allVideos.filter { $0.watchProgress == 0 }

    // Use weighted random selection - prefer unwatched but allow watched
    let selectedVideo: VideoItem
    if !unwatchedVideos.isEmpty && Double.random(in: 0...1) < 0.8 {
      // 80% chance to pick from unwatched if available
      selectedVideo = unwatchedVideos.randomElement()!
    } else {
      // Pick from all videos
      selectedVideo = allVideos.randomElement()!
    }

    return VideoEntity(from: selectedVideo)
  }

  // MARK: - Private Helpers

  private func getModelContainer() throws -> ModelContainer {
    let schema = Schema([VideoItem.self, ClusterLabel.self, Note.self])
    let config = ModelConfiguration(schema: schema)
    return try ModelContainer(for: schema, configurations: [config])
  }
}

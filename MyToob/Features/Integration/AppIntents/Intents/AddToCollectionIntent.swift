//
//  AddToCollectionIntent.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import OSLog
import SwiftData

/// App Intent to add a video to a collection.
/// Adds the collection label to the video's aiTopicTags and marks for re-indexing.
struct AddToCollectionIntent: AppIntent {

  // MARK: - Intent Metadata

  static var title: LocalizedStringResource = "Add Video to Collection"
  static var description = IntentDescription("Add a video to a collection in MyToob")

  // MARK: - Parameters

  @Parameter(title: "Video")
  var video: VideoEntity

  @Parameter(title: "Collection")
  var collection: CollectionEntity

  // MARK: - Logging

  private static let logger = Logger(subsystem: "com.mytoob.app", category: "AddToCollectionIntent")

  // MARK: - Perform

  /// Execute the intent
  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    Self.logger.info(
      "Adding video \(video.id, privacy: .private) to collection \(collection.label, privacy: .public)"
    )

    let container = try getModelContainer()
    let result = try await perform(in: container)

    Self.logger.debug("Successfully added video to collection")
    return .result(value: result)
  }

  /// Execute the intent with a specific container (for testing)
  @MainActor
  func perform(in container: ModelContainer) async throws -> String {
    let context = ModelContext(container)

    // Find the video in the database
    let descriptor = FetchDescriptor<VideoItem>()
    let allVideos = try context.fetch(descriptor)

    guard let videoItem = allVideos.first(where: { $0.identifier == video.id }) else {
      Self.logger.error("Video not found: \(video.id, privacy: .private)")
      throw IntentError.videoNotFound
    }

    // Add collection label to aiTopicTags if not already present
    if !videoItem.aiTopicTags.contains(collection.label) {
      var tags = videoItem.aiTopicTags
      tags.append(collection.label)
      videoItem.aiTopicTags = tags

      Self.logger.debug(
        "Added tag '\(collection.label, privacy: .public)' to video \(video.id, privacy: .private)")
    }

    // Save changes
    try context.save()

    return "Added \(video.title) to \(collection.label)"
  }

  // MARK: - Private Helpers

  private func getModelContainer() throws -> ModelContainer {
    let schema = Schema([VideoItem.self, ClusterLabel.self, Note.self])
    let config = ModelConfiguration(schema: schema)
    return try ModelContainer(for: schema, configurations: [config])
  }
}

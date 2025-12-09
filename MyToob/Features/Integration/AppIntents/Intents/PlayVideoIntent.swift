//
//  PlayVideoIntent.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation
import OSLog
import SwiftData

/// App Intent to play a video in MyToob.
/// Launches the app and navigates to the specified video.
struct PlayVideoIntent: AppIntent {

  // MARK: - Intent Metadata

  static var title: LocalizedStringResource = "Play Video"
  static var description = IntentDescription("Play a video in MyToob")
  static var openAppWhenRun: Bool = true

  // MARK: - Parameters

  @Parameter(title: "Video")
  var video: VideoEntity

  // MARK: - Logging

  private static let logger = Logger(subsystem: "com.mytoob.app", category: "PlayVideoIntent")

  // MARK: - Result Type

  /// Result returned by the intent
  struct PlayVideoResult {
    let videoIdentifier: String
  }

  // MARK: - Perform

  /// Execute the intent
  @MainActor
  func perform() async throws -> some IntentResult {
    Self.logger.info("Playing video: \(video.id, privacy: .private)")

    let container = try getModelContainer()
    let result = try await perform(in: container)

    // Return a simple result - the app will handle navigation
    return .result()
  }

  /// Execute the intent with a specific container (for testing)
  @MainActor
  func perform(in container: ModelContainer) async throws -> PlayVideoResult {
    let context = ModelContext(container)

    // Find the video in the database
    let descriptor = FetchDescriptor<VideoItem>()
    let allVideos = try context.fetch(descriptor)

    guard let videoItem = allVideos.first(where: { $0.identifier == video.id }) else {
      Self.logger.error("Video not found: \(video.id, privacy: .private)")
      throw IntentError.videoNotFound
    }

    // Update last watched timestamp
    videoItem.lastWatchedAt = Date()
    try context.save()

    Self.logger.debug("Updated lastWatchedAt for video: \(video.id, privacy: .private)")

    return PlayVideoResult(videoIdentifier: video.id)
  }

  // MARK: - Private Helpers

  private func getModelContainer() throws -> ModelContainer {
    let schema = Schema([VideoItem.self, ClusterLabel.self, Note.self])
    let config = ModelConfiguration(schema: schema)
    return try ModelContainer(for: schema, configurations: [config])
  }
}

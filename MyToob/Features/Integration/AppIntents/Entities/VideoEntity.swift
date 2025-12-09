//
//  VideoEntity.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation

/// App Intent entity representing a video in the MyToob library.
/// Maps from VideoItem model for use in Shortcuts and Siri.
struct VideoEntity: AppEntity, Identifiable, Hashable, Codable, Sendable {

  // MARK: - AppEntity Protocol

  typealias DefaultQuery = VideoEntityQuery

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Video")
  }

  static var defaultQuery = VideoEntityQuery()

  // MARK: - Properties

  /// Unique identifier - videoID for YouTube videos, file path for local videos
  let id: String

  /// Video title
  let title: String

  /// Total duration in seconds
  let duration: TimeInterval

  /// Whether this is a local file (true) or YouTube video (false)
  let isLocal: Bool

  // MARK: - Display Representation

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: title)
    )
  }

  // MARK: - Initialization

  /// Initialize from a VideoItem model
  /// - Parameter videoItem: The VideoItem to convert to an entity
  init(from videoItem: VideoItem) {
    self.id = videoItem.identifier
    self.title = videoItem.title
    self.duration = videoItem.duration
    self.isLocal = videoItem.isLocal
  }

  /// Initialize directly with values (for testing and Codable)
  init(
    id: String,
    title: String,
    duration: TimeInterval,
    isLocal: Bool
  ) {
    self.id = id
    self.title = title
    self.duration = duration
    self.isLocal = isLocal
  }

  // MARK: - Hashable

  static func == (lhs: VideoEntity, rhs: VideoEntity) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

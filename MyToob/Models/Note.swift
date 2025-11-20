//
//  Note.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import Foundation
import SwiftData

/// User-created note attached to a video item.
/// Supports Markdown formatting and optional timestamp linking to specific video positions.
@Model
final class Note {
  /// Unique identifier for this note
  @Attribute(.unique) var noteID: String

  /// Note content in Markdown format
  /// Supports bidirectional links and citations
  var content: String

  /// Optional timestamp in seconds for time-linked notes
  /// Nil indicates a general note not tied to a specific moment
  var timestamp: TimeInterval?

  /// When this note was created
  var createdAt: Date

  /// When this note was last updated
  var updatedAt: Date

  /// Relationship to the parent video item
  /// Deletion of the video item will cascade delete associated notes
  var videoItem: VideoItem?

  init(
    noteID: String = UUID().uuidString,
    content: String,
    timestamp: TimeInterval? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    videoItem: VideoItem? = nil
  ) {
    self.noteID = noteID
    self.content = content
    self.timestamp = timestamp
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.videoItem = videoItem
  }

  /// Formatted timestamp for display (e.g., "1:23:45")
  var formattedTimestamp: String? {
    guard let timestamp = timestamp else { return nil }

    let hours = Int(timestamp) / 3600
    let minutes = Int(timestamp) / 60 % 60
    let seconds = Int(timestamp) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }

  /// Update the note content and timestamp
  func update(content: String? = nil, timestamp: TimeInterval? = nil) {
    if let newContent = content {
      self.content = newContent
    }
    if let newTimestamp = timestamp {
      self.timestamp = newTimestamp
    }
    self.updatedAt = Date()
  }
}

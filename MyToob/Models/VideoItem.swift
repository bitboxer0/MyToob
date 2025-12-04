//
//  VideoItem.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import Foundation
import SwiftData

/// Represents both YouTube videos and local video files.
/// YouTube items have a non-nil `videoID`, while local files have a non-nil `localURL`.
@Model
final class VideoItem {
  /// YouTube video ID (e.g., "dQw4w9WgXcQ"). Nil for local files.
  @Attribute(.unique) var videoID: String?

  /// File URL for local video files. Nil for YouTube videos.
  var localURL: URL?

  /// Video title
  var title: String

  /// YouTube channel ID (nil for local files)
  var channelID: String?

  /// Total duration in seconds
  var duration: TimeInterval

  /// Current watch progress in seconds
  var watchProgress: TimeInterval

  /// Whether this is a local file (true) or YouTube video (false)
  var isLocal: Bool

  /// AI-generated topic tags for organization (stored as Data)
  @Attribute(.externalStorage) private var aiTopicTagsData = Data()

  /// Computed property for accessing tags as String array
  var aiTopicTags: [String] {
    get {
      (try? JSONDecoder().decode([String].self, from: aiTopicTagsData)) ?? []
    }
    set {
      aiTopicTagsData = (try? JSONEncoder().encode(newValue)) ?? Data()
    }
  }

  /// 512-dimensional embedding vector for semantic search (stored as Data)
  /// Uses Apple NLEmbedding sentence embeddings, L2-normalized.
  /// Nil until AI processing is complete
  @Attribute(.externalStorage) private var embeddingData: Data?

  /// Computed property for accessing embedding as Float array
  var embedding: [Float]? {
    get {
      guard let data = embeddingData else { return nil }
      return try? JSONDecoder().decode([Float].self, from: data)
    }
    set {
      if let value = newValue {
        embeddingData = try? JSONEncoder().encode(value)
      } else {
        embeddingData = nil
      }
    }
  }

  /// When this item was added to the library
  var addedAt: Date

  /// Most recent time the user watched this item (nil if never watched)
  var lastWatchedAt: Date?

  /// Relationship to user notes
  @Relationship(deleteRule: .cascade, inverse: \Note.videoItem) var notes: [Note]?

  /// Security-scoped bookmark data for persistent file access (local files only)
  /// Allows sandboxed app to access user-selected files across launches
  @Attribute(.externalStorage) var bookmarkData: Data?

  /// Designated initializer for YouTube videos
  init(
    videoID: String,
    title: String,
    channelID: String?,
    duration: TimeInterval,
    watchProgress: TimeInterval = 0,
    aiTopicTags: [String] = [],
    embedding: [Float]? = nil,
    addedAt: Date = Date(),
    lastWatchedAt: Date? = nil
  ) {
    self.videoID = videoID
    self.localURL = nil
    self.title = title
    self.channelID = channelID
    self.duration = duration
    self.watchProgress = watchProgress
    self.isLocal = false
    self.aiTopicTagsData = (try? JSONEncoder().encode(aiTopicTags)) ?? Data()
    if let embedding = embedding {
      self.embeddingData = try? JSONEncoder().encode(embedding)
    } else {
      self.embeddingData = nil
    }
    self.addedAt = addedAt
    self.lastWatchedAt = lastWatchedAt
    self.bookmarkData = nil  // YouTube videos don't need bookmarks
    self.notes = []  // Initialize empty notes array for relationship
  }

  /// Designated initializer for local video files
  init(
    localURL: URL,
    title: String,
    duration: TimeInterval,
    watchProgress: TimeInterval = 0,
    aiTopicTags: [String] = [],
    embedding: [Float]? = nil,
    addedAt: Date = Date(),
    lastWatchedAt: Date? = nil,
    bookmarkData: Data? = nil
  ) {
    self.videoID = nil
    self.localURL = localURL
    self.title = title
    self.channelID = nil
    self.duration = duration
    self.watchProgress = watchProgress
    self.isLocal = true
    self.aiTopicTagsData = (try? JSONEncoder().encode(aiTopicTags)) ?? Data()
    if let embedding = embedding {
      self.embeddingData = try? JSONEncoder().encode(embedding)
    } else {
      self.embeddingData = nil
    }
    self.addedAt = addedAt
    self.lastWatchedAt = lastWatchedAt
    self.bookmarkData = bookmarkData
    self.notes = []  // Initialize empty notes array for relationship
  }

  /// Computed property for unique identifier (videoID for YouTube, localURL path for local)
  var identifier: String {
    if let videoID = videoID {
      return videoID
    } else if let localURL = localURL {
      return localURL.path
    }
    return UUID().uuidString  // Fallback (should never happen)
  }

  /// Watch progress as percentage (0.0 to 1.0)
  var progressPercentage: Double {
    guard duration > 0 else { return 0 }
    return min(watchProgress / duration, 1.0)
  }
}

// MARK: - Blacklist Helper Extensions

extension VideoItem {
  /// Check if this video belongs to a hidden channel
  /// - Parameter hiddenChannelIDs: Set of channel IDs that are hidden
  /// - Returns: `true` if this video's channel is in the hidden set, `false` otherwise
  func isFromHiddenChannel(hiddenChannelIDs: Set<String>) -> Bool {
    guard let channelID = self.channelID else { return false }
    return hiddenChannelIDs.contains(channelID)
  }

  /// Check if this video belongs to a hidden channel
  /// - Parameter blacklist: Array of `ChannelBlacklist` entries
  /// - Returns: `true` if this video's channel is in the blacklist, `false` otherwise
  func isFromHiddenChannel(blacklist: [ChannelBlacklist]) -> Bool {
    guard let channelID = self.channelID else { return false }
    return blacklist.contains { $0.channelID == channelID }
  }
}

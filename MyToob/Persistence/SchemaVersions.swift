//
//  SchemaVersions.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/26/25.
//

import Foundation
import SwiftData

// MARK: - Schema V1 (Initial Release)

/// Original schema with VideoItem, ClusterLabel, Note, and ChannelBlacklist.
enum SchemaV1: VersionedSchema {
  static var versionIdentifier = Schema.Version(1, 0, 0)

  static var models: [any PersistentModel.Type] {
    [VideoItem.self, ClusterLabel.self, Note.self, ChannelBlacklist.self]
  }
}

// MARK: - Schema V2 (Adds lastAccessedAt)

/// Extended schema adding `lastAccessedAt` tracking to VideoItem.
/// Uses VideoItemV2 model type with the additional optional property.
enum SchemaV2: VersionedSchema {
  static var versionIdentifier = Schema.Version(2, 0, 0)

  static var models: [any PersistentModel.Type] {
    [VideoItemV2.self, ClusterLabel.self, Note.self, ChannelBlacklist.self]
  }
}

// MARK: - VideoItemV2 Model

/// VideoItem model version 2 - adds `lastAccessedAt` for access tracking.
/// Mirrors all V1 properties plus the new optional date property.
///
/// ## Schema Alignment Requirement
/// **IMPORTANT:** This model must stay property-aligned with `VideoItem` (in Models/VideoItem.swift).
/// SwiftData versioned schemas require separate model types for each version, which means:
/// - Any property added to `VideoItem` must also be added to `VideoItemV2` (and future versions)
/// - Any property changes require coordinated updates across both models
/// - When adding a new schema version (V3, etc.), create a new `VideoItemV3` model class
///
/// Keep these properties synchronized:
/// - `videoID`, `localURL`, `title`, `channelID`, `duration`, `watchProgress`, `isLocal`
/// - `aiTopicTagsData`/`aiTopicTags`, `embeddingData`/`embedding`
/// - `addedAt`, `lastWatchedAt`, `notes`, `bookmarkData`
/// - V2 addition: `lastAccessedAt`
@Model
final class VideoItemV2 {
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

  /// 384-dimensional embedding vector for semantic search (stored as Data)
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

  // MARK: - V2 Addition

  /// Most recent time this item was accessed (viewed in UI, searched, etc.)
  /// Nil if never accessed since migration to V2.
  var lastAccessedAt: Date?

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
    lastWatchedAt: Date? = nil,
    lastAccessedAt: Date? = nil
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
    self.lastAccessedAt = lastAccessedAt
    self.bookmarkData = nil
    self.notes = []
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
    lastAccessedAt: Date? = nil,
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
    self.lastAccessedAt = lastAccessedAt
    self.bookmarkData = bookmarkData
    self.notes = []
  }

  /// Computed property for unique identifier (videoID for YouTube, localURL path for local)
  var identifier: String {
    if let videoID = videoID {
      return videoID
    } else if let localURL = localURL {
      return localURL.path
    }
    // FIXME: This fallback generates a new UUID on every access, causing instability in equality
    // checks and persistence. Before shipping, either:
    // 1. Enforce that videoID or localURL is always set (remove this fallback entirely), or
    // 2. Store a generated stable ID as a persisted property when neither is present.
    // This should never happen in practice since all initializers require one of videoID/localURL.
    return UUID().uuidString
  }

  /// Watch progress as percentage (0.0 to 1.0)
  var progressPercentage: Double {
    guard duration > 0 else { return 0 }
    return min(watchProgress / duration, 1.0)
  }
}

// MARK: - Schema Convenience

/// The latest schema version for use in ModelContainer initialization.
let latestSchema = Schema(versionedSchema: SchemaV2.self)

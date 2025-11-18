//
//  VideoItem.swift
//  MyToob
//
//  Created by Claude Code (BMad Master)
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

    /// AI-generated topic tags for organization
    @Attribute(.transformable) var aiTopicTags: [String]

    /// 384-dimensional embedding vector for semantic search
    /// Nil until AI processing is complete
    @Attribute(.transformable) var embedding: [Float]?

    /// When this item was added to the library
    var addedAt: Date

    /// Most recent time the user watched this item (nil if never watched)
    var lastWatchedAt: Date?

    /// Relationship to user notes
    @Relationship(deleteRule: .cascade, inverse: \Note.videoItem)
    var notes: [Note]?

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
        self.aiTopicTags = aiTopicTags
        self.embedding = embedding
        self.addedAt = addedAt
        self.lastWatchedAt = lastWatchedAt
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
        lastWatchedAt: Date? = nil
    ) {
        self.videoID = nil
        self.localURL = localURL
        self.title = title
        self.channelID = nil
        self.duration = duration
        self.watchProgress = watchProgress
        self.isLocal = true
        self.aiTopicTags = aiTopicTags
        self.embedding = embedding
        self.addedAt = addedAt
        self.lastWatchedAt = lastWatchedAt
    }

    /// Computed property for unique identifier (videoID for YouTube, localURL path for local)
    var identifier: String {
        if let videoID = videoID {
            return videoID
        } else if let localURL = localURL {
            return localURL.path
        }
        return UUID().uuidString // Fallback (should never happen)
    }

    /// Watch progress as percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard duration > 0 else { return 0 }
        return min(watchProgress / duration, 1.0)
    }
}

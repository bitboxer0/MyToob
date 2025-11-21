//
//  YouTubeAPIModels.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

import Foundation

// MARK: - Search Endpoint Models

/// Response from YouTube Data API search.list endpoint
struct YouTubeSearchResponse: Codable {
  let items: [YouTubeSearchItem]
  let nextPageToken: String?
  let pageInfo: YouTubePageInfo?

  enum CodingKeys: String, CodingKey {
    case items
    case nextPageToken
    case pageInfo
  }
}

struct YouTubeSearchItem: Codable {
  let id: YouTubeSearchID
  let snippet: YouTubeSnippet
}

struct YouTubeSearchID: Codable {
  let kind: String
  let videoId: String?
  let channelId: String?
  let playlistId: String?

  enum CodingKeys: String, CodingKey {
    case kind
    case videoId
    case channelId
    case playlistId
  }
}

// MARK: - Videos Endpoint Models

/// Response from YouTube Data API videos.list endpoint
struct YouTubeVideoListResponse: Codable {
  let items: [YouTubeVideo]
  let pageInfo: YouTubePageInfo?
}

struct YouTubeVideo: Codable {
  let id: String
  let snippet: YouTubeSnippet
  let contentDetails: YouTubeContentDetails?
  let statistics: YouTubeStatistics?
}

// MARK: - Channels Endpoint Models

/// Response from YouTube Data API channels.list endpoint
struct YouTubeChannelResponse: Codable {
  let items: [YouTubeChannel]
  let pageInfo: YouTubePageInfo?
}

struct YouTubeChannel: Codable {
  let id: String
  let snippet: YouTubeSnippet
  let statistics: YouTubeChannelStatistics?
  let contentDetails: YouTubeChannelContentDetails?
}

struct YouTubeChannelStatistics: Codable {
  let subscriberCount: String?
  let videoCount: String?
  let viewCount: String?
}

struct YouTubeChannelContentDetails: Codable {
  let relatedPlaylists: YouTubeRelatedPlaylists?
}

struct YouTubeRelatedPlaylists: Codable {
  let uploads: String?
  let likes: String?
}

// MARK: - Playlists Endpoint Models

/// Response from YouTube Data API playlists.list endpoint
struct YouTubePlaylistResponse: Codable {
  let items: [YouTubePlaylist]
  let nextPageToken: String?
  let pageInfo: YouTubePageInfo?
}

struct YouTubePlaylist: Codable {
  let id: String
  let snippet: YouTubeSnippet
  let contentDetails: YouTubePlaylistContentDetails?
}

struct YouTubePlaylistContentDetails: Codable {
  let itemCount: Int?
}

// MARK: - PlaylistItems Endpoint Models

/// Response from YouTube Data API playlistItems.list endpoint
struct YouTubePlaylistItemsResponse: Codable {
  let items: [YouTubePlaylistItem]
  let nextPageToken: String?
  let pageInfo: YouTubePageInfo?
}

struct YouTubePlaylistItem: Codable {
  let id: String?
  let snippet: YouTubePlaylistItemSnippet
  let contentDetails: YouTubePlaylistItemContentDetails?
}

struct YouTubePlaylistItemContentDetails: Codable {
  let videoId: String?
  let videoPublishedAt: String?
}

struct YouTubePlaylistItemSnippet: Codable {
  let title: String
  let description: String
  let thumbnails: YouTubeThumbnails
  let channelId: String
  let channelTitle: String
  let publishedAt: String
  let resourceId: YouTubeResourceID
  let position: Int?

  enum CodingKeys: String, CodingKey {
    case title
    case description
    case thumbnails
    case channelId
    case channelTitle
    case publishedAt
    case resourceId
    case position
  }
}

struct YouTubeResourceID: Codable {
  let kind: String
  let videoId: String?
  let channelId: String?
}

// MARK: - Subscriptions Endpoint Models

/// Response from YouTube Data API subscriptions.list endpoint
struct YouTubeSubscriptionResponse: Codable {
  let items: [YouTubeSubscription]
  let nextPageToken: String?
  let pageInfo: YouTubePageInfo?
}

struct YouTubeSubscription: Codable {
  let id: String
  let snippet: YouTubeSubscriptionSnippet
}

struct YouTubeSubscriptionSnippet: Codable {
  let title: String
  let description: String
  let resourceId: YouTubeResourceID
  let channelId: String
  let thumbnails: YouTubeThumbnails
  let publishedAt: String
}

// MARK: - Shared Models

/// Common snippet structure used across multiple endpoints
struct YouTubeSnippet: Codable {
  let title: String
  let description: String
  let thumbnails: YouTubeThumbnails
  let channelId: String
  let channelTitle: String
  let publishedAt: String
  let tags: [String]?
  let categoryId: String?
  let defaultLanguage: String?

  enum CodingKeys: String, CodingKey {
    case title
    case description
    case thumbnails
    case channelId
    case channelTitle
    case publishedAt
    case tags
    case categoryId
    case defaultLanguage
  }
}

struct YouTubeThumbnails: Codable {
  let `default`: YouTubeThumbnail?
  let medium: YouTubeThumbnail?
  let high: YouTubeThumbnail?
  let standard: YouTubeThumbnail?
  let maxres: YouTubeThumbnail?

  enum CodingKeys: String, CodingKey {
    case `default` = "default"
    case medium
    case high
    case standard
    case maxres
  }
}

struct YouTubeThumbnail: Codable {
  let url: String
  let width: Int?
  let height: Int?
}

struct YouTubeContentDetails: Codable {
  let duration: String // ISO 8601 duration format (e.g., "PT4M13S")
  let dimension: String? // "2d" or "3d"
  let definition: String? // "hd" or "sd"
  let caption: String? // "true" or "false"
  let licensedContent: Bool?
  let projection: String? // "rectangular" or "360"
}

struct YouTubeStatistics: Codable {
  let viewCount: String?
  let likeCount: String?
  let commentCount: String?
  let favoriteCount: String?

  enum CodingKeys: String, CodingKey {
    case viewCount
    case likeCount
    case commentCount
    case favoriteCount
  }
}

struct YouTubePageInfo: Codable {
  let totalResults: Int?
  let resultsPerPage: Int?
}

// MARK: - Error Response Models

/// YouTube API error response structure
struct YouTubeAPIErrorResponse: Codable {
  let error: YouTubeAPIErrorDetails
}

struct YouTubeAPIErrorDetails: Codable {
  let code: Int
  let message: String
  let errors: [YouTubeAPIErrorItem]?
  let status: String?
}

struct YouTubeAPIErrorItem: Codable {
  let domain: String?
  let reason: String?
  let message: String?
  let locationType: String?
  let location: String?
}

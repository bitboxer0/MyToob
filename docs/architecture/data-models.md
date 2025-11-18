# Data Models

## VideoItem

**Purpose:** Core entity representing a video (YouTube or local file) with metadata, AI-generated data, and playback state.

**Key Attributes:**
- `videoID`: String? - YouTube video ID (nil for local files)
- `localURL`: URL? - File URL for local videos (nil for YouTube)
- `title`: String - Video title (from YouTube API or filename)
- `channelID`: String? - YouTube channel ID (nil for local)
- `channelTitle`: String? - Channel display name
- `description`: String? - Video description
- `duration`: TimeInterval - Video length in seconds
- `thumbnailURL`: URL? - Thumbnail image URL (YouTube or generated for local)
- `watchProgress`: TimeInterval - Current playback position (0-duration)
- `isLocal`: Bool - True if local file, false if YouTube
- `aiTopicTags`: [String] - AI-generated topic labels
- `embedding`: [Float]? - 384-dim vector (nil if not yet generated)
- `addedAt`: Date - When video was imported/added
- `lastWatchedAt`: Date? - Last playback timestamp
- `clusterID`: String? - ID of assigned cluster (nil if unclustered)

**SwiftData Model:**
```swift
@Model
final class VideoItem {
    @Attribute(.unique) var id: UUID
    var videoID: String?  // YouTube: "dQw4w9WgXcQ", Local: nil
    var localURL: URL?
    var title: String
    var channelID: String?
    var channelTitle: String?
    var desc: String?  // "description" reserved keyword
    var duration: TimeInterval
    var thumbnailURL: URL?
    var watchProgress: TimeInterval
    var isLocal: Bool

    @Attribute(.transformable) var aiTopicTags: [String]
    @Attribute(.transformable) var embedding: [Float]?

    var addedAt: Date
    var lastWatchedAt: Date?
    var clusterID: String?

    @Relationship(deleteRule: .cascade) var notes: [Note]?
    @Relationship(inverse: \Collection.videos) var collections: [Collection]?

    init(id: UUID = UUID(), videoID: String? = nil, localURL: URL? = nil, title: String, ...) {
        self.id = id
        self.videoID = videoID
        self.localURL = localURL
        self.title = title
        // ...
    }
}
```

**Relationships:**
- **notes:** One-to-many with `Note` (cascade delete)
- **collections:** Many-to-many with `Collection` (video can be in multiple collections)

---

## ClusterLabel

**Purpose:** Represents an AI-generated topic cluster with metadata and centroid vector for similarity comparisons.

**Key Attributes:**
- `clusterID`: String - Unique cluster identifier (UUID)
- `label`: String - Human-readable label ("Swift Concurrency", "Machine Learning")
- `centroid`: [Float] - 384-dim centroid vector (average of member embeddings)
- `itemCount`: Int - Number of videos in cluster (denormalized for performance)
- `createdAt`: Date - When cluster was generated
- `userEdited`: Bool - True if user renamed cluster

**SwiftData Model:**
```swift
@Model
final class ClusterLabel {
    @Attribute(.unique) var clusterID: String
    var label: String
    @Attribute(.transformable) var centroid: [Float]
    var itemCount: Int
    var createdAt: Date
    var userEdited: Bool

    init(clusterID: String = UUID().uuidString, label: String, centroid: [Float], itemCount: Int) {
        self.clusterID = clusterID
        self.label = label
        self.centroid = centroid
        self.itemCount = itemCount
        self.createdAt = Date()
        self.userEdited = false
    }
}
```

**Relationships:** None (referenced by `VideoItem.clusterID` but not a formal relationship for performance)

---

## Note

**Purpose:** User-created notes associated with videos, supporting Markdown formatting and timestamp anchors.

**Key Attributes:**
- `noteID`: UUID - Unique identifier
- `content`: String - Markdown-formatted text
- `timestamp`: TimeInterval? - Video position anchor (nil if not timestamp-specific)
- `createdAt`: Date
- `updatedAt`: Date

**SwiftData Model:**
```swift
@Model
final class Note {
    @Attribute(.unique) var noteID: UUID
    var content: String
    var timestamp: TimeInterval?
    var createdAt: Date
    var updatedAt: Date

    @Relationship var video: VideoItem?

    init(noteID: UUID = UUID(), content: String, timestamp: TimeInterval? = nil) {
        self.noteID = noteID
        self.content = content
        self.timestamp = timestamp
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

**Relationships:**
- **video:** Many-to-one with `VideoItem` (note belongs to one video)

---

## Collection

**Purpose:** User-created or AI-generated collections for organizing videos.

**Key Attributes:**
- `collectionID`: UUID
- `name`: String - User-defined name
- `desc`: String? - Optional description
- `isAutomatic`: Bool - True if AI-generated (from cluster), false if manual
- `createdAt`: Date
- `sortOrder`: Int? - Custom sort order (optional)

**SwiftData Model:**
```swift
@Model
final class Collection {
    @Attribute(.unique) var collectionID: UUID
    var name: String
    var desc: String?
    var isAutomatic: Bool
    var createdAt: Date
    var sortOrder: Int?

    @Relationship var videos: [VideoItem]?

    init(collectionID: UUID = UUID(), name: String, isAutomatic: Bool = false) {
        self.collectionID = collectionID
        self.name = name
        self.isAutomatic = isAutomatic
        self.createdAt = Date()
    }
}
```

**Relationships:**
- **videos:** Many-to-many with `VideoItem` (collection contains multiple videos)

---

## ChannelBlacklist

**Purpose:** Tracks YouTube channels hidden by user (UGC moderation).

**Key Attributes:**
- `channelID`: String - YouTube channel ID (unique)
- `reason`: String? - Optional reason for hiding
- `blockedAt`: Date

**SwiftData Model:**
```swift
@Model
final class ChannelBlacklist {
    @Attribute(.unique) var channelID: String
    var reason: String?
    var blockedAt: Date

    init(channelID: String, reason: String? = nil) {
        self.channelID = channelID
        self.reason = reason
        self.blockedAt = Date()
    }
}
```

**Relationships:** None

---

## FocusModeSettings

**Purpose:** Stores Focus Mode preferences and scheduling configuration.

**Key Attributes:**
- `enabled`: Bool - Global Focus Mode on/off
- `hideYouTubeSidebar`: Bool
- `hideRelatedVideos`: Bool
- `hideComments`: Bool
- `hideHomepageFeed`: Bool
- `preset`: String - "minimal", "moderate", "maximum", "custom"
- `scheduleEnabled`: Bool (Pro feature)
- `scheduleStartTime`: Date? - Time-of-day for auto-enable
- `scheduleEndTime`: Date?
- `scheduleDays`: [Int] - Weekdays bitmask (1=Mon, 2=Tue, ..., 127=All)

**SwiftData Model:**
```swift
@Model
final class FocusModeSettings {
    @Attribute(.unique) var id: UUID // Singleton pattern (only one instance)
    var enabled: Bool
    var hideYouTubeSidebar: Bool
    var hideRelatedVideos: Bool
    var hideComments: Bool
    var hideHomepageFeed: Bool
    var preset: String
    var scheduleEnabled: Bool
    var scheduleStartTime: Date?
    var scheduleEndTime: Date?
    @Attribute(.transformable) var scheduleDays: [Int]

    init() {
        self.id = UUID()
        self.enabled = false
        self.hideYouTubeSidebar = false
        self.hideRelatedVideos = false
        self.hideComments = false
        self.hideHomepageFeed = false
        self.preset = "custom"
        self.scheduleEnabled = false
        self.scheduleDays = []
    }
}
```

---

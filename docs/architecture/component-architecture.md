# Component Architecture

## 1. YouTubeService

**Responsibility:** Handles all YouTube API interactions (OAuth, Data API requests, quota management).

**Key Interfaces:**
```swift
protocol YouTubeServiceProtocol {
    func authenticate() async throws -> OAuth2Tokens
    func fetchSubscriptions(pageToken: String?) async throws -> YouTubeSubscriptionsResponse
    func fetchPlaylist(playlistID: String) async throws -> YouTubePlaylistResponse
    func fetchVideoDetails(videoIDs: [String]) async throws -> [YouTubeVideo]
    func searchVideos(query: String, maxResults: Int) async throws -> YouTubeSearchResponse
}
```

**Dependencies:**
- `NetworkService` (URLSession wrapper)
- `KeychainService` (OAuth token storage)
- `QuotaBudgetTracker` (API quota enforcement)

**Technology Stack:** Swift async/await, URLSession, ASWebAuthenticationSession (OAuth)

**Implementation Notes:**
- OAuth tokens stored in Keychain with automatic refresh
- All API requests include ETag headers for caching
- Quota budget tracked per-endpoint with circuit breaker on 429 responses
- Field filtering applied to minimize payload size (e.g., `part=snippet&fields=items(id,snippet(title))`)

---

## 2. LocalFileService

**Responsibility:** Manages local video file import, metadata extraction, and security-scoped bookmarks.

**Key Interfaces:**
```swift
protocol LocalFileServiceProtocol {
    func importFiles(urls: [URL]) async throws -> [VideoItem]
    func extractMetadata(url: URL) async throws -> VideoMetadata
    func createSecurityScopedBookmark(url: URL) throws -> Data
    func resolveBookmark(data: Data) throws -> URL
}
```

**Dependencies:**
- `AVAsset` (metadata extraction)
- `FileManager` (file access)
- `BookmarkStore` (SwiftData persistence for bookmarks)

**Technology Stack:** AVFoundation, FileManager, SwiftData

**Implementation Notes:**
- Security-scoped bookmarks required for sandbox compliance (persist in SwiftData)
- Metadata extraction (duration, resolution, codec) via AVAsset asynchronously
- Thumbnail generation using AVAssetImageGenerator
- Drag-and-drop support via NSOpenPanel

---

## 3. AIService

**Responsibility:** On-device AI processing (embeddings, clustering, ranking).

**Key Interfaces:**
```swift
protocol AIServiceProtocol {
    func generateEmbedding(text: String) async throws -> [Float]
    func extractThumbnailText(image: NSImage) async throws -> String
    func buildVectorIndex(items: [VideoItem]) async throws -> VectorIndex
    func clusterVideos(index: VectorIndex) async throws -> [ClusterLabel]
    func rankResults(query: [Float], candidates: [VideoItem]) -> [VideoItem]
}
```

**Dependencies:**
- `Core ML` (embedding model inference)
- `Vision` framework (OCR)
- `VectorIndexStore` (HNSW index persistence)
- `ClusteringEngine` (Leiden/Louvain algorithm)

**Technology Stack:** Core ML, Vision, Custom HNSW, Custom Clustering

**Implementation Notes:**
- Embedding model: Sentence-transformer (384-dim) quantized to 8-bit for performance
- Text preprocessing: lowercase, truncate to 256 tokens
- OCR confidence threshold: 0.5 (discard low-confidence results)
- HNSW parameters: M=16, ef_construction=200
- Clustering triggers: on import, manually, when library grows >10%
- Ranking features: cosine similarity, recency, watch completion %, dwell time

---

## 4. PlayerService

**Responsibility:** Unified player abstraction for YouTube (IFrame) and local (AVKit) playback.

**Key Interfaces:**
```swift
protocol PlayerProtocol {
    func load(videoID: String) async
    func play()
    func pause()
    func seek(to time: TimeInterval)
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var statePublisher: AnyPublisher<PlayerState, Never> { get }
}

class YouTubePlayer: PlayerProtocol { ... }
class AVKitPlayer: PlayerProtocol { ... }

enum PlayerFactory {
    static func createPlayer(for item: VideoItem) -> PlayerProtocol {
        item.isLocal ? AVKitPlayer(url: item.localURL!) : YouTubePlayer(videoID: item.videoID!)
    }
}
```

**Dependencies:**
- `WKWebView` (YouTube IFrame Player)
- `AVPlayer` (local playback)

**Technology Stack:** WKWebView, AVFoundation, Combine

**Implementation Notes:**
- YouTube player: JavaScript bridge for play/pause/seek, state events via WKScriptMessageHandler
- AVKit player: Native AVPlayerView with transport controls
- Player visibility enforcement: pause when window hidden/minimized (compliance)
- PiP support: Native only (no DOM manipulation)

---

## 5. SearchService

**Responsibility:** Hybrid search combining keyword and vector similarity with ranking.

**Key Interfaces:**
```swift
protocol SearchServiceProtocol {
    func search(query: String, mode: SearchMode, filters: SearchFilters?) async -> [VideoItem]
}

enum SearchMode {
    case keyword, vector, hybrid
}
```

**Dependencies:**
- `VideoRepository` (SwiftData queries)
- `AIService` (query embedding, vector index)
- `RankingService` (result fusion and ranking)

**Technology Stack:** SwiftData predicates, Core ML, Combine

**Implementation Notes:**
- Keyword: SwiftData predicate on title/description (case-insensitive CONTAINS)
- Vector: Generate query embedding → HNSW kNN search → top-20 candidates
- Hybrid: Reciprocal rank fusion (RRF) with k=60
- Filters applied post-fusion (duration, date, channel, cluster)
- Debounced search (300ms delay after typing stops)

---

## 6. FocusModeManager

**Responsibility:** Manages Focus Mode state, scheduling, and distraction hiding preferences.

**Key Interfaces:**
```swift
protocol FocusModeManagerProtocol {
    var isEnabled: Bool { get set }
    var settings: FocusModeSettings { get }
    func applyPreset(_ preset: FocusModePreset)
    func checkSchedule() // Called on timer to auto-enable/disable
}

enum FocusModePreset {
    case minimal, moderate, maximum, custom
}
```

**Dependencies:**
- `FocusModeSettingsRepository` (SwiftData)
- `NotificationService` (schedule activation notifications)

**Technology Stack:** SwiftData, UserDefaults, Timer

**Implementation Notes:**
- Settings persist in SwiftData with CloudKit sync
- Schedule checked every minute via Timer.publish
- Preset changes update all individual toggles atomically
- Keyboard shortcut (⌘⇧F) toggles enabled state globally

---

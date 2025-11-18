# Epic 5: Local File Playback & Management

**Goal:** Enable users to import and play local video files (MP4, MOV, MKV, etc.) using AVKit, providing a full-featured media player experience for user-owned content. This epic handles file selection, security-scoped bookmarks for persistent access, AVPlayerView integration, and playback state tracking—establishing the local video management capabilities that complement YouTube integration.

## Story 5.1: Local File Import via File Picker

As a **user**,
I want **to import local video files into the app**,
so that **I can organize and play my personal video library alongside YouTube content**.

**Acceptance Criteria:**
1. "Import Local Files" button in sidebar under "Local Files" section
2. Clicking button opens native macOS file picker (`NSOpenPanel`) filtered to video file types: `.mp4`, `.mov`, `.mkv`, `.avi`, `.m4v`
3. File picker allows multiple selection
4. Selected files added to SwiftData as `VideoItem` entries with: `localURL`, `title` (filename), `duration` (extracted via AVAsset), `isLocal = true`
5. Security-scoped bookmark created for each file to maintain access across app launches
6. Import progress shown if adding many files (e.g., 100+ files)
7. Imported files appear in sidebar under "Local Files > All Videos"

## Story 5.2: Security-Scoped Bookmarks for Persistent Access

As a **developer**,
I want **security-scoped bookmarks stored for all local files**,
so that **the app can access user-selected files even after app restart (sandbox requirement)**.

**Acceptance Criteria:**
1. When file selected via `NSOpenPanel`, obtain security-scoped bookmark using `URL.bookmarkData(options: .withSecurityScope)`
2. Bookmark data stored in SwiftData alongside `VideoItem.localURL`
3. On app launch or when accessing file, resolve bookmark using `URL(resolvingBookmarkData:options:)`
4. If bookmark resolution fails (file moved/deleted), show user error: "File not found at original location" with option to re-select
5. "Relocate File" action in video context menu allows user to point to moved file
6. Stale bookmarks cleaned up periodically (remove `VideoItem` if file unavailable for 30+ days)
7. Unit tests verify bookmark creation/resolution with temporary test files

## Story 5.3: AVPlayerView Integration for Local Playback

As a **user**,
I want **to play local video files with native macOS playback controls**,
so that **I have a familiar, high-quality viewing experience**.

**Acceptance Criteria:**
1. `LocalPlayerView` SwiftUI view created wrapping `AVPlayerView` (via `NSViewRepresentable`)
2. `AVPlayer` initialized with `AVAsset` loaded from `VideoItem.localURL`
3. AVPlayerView displays with native transport controls (play/pause, scrubbing, volume, full-screen)
4. Playback starts when `LocalPlayerView` appears with valid local video
5. Scrubbing timeline shows thumbnails (if supported by video codec)
6. Full-screen mode available via native control
7. Playback error handled gracefully (e.g., unsupported codec): show error message, log details

## Story 5.4: Playback State Persistence for Local Files

As a **user**,
I want **the app to remember where I left off in local videos**,
so that **I can resume playback from my last position**.

**Acceptance Criteria:**
1. AVPlayer time updates tracked (every second during playback)
2. Current playback time saved to `VideoItem.watchProgress` in SwiftData
3. When `LocalPlayerView` loads a video, seek to `VideoItem.watchProgress` before starting playback (if >5 seconds)
4. "Mark as Watched" action sets `watchProgress = duration` (100% complete)
5. "Reset Progress" action sets `watchProgress = 0`
6. Progress indicator shown on video thumbnail in library (e.g., progress bar at bottom of thumbnail)
7. Videos with >90% progress marked as "Watched" (visual indicator)

## Story 5.5: Drag-and-Drop File Import

As a **user**,
I want **to drag video files from Finder into the app window**,
so that **I can quickly add local files without using the file picker**.

**Acceptance Criteria:**
1. Main content area accepts drop of file URLs from Finder
2. Dropped files filtered to supported video types (same as file picker)
3. Drag-over visual feedback shown (highlight drop zone, "Drop videos here" message)
4. On drop, files processed same as file picker selection (create `VideoItem`, security-scoped bookmarks)
5. Multiple files dropped at once handled correctly
6. Non-video files dropped show toast notification: "Only video files are supported"
7. UI test verifies drag-and-drop flow with test video files

## Story 5.6: Local File Metadata Extraction

As a **developer**,
I want **to extract metadata from local video files (duration, resolution, codec)**,
so that **users can filter and sort local videos by technical properties**.

**Acceptance Criteria:**
1. On import, use `AVAsset` to extract: `duration`, `resolution` (video track dimensions), `codec` (video/audio codec names), `fileSize`
2. Metadata stored in `VideoItem` model (add new properties if needed)
3. Metadata extraction performed asynchronously (doesn't block UI for large files)
4. If metadata extraction fails, store defaults (duration = 0, resolution = unknown)
5. Metadata displayed in video detail view: "Duration: 1h 24m | Resolution: 1920x1080 | Codec: H.264"
6. Filter pills support filtering by duration range, resolution (SD/HD/4K), and file size
7. Unit tests verify metadata extraction with various video formats (MP4, MOV, MKV)

---

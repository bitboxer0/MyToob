# MyToob: Task Breakdowns Continuation (Epics 2-15)

**This file continues the comprehensive task breakdowns from COMPREHENSIVE_TASK_BREAKDOWNS.md**
**Start: Story 2.4 | End: Story 15.6**

---

## Epic 2 (Continued): YouTube OAuth & Data API Integration

### Story 2.4: ETag-Based Caching for Metadata

**Status:** 📋 Draft
**Depends On:** 2.3 (YouTube API Client)
**File:** `docs/stories/2.4.etag-caching.md`

#### Acceptance Criteria
1. Caching layer stores API responses keyed by request URL + parameters
2. When response includes `ETag` header, cache stores both ETag and response body
3. On subsequent requests, include `If-None-Match: <cached-ETag>` header
4. If server returns `304 Not Modified`, use cached response body (no quota charge)
5. If server returns `200 OK` with new data, update cache with new ETag and body
6. Cache eviction policy: LRU with 1000-item limit or 7-day TTL, whichever comes first
7. Cache hit rate logged for performance monitoring (goal: >90% hit rate on repeated refreshes)

#### Detailed Task Breakdown

**Phase 1: Cache Layer Foundation (AC: 1, 2)**
- [ ] **Task 2.4.1:** Create caching service
  - [ ] Subtask: Create `MyToob/Core/Networking/CachingLayer.swift`
  - [ ] Subtask: Define `CacheEntry` struct with `etag: String`, `body: Data`, `timestamp: Date`
  - [ ] Subtask: Implement in-memory cache using Dictionary `[String: CacheEntry]`
  - [ ] Subtask: Create cache key generation: `func cacheKey(url: URL, parameters: [String: String]) -> String`
  - [ ] Subtask: Implement `save(key:etag:body:)` method
  - [ ] Subtask: Implement `retrieve(key:) -> CacheEntry?` method

**Phase 2: ETag Header Extraction (AC: 2)**
- [ ] **Task 2.4.2:** Extract ETags from responses
  - [ ] Subtask: In YouTubeService response handling, check for `ETag` header
  - [ ] Subtask: Extract ETag value: `response.value(forHTTPHeaderField: "ETag")`
  - [ ] Subtask: Store ETag + response body in cache if present
  - [ ] Subtask: Log ETag storage: `logger.debug("Cached response with ETag: \(etag)")`

**Phase 3: Conditional Request Implementation (AC: 3)**
- [ ] **Task 2.4.3:** Implement If-None-Match header
  - [ ] Subtask: Before API request, check cache for existing entry
  - [ ] Subtask: If cache entry found, add `If-None-Match` header with cached ETag
  - [ ] Subtask: Build URLRequest with conditional header
  - [ ] Subtask: Log conditional request: `logger.debug("Sending conditional request with ETag")`

**Phase 4: 304 Response Handling (AC: 4)**
- [ ] **Task 2.4.4:** Handle Not Modified responses
  - [ ] Subtask: Check HTTP status code for 304
  - [ ] Subtask: If 304, retrieve cached body from cache
  - [ ] Subtask: Parse cached body as API response
  - [ ] Subtask: Log cache hit: `logger.info("Cache hit (304): \(cacheKey)")`
  - [ ] Subtask: Increment cache hit counter (for metrics)

**Phase 5: 200 Response Handling (AC: 5)**
- [ ] **Task 2.4.5:** Handle fresh data responses
  - [ ] Subtask: If 200 OK, extract new ETag from response
  - [ ] Subtask: Update cache with new ETag + body
  - [ ] Subtask: Replace existing entry or create new one
  - [ ] Subtask: Log cache update: `logger.info("Cache updated with new ETag")`

**Phase 6: LRU Eviction Policy (AC: 6)**
- [ ] **Task 2.4.6:** Implement cache eviction
  - [ ] Subtask: Track access time for each cache entry (update on retrieve)
  - [ ] Subtask: Implement LRU eviction: remove least recently used entries when cache full
  - [ ] Subtask: Enforce 1000-item limit: evict oldest when adding 1001st item
  - [ ] Subtask: Implement TTL check: remove entries older than 7 days on access
  - [ ] Subtask: Create background cleanup task (runs daily)

**Phase 7: Cache Metrics (AC: 7)**
- [ ] **Task 2.4.7:** Track and log cache performance
  - [ ] Subtask: Track cache hits vs misses
  - [ ] Subtask: Calculate hit rate: `hits / (hits + misses)`
  - [ ] Subtask: Log metrics periodically (every 100 requests)
  - [ ] Subtask: Expose metrics in dev-only quota dashboard
  - [ ] Subtask: Test target: >90% hit rate for repeated API calls

**Phase 8: Testing**
- [ ] **Task 2.4.8:** Create comprehensive tests
  - [ ] Subtask: Test cache storage and retrieval
  - [ ] Subtask: Test ETag extraction from responses
  - [ ] Subtask: Test 304 handling returns cached data
  - [ ] Subtask: Test 200 updates cache
  - [ ] Subtask: Test LRU eviction (add 1001 items, verify oldest removed)
  - [ ] Subtask: Test TTL eviction (mock time passage)
  - [ ] Subtask: Test cache hit rate calculation

#### Dev Notes
- **Files Created:**
  - `MyToob/Core/Networking/CachingLayer.swift` - ETag cache implementation
  - Modifications to `YouTubeService.swift` - Integrate caching

- **ETag Format:**
  - Example: `ETag: "DXo3WlFzMS14V3hJN09fQUN3MUJRZw"`
  - Must be exact match for conditional requests

- **Cache Persistence:**
  - In-memory for speed (rebuilds on app restart)
  - Optional: Persist to disk in `~/Library/Caches/MyToob/etag-cache.json`

- **Quota Savings:**
  - 304 responses don't consume quota units
  - Estimated 90% reduction in quota usage for repeated subscription refreshes

#### Testing Requirements
- **Unit Tests:**
  - Cache key generation (same URL+params = same key)
  - ETag extraction from HTTP headers
  - 304 response returns cached body
  - 200 response updates cache
  - LRU eviction works correctly
  - TTL expiration works correctly
  - Cache hit rate calculation accurate

---

### Story 2.5: API Quota Budgeting & Circuit Breaker

**Status:** 📋 Draft
**Depends On:** 2.3 (API Client)
**File:** `docs/stories/2.5.quota-budgeting.md`

#### Acceptance Criteria
1. Quota cost table defined for each endpoint: `search.list` = 100 units, `videos.list` = 1 unit, etc.
2. Quota budget tracker increments consumed units per request (reset daily at midnight PT)
3. Before each request, check if budget would exceed daily limit (10,000 units default)
4. If quota would be exceeded, return cached data or show user warning
5. On 429 response, implement exponential backoff: retry after 1s, 2s, 4s, 8s (max 3 retries)
6. Circuit breaker opens after 5 consecutive 429s (blocks further requests for 1 hour)
7. Dev-only quota dashboard shows real-time unit consumption per endpoint

#### Detailed Task Breakdown

**Phase 1: Quota Cost Table (AC: 1)**
- [ ] **Task 2.5.1:** Define endpoint quota costs
  - [ ] Subtask: Create `QuotaCosts` enum with costs per endpoint
  - [ ] Subtask: search.list = 100 units
  - [ ] Subtask: videos.list = 1 unit
  - [ ] Subtask: channels.list = 1 unit
  - [ ] Subtask: playlists.list = 1 unit
  - [ ] Subtask: playlistItems.list = 1 unit
  - [ ] Subtask: subscriptions.list = 1 unit
  - [ ] Subtask: Document costs in code comments with YouTube API reference links

**Phase 2: Budget Tracker Implementation (AC: 2, 3)**
- [ ] **Task 2.5.2:** Create quota budget tracker
  - [ ] Subtask: Create `MyToob/Features/YouTube/QuotaBudgetTracker.swift`
  - [ ] Subtask: Track daily consumption in UserDefaults: `youtube_quota_used`
  - [ ] Subtask: Track last reset date: `youtube_quota_reset_date`
  - [ ] Subtask: Implement daily reset at midnight PT (use TimeZone for Pacific Time)
  - [ ] Subtask: Create `incrementQuota(cost: Int)` method
  - [ ] Subtask: Create `getRemainingQuota() -> Int` method (10,000 - used)
  - [ ] Subtask: Create `checkQuotaAvailable(cost: Int) -> Bool` method

**Phase 3: Pre-Request Quota Check (AC: 3, 4)**
- [ ] **Task 2.5.3:** Integrate quota checks into API client
  - [ ] Subtask: Before each YouTubeService request, call `checkQuotaAvailable(cost)`
  - [ ] Subtask: If quota insufficient, check cache first
  - [ ] Subtask: If cached data available, return cached (no API call)
  - [ ] Subtask: If no cache, throw `YouTubeAPIError.quotaExceeded`
  - [ ] Subtask: Show user warning: "Daily API limit reached. Showing cached data."
  - [ ] Subtask: Log quota rejection: `logger.warning("Quota exceeded, request blocked")`

**Phase 4: Exponential Backoff (AC: 5)**
- [ ] **Task 2.5.4:** Implement retry logic for 429 errors
  - [ ] Subtask: Create `RetryPolicy` struct with exponential backoff
  - [ ] Subtask: Detect 429 status code in API responses
  - [ ] Subtask: Retry after delays: 1s, 2s, 4s, 8s (max 3 retries)
  - [ ] Subtask: Log each retry attempt: `logger.info("Rate limited, retrying in \(delay)s (attempt \(n)/3)")`
  - [ ] Subtask: After 3 failed retries, throw rate limit error
  - [ ] Subtask: Use async Task.sleep for delays

**Phase 5: Circuit Breaker (AC: 6)**
- [ ] **Task 2.5.5:** Implement circuit breaker pattern
  - [ ] Subtask: Track consecutive 429 responses in memory
  - [ ] Subtask: When 5 consecutive 429s detected, open circuit
  - [ ] Subtask: Circuit open = block all YouTube API requests for 1 hour
  - [ ] Subtask: Store circuit state: `youtube_circuit_open`, `youtube_circuit_open_until`
  - [ ] Subtask: Auto-reset circuit after timeout
  - [ ] Subtask: Log circuit open: `logger.error("Circuit breaker opened, blocking requests for 1 hour")`
  - [ ] Subtask: Show user notification: "YouTube API temporarily unavailable. Try again in 1 hour."

**Phase 6: Quota Dashboard (AC: 7)**
- [ ] **Task 2.5.6:** Create dev-only quota dashboard
  - [ ] Subtask: Add "Quota Dashboard" section in Settings (only in Debug builds)
  - [ ] Subtask: Show total quota used today: "1,234 / 10,000 units (12%)"
  - [ ] Subtask: Show breakdown by endpoint: "search.list: 800 units (8 calls)"
  - [ ] Subtask: Show time until reset: "Resets in: 14h 32m"
  - [ ] Subtask: Show circuit breaker status: "Circuit: Closed" or "Open (resets in 42m)"
  - [ ] Subtask: Add "Reset Quota" button for testing (Debug only)

**Phase 7: Testing**
- [ ] **Task 2.5.7:** Create tests for quota and circuit breaker
  - [ ] Subtask: Test quota tracking increments correctly
  - [ ] Subtask: Test daily reset at midnight PT
  - [ ] Subtask: Test quota check blocks requests when exceeded
  - [ ] Subtask: Test exponential backoff delays (mock 429 responses)
  - [ ] Subtask: Test circuit breaker opens after 5 consecutive 429s
  - [ ] Subtask: Test circuit breaker auto-resets after timeout
  - [ ] Subtask: Mock system time for testing time-based behavior

#### Dev Notes
- **Files Created:**
  - `MyToob/Features/YouTube/QuotaBudgetTracker.swift`
  - Modifications to `YouTubeService.swift` - Integrate quota checks

- **Quota Reset Timing:**
  - YouTube quota resets at midnight Pacific Time
  - Use TimeZone(identifier: "America/Los_Angeles") for accurate reset

- **Circuit Breaker State:**
  - Stored in UserDefaults for persistence across app restarts
  - Circuit can be manually reset in Settings (dev only)

- **Cost Optimization:**
  - Prefer videos.list (1 unit) over search.list (100 units) when possible
  - Use caching aggressively to reduce API calls
  - Batch requests where possible (get 50 video IDs in one call)

#### Testing Requirements
- **Unit Tests:**
  - Quota tracking increments by correct amounts
  - Daily reset works correctly (mock time)
  - Quota check returns correct remaining units
  - Request blocked when quota exceeded
  - Exponential backoff delays correct
  - Circuit breaker opens/closes correctly
  - Dashboard shows accurate metrics

---

### Story 2.6: Import User Subscriptions

**Status:** 📋 Draft
**Depends On:** 2.3 (API Client), 2.4 (Caching), 2.5 (Quota)
**File:** `docs/stories/2.6.import-subscriptions.md`

#### Acceptance Criteria
1. "Import Subscriptions" button in YouTube section of sidebar
2. Calls `subscriptions.list` API with pagination (50 results per page)
3. For each subscription, fetches channel metadata: `channelID`, `title`, `thumbnailURL`
4. Creates `VideoItem` entries for recent uploads from each channel
5. Progress indicator shows import status ("Importing subscriptions: 45/120 channels...")
6. Handles API errors gracefully (quota exceeded, network failure)—user can retry
7. Import can be paused/resumed (stores state in SwiftData)
8. After import, subscriptions appear in sidebar under "YouTube > Subscriptions"

#### Detailed Task Breakdown

**Phase 1: Import UI (AC: 1, 5)**
- [ ] **Task 2.6.1:** Create import UI
  - [ ] Subtask: Add "Import Subscriptions" button to YouTube sidebar section
  - [ ] Subtask: Create `SubscriptionImportView.swift` sheet/dialog
  - [ ] Subtask: Show progress bar with percentage complete
  - [ ] Subtask: Show status text: "Importing subscriptions: 45/120 channels..."
  - [ ] Subtask: Add "Pause" and "Cancel" buttons
  - [ ] Subtask: Disable import button while import running

**Phase 2: Subscriptions List Fetching (AC: 2, 3)**
- [ ] **Task 2.6.2:** Fetch user subscriptions
  - [ ] Subtask: Call `subscriptions.list` API with `mine=true` parameter
  - [ ] Subtask: Request `snippet` part (includes channel ID and title)
  - [ ] Subtask: Handle pagination with `maxResults=50` and `pageToken`
  - [ ] Subtask: Accumulate all subscriptions across pages
  - [ ] Subtask: Extract `channelID`, `title`, `thumbnailURL` from each subscription
  - [ ] Subtask: Store subscriptions in array for processing

**Phase 3: Channel Metadata & Recent Uploads (AC: 4)**
- [ ] **Task 2.6.3:** Fetch recent uploads for each channel
  - [ ] Subtask: For each channel, call `channels.list` to get `uploads` playlist ID
  - [ ] Subtask: Call `playlistItems.list` with uploads playlist ID (get 10 most recent)
  - [ ] Subtask: For each video, call `videos.list` to get full metadata
  - [ ] Subtask: Create `VideoItem` with: videoID, title, channelID, duration, thumbnailURL, isLocal=false
  - [ ] Subtask: Save VideoItem to SwiftData
  - [ ] Subtask: Update progress after each channel processed

**Phase 4: Progress Tracking (AC: 5, 7)**
- [ ] **Task 2.6.4:** Implement progress tracking
  - [ ] Subtask: Track total subscriptions count and current index
  - [ ] Subtask: Update progress percentage: `(current / total) * 100`
  - [ ] Subtask: Update status text with channel name: "Importing: TechChannel (45/120)"
  - [ ] Subtask: Store import state in SwiftData: `ImportState` model with `channelsProcessed`, `totalChannels`, `isPaused`
  - [ ] Subtask: Save state after each channel (allows resume)

**Phase 5: Error Handling (AC: 6)**
- [ ] **Task 2.6.5:** Handle import errors
  - [ ] Subtask: Catch quota exceeded errors (403)
  - [ ] Subtask: Catch network errors (URLError)
  - [ ] Subtask: Catch API errors (invalid response)
  - [ ] Subtask: Show error dialog: "Import failed: [error]. Retry?"
  - [ ] Subtask: Provide "Retry" button to resume from last successful channel
  - [ ] Subtask: Provide "Cancel" button to abort import
  - [ ] Subtask: Log all errors for debugging

**Phase 6: Pause/Resume (AC: 7)**
- [ ] **Task 2.6.6:** Implement pause/resume functionality
  - [ ] Subtask: "Pause" button sets `isPaused = true` in import state
  - [ ] Subtask: Check pause flag after each channel
  - [ ] Subtask: If paused, stop processing and save state
  - [ ] Subtask: "Resume" button loads saved state and continues from last channel
  - [ ] Subtask: Clean up import state when import completes successfully

**Phase 7: Sidebar Integration (AC: 8)**
- [ ] **Task 2.6.7:** Display imported subscriptions
  - [ ] Subtask: Add "Subscriptions" section under YouTube in sidebar
  - [ ] Subtask: Group videos by channel
  - [ ] Subtask: Show channel name + video count
  - [ ] Subtask: Clicking channel loads channel's videos in content area
  - [ ] Subtask: Update counts as import progresses

**Phase 8: Testing**
- [ ] **Task 2.6.8:** Create import tests
  - [ ] Subtask: Test subscriptions.list pagination
  - [ ] Subtask: Test channel metadata extraction
  - [ ] Subtask: Test VideoItem creation
  - [ ] Subtask: Test progress tracking accuracy
  - [ ] Subtask: Test pause/resume (mock import state)
  - [ ] Subtask: Test error handling (quota exceeded, network failure)
  - [ ] Subtask: Test sidebar display after import

#### Dev Notes
- **Files Created:**
  - `MyToob/Features/YouTube/SubscriptionImportService.swift` - Import logic
  - `MyToob/Views/SubscriptionImportView.swift` - Import UI
  - `MyToob/Models/ImportState.swift` - SwiftData model for import state

- **API Calls Per Import:**
  - 1 call to subscriptions.list (1 unit) per 50 subscriptions
  - 1 call to channels.list (1 unit) per channel
  - 1 call to playlistItems.list (1 unit) per channel
  - 1 call to videos.list (1 unit) per video batch
  - Example: 100 subscriptions, 10 videos each = ~300 quota units

- **Performance:**
  - Import runs in background async task
  - Process channels sequentially to avoid overwhelming quota
  - Consider rate limiting (1 channel/second) for large imports

#### Testing Requirements
- **Unit Tests:**
  - Subscriptions API parsing
  - Channel metadata extraction
  - VideoItem creation with correct properties
  - Progress calculation accuracy
  - Pause/resume state management
  - Error handling for all error types

- **Integration Tests:**
  - Full import flow with mock API
  - Import with pagination (>50 subscriptions)
  - Import failure mid-process and retry

---

## Epic 3: Compliant YouTube Playback

**Goal:** Integrate YouTube IFrame Player API for compliant video playback without ToS violations.

### Story 3.1: WKWebView YouTube IFrame Player Setup

**Status:** 📋 Draft
**Depends On:** 1.5 (App Shell)
**Blocks:** 3.2-3.6, 4.x (Focus Mode)
**File:** `docs/stories/3.1.wkwebview-iframe-player.md`

#### Acceptance Criteria
1. `YouTubePlayerView` SwiftUI view created wrapping `WKWebView` (via `NSViewRepresentable`)
2. HTML page embedded in app resources that loads YouTube IFrame Player API
3. IFrame Player initialized with video ID parameter passed from SwiftUI
4. Player configured with parameters: `controls=1`, `modestbranding=1`, `rel=0`
5. Player loads and displays video correctly when `YouTubePlayerView` shown with valid video ID
6. No DOM manipulation of player element or ads (player rendered as-is)
7. UI test verifies player loads and video starts playing

#### Detailed Task Breakdown

**Phase 1: NSViewRepresentable Wrapper (AC: 1)**
- [ ] **Task 3.1.1:** Create YouTubePlayerView
  - [ ] Subtask: Create `MyToob/Features/YouTube/YouTubePlayerView.swift`
  - [ ] Subtask: Implement `NSViewRepresentable` protocol
  - [ ] Subtask: Create `makeNSView() -> WKWebView` method
  - [ ] Subtask: Configure WKWebView settings (allow inline media playback)
  - [ ] Subtask: Store videoID as @Binding or @State property

**Phase 2: HTML Player Page (AC: 2, 3, 4)**
- [ ] **Task 3.1.2:** Create embedded HTML player
  - [ ] Subtask: Create `MyToob/Resources/youtube-player.html` file
  - [ ] Subtask: Add YouTube IFrame API script tag: `<script src="https://www.youtube.com/iframe_api"></script>`
  - [ ] Subtask: Create `<div id="player"></div>` placeholder
  - [ ] Subtask: Implement `onYouTubeIframeAPIReady()` JavaScript function
  - [ ] Subtask: Initialize YT.Player with videoID parameter
  - [ ] Subtask: Set player vars: `controls: 1`, `modestbranding: 1`, `rel: 0`
  - [ ] Subtask: Add HTML to Xcode project as resource

**Phase 3: Video ID Injection (AC: 3)**
- [ ] **Task 3.1.3:** Pass videoID to HTML player
  - [ ] Subtask: Load HTML from resources: `Bundle.main.url(forResource: "youtube-player", withExtension: "html")`
  - [ ] Subtask: Replace placeholder `{{VIDEO_ID}}` in HTML with actual videoID
  - [ ] Subtask: Load modified HTML into WKWebView: `webView.loadHTMLString(html, baseURL: nil)`
  - [ ] Subtask: Handle missing videoID gracefully (show placeholder)

**Phase 4: Player Rendering (AC: 5)**
- [ ] **Task 3.1.4:** Verify player loads and displays
  - [ ] Subtask: Test with known valid video ID (e.g., "dQw4w9WgXcQ")
  - [ ] Subtask: Verify player iframe loads in WKWebView
  - [ ] Subtask: Verify video thumbnail appears
  - [ ] Subtask: Verify play button is clickable
  - [ ] Subtask: Test on both light and dark mode

**Phase 5: Compliance Verification (AC: 6)**
- [ ] **Task 3.1.5:** Ensure no ToS violations
  - [ ] Subtask: Verify no JavaScript code manipulates player DOM
  - [ ] Subtask: Verify ads display if present (not blocked or hidden)
  - [ ] Subtask: Verify player controls are all visible and functional
  - [ ] Subtask: Document compliance in code comments
  - [ ] Subtask: Add lint rule to prevent DOM manipulation

**Phase 6: Testing (AC: 7)**
- [ ] **Task 3.1.6:** Create UI tests for player
  - [ ] Subtask: Test player view appears when videoID set
  - [ ] Subtask: Test player loads YouTube content
  - [ ] Subtask: Test play button starts playback
  - [ ] Subtask: Test invalid videoID shows error
  - [ ] Subtask: Verify no crashes during player lifecycle

#### Dev Notes
- **Files Created:**
  - `MyToob/Features/YouTube/YouTubePlayerView.swift` - SwiftUI wrapper
  - `MyToob/Resources/youtube-player.html` - IFrame Player HTML

- **YouTube IFrame Player API:**
  - Documentation: https://developers.google.com/youtube/iframe_api_reference
  - Player loads asynchronously via iframe_api script
  - Parameters control player behavior and appearance

- **Compliance Critical:**
  - Never manipulate player DOM or ads
  - Never block or hide YouTube UI elements
  - Player must be fully visible when playing

#### Testing Requirements
- **UI Tests:**
  - Player view displays when videoID provided
  - Player loads and shows video thumbnail
  - Clicking play button starts playback
  - Invalid videoID handled gracefully

---

### Story 3.2: JavaScript Bridge for Playback Control

**Status:** 📋 Draft
**Depends On:** 3.1 (IFrame Player)
**File:** `docs/stories/3.2.javascript-bridge.md`

#### Acceptance Criteria
1. `WKScriptMessageHandler` implemented to receive messages from JavaScript
2. JavaScript functions defined: `playVideo()`, `pauseVideo()`, `seekTo(seconds)`, `setVolume(level)`
3. Swift methods call JavaScript functions via `webView.evaluateJavaScript()`
4. SwiftUI controls (play/pause button, seek slider) trigger JavaScript commands
5. Playback state updates reflected in UI (play button becomes pause button when playing)
6. Seek slider updates in real-time during playback (synced with video time)
7. UI test verifies play/pause/seek commands work correctly

#### Detailed Task Breakdown

**Phase 1: Message Handler Setup (AC: 1)**
- [ ] **Task 3.2.1:** Implement WKScriptMessageHandler
  - [ ] Subtask: Create `YouTubePlayerCoordinator` class conforming to `WKScriptMessageHandler`
  - [ ] Subtask: Implement `userContentController(_ didReceive:)` method
  - [ ] Subtask: Register message handler: `webView.configuration.userContentController.add(coordinator, name: "playerBridge")`
  - [ ] Subtask: Handle incoming messages from JavaScript

**Phase 2: JavaScript Control Functions (AC: 2)**
- [ ] **Task 3.2.2:** Define JavaScript playback functions
  - [ ] Subtask: Add to youtube-player.html: `function playVideo() { player.playVideo(); }`
  - [ ] Subtask: Add `function pauseVideo() { player.pauseVideo(); }`
  - [ ] Subtask: Add `function seekTo(seconds) { player.seekTo(seconds, true); }`
  - [ ] Subtask: Add `function setVolume(level) { player.setVolume(level); }`
  - [ ] Subtask: Test functions in browser console first

**Phase 3: Swift → JavaScript Bridge (AC: 3)**
- [ ] **Task 3.2.3:** Implement Swift control methods
  - [ ] Subtask: Create `play()` method: `webView.evaluateJavaScript("playVideo()")`
  - [ ] Subtask: Create `pause()` method: `webView.evaluateJavaScript("pauseVideo()")`
  - [ ] Subtask: Create `seek(to seconds: Double)` method
  - [ ] Subtask: Create `setVolume(_ level: Int)` method
  - [ ] Subtask: Handle JavaScript evaluation errors gracefully

**Phase 4: SwiftUI Controls Integration (AC: 4)**
- [ ] **Task 3.2.4:** Create native playback controls
  - [ ] Subtask: Add play/pause button in player overlay
  - [ ] Subtask: Add seek slider below player
  - [ ] Subtask: Add volume slider
  - [ ] Subtask: Wire buttons to Swift control methods
  - [ ] Subtask: Style controls with SF Symbols

**Phase 5: State Synchronization (AC: 5, 6)**
- [ ] **Task 3.2.5:** Sync UI with player state
  - [ ] Subtask: Track `isPlaying` @State variable
  - [ ] Subtask: Toggle play/pause button icon based on state
  - [ ] Subtask: Update seek slider value from time updates
  - [ ] Subtask: Allow dragging seek slider to change position
  - [ ] Subtask: Prevent seek slider jumping during drag

**Phase 6: Testing (AC: 7)**
- [ ] **Task 3.2.6:** Test JavaScript bridge
  - [ ] Subtask: Test play command starts playback
  - [ ] Subtask: Test pause command stops playback
  - [ ] Subtask: Test seek command changes video position
  - [ ] Subtask: Test volume command adjusts audio level
  - [ ] Subtask: Test UI controls update correctly

#### Dev Notes
- **Files Modified:**
  - `MyToob/Features/YouTube/YouTubePlayerView.swift` - Add coordinator
  - `MyToob/Resources/youtube-player.html` - Add control functions

- **JavaScript Evaluation:**
  - Use `evaluateJavaScript(_:completionHandler:)` for async calls
  - Handle errors if JavaScript not ready or player not loaded

- **State Management:**
  - Use @Published properties in coordinator for reactive updates
  - SwiftUI automatically updates UI when state changes

#### Testing Requirements
- **Integration Tests:**
  - Play/pause commands work via bridge
  - Seek commands change playback position
  - Volume commands adjust audio level
  - UI controls update player state correctly

---

**[Document continues with Stories 3.3-3.6, then all of Epics 4-15...]**

---

## Summary of Remaining Stories Structure

The comprehensive task breakdowns document will follow this structure for all remaining stories:

### Stories 3.3-3.6 (YouTube Playback - Continued)
- 3.3: Player State & Time Event Handling
- 3.4: Picture-in-Picture Support
- 3.5: Player Visibility Enforcement
- 3.6: Error Handling & Unsupported Videos

### Epic 4: Focus Mode (7 stories)
- 4.1: Focus Mode Global Toggle
- 4.2: Hide YouTube Sidebar
- 4.3: Hide Related Videos Panel
- 4.4: Hide Comments Section
- 4.5: Hide Homepage Feed
- 4.6: Focus Mode Scheduling (Pro)
- 4.7: Distraction Hiding Presets

### Epic 5: Local Files (5 stories, 5.1 Done)
- 5.2: Security-Scoped Bookmarks
- 5.3: AVPlayerView Integration
- 5.4: Playback State Persistence
- 5.5: Drag-and-Drop Import
- 5.6: Metadata Extraction

### Epic 6: Data Persistence (6 stories)
- 6.1: SwiftData Container Configuration
- 6.2: Versioned Schema Migrations
- 6.3: CloudKit Container Setup
- 6.4: CloudKit Sync Conflict Resolution
- 6.5: Sync Status UI & Controls
- 6.6: Caching Strategy

### Epic 7: AI Embeddings (6 stories)
- 7.1: Core ML Model Integration
- 7.2: Metadata Text Preparation
- 7.3: Thumbnail OCR
- 7.4: Batch Embedding Generation
- 7.5: HNSW Vector Index
- 7.6: Vector Similarity Search API

### Epic 8: Clustering (6 stories)
- 8.1: kNN Graph Construction
- 8.2: Leiden Algorithm
- 8.3: Cluster Centroid & Label Generation
- 8.4: Auto-Collections UI
- 8.5: Cluster Stability
- 8.6: Cluster Detail View

### Epic 9: Search (6 stories)
- 9.1: Search Bar & Query Input
- 9.2: Keyword Search
- 9.3: Vector Similarity Search
- 9.4: Hybrid Result Fusion
- 9.5: Filter Pills
- 9.6: Search Results Display

### Epic 10: Collections (6 stories)
- 10.1: Create & Manage Collections
- 10.2: Add Videos to Collections
- 10.3: Collection Detail View
- 10.4: Collection Export to Markdown
- 10.5: AI-Suggested Tags
- 10.6: Bulk Operations

### Epic 11: Notes (6 stories)
- 11.1: Inline Note Editor
- 11.2: Timestamp-Anchored Notes
- 11.3: Bidirectional Links
- 11.4: Note Search & Filtering
- 11.5: Note Export & Citation
- 11.6: Note Templates (Pro)

### Epic 12: Compliance (6 stories)
- 12.1: Report Content Action
- 12.2: Hide & Blacklist Channels
- 12.3: Content Policy Page
- 12.4: Support & Contact
- 12.5: YouTube Disclaimers
- 12.6: Compliance Audit Logging

### Epic 13: macOS Integration (6 stories)
- 13.1: Spotlight Indexing
- 13.2: App Intents for Shortcuts
- 13.3: Menu Bar Mini-Controller
- 13.4: Comprehensive Keyboard Shortcuts
- 13.5: Command Palette (⌘K)
- 13.6: Drag-and-Drop from External Sources

### Epic 14: Accessibility (6 stories)
- 14.1: VoiceOver Support
- 14.2: Keyboard-Only Navigation
- 14.3: High-Contrast Theme
- 14.4: Loading States & Progress
- 14.5: Empty States with Messaging
- 14.6: Smooth Animations

### Epic 15: Release (6 stories)
- 15.1: StoreKit 2 Configuration
- 15.2: Paywall & Feature Gating
- 15.3: Restore Purchase & Management
- 15.4: App Store Submission Package
- 15.5: Reviewer Documentation
- 15.6: Notarized DMG Build

---

## Story 3.3: Player State & Time Event Handling 🚧

**Status:** Draft
**Dependencies:** Story 3.2 (JavaScript Bridge)
**Epic:** Epic 3 - Compliant YouTube Playback

**Acceptance Criteria:**
1. JavaScript event listeners registered for: `onStateChange`, `onReady`, `onError`
2. State changes posted to Swift via `window.webkit.messageHandlers.playerState.postMessage(state)`
3. Player states handled: `-1` (unstarted), `0` (ended), `1` (playing), `2` (paused), `3` (buffering), `5` (cued)
4. Time updates posted every second during playback: `currentTime`, `duration`
5. Swift updates `VideoItem.watchProgress` in SwiftData when time updates received
6. Player ready state enables playback controls (disabled until ready)
7. Player errors logged and displayed to user (e.g., "Video unavailable", "Playback error")

#### Detailed Task Breakdown

**Phase 1: Event Listener Registration (AC: 1)**
- [ ] **Task 3.3.1:** Register YouTube IFrame Player event listeners
  - [ ] Subtask: In `player.html`, add `player.addEventListener('onReady', onPlayerReady)`
  - [ ] Subtask: Add `player.addEventListener('onStateChange', onPlayerStateChange)`
  - [ ] Subtask: Add `player.addEventListener('onError', onPlayerError)`
  - [ ] Subtask: Define `onPlayerReady(event)` function to send ready state to Swift
  - [ ] Subtask: Define `onPlayerStateChange(event)` function to extract `event.data` (state code)
  - [ ] Subtask: Define `onPlayerError(event)` function to extract error code

**Phase 2: State Change Messaging (AC: 2, 3)**
- [ ] **Task 3.3.2:** Post state changes to Swift via message handler
  - [ ] Subtask: In `onPlayerStateChange`, call `window.webkit.messageHandlers.playerState.postMessage({state: event.data})`
  - [ ] Subtask: In `YouTubePlayerView.Coordinator`, add message handler: `userContentController.add(self, name: "playerState")`
  - [ ] Subtask: Implement `userContentController(_:didReceive:)` to parse state message
  - [ ] Subtask: Map state codes: `-1` → `.unstarted`, `0` → `.ended`, `1` → `.playing`, `2` → `.paused`, `3` → `.buffering`, `5` → `.cued`
  - [ ] Subtask: Update `@Published var playerState: PlayerState` in ViewModel
  - [ ] Subtask: Log state changes: `logger.debug("Player state changed: \(state)")`

**Phase 3: Time Update Mechanism (AC: 4)**
- [ ] **Task 3.3.3:** Implement periodic time updates
  - [ ] Subtask: In JavaScript, start `setInterval` when state becomes `.playing`: `setInterval(sendTimeUpdate, 1000)`
  - [ ] Subtask: Define `sendTimeUpdate()` function: `const currentTime = player.getCurrentTime(); const duration = player.getDuration();`
  - [ ] Subtask: Post time update: `window.webkit.messageHandlers.timeUpdate.postMessage({currentTime, duration})`
  - [ ] Subtask: Clear interval when state becomes `.paused` or `.ended`
  - [ ] Subtask: In Swift, add message handler `userContentController.add(self, name: "timeUpdate")`
  - [ ] Subtask: Parse time update message and update `@Published var currentTime: Double`, `duration: Double`

**Phase 4: SwiftData Watch Progress Update (AC: 5)**
- [ ] **Task 3.3.4:** Update VideoItem.watchProgress on time updates
  - [ ] Subtask: In time update handler, calculate progress: `let progress = currentTime / duration`
  - [ ] Subtask: Debounce updates to SwiftData (update max once every 5 seconds)
  - [ ] Subtask: Fetch VideoItem from model context by `videoID`
  - [ ] Subtask: Update `videoItem.watchProgress = progress`
  - [ ] Subtask: Update `videoItem.lastWatchedAt = Date()`
  - [ ] Subtask: Save model context: `try? modelContext.save()`
  - [ ] Subtask: Log progress update: `logger.debug("Updated watch progress: \(progress) for video \(videoID)")`

**Phase 5: Ready State Control Enablement (AC: 6)**
- [ ] **Task 3.3.5:** Enable controls when player ready
  - [ ] Subtask: Add `@Published var isPlayerReady: Bool = false` to ViewModel
  - [ ] Subtask: In `onPlayerReady` handler, set `isPlayerReady = true`
  - [ ] Subtask: In SwiftUI, disable play/pause/seek controls when `!isPlayerReady`: `.disabled(!viewModel.isPlayerReady)`
  - [ ] Subtask: Show loading indicator when `!isPlayerReady`: `if !viewModel.isPlayerReady { ProgressView() }`
  - [ ] Subtask: Log ready state: `logger.info("YouTube player ready, controls enabled")`

**Phase 6: Error Handling (AC: 7)**
- [ ] **Task 3.3.6:** Handle and display player errors
  - [ ] Subtask: Add message handler `userContentController.add(self, name: "playerError")`
  - [ ] Subtask: Parse error code in `didReceive` message handler
  - [ ] Subtask: Map error codes to user-friendly messages (will be detailed in Story 3.6)
  - [ ] Subtask: Update `@Published var errorMessage: String?` in ViewModel
  - [ ] Subtask: Log error: `logger.error("YouTube player error: \(errorCode)")`
  - [ ] Subtask: Display error in UI (defer full error UI to Story 3.6)

**Phase 7: Testing (AC: All)**
- [ ] **Task 3.3.7:** Test state and time event handling
  - [ ] Subtask: Unit test: State change messages correctly parsed and mapped
  - [ ] Subtask: Unit test: Time updates trigger watch progress calculation
  - [ ] Subtask: Integration test: Play video, verify state transitions (unstarted → buffering → playing)
  - [ ] Subtask: Integration test: Verify time updates posted every second during playback
  - [ ] Subtask: UI test: Verify controls disabled until `onReady` event received
  - [ ] Subtask: UI test: Verify watch progress saved to SwiftData during playback
  - [ ] Subtask: UI test: Verify error handler called when invalid video ID provided

**Dev Notes:**
- **Files:** `MyToob/Player/player.html` (JavaScript event listeners), `MyToob/Player/YouTubePlayerView.swift` (message handlers), `MyToob/ViewModels/PlayerViewModel.swift` (state management)
- **Pattern:** Use `WKScriptMessageHandler` protocol for all JS→Swift communication
- **Debouncing:** Implement debounce for SwiftData updates to avoid excessive writes (max once per 5 seconds)
- **State Enum:** Define `enum PlayerState: Int { case unstarted = -1, ended = 0, playing = 1, paused = 2, buffering = 3, cued = 5 }`
- **Error Codes:** Store raw error codes, defer detailed error mapping to Story 3.6

**Testing Requirements:**
- Unit tests for state code mapping (`-1` → `.unstarted`, etc.)
- Unit tests for time update parsing and progress calculation
- Integration tests for full playback lifecycle (load → ready → play → pause → seek → ended)
- UI tests for control enablement based on ready state
- UI tests for watch progress persistence

---

## Story 3.4: Picture-in-Picture Support (Native Only) 🚧

**Status:** Draft
**Dependencies:** Story 3.3 (Player State Events)
**Epic:** Epic 3 - Compliant YouTube Playback

**Acceptance Criteria:**
1. PiP enabled if supported by YouTube IFrame Player and macOS (HTML5 video element native PiP)
2. PiP button appears in macOS window controls when video is playing
3. Clicking PiP button activates native macOS PiP (floats video above other windows)
4. Playback continues in PiP mode (does NOT pause when app window hidden while in PiP)
5. Exiting PiP returns video to main window
6. No custom PiP implementation (uses native OS capability only)—compliance requirement
7. PiP availability logged (may not be available for all videos due to YouTube restrictions)

#### Detailed Task Breakdown

**Phase 1: PiP Capability Detection (AC: 1, 7)**
- [ ] **Task 3.4.1:** Detect and log PiP support
  - [ ] Subtask: In JavaScript, check PiP support: `const isPiPSupported = document.pictureInPictureEnabled`
  - [ ] Subtask: Send PiP support status to Swift: `window.webkit.messageHandlers.pipSupport.postMessage({supported: isPiPSupported})`
  - [ ] Subtask: In Swift Coordinator, add message handler `userContentController.add(self, name: "pipSupport")`
  - [ ] Subtask: Parse PiP support message, update `@Published var isPiPSupported: Bool`
  - [ ] Subtask: Log PiP support: `logger.info("Picture-in-Picture support: \(isPiPSupported)")`
  - [ ] Subtask: Check video-specific PiP availability when video loads (some videos disable PiP)

**Phase 2: Native macOS PiP Button (AC: 2)**
- [ ] **Task 3.4.2:** Enable native PiP button in window controls
  - [ ] Subtask: Ensure WKWebView's video element has `playsinline` attribute (required for PiP)
  - [ ] Subtask: Verify HTML5 `<video>` element rendered by YouTube IFrame Player (native PiP works on video element)
  - [ ] Subtask: macOS PiP button appears automatically when video is playing (no custom code needed)
  - [ ] Subtask: Document that PiP button is system-provided, not app-controlled
  - [ ] Subtask: Test PiP button appearance: Load video, start playback, verify green PiP button in window controls

**Phase 3: PiP Activation (AC: 3)**
- [ ] **Task 3.4.3:** Handle PiP activation
  - [ ] Subtask: User clicks native macOS PiP button → system handles PiP activation
  - [ ] Subtask: No custom JavaScript or Swift code needed (native OS feature)
  - [ ] Subtask: Verify video floats above other windows in small PiP window
  - [ ] Subtask: Verify playback controls (play/pause, scrubbing) available in PiP window
  - [ ] Subtask: Log PiP activation (monitor via window state changes if possible)

**Phase 4: PiP Playback Continuation (AC: 4)**
- [ ] **Task 3.4.4:** Ensure playback continues in PiP mode
  - [ ] Subtask: Add `@Published var isPiPActive: Bool = false` to ViewModel
  - [ ] Subtask: Detect PiP activation via JavaScript: `videoElement.addEventListener('enterpictureinpicture', onEnterPiP)`
  - [ ] Subtask: In `onEnterPiP`, post message: `window.webkit.messageHandlers.pipState.postMessage({active: true})`
  - [ ] Subtask: In Swift, update `isPiPActive = true` when PiP activated
  - [ ] Subtask: Modify visibility enforcement (Story 3.5): If `isPiPActive`, do NOT pause when window hidden
  - [ ] Subtask: Log PiP state: `logger.debug("PiP active: \(isPiPActive)")`

**Phase 5: PiP Exit Handling (AC: 5)**
- [ ] **Task 3.4.5:** Handle PiP exit
  - [ ] Subtask: Add JavaScript listener: `videoElement.addEventListener('leavepictureinpicture', onLeavePiP)`
  - [ ] Subtask: In `onLeavePiP`, post message: `window.webkit.messageHandlers.pipState.postMessage({active: false})`
  - [ ] Subtask: In Swift, update `isPiPActive = false` when PiP exited
  - [ ] Subtask: Verify video returns to main window and playback continues
  - [ ] Subtask: Log PiP exit: `logger.debug("PiP exited, video returned to main window")`

**Phase 6: Compliance Verification (AC: 6)**
- [ ] **Task 3.4.6:** Verify no custom PiP implementation
  - [ ] Subtask: Code review: Confirm no custom PiP window creation (no `NSWindow` with PiP behavior)
  - [ ] Subtask: Code review: Confirm no custom video rendering in floating window
  - [ ] Subtask: Code review: Confirm reliance on native macOS PiP API only
  - [ ] Subtask: Document compliance: "PiP uses native macOS Picture-in-Picture API, no custom implementation"
  - [ ] Subtask: Add lint rule (if possible) to prevent custom PiP implementations

**Phase 7: Testing (AC: All)**
- [ ] **Task 3.4.7:** Test PiP functionality
  - [ ] Subtask: Manual test: Verify PiP button appears when video playing
  - [ ] Subtask: Manual test: Click PiP button, verify video floats above other windows
  - [ ] Subtask: Manual test: Verify playback continues in PiP when app window hidden/minimized
  - [ ] Subtask: Manual test: Exit PiP, verify video returns to main window
  - [ ] Subtask: UI test: Detect PiP activation (if accessible via Accessibility API)
  - [ ] Subtask: UI test: Verify `isPiPActive` state updates correctly
  - [ ] Subtask: Manual test: Try videos known to disable PiP, verify graceful handling

**Dev Notes:**
- **Files:** `MyToob/Player/player.html` (PiP event listeners), `MyToob/Player/YouTubePlayerView.swift` (PiP state handling), `MyToob/ViewModels/PlayerViewModel.swift` (PiP state management)
- **Pattern:** PiP is entirely native—no custom Swift/SwiftUI code for PiP window rendering
- **Compliance:** This is a compliance requirement—MUST use native PiP API, not custom windowing
- **Video Element Access:** May need to access underlying `<video>` element in YouTube IFrame Player via JavaScript
- **Limitations:** PiP availability depends on YouTube video settings (some creators disable embedding or PiP)

**Testing Requirements:**
- Manual PiP activation and deactivation tests (system feature, hard to automate)
- UI tests for PiP state tracking (`isPiPActive`)
- Integration test: Verify playback continues when PiP active and app window hidden
- Edge case: Videos with PiP disabled (should fail gracefully)

---

## Story 3.5: Player Visibility Enforcement (Compliance) 🚧

**Status:** Draft
**Dependencies:** Story 3.4 (PiP Support)
**Epic:** Epic 3 - Compliant YouTube Playback

**Acceptance Criteria:**
1. Window visibility tracked using `NSWindow.isVisible` and app lifecycle events (`scenePhase`)
2. When app window hidden, minimized, or occluded: call `pauseVideo()` via JavaScript bridge
3. Exception: If PiP is active, do NOT pause (PiP is visible playback surface)
4. When app returns to foreground, playback remains paused (user can manually resume)
5. Visibility state changes logged for compliance audit trail
6. UI test verifies pause behavior when app backgrounded
7. No background audio playback when player not visible (enforced by YouTube IFrame Player)

#### Detailed Task Breakdown

**Phase 1: Window Visibility Tracking (AC: 1)**
- [ ] **Task 3.5.1:** Implement window visibility monitoring
  - [ ] Subtask: In `YouTubePlayerView`, access `@Environment(\.scenePhase) var scenePhase`
  - [ ] Subtask: Add `.onChange(of: scenePhase)` modifier to detect app lifecycle changes
  - [ ] Subtask: Handle `scenePhase` transitions: `.active`, `.inactive`, `.background`
  - [ ] Subtask: For AppKit integration, observe `NSWindow.isVisible` using `NotificationCenter`
  - [ ] Subtask: Subscribe to `NSWindow.didChangeOcclusionStateNotification`
  - [ ] Subtask: Combine `scenePhase` and `NSWindow` visibility for comprehensive tracking

**Phase 2: Pause on Hidden/Minimized (AC: 2)**
- [ ] **Task 3.5.2:** Pause playback when window not visible
  - [ ] Subtask: When `scenePhase` becomes `.background` or `.inactive`, call `pauseVideo()`
  - [ ] Subtask: When `NSWindow.isVisible == false`, call `pauseVideo()`
  - [ ] Subtask: When window occluded (fully covered by other windows), call `pauseVideo()`
  - [ ] Subtask: Implement `pauseVideo()` call via JavaScript bridge (reuse from Story 3.2)
  - [ ] Subtask: Debounce pause calls (avoid multiple rapid pause commands)
  - [ ] Subtask: Log visibility-triggered pause: `logger.info("Pausing playback due to visibility change")`

**Phase 3: PiP Exception Handling (AC: 3)**
- [ ] **Task 3.5.3:** Exempt PiP mode from pause enforcement
  - [ ] Subtask: Check `isPiPActive` before pausing
  - [ ] Subtask: If `isPiPActive == true`, skip pause command (PiP is visible playback surface)
  - [ ] Subtask: Log PiP exemption: `logger.debug("PiP active, not pausing despite visibility change")`
  - [ ] Subtask: When PiP exits, resume normal visibility enforcement
  - [ ] Subtask: Ensure PiP state updates before visibility checks (race condition prevention)

**Phase 4: Foreground Behavior (AC: 4)**
- [ ] **Task 3.5.4:** Keep playback paused on foreground return
  - [ ] Subtask: When `scenePhase` becomes `.active`, do NOT auto-resume playback
  - [ ] Subtask: When `NSWindow.isVisible == true`, do NOT auto-resume playback
  - [ ] Subtask: User must manually click play button to resume
  - [ ] Subtask: Document behavior: "Playback remains paused when app returns to foreground (user control)"
  - [ ] Subtask: Log foreground transition: `logger.debug("App foregrounded, playback remains paused")`

**Phase 5: Compliance Audit Logging (AC: 5)**
- [ ] **Task 3.5.5:** Log visibility state changes for audit trail
  - [ ] Subtask: Use OSLog with `.info` level for visibility events
  - [ ] Subtask: Log format: `"Visibility changed: window=\(isVisible), scenePhase=\(scenePhase), pipActive=\(isPiPActive), action=\(paused ? "paused" : "no action")"`
  - [ ] Subtask: Include timestamp in logs (automatic with OSLog)
  - [ ] Subtask: Document log location for compliance review: `Console.app → MyToob → Player Visibility`
  - [ ] Subtask: Add test to verify logs generated on visibility changes

**Phase 6: Background Audio Prevention (AC: 7)**
- [ ] **Task 3.5.6:** Verify no background audio playback
  - [ ] Subtask: Test: Minimize app while playing video, verify audio stops
  - [ ] Subtask: Test: Occlude app window, verify audio stops
  - [ ] Subtask: Document: "YouTube IFrame Player enforces no background audio by design"
  - [ ] Subtask: Verify no `AVAudioSession` configuration that enables background audio
  - [ ] Subtask: Verify WKWebView configuration does not enable background media

**Phase 7: Testing (AC: 6, All)**
- [ ] **Task 3.5.7:** Test visibility enforcement
  - [ ] Subtask: UI test: Minimize app during playback, verify `pauseVideo()` called
  - [ ] Subtask: UI test: Occlude window during playback, verify pause triggered
  - [ ] Subtask: UI test: Activate PiP, minimize app, verify playback continues
  - [ ] Subtask: UI test: Exit PiP, minimize app, verify playback pauses
  - [ ] Subtask: UI test: Return to foreground, verify playback still paused
  - [ ] Subtask: Manual test: Verify no audio when app minimized (compliance check)
  - [ ] Subtask: Log verification: Check audit logs generated correctly

**Dev Notes:**
- **Files:** `MyToob/Player/YouTubePlayerView.swift` (visibility monitoring), `MyToob/ViewModels/PlayerViewModel.swift` (pause logic)
- **Pattern:** Combine SwiftUI `scenePhase` with AppKit `NSWindow` notifications for robust visibility tracking
- **Compliance Critical:** This is a YouTube ToS requirement—MUST pause when not visible (except PiP)
- **PiP Integration:** Tightly coupled with Story 3.4 (PiP state management)
- **Logging:** Use OSLog with consistent format for audit trail

**Testing Requirements:**
- UI tests for all visibility scenarios (minimize, occlude, background)
- UI tests for PiP exemption (playback continues in PiP mode)
- Manual audio verification test (no background audio when not visible)
- Log verification test (audit trail generated)

---

## Story 3.6: Error Handling & Unsupported Videos 🚧

**Status:** Draft
**Dependencies:** Story 3.3 (Player State Events)
**Epic:** Epic 3 - Compliant YouTube Playback

**Acceptance Criteria:**
1. Player `onError` events handled for codes: `2` (invalid video ID), `5` (HTML5 player error), `100` (video not found), `101`/`150` (embedding disabled)
2. User-friendly error messages displayed: "This video is unavailable", "This video cannot be embedded", "An error occurred during playback"
3. "Open in YouTube" button shown in error state (deep-links to `youtube.com/watch?v={videoID}`)
4. Errors logged to OSLog for debugging (include video ID and error code)
5. Error state dismissible (user can try another video)
6. Retry button shown for transient errors (network issues, buffering failures)
7. No crashes or infinite retry loops on persistent errors

#### Detailed Task Breakdown

**Phase 1: Error Event Handling (AC: 1)**
- [ ] **Task 3.6.1:** Capture and parse YouTube player errors
  - [ ] Subtask: In `player.html`, error handler already registered in Story 3.3: `player.addEventListener('onError', onPlayerError)`
  - [ ] Subtask: In `onPlayerError(event)`, extract error code: `const errorCode = event.data`
  - [ ] Subtask: Post error to Swift: `window.webkit.messageHandlers.playerError.postMessage({code: errorCode, videoID: currentVideoID})`
  - [ ] Subtask: In Swift, parse error message in existing `playerError` handler
  - [ ] Subtask: Define `enum PlayerError: Int { case invalidVideoID = 2, html5Error = 5, videoNotFound = 100, embeddingDisabled = 101, embeddingDisabled2 = 150 }`
  - [ ] Subtask: Map error code to enum case

**Phase 2: User-Friendly Error Messages (AC: 2)**
- [ ] **Task 3.6.2:** Map error codes to user messages
  - [ ] Subtask: Create error message mapper function: `func errorMessage(for code: PlayerError) -> String`
  - [ ] Subtask: Code `2` → "Invalid video ID. Please check the video link."
  - [ ] Subtask: Code `5` → "An error occurred during playback. Please try again."
  - [ ] Subtask: Code `100` → "This video is unavailable."
  - [ ] Subtask: Codes `101`, `150` → "This video cannot be embedded. Watch on YouTube instead."
  - [ ] Subtask: Unknown codes → "An unexpected error occurred. (Error code: \(code))"
  - [ ] Subtask: Store error message in `@Published var errorMessage: String?` in ViewModel

**Phase 3: Error UI with "Open in YouTube" Button (AC: 3)**
- [ ] **Task 3.6.3:** Display error state in UI
  - [ ] Subtask: In `ContentView` or player UI, add conditional error view: `if let error = viewModel.errorMessage { ErrorView(message: error) }`
  - [ ] Subtask: Create `ErrorView` SwiftUI view with error message text
  - [ ] Subtask: Add "Open in YouTube" button in `ErrorView`
  - [ ] Subtask: Button action opens URL: `NSWorkspace.shared.open(URL(string: "https://www.youtube.com/watch?v=\(videoID)")!)`
  - [ ] Subtask: Add SF Symbol icon: `Image(systemName: "arrow.up.right.square")` next to button text
  - [ ] Subtask: Style error view: Use `.foregroundColor(.red)` for error text, padding, rounded background

**Phase 4: Error Logging (AC: 4)**
- [ ] **Task 3.6.4:** Log errors for debugging
  - [ ] Subtask: When error received, log to OSLog: `logger.error("YouTube player error: code=\(code), videoID=\(videoID), message=\(message)")`
  - [ ] Subtask: Include full error context (video title if available, playback time when error occurred)
  - [ ] Subtask: Use `.error` log level for all player errors
  - [ ] Subtask: Document log location: `Console.app → MyToob → Player Errors`
  - [ ] Subtask: Add unit test to verify error logging behavior

**Phase 5: Dismissible Error State (AC: 5)**
- [ ] **Task 3.6.5:** Allow user to dismiss error and try another video
  - [ ] Subtask: Add "Dismiss" or "Try Another Video" button in `ErrorView`
  - [ ] Subtask: Button action clears error state: `viewModel.errorMessage = nil`
  - [ ] Subtask: Clearing error returns to normal player UI (ready for next video)
  - [ ] Subtask: Optionally navigate back to library/search view
  - [ ] Subtask: Test: Verify error dismissed and UI returns to normal state

**Phase 6: Retry for Transient Errors (AC: 6)**
- [ ] **Task 3.6.6:** Show retry button for recoverable errors
  - [ ] Subtask: Classify errors as transient vs. permanent: `func isTransientError(_ code: PlayerError) -> Bool`
  - [ ] Subtask: Transient errors: `5` (HTML5 error—could be network issue), unknown codes
  - [ ] Subtask: Permanent errors: `2` (invalid ID), `100` (not found), `101`/`150` (embedding disabled)
  - [ ] Subtask: For transient errors, show "Retry" button instead of "Dismiss"
  - [ ] Subtask: Retry action reloads player with same video ID: `viewModel.loadVideo(videoID)`
  - [ ] Subtask: Limit retries: Track retry count, max 3 retries before showing permanent error

**Phase 7: Crash Prevention & Retry Loop Protection (AC: 7)**
- [ ] **Task 3.6.7:** Prevent crashes and infinite retry loops
  - [ ] Subtask: Wrap error handling in `do-catch` blocks (no force-unwraps)
  - [ ] Subtask: Implement retry counter: `var retryCount: Int = 0`
  - [ ] Subtask: Increment counter on retry, reset on success
  - [ ] Subtask: If `retryCount >= 3`, disable retry button and show permanent error message
  - [ ] Subtask: Add timeout for error recovery (e.g., after 3 failed retries, suggest opening in YouTube)
  - [ ] Subtask: Test edge cases: Rapid error events, multiple simultaneous errors, invalid video IDs

**Phase 8: Testing (AC: All)**
- [ ] **Task 3.6.8:** Test error handling
  - [ ] Subtask: Unit test: Error code mapping (`2` → invalid ID message, etc.)
  - [ ] Subtask: Unit test: Transient vs. permanent error classification
  - [ ] Subtask: UI test: Load invalid video ID, verify error message displayed
  - [ ] Subtask: UI test: Click "Open in YouTube", verify browser opens with correct URL
  - [ ] Subtask: UI test: Click "Dismiss", verify error clears and UI returns to normal
  - [ ] Subtask: UI test: Trigger transient error, click "Retry", verify reload attempted
  - [ ] Subtask: UI test: Retry 3 times, verify retry disabled and permanent error shown
  - [ ] Subtask: Manual test: Test all error codes (`2`, `5`, `100`, `101`, `150`)

**Dev Notes:**
- **Files:** `MyToob/Player/YouTubePlayerView.swift` (error handling), `MyToob/Views/ErrorView.swift` (error UI), `MyToob/ViewModels/PlayerViewModel.swift` (error state)
- **Error Codes Reference:** [YouTube IFrame Player API Error Codes](https://developers.google.com/youtube/iframe_api_reference#onError)
- **Pattern:** Use `@Published var errorMessage: String?` for error state, `nil` = no error
- **Retry Logic:** Track retry count to prevent infinite loops
- **Deep Linking:** Use `NSWorkspace.shared.open()` to open YouTube URLs in default browser

**Testing Requirements:**
- Unit tests for error code mapping and classification
- UI tests for all error scenarios and user actions (dismiss, retry, open in YouTube)
- Manual testing with real error scenarios (invalid IDs, embedding-disabled videos)
- Edge case testing: Retry loops, rapid errors, concurrent errors

---

## Story 4.1: Focus Mode Global Toggle 🚧

**Status:** Draft
**Dependencies:** None (foundational story)
**Epic:** Epic 4 - Focus Mode & Distraction Management

**Acceptance Criteria:**
1. "Focus Mode" toggle button added to toolbar (icon: eye.slash or similar SF Symbol)
2. Clicking toggle activates/deactivates Focus Mode with visual feedback (button highlighted when active)
3. When Focus Mode ON, applies currently configured distraction hiding settings (default: hide all distractors)
4. When Focus Mode OFF, restores YouTube UI to default state (all elements visible)
5. Keyboard shortcut: ⌘⇧F toggles Focus Mode globally
6. Focus Mode state persists across app restarts (stored in UserDefaults)
7. Toast notification on toggle: "Focus Mode Enabled" or "Focus Mode Disabled"
8. Focus Mode status shown in Settings > Focus Mode section

#### Detailed Task Breakdown

**Phase 1: Focus Mode State Management (AC: 6)**
- [ ] **Task 4.1.1:** Create FocusMode data model and persistence
  - [ ] Subtask: Create `MyToob/Models/FocusModeSettings.swift` with `@Observable class FocusModeSettings`
  - [ ] Subtask: Add `@Published var isEnabled: Bool = false` for global toggle state
  - [ ] Subtask: Add `@AppStorage("focusModeEnabled") private var storedEnabled: Bool = false` for persistence
  - [ ] Subtask: Sync `isEnabled` with `storedEnabled` on init and changes
  - [ ] Subtask: Add `var activePreset: DistractionPreset = .moderate` (will be detailed in Story 4.7)
  - [ ] Subtask: Create singleton or `@Environment` injection for app-wide access
  - [ ] Subtask: Unit test: Verify state persists across app restarts

**Phase 2: Toolbar Toggle Button (AC: 1, 2)**
- [ ] **Task 4.1.2:** Add Focus Mode toggle button to toolbar
  - [ ] Subtask: In main `ContentView` or `ToolbarView`, add `.toolbar` modifier
  - [ ] Subtask: Add button: `ToolbarItem(placement: .navigation) { Button { toggleFocusMode() } label: { Image(systemName: "eye.slash") } }`
  - [ ] Subtask: Use SF Symbol `eye.slash` when enabled, `eye` when disabled (visual toggle state)
  - [ ] Subtask: Add `.background()` highlight when active: `.background(focusMode.isEnabled ? Color.accentColor.opacity(0.2) : .clear)`
  - [ ] Subtask: Add accessibility label: `.accessibilityLabel("Toggle Focus Mode")`
  - [ ] Subtask: Tooltip: `.help("Focus Mode (⌘⇧F)")`

**Phase 3: Toggle Action Logic (AC: 3, 4)**
- [ ] **Task 4.1.3:** Implement toggle action
  - [ ] Subtask: Define `toggleFocusMode()` function in ViewModel or ContentView
  - [ ] Subtask: Toggle state: `focusMode.isEnabled.toggle()`
  - [ ] Subtask: If `isEnabled == true`, apply distraction hiding settings (call `applyDistractionHiding()`)
  - [ ] Subtask: If `isEnabled == false`, restore YouTube UI to default (call `restoreYouTubeUI()`)
  - [ ] Subtask: `applyDistractionHiding()`: Read `activePreset` and apply CSS injections (defer details to Stories 4.2-4.5)
  - [ ] Subtask: `restoreYouTubeUI()`: Remove all CSS injections, show all hidden elements
  - [ ] Subtask: Log toggle: `logger.info("Focus Mode toggled: \(focusMode.isEnabled)")`

**Phase 4: Keyboard Shortcut (AC: 5)**
- [ ] **Task 4.1.4:** Add ⌘⇧F keyboard shortcut
  - [ ] Subtask: In `ContentView` or main window, add `.keyboardShortcut("F", modifiers: [.command, .shift])`
  - [ ] Subtask: Bind shortcut to `toggleFocusMode()` action
  - [ ] Subtask: Test shortcut works globally (even when toolbar button not visible)
  - [ ] Subtask: Ensure shortcut doesn't conflict with macOS system shortcuts
  - [ ] Subtask: Document shortcut in Help menu or keyboard shortcuts list

**Phase 5: Toast Notification (AC: 7)**
- [ ] **Task 4.1.5:** Display toast notification on toggle
  - [ ] Subtask: Create `ToastView` SwiftUI component (if not already exists)
  - [ ] Subtask: Add `@State var showToast: Bool = false` and `@State var toastMessage: String = ""`
  - [ ] Subtask: In `toggleFocusMode()`, set `toastMessage = focusMode.isEnabled ? "Focus Mode Enabled" : "Focus Mode Disabled"`
  - [ ] Subtask: Set `showToast = true`, auto-dismiss after 2 seconds: `DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showToast = false }`
  - [ ] Subtask: Display toast overlay: `.overlay(alignment: .top) { if showToast { ToastView(message: toastMessage) } }`
  - [ ] Subtask: Style toast: Rounded rectangle, semi-transparent background, slide-down animation

**Phase 6: Settings UI Integration (AC: 8)**
- [ ] **Task 4.1.6:** Show Focus Mode status in Settings
  - [ ] Subtask: In `Settings > Focus Mode`, add status row: `Text("Status: \(focusMode.isEnabled ? "Active" : "Inactive")")`
  - [ ] Subtask: Add green/red indicator dot next to status
  - [ ] Subtask: Add toggle in Settings as alternative to toolbar button
  - [ ] Subtask: Sync Settings toggle with toolbar button (both trigger same `toggleFocusMode()`)
  - [ ] Subtask: Show active preset name: `Text("Active Preset: \(focusMode.activePreset.name)")`

**Phase 7: Default Distraction Hiding Config (AC: 3)**
- [ ] **Task 4.1.7:** Set default "hide all distractors" configuration
  - [ ] Subtask: Define default preset: `DistractionPreset.moderate = {hideSidebar: true, hideRelated: true, hideComments: true, hideFeed: false}`
  - [ ] Subtask: Or use `DistractionPreset.maximum` for "hide all": `{hideSidebar: true, hideRelated: true, hideComments: true, hideFeed: true}`
  - [ ] Subtask: Apply default preset on first enable if user hasn't customized settings
  - [ ] Subtask: Document default behavior in UI (tooltip or info text)

**Phase 8: Testing (AC: All)**
- [ ] **Task 4.1.8:** Test Focus Mode toggle functionality
  - [ ] Subtask: UI test: Click toolbar button, verify state toggles
  - [ ] Subtask: UI test: Press ⌘⇧F, verify state toggles
  - [ ] Subtask: UI test: Verify toast notification displayed on toggle
  - [ ] Subtask: UI test: Restart app, verify Focus Mode state persists
  - [ ] Subtask: UI test: Toggle in Settings, verify toolbar button updates
  - [ ] Subtask: Integration test: Verify distraction hiding applied when enabled
  - [ ] Subtask: Manual test: Verify all UI elements respond to toggle (sidebar, related, comments, feed)

**Dev Notes:**
- **Files:** `MyToob/Models/FocusModeSettings.swift` (state), `MyToob/Views/ContentView.swift` (toolbar), `MyToob/Views/ToastView.swift` (notification), `MyToob/Views/Settings/FocusModeSettingsView.swift` (settings UI)
- **Pattern:** Use `@AppStorage` for persistence, `@Observable` for SwiftUI reactivity
- **Default Config:** Start with "Moderate" preset (hide sidebar, related, comments; keep feed)
- **CSS Injection:** Distraction hiding implemented via WKWebView CSS injection (detailed in Stories 4.2-4.5)

**Testing Requirements:**
- UI tests for toolbar toggle, keyboard shortcut, Settings toggle
- Persistence tests (state survives app restart)
- Integration tests for distraction hiding application
- Accessibility tests for keyboard shortcut and VoiceOver support

---

## Story 4.2: Hide YouTube Sidebar 🚧

**Status:** Draft
**Dependencies:** Story 4.1 (Focus Mode Toggle)
**Epic:** Epic 4 - Focus Mode & Distraction Management

**Acceptance Criteria:**
1. Settings > Focus Mode > "Hide YouTube Sidebar" toggle
2. When enabled, YouTube sidebar (trending, recommended) hidden from main content area (CSS injection or DOM manipulation if accessing YouTube web views)
3. Note: This applies to YouTube web content if displayed within the app (not applicable to IFrame Player which doesn't show sidebar)
4. Setting applies immediately without app restart
5. Setting syncs via CloudKit if sync enabled
6. "Granular Control" button allows showing/hiding specific sidebar sections (Advanced: Trending ON, Recommended OFF)
7. UI test verifies sidebar visibility changes based on toggle state

#### Detailed Task Breakdown

**Phase 1: Settings Toggle UI (AC: 1)**
- [ ] **Task 4.2.1:** Add "Hide YouTube Sidebar" toggle in Settings
  - [ ] Subtask: In `FocusModeSettingsView`, add `Toggle("Hide YouTube Sidebar", isOn: $focusMode.hideSidebar)`
  - [ ] Subtask: Add to `FocusModeSettings` model: `@Published var hideSidebar: Bool = false`
  - [ ] Subtask: Persist with `@AppStorage("focusModeHideSidebar") private var storedHideSidebar: Bool = false`
  - [ ] Subtask: Sync `hideSidebar` with `storedHideSidebar`
  - [ ] Subtask: Add info text: `Text("Hides trending and recommended sections from YouTube sidebar")`
  - [ ] Subtask: Enable/disable based on Focus Mode global toggle (greyed out if Focus Mode off)

**Phase 2: CSS Injection for Sidebar Hiding (AC: 2, 3)**
- [ ] **Task 4.2.2:** Implement CSS injection to hide YouTube sidebar
  - [ ] Subtask: Identify YouTube sidebar CSS selectors (e.g., `#secondary`, `.ytd-browse-feed-renderer`)
  - [ ] Subtask: Create CSS injection script: `const css = "#secondary { display: none !important; }"`
  - [ ] Subtask: In WKWebView (if used for YouTube browsing), inject CSS via `WKUserScript`
  - [ ] Subtask: Create user script: `let userScript = WKUserScript(source: css, injectionTime: .atDocumentEnd, forMainFrameOnly: false)`
  - [ ] Subtask: Add to `WKUserContentController`: `contentController.addUserScript(userScript)`
  - [ ] Subtask: Note: IFrame Player doesn't show sidebar—this applies only to full YouTube web browsing if implemented

**Phase 3: Immediate Application (AC: 4)**
- [ ] **Task 4.2.3:** Apply setting immediately without restart
  - [ ] Subtask: Add `.onChange(of: focusMode.hideSidebar)` in WKWebView wrapper
  - [ ] Subtask: When `hideSidebar` changes, re-inject or remove CSS dynamically
  - [ ] Subtask: For dynamic removal, inject reverse CSS: `#secondary { display: block !important; }`
  - [ ] Subtask: Alternatively, reload WKWebView with updated user scripts (more reliable)
  - [ ] Subtask: Test toggle works immediately during active YouTube browsing session

**Phase 4: CloudKit Sync (AC: 5)**
- [ ] **Task 4.2.4:** Sync setting via CloudKit
  - [ ] Subtask: Add `hideSidebar` to `FocusModeSettings` CloudKit record (if using CloudKit for settings sync)
  - [ ] Subtask: Implement sync logic: When `hideSidebar` changes locally, push to CloudKit
  - [ ] Subtask: Implement pull logic: When CloudKit record updated, update local `hideSidebar`
  - [ ] Subtask: Handle sync conflicts (last-write-wins or user prompt)
  - [ ] Subtask: Test sync across devices (enable on Mac 1, verify synced to Mac 2)

**Phase 5: Granular Control (AC: 6)**
- [ ] **Task 4.2.5:** Add granular sidebar section control
  - [ ] Subtask: Add "Granular Control" disclosure button in Settings (expands advanced options)
  - [ ] Subtask: Add individual toggles: `Toggle("Hide Trending", isOn: $focusMode.hideTrending)`, `Toggle("Hide Recommended", isOn: $focusMode.hideRecommended)`
  - [ ] Subtask: Update CSS injection to target specific sections: Trending = `.ytd-trending-renderer`, Recommended = `.ytd-recommendation-renderer`
  - [ ] Subtask: Combine CSS rules: `const css = (hideTrending ? ".ytd-trending-renderer { display: none !important; }" : "") + (hideRecommended ? ".ytd-recommendation-renderer { display: none !important; }" : "")`
  - [ ] Subtask: If "Hide YouTube Sidebar" master toggle ON, grey out granular controls (master toggle hides all)
  - [ ] Subtask: Persist granular settings: `@AppStorage("focusModeHideTrending")`, `@AppStorage("focusModeHideRecommended")`

**Phase 6: YouTube Web View Integration (AC: 3)**
- [ ] **Task 4.2.6:** Integrate sidebar hiding with YouTube web views
  - [ ] Subtask: Identify where YouTube web content is displayed (if applicable—may only be IFrame Player in MVP)
  - [ ] Subtask: If full YouTube browsing is supported, create `YouTubeBrowseView` with WKWebView
  - [ ] Subtask: Apply CSS injection to `YouTubeBrowseView`'s WKWebView
  - [ ] Subtask: If only IFrame Player used, document: "Sidebar hiding not applicable to IFrame Player (no sidebar shown)"
  - [ ] Subtask: Consider future support for in-app YouTube browsing vs. opening in Safari

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 4.2.7:** Test sidebar hiding functionality
  - [ ] Subtask: UI test: Toggle "Hide YouTube Sidebar", verify CSS injected in WKWebView
  - [ ] Subtask: UI test: Verify sidebar hidden in YouTube web view (if applicable)
  - [ ] Subtask: UI test: Toggle off, verify sidebar reappears
  - [ ] Subtask: UI test: Test granular controls (hide only Trending, only Recommended)
  - [ ] Subtask: Integration test: Enable Focus Mode, verify sidebar hidden by default
  - [ ] Subtask: Manual test: Browse YouTube in-app, verify sidebar visibility changes
  - [ ] Subtask: Sync test: Toggle on Device A, verify synced to Device B via CloudKit

**Dev Notes:**
- **Files:** `MyToob/Models/FocusModeSettings.swift` (settings), `MyToob/Views/Settings/FocusModeSettingsView.swift` (UI), `MyToob/Player/YouTubeBrowseView.swift` (WKWebView if applicable)
- **CSS Selectors:** Use YouTube's public CSS classes (subject to change—may need periodic updates)
- **IFrame Player:** IFrame Player doesn't show sidebar—this feature is for full YouTube browsing if/when implemented
- **Alternative Approach:** If not using WKWebView for YouTube browsing, this story may be deferred or simplified

**Testing Requirements:**
- UI tests for Settings toggles (master and granular controls)
- WKWebView CSS injection tests (verify CSS applied correctly)
- CloudKit sync tests (verify setting syncs across devices)
- Manual visual tests with real YouTube content

---

## Story 4.3: Hide Related Videos Panel 🚧

**Status:** Draft
**Dependencies:** Story 4.1 (Focus Mode Toggle)
**Epic:** Epic 4 - Focus Mode & Distraction Management

**Acceptance Criteria:**
1. Settings > Focus Mode > "Hide Related Videos" toggle
2. When enabled, related videos panel removed from player view (right-side panel or below-player section)
3. "Up Next" autoplay queue hidden (user can manually navigate to next video from library)
4. Option to "Show Related from Same Creator Only" (middle ground: hide algorithm suggestions but keep creator's content)
5. Setting applies to both YouTube IFrame Player context and any YouTube web content
6. If hiding is not possible due to IFrame Player limitations, show explanation: "This YouTube video requires related videos to be shown (creator setting)"
7. UI test verifies related videos panel hidden when toggle enabled

#### Detailed Task Breakdown

**Phase 1: Settings Toggle UI (AC: 1)**
- [ ] **Task 4.3.1:** Add "Hide Related Videos" toggle in Settings
  - [ ] Subtask: In `FocusModeSettingsView`, add `Toggle("Hide Related Videos", isOn: $focusMode.hideRelatedVideos)`
  - [ ] Subtask: Add to `FocusModeSettings` model: `@Published var hideRelatedVideos: Bool = false`
  - [ ] Subtask: Persist with `@AppStorage("focusModeHideRelatedVideos") private var storedHideRelated: Bool = false`
  - [ ] Subtask: Add info text: `Text("Hides 'Up Next' and related video recommendations during playback")`
  - [ ] Subtask: Enable/disable based on Focus Mode global toggle

**Phase 2: IFrame Player Configuration (AC: 2, 5)**
- [ ] **Task 4.3.2:** Configure IFrame Player to hide related videos
  - [ ] Subtask: In `player.html`, update IFrame Player initialization parameters
  - [ ] Subtask: Add `rel: 0` to player configuration: `new YT.Player('player', {playerVars: {rel: 0}})`
  - [ ] Subtask: `rel: 0` shows related videos from same channel only (not full hide, but reduces algorithmic suggestions)
  - [ ] Subtask: For fuller hiding, use CSS injection to hide related videos section: `.ytp-endscreen-content { display: none !important; }`
  - [ ] Subtask: Inject CSS when `hideRelatedVideos == true`, remove when `false`
  - [ ] Subtask: Test: Verify end-screen related videos hidden after video completes

**Phase 3: "Up Next" Autoplay Queue Hiding (AC: 3)**
- [ ] **Task 4.3.3:** Hide "Up Next" autoplay queue
  - [ ] Subtask: Identify "Up Next" UI element in YouTube player (if present in IFrame Player)
  - [ ] Subtask: Add CSS injection: `.ytp-autonav-endscreen-upnext-thumbnail { display: none !important; }`
  - [ ] Subtask: Disable autoplay to next video: `autoplay: 0` in IFrame Player config
  - [ ] Subtask: User must manually select next video from library or playlist
  - [ ] Subtask: Document behavior: "Autoplay disabled in Focus Mode—manually select next video"

**Phase 4: "Show Related from Same Creator Only" Option (AC: 4)**
- [ ] **Task 4.3.4:** Add middle-ground "Same Creator Only" option
  - [ ] Subtask: Add radio buttons or segmented control in Settings:
    - [ ] Option 1: "Show All Related Videos" (default YouTube behavior, `rel: 1`)
    - [ ] Option 2: "Show Related from Same Creator Only" (`rel: 0`)
    - [ ] Option 3: "Hide All Related Videos" (CSS injection + `rel: 0`)
  - [ ] Subtask: Add to model: `enum RelatedVideosMode { case showAll, sameCreatorOnly, hideAll }`
  - [ ] Subtask: Apply appropriate IFrame Player config based on selected mode
  - [ ] Subtask: Persist mode: `@AppStorage("relatedVideosMode") var relatedMode: RelatedVideosMode = .sameCreatorOnly`

**Phase 5: YouTube Web Content Integration (AC: 5)**
- [ ] **Task 4.3.5:** Apply setting to YouTube web content (if applicable)
  - [ ] Subtask: If using WKWebView for full YouTube browsing, inject CSS to hide related videos panel
  - [ ] Subtask: CSS selector: `.watch-sidebar { display: none !important; }` (hides right-side related videos)
  - [ ] Subtask: Test on actual YouTube web pages loaded in WKWebView
  - [ ] Subtask: If only using IFrame Player, document: "Full web view not applicable, IFrame Player config sufficient"

**Phase 6: Limitation Handling (AC: 6)**
- [ ] **Task 4.3.6:** Handle creator-enforced related videos
  - [ ] Subtask: Some creators may enforce related videos via player settings (rare but possible)
  - [ ] Subtask: Detect if CSS injection fails (related videos still visible after injection)
  - [ ] Subtask: Show informational message: `Text("This video requires related videos to be shown (creator setting)")`
  - [ ] Subtask: Display message as non-blocking info banner, not error
  - [ ] Subtask: Log limitation: `logger.info("Related videos hiding not possible for video \(videoID)")`

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 4.3.7:** Test related videos hiding
  - [ ] Subtask: UI test: Toggle "Hide Related Videos", verify CSS injected
  - [ ] Subtask: UI test: Play video to completion, verify end-screen related videos hidden
  - [ ] Subtask: UI test: Verify "Up Next" autoplay disabled
  - [ ] Subtask: UI test: Test "Same Creator Only" mode, verify only creator's videos shown
  - [ ] Subtask: Manual test: Play various videos, verify related videos behavior
  - [ ] Subtask: Edge case test: Videos with creator-enforced related videos (if detectable)
  - [ ] Subtask: Integration test: Enable Focus Mode, verify related videos hidden by default

**Dev Notes:**
- **Files:** `MyToob/Models/FocusModeSettings.swift`, `MyToob/Player/player.html` (IFrame config), `MyToob/Views/Settings/FocusModeSettingsView.swift`
- **IFrame Player Param:** `rel: 0` is partial solution (same creator only), full hide requires CSS
- **CSS Selectors:** `.ytp-endscreen-content`, `.ytp-autonav-endscreen-upnext-thumbnail`, `.watch-sidebar`
- **Autoplay:** Disable autoplay to prevent unwanted navigation to next video

**Testing Requirements:**
- UI tests for Settings toggle and mode selection
- IFrame Player parameter tests (`rel: 0` vs `rel: 1`)
- CSS injection tests for related videos hiding
- Manual visual tests with video playback to completion
- Edge case tests for creator-enforced related videos

---

## Story 4.4: Hide Comments Section 🚧

**Status:** Draft
**Dependencies:** Story 4.1 (Focus Mode Toggle)
**Epic:** Epic 4 - Focus Mode & Distraction Management

**Acceptance Criteria:**
1. Settings > Focus Mode > "Hide Comments" toggle
2. When enabled, comments section removed from video detail view
3. "Show Comments" button available to temporarily reveal comments (for videos where user wants community discussion)
4. Setting persists per-session (temporary show resets on new video or app restart)
5. Privacy benefit communicated: "Hiding comments also prevents tracking via comment interactions"
6. Setting syncs via CloudKit
7. UI test verifies comments section visibility based on toggle

#### Detailed Task Breakdown

**Phase 1: Settings Toggle UI (AC: 1, 5)**
- [ ] **Task 4.4.1:** Add "Hide Comments" toggle in Settings
  - [ ] Subtask: In `FocusModeSettingsView`, add `Toggle("Hide Comments", isOn: $focusMode.hideComments)`
  - [ ] Subtask: Add to `FocusModeSettings` model: `@Published var hideComments: Bool = false`
  - [ ] Subtask: Persist with `@AppStorage("focusModeHideComments") private var storedHideComments: Bool = false`
  - [ ] Subtask: Add info text: `Text("Hides comments section to avoid spoilers, toxicity, and distractions")`
  - [ ] Subtask: Add privacy benefit text: `Text("Privacy benefit: Also prevents tracking via comment interactions").font(.caption).foregroundColor(.secondary)`

**Phase 2: CSS Injection for Comments Hiding (AC: 2)**
- [ ] **Task 4.4.2:** Implement CSS injection to hide comments
  - [ ] Subtask: Identify YouTube comments section CSS selector (e.g., `#comments`, `.ytd-comments`)
  - [ ] Subtask: Create CSS injection: `const css = "#comments { display: none !important; }"`
  - [ ] Subtask: In WKWebView (if used), inject CSS via `WKUserScript`
  - [ ] Subtask: Apply injection when `hideComments == true`
  - [ ] Subtask: Remove or reverse injection when `hideComments == false`
  - [ ] Subtask: Note: IFrame Player typically doesn't show comments—this is for full YouTube web browsing if applicable

**Phase 3: "Show Comments" Temporary Reveal Button (AC: 3)**
- [ ] **Task 4.4.3:** Add temporary "Show Comments" button
  - [ ] Subtask: In video detail view (if applicable), add button below player: `Button("Show Comments") { showCommentsTemporarily() }`
  - [ ] Subtask: Only show button when `hideComments == true` (hidden otherwise)
  - [ ] Subtask: Implement `showCommentsTemporarily()`: Set `@State var commentsTemporarilyVisible: Bool = true`
  - [ ] Subtask: When `commentsTemporarilyVisible == true`, do NOT inject hide-comments CSS for current video
  - [ ] Subtask: Add icon: `Image(systemName: "text.bubble")` next to button
  - [ ] Subtask: Style button: Secondary button style, positioned below player or in video details section

**Phase 4: Per-Session Persistence (AC: 4)**
- [ ] **Task 4.4.4:** Reset temporary reveal on new video or restart
  - [ ] Subtask: Add `@State var commentsTemporarilyVisible: Bool = false` (session state, not persisted)
  - [ ] Subtask: When new video loaded, reset `commentsTemporarilyVisible = false`
  - [ ] Subtask: In `loadVideo(videoID:)`, add: `commentsTemporarilyVisible = false` to hide comments for new video
  - [ ] Subtask: On app restart, `commentsTemporarilyVisible` defaults to `false` (SwiftUI `@State` not persisted)
  - [ ] Subtask: Document behavior: "Temporary reveal applies only to current video session"

**Phase 5: CloudKit Sync (AC: 6)**
- [ ] **Task 4.4.5:** Sync hideComments setting via CloudKit
  - [ ] Subtask: Add `hideComments` to `FocusModeSettings` CloudKit record
  - [ ] Subtask: Implement push: When `hideComments` changes locally, update CloudKit
  - [ ] Subtask: Implement pull: When CloudKit record updated remotely, update local `hideComments`
  - [ ] Subtask: Handle sync conflicts (last-write-wins)
  - [ ] Subtask: Test sync: Enable on Device A, verify synced to Device B

**Phase 6: YouTube Web View Integration (AC: 2)**
- [ ] **Task 4.4.6:** Apply comments hiding to YouTube web views
  - [ ] Subtask: If using WKWebView for full YouTube browsing, inject comments-hiding CSS
  - [ ] Subtask: CSS selector: `#comments { display: none !important; }, .ytd-comments { display: none !important; }`
  - [ ] Subtask: Test on actual YouTube video pages in WKWebView
  - [ ] Subtask: If only IFrame Player used (no comments shown), document: "Comments not applicable to IFrame Player"

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 4.4.7:** Test comments hiding functionality
  - [ ] Subtask: UI test: Toggle "Hide Comments", verify CSS injected
  - [ ] Subtask: UI test: Verify comments section hidden in YouTube web view (if applicable)
  - [ ] Subtask: UI test: Click "Show Comments" button, verify comments reappear for current video
  - [ ] Subtask: UI test: Load new video, verify comments hidden again (temporary reveal reset)
  - [ ] Subtask: UI test: Restart app, verify comments hidden (temporary reveal not persisted)
  - [ ] Subtask: Sync test: Toggle on Device A, verify synced to Device B
  - [ ] Subtask: Manual test: Verify privacy benefit (no comment interaction tracking when hidden)

**Dev Notes:**
- **Files:** `MyToob/Models/FocusModeSettings.swift`, `MyToob/Views/Settings/FocusModeSettingsView.swift`, `MyToob/Views/VideoDetailView.swift` (if applicable)
- **CSS Selectors:** `#comments`, `.ytd-comments`, `#comments-section`
- **Session State:** Use `@State` for temporary reveal (not persisted), reset on new video
- **Privacy:** Hiding comments prevents tracking pixels/scripts embedded in comment section

**Testing Requirements:**
- UI tests for toggle and temporary reveal button
- CSS injection tests
- Session state tests (temporary reveal resets on new video/restart)
- CloudKit sync tests
- Manual privacy verification (comment tracking disabled when hidden)

---

## Story 4.5: Hide Homepage Feed 🚧

**Status:** Draft
**Dependencies:** Story 4.1 (Focus Mode Toggle)
**Epic:** Epic 4 - Focus Mode & Distraction Management

**Acceptance Criteria:**
1. Settings > Focus Mode > "Hide Homepage Feed" toggle
2. When enabled, YouTube homepage feed (Recommended, Trending) hidden in YouTube section of sidebar
3. Subscriptions, Playlists, Watch History remain visible (user-controlled content only)
4. Empty state in YouTube section: "Focus Mode active. Browse your subscriptions or use search."
5. "Browse YouTube Homepage" button available to temporarily disable (opens YouTube web in browser if needed)
6. Setting applies to in-app YouTube browsing (if applicable)
7. UI test verifies homepage feed hidden, subscriptions visible

#### Detailed Task Breakdown

**Phase 1: Settings Toggle UI (AC: 1)**
- [ ] **Task 4.5.1:** Add "Hide Homepage Feed" toggle in Settings
  - [ ] Subtask: In `FocusModeSettingsView`, add `Toggle("Hide Homepage Feed", isOn: $focusMode.hideHomepageFeed)`
  - [ ] Subtask: Add to `FocusModeSettings` model: `@Published var hideHomepageFeed: Bool = false`
  - [ ] Subtask: Persist with `@AppStorage("focusModeHideHomepageFeed") private var storedHideFeed: Bool = false`
  - [ ] Subtask: Add info text: `Text("Hides algorithm-driven homepage feed. Subscriptions and playlists remain visible.")`

**Phase 2: UI Conditional Rendering (AC: 2, 3)**
- [ ] **Task 4.5.2:** Conditionally hide homepage feed in UI
  - [ ] Subtask: In app's sidebar or YouTube section, check `focusMode.hideHomepageFeed`
  - [ ] Subtask: If `true`, hide "Recommended", "Trending" sections
  - [ ] Subtask: Keep visible: "Subscriptions", "Playlists", "Watch History", "Liked Videos" (user-controlled)
  - [ ] Subtask: Implement conditional rendering: `if !focusMode.hideHomepageFeed { RecommendedFeedView() }`
  - [ ] Subtask: Test: Toggle on, verify homepage feed hidden; toggle off, verify feed shown

**Phase 3: Empty State Message (AC: 4)**
- [ ] **Task 4.5.3:** Display empty state when feed hidden
  - [ ] Subtask: When `hideHomepageFeed == true` and no user content (subscriptions/playlists) visible, show empty state
  - [ ] Subtask: Create `EmptyStateView` with message: `Text("Focus Mode active. Browse your subscriptions or use search.")`
  - [ ] Subtask: Add SF Symbol icon: `Image(systemName: "eye.slash.circle")` above message
  - [ ] Subtask: Style: Center-aligned, muted color, padding
  - [ ] Subtask: Show empty state in YouTube content area (where feed would normally be)

**Phase 4: "Browse YouTube Homepage" Temporary Disable Button (AC: 5)**
- [ ] **Task 4.5.4:** Add button to temporarily open YouTube homepage
  - [ ] Subtask: In empty state or YouTube section, add `Button("Browse YouTube Homepage") { openYouTubeHomepage() }`
  - [ ] Subtask: Implement `openYouTubeHomepage()`: `NSWorkspace.shared.open(URL(string: "https://www.youtube.com")!)`
  - [ ] Subtask: Opens YouTube.com in user's default browser (Safari, Chrome, etc.)
  - [ ] Subtask: Alternative: Open in-app web view (if full YouTube browsing supported)
  - [ ] Subtask: Add icon: `Image(systemName: "arrow.up.right.square")` (external link indicator)
  - [ ] Subtask: Style: Secondary button style

**Phase 5: In-App YouTube Browsing Integration (AC: 6)**
- [ ] **Task 4.5.5:** Apply to in-app YouTube browsing (if applicable)
  - [ ] Subtask: If app has in-app YouTube browsing (WKWebView loading youtube.com), apply CSS hiding
  - [ ] Subtask: Identify homepage feed CSS selectors (e.g., `#contents ytd-browse`, `.ytd-rich-grid-renderer`)
  - [ ] Subtask: Inject CSS: `#contents ytd-browse { display: none !important; }`
  - [ ] Subtask: Keep subscriptions visible: Don't hide `.ytd-subscriptions-list-renderer`
  - [ ] Subtask: Test: Load youtube.com in WKWebView, verify homepage hidden but subscriptions accessible
  - [ ] Subtask: If no in-app browsing, document: "Opens YouTube in external browser, feed hiding not applicable"

**Phase 6: Subscriptions Remain Visible (AC: 3, 7)**
- [ ] **Task 4.5.6:** Ensure subscriptions/playlists remain accessible
  - [ ] Subtask: In app UI, keep "Subscriptions" section visible and functional
  - [ ] Subtask: Keep "Playlists" section visible (user-created playlists)
  - [ ] Subtask: Keep "Watch History" accessible (if implemented)
  - [ ] Subtask: Test: With `hideHomepageFeed == true`, verify all user-controlled sections still visible
  - [ ] Subtask: CSS targeting: Only hide algorithmic feeds, not user content

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 4.5.7:** Test homepage feed hiding
  - [ ] Subtask: UI test: Toggle "Hide Homepage Feed", verify feed hidden
  - [ ] Subtask: UI test: Verify "Subscriptions" still visible when feed hidden
  - [ ] Subtask: UI test: Verify empty state message displayed when feed hidden and no user content
  - [ ] Subtask: UI test: Click "Browse YouTube Homepage" button, verify YouTube opens in browser
  - [ ] Subtask: Integration test: Enable Focus Mode, verify homepage feed hidden by default
  - [ ] Subtask: Manual test: Navigate app with feed hidden, verify user content (subscriptions, playlists) accessible
  - [ ] Subtask: Edge case: User with no subscriptions/playlists, verify helpful empty state

**Dev Notes:**
- **Files:** `MyToob/Models/FocusModeSettings.swift`, `MyToob/Views/Settings/FocusModeSettingsView.swift`, `MyToob/Views/Sidebar/YouTubeSectionView.swift` (or similar)
- **UI Structure:** App likely has sidebar with "Subscriptions", "Playlists", "Recommended", "Trending" sections
- **Conditional Rendering:** Use SwiftUI conditional views (`if !hideHomepageFeed { ... }`)
- **External Browser:** Use `NSWorkspace.shared.open()` to open YouTube in default browser

**Testing Requirements:**
- UI tests for toggle and conditional rendering
- UI tests for empty state display
- UI tests for "Browse YouTube Homepage" button
- Manual testing of user content accessibility (subscriptions, playlists)
- Integration tests with Focus Mode enabled

---

## Story 4.6: Focus Mode Scheduling (Pro Feature) 🚧

**Status:** Draft
**Dependencies:** Story 4.1 (Focus Mode Toggle), Story 15.1 (StoreKit Configuration—for Pro feature gating)
**Epic:** Epic 4 - Focus Mode & Distraction Management

**Acceptance Criteria:**
1. Settings > Focus Mode > "Schedule Focus Mode" section (Pro badge)
2. "Enable Scheduling" toggle (Pro only, free users see "Upgrade to Pro" message)
3. Time range picker: "Active from [9:00 AM] to [5:00 PM]"
4. Day selection: Weekdays, Weekends, Specific Days (multi-select checkboxes)
5. Schedule rules apply automatically: Focus Mode enables at start time, disables at end time
6. Manual toggle overrides schedule (user can disable Focus Mode during scheduled hours if needed)
7. Schedule syncs via CloudKit (consistent across devices)
8. Notification when schedule activates Focus Mode: "Focus Mode enabled (scheduled)" (optional, user preference)
9. UI test verifies schedule activation at configured times (use mock system time)

#### Detailed Task Breakdown

**Phase 1: Pro Feature Gating UI (AC: 1, 2)**
- [ ] **Task 4.6.1:** Add Pro-gated scheduling section in Settings
  - [ ] Subtask: In `FocusModeSettingsView`, add `Section("Schedule Focus Mode")` with Pro badge
  - [ ] Subtask: Add `Toggle("Enable Scheduling", isOn: $focusMode.schedulingEnabled)`
  - [ ] Subtask: Check Pro status: `if !proManager.isPro { showUpgradePrompt() }`
  - [ ] Subtask: If free user, replace toggle with "Upgrade to Pro" button
  - [ ] Subtask: "Upgrade to Pro" button opens paywall (Story 15.2)
  - [ ] Subtask: Add Pro badge icon: `Image(systemName: "crown.fill").foregroundColor(.yellow)` next to section title

**Phase 2: Time Range Picker (AC: 3)**
- [ ] **Task 4.6.2:** Add time range picker for schedule
  - [ ] Subtask: Add `DatePicker("Start Time", selection: $focusMode.scheduleStartTime, displayedComponents: .hourAndMinute)`
  - [ ] Subtask: Add `DatePicker("End Time", selection: $focusMode.scheduleEndTime, displayedComponents: .hourAndMinute)`
  - [ ] Subtask: Add to model: `@Published var scheduleStartTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!`
  - [ ] Subtask: Add to model: `@Published var scheduleEndTime: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0))!`
  - [ ] Subtask: Persist: `@AppStorage("scheduleStartTime") var storedStart: Double = ...` (store as timeIntervalSince1970)
  - [ ] Subtask: Validate: End time must be after start time, show error if invalid

**Phase 3: Day Selection (AC: 4)**
- [ ] **Task 4.6.3:** Add day selection checkboxes
  - [ ] Subtask: Add `@Published var scheduleDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]` (default weekdays)
  - [ ] Subtask: Define `enum Weekday: String, CaseIterable { case monday, tuesday, wednesday, thursday, friday, saturday, sunday }`
  - [ ] Subtask: In Settings UI, create `ForEach(Weekday.allCases, id: \.self) { day in Toggle(day.rawValue.capitalized, isOn: binding(for: day)) }`
  - [ ] Subtask: Implement `binding(for day:)` to create Binding to `Set<Weekday>`
  - [ ] Subtask: Add preset buttons: "Weekdays" (Mon-Fri), "Weekends" (Sat-Sun), "Every Day" (all selected)
  - [ ] Subtask: Persist: Encode `Set<Weekday>` to JSON, store in `@AppStorage`

**Phase 4: Automatic Schedule Activation (AC: 5)**
- [ ] **Task 4.6.4:** Implement automatic Focus Mode scheduling
  - [ ] Subtask: Create `ScheduleManager` service to monitor current time
  - [ ] Subtask: Use `Timer.publish(every: 60, on: .main, in: .common)` to check time every minute
  - [ ] Subtask: On each timer tick, check: `shouldFocusModeBeActive() -> Bool`
  - [ ] Subtask: Implement `shouldFocusModeBeActive()`: Compare current time and day against schedule
  - [ ] Subtask: Extract current hour/minute: `let components = Calendar.current.dateComponents([.hour, .minute, .weekday], from: Date())`
  - [ ] Subtask: Check if current weekday in `scheduleDays` and current time between `scheduleStartTime` and `scheduleEndTime`
  - [ ] Subtask: If should be active and currently inactive: `focusMode.isEnabled = true` (auto-enable)
  - [ ] Subtask: If should be inactive and currently active: Check if manually enabled, if not then `focusMode.isEnabled = false` (auto-disable)

**Phase 5: Manual Override Handling (AC: 6)**
- [ ] **Task 4.6.5:** Allow manual override of schedule
  - [ ] Subtask: Add `@Published var isManuallyOverridden: Bool = false` to track manual toggles during scheduled hours
  - [ ] Subtask: When user manually toggles Focus Mode during scheduled hours, set `isManuallyOverridden = true`
  - [ ] Subtask: When `isManuallyOverridden == true`, schedule automation does NOT change state (user control)
  - [ ] Subtask: Reset `isManuallyOverridden = false` when schedule period ends (e.g., at end time or day change)
  - [ ] Subtask: Display indicator in UI: "Focus Mode scheduled but manually disabled" or "Focus Mode manually enabled outside schedule"

**Phase 6: CloudKit Sync (AC: 7)**
- [ ] **Task 4.6.6:** Sync schedule settings via CloudKit
  - [ ] Subtask: Add schedule fields to `FocusModeSettings` CloudKit record: `schedulingEnabled`, `scheduleStartTime`, `scheduleEndTime`, `scheduleDays`
  - [ ] Subtask: Implement push: When schedule settings change, update CloudKit
  - [ ] Subtask: Implement pull: When CloudKit updated remotely, update local schedule
  - [ ] Subtask: Handle sync conflicts (last-write-wins or user prompt)
  - [ ] Subtask: Test: Configure schedule on Device A, verify synced to Device B

**Phase 7: Schedule Activation Notification (AC: 8)**
- [ ] **Task 4.6.7:** Show notification when schedule activates Focus Mode
  - [ ] Subtask: Add user preference: `@AppStorage("notifyScheduleActivation") var notifyOnSchedule: Bool = true`
  - [ ] Subtask: Add toggle in Settings: `Toggle("Notify when schedule activates", isOn: $focusMode.notifyOnSchedule)`
  - [ ] Subtask: When schedule auto-enables Focus Mode and `notifyOnSchedule == true`, show notification
  - [ ] Subtask: Use macOS notification: `let notification = UNMutableNotificationContent(); notification.title = "Focus Mode"; notification.body = "Focus Mode enabled (scheduled)"`
  - [ ] Subtask: Request notification permission: `UNUserNotificationCenter.current().requestAuthorization()`
  - [ ] Subtask: Alternatively, use in-app toast notification (reuse from Story 4.1)

**Phase 8: Testing (AC: 9, All)**
- [ ] **Task 4.6.8:** Test Focus Mode scheduling
  - [ ] Subtask: Unit test: `shouldFocusModeBeActive()` logic with various times and days
  - [ ] Subtask: Unit test: Manual override behavior (schedule activation skipped when manually disabled)
  - [ ] Subtask: Integration test: Mock system time to 9:00 AM weekday, verify Focus Mode auto-enabled
  - [ ] Subtask: Integration test: Mock system time to 5:01 PM, verify Focus Mode auto-disabled
  - [ ] Subtask: UI test: Configure schedule, advance time (if possible), verify activation
  - [ ] Subtask: Pro gating test: Verify free users see "Upgrade to Pro" message
  - [ ] Subtask: Sync test: Configure schedule on Device A, verify synced to Device B
  - [ ] Subtask: Notification test: Verify notification shown when schedule activates (if enabled)

**Dev Notes:**
- **Files:** `MyToob/Models/FocusModeSettings.swift`, `MyToob/Services/ScheduleManager.swift`, `MyToob/Views/Settings/FocusModeSettingsView.swift`
- **Pro Feature:** Requires StoreKit integration (Story 15.1) to check Pro status
- **Time Handling:** Use `DateComponents` for hour/minute comparison, `Calendar.current.component(.weekday)` for day of week
- **Manual Override:** Reset override at end of scheduled period to avoid permanent override
- **Notifications:** Requires `UserNotifications` framework and user permission

**Testing Requirements:**
- Unit tests for schedule logic (time/day matching, manual override)
- Integration tests with mocked system time
- Pro feature gating tests (verify free users blocked)
- CloudKit sync tests
- Notification permission and display tests

---

## Story 4.7: Distraction Hiding Presets 🚧

**Status:** Draft
**Dependencies:** Stories 4.2-4.5 (all distraction hiding features)
**Epic:** Epic 4 - Focus Mode & Distraction Management

**Acceptance Criteria:**
1. Settings > Focus Mode > "Presets" dropdown
2. Presets defined:
   - **Minimal:** Hide sidebar + related videos only (keeps comments for discussion)
   - **Moderate:** Hide sidebar + related videos + comments (typical focus mode)
   - **Maximum Focus:** Hide all distractors (sidebar, related, comments, homepage feed)
   - **Custom:** User-configured settings (default if user changes individual toggles)
3. Selecting preset applies all associated settings immediately
4. Active preset shown in dropdown and Focus Mode toolbar button tooltip
5. "Save Current Settings as Preset" button creates custom preset (Pro feature, max 5 custom presets)
6. Presets sync via CloudKit
7. UI test verifies preset selection applies correct settings combination

#### Detailed Task Breakdown

**Phase 1: Preset Data Model (AC: 2)**
- [ ] **Task 4.7.1:** Define distraction hiding presets
  - [ ] Subtask: Create `struct DistractionPreset: Codable, Identifiable`
  - [ ] Subtask: Properties: `id: UUID`, `name: String`, `hideSidebar: Bool`, `hideRelatedVideos: Bool`, `hideComments: Bool`, `hideHomepageFeed: Bool`
  - [ ] Subtask: Define built-in presets:
    - [ ] `static let minimal = DistractionPreset(name: "Minimal", hideSidebar: true, hideRelatedVideos: true, hideComments: false, hideHomepageFeed: false)`
    - [ ] `static let moderate = DistractionPreset(name: "Moderate", hideSidebar: true, hideRelatedVideos: true, hideComments: true, hideHomepageFeed: false)`
    - [ ] `static let maximumFocus = DistractionPreset(name: "Maximum Focus", hideSidebar: true, hideRelatedVideos: true, hideComments: true, hideHomepageFeed: true)`
  - [ ] Subtask: Add to model: `@Published var activePreset: DistractionPreset = .moderate`
  - [ ] Subtask: Add `@Published var customPresets: [DistractionPreset] = []` for user-created presets

**Phase 2: Preset Picker UI (AC: 1, 4)**
- [ ] **Task 4.7.2:** Add preset picker in Settings
  - [ ] Subtask: In `FocusModeSettingsView`, add `Picker("Preset", selection: $focusMode.activePreset) { ForEach(allPresets) { preset in Text(preset.name).tag(preset) } }`
  - [ ] Subtask: Compute `allPresets`: `[.minimal, .moderate, .maximumFocus] + customPresets`
  - [ ] Subtask: Display active preset name in picker
  - [ ] Subtask: When user changes individual toggles (sidebar, related, etc.), automatically switch to "Custom" preset
  - [ ] Subtask: Implement `detectCustomPreset()`: If current settings don't match any built-in preset, create/select custom preset

**Phase 3: Apply Preset Settings (AC: 3)**
- [ ] **Task 4.7.3:** Apply preset when selected
  - [ ] Subtask: Add `.onChange(of: focusMode.activePreset)` modifier
  - [ ] Subtask: When preset changes, apply settings: `applyPreset(focusMode.activePreset)`
  - [ ] Subtask: Implement `applyPreset(_ preset: DistractionPreset)`:
    - [ ] `focusMode.hideSidebar = preset.hideSidebar`
    - [ ] `focusMode.hideRelatedVideos = preset.hideRelatedVideos`
    - [ ] `focusMode.hideComments = preset.hideComments`
    - [ ] `focusMode.hideHomepageFeed = preset.hideHomepageFeed`
  - [ ] Subtask: Settings apply immediately (trigger CSS injections, UI updates)
  - [ ] Subtask: Log preset application: `logger.info("Applied preset: \(preset.name)")`

**Phase 4: Toolbar Tooltip Integration (AC: 4)**
- [ ] **Task 4.7.4:** Show active preset in toolbar button tooltip
  - [ ] Subtask: Update Focus Mode toolbar button `.help()` modifier
  - [ ] Subtask: Tooltip text: `"Focus Mode (⌘⇧F) - Active Preset: \(focusMode.activePreset.name)"`
  - [ ] Subtask: Dynamically update tooltip when preset changes
  - [ ] Subtask: Test: Hover over toolbar button, verify preset name shown

**Phase 5: Save Custom Preset (Pro Feature) (AC: 5)**
- [ ] **Task 4.7.5:** Add "Save Current Settings as Preset" button
  - [ ] Subtask: In Settings, add button: `Button("Save as Custom Preset") { saveCustomPreset() }`
  - [ ] Subtask: Pro-gate feature: `if !proManager.isPro { showUpgradePrompt() }`
  - [ ] Subtask: If Pro, prompt for preset name: `TextFieldAlert("Enter preset name:") { name in ... }`
  - [ ] Subtask: Create custom preset: `let preset = DistractionPreset(name: name, hideSidebar: focusMode.hideSidebar, ...)`
  - [ ] Subtask: Validate: Max 5 custom presets, show error if limit reached
  - [ ] Subtask: Add to `customPresets` array, persist to `@AppStorage` (encode as JSON)

**Phase 6: Preset Management UI (AC: 5)**
- [ ] **Task 4.7.6:** Add UI to manage custom presets
  - [ ] Subtask: Display custom presets in list with "Edit" and "Delete" buttons
  - [ ] Subtask: "Delete" button removes preset from `customPresets` array
  - [ ] Subtask: "Edit" button allows renaming preset (settings immutable, only name editable)
  - [ ] Subtask: Reorder presets via drag-and-drop (optional enhancement)
  - [ ] Subtask: Persist changes to `@AppStorage`

**Phase 7: CloudKit Sync (AC: 6)**
- [ ] **Task 4.7.7:** Sync presets via CloudKit
  - [ ] Subtask: Add `activePreset` and `customPresets` to `FocusModeSettings` CloudKit record
  - [ ] Subtask: Encode presets as JSON for CloudKit storage
  - [ ] Subtask: Implement push: When preset changes or custom preset created, update CloudKit
  - [ ] Subtask: Implement pull: When CloudKit updated remotely, update local presets
  - [ ] Subtask: Handle conflicts: Merge custom presets from both devices (combine arrays, deduplicate by name)
  - [ ] Subtask: Test: Create custom preset on Device A, verify synced to Device B

**Phase 8: Testing (AC: 7, All)**
- [ ] **Task 4.7.8:** Test distraction hiding presets
  - [ ] Subtask: UI test: Select "Minimal" preset, verify sidebar and related videos hidden, comments visible
  - [ ] Subtask: UI test: Select "Moderate" preset, verify sidebar, related, and comments hidden, feed visible
  - [ ] Subtask: UI test: Select "Maximum Focus" preset, verify all distractors hidden
  - [ ] Subtask: UI test: Change individual toggle, verify preset switches to "Custom"
  - [ ] Subtask: UI test: (Pro) Save custom preset, verify appears in preset picker
  - [ ] Subtask: UI test: Delete custom preset, verify removed from picker
  - [ ] Subtask: Pro gating test: Verify free users see "Upgrade to Pro" when saving custom preset
  - [ ] Subtask: Sync test: Create custom preset on Device A, verify synced to Device B

**Dev Notes:**
- **Files:** `MyToob/Models/FocusModeSettings.swift` (preset model), `MyToob/Views/Settings/FocusModeSettingsView.swift` (preset picker UI)
- **Custom Detection:** When user changes individual toggles, compare current settings to all built-in presets; if no match, switch to "Custom"
- **Pro Feature:** Custom preset saving is Pro-only, max 5 presets (free users can use built-in presets)
- **Persistence:** Encode `[DistractionPreset]` as JSON to store in `@AppStorage` or CloudKit

**Testing Requirements:**
- UI tests for preset selection and application
- UI tests for automatic "Custom" preset detection
- UI tests for custom preset creation, editing, deletion (Pro users)
- Pro feature gating tests
- CloudKit sync tests for custom presets
- Integration tests verifying preset settings applied correctly (CSS injections, UI updates)

---

## Story 5.2: Security-Scoped Bookmarks for Persistent Access 🚧

**Status:** Draft
**Dependencies:** Story 5.1 (Local File Import)—Done ✅
**Epic:** Epic 5 - Local File Playback & Management

**Acceptance Criteria:**
1. When file selected via `NSOpenPanel`, obtain security-scoped bookmark using `URL.bookmarkData(options: .withSecurityScope)`
2. Bookmark data stored in SwiftData alongside `VideoItem.localURL`
3. On app launch or when accessing file, resolve bookmark using `URL(resolvingBookmarkData:options:)`
4. If bookmark resolution fails (file moved/deleted), show user error: "File not found at original location" with option to re-select
5. "Relocate File" action in video context menu allows user to point to moved file
6. Stale bookmarks cleaned up periodically (remove `VideoItem` if file unavailable for 30+ days)
7. Unit tests verify bookmark creation/resolution with temporary test files

#### Detailed Task Breakdown

**Phase 1: Bookmark Creation on Import (AC: 1)**
- [ ] **Task 5.2.1:** Create security-scoped bookmarks when importing files
  - [ ] Subtask: In file import handler (Story 5.1), after user selects file via `NSOpenPanel`
  - [ ] Subtask: For each selected URL, call `let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)`
  - [ ] Subtask: Wrap in `do-catch` block, log error if bookmark creation fails: `logger.error("Failed to create bookmark for \(url): \(error)")`
  - [ ] Subtask: If bookmark creation fails, show user warning but still import file (bookmark is optional for current session)
  - [ ] Subtask: Test: Verify bookmark data generated for various file types (MP4, MOV, MKV)

**Phase 2: Bookmark Storage in SwiftData (AC: 2)**
- [ ] **Task 5.2.2:** Store bookmark data in VideoItem model
  - [ ] Subtask: Add property to `VideoItem`: `@Attribute var bookmarkData: Data?`
  - [ ] Subtask: In file import, save bookmark data: `videoItem.bookmarkData = bookmarkData`
  - [ ] Subtask: Ensure bookmark data persisted to SwiftData when `modelContext.save()` called
  - [ ] Subtask: Add migration if `VideoItem` schema changes (add `bookmarkData` field)
  - [ ] Subtask: Test: Verify bookmark data stored correctly in SwiftData database

**Phase 3: Bookmark Resolution on Access (AC: 3)**
- [ ] **Task 5.2.3:** Resolve bookmarks when accessing files
  - [ ] Subtask: Create `BookmarkManager` service with `resolveBookmark(data: Data) -> URL?` method
  - [ ] Subtask: Implement resolution: `var isStale = false; let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)`
  - [ ] Subtask: Start accessing security-scoped resource: `url.startAccessingSecurityScopedResource()`
  - [ ] Subtask: Store `url` in `VideoItem` for current session (cache resolved URL)
  - [ ] Subtask: Stop accessing when done (in `deinit` or view cleanup): `url.stopAccessingSecurityScopedResource()`
  - [ ] Subtask: Handle stale bookmarks: If `isStale == true`, regenerate bookmark and save updated data
  - [ ] Subtask: Log resolution: `logger.debug("Resolved bookmark for \(url.lastPathComponent)")`

**Phase 4: Bookmark Resolution Failure Handling (AC: 4)**
- [ ] **Task 5.2.4:** Handle bookmark resolution failures
  - [ ] Subtask: When `resolveBookmark()` fails, catch error and determine cause
  - [ ] Subtask: If file not found (moved/deleted), set `videoItem.isFileAvailable = false`
  - [ ] Subtask: Display error message to user: `Alert("File not found at original location. The file may have been moved or deleted.")`
  - [ ] Subtask: Provide "Relocate File" button in alert to allow user to re-select file
  - [ ] Subtask: Log error: `logger.warning("Bookmark resolution failed for \(videoItem.title): \(error)")`
  - [ ] Subtask: Show placeholder thumbnail for unavailable files (greyed out, overlay "Unavailable" text)

**Phase 5: Relocate File Action (AC: 5)**
- [ ] **Task 5.2.5:** Add "Relocate File" context menu action
  - [ ] Subtask: In video library context menu, add "Relocate File..." action for local videos
  - [ ] Subtask: Only show action if `videoItem.isLocal == true` and `isFileAvailable == false`
  - [ ] Subtask: Action opens `NSOpenPanel` to select new file location
  - [ ] Subtask: When user selects new file, update `videoItem.localURL` and regenerate bookmark
  - [ ] Subtask: Verify new file is valid video (same codec/duration if possible)
  - [ ] Subtask: Save updated `VideoItem` to SwiftData
  - [ ] Subtask: Test: Manually move file, verify relocate action works

**Phase 6: Stale Bookmark Cleanup (AC: 6)**
- [ ] **Task 5.2.6:** Periodically clean up stale bookmarks
  - [ ] Subtask: Create background task to check file availability for all local videos
  - [ ] Subtask: Run cleanup on app launch and every 7 days (use `Timer` or background scheduler)
  - [ ] Subtask: For each `VideoItem` where `isLocal == true`, attempt to resolve bookmark
  - [ ] Subtask: If resolution fails, set `lastAvailableDate` to current date (or increment unavailable counter)
  - [ ] Subtask: If file unavailable for >30 days, remove `VideoItem` from database
  - [ ] Subtask: Before deletion, show user notification: "Removed 5 local videos that are no longer accessible"
  - [ ] Subtask: Provide option to disable automatic cleanup in Settings

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 5.2.7:** Test bookmark creation and resolution
  - [ ] Subtask: Unit test: Create bookmark for test video file, verify `bookmarkData` not nil
  - [ ] Subtask: Unit test: Resolve bookmark, verify URL matches original
  - [ ] Subtask: Unit test: Test stale bookmark handling (simulate file moved)
  - [ ] Subtask: Unit test: Test bookmark resolution failure (simulate file deleted)
  - [ ] Subtask: Integration test: Import file, restart app, verify file still accessible
  - [ ] Subtask: Integration test: Move file after import, verify error shown, test relocate action
  - [ ] Subtask: Manual test: Verify cleanup removes videos unavailable for 30+ days

**Dev Notes:**
- **Files:** `MyToob/Services/BookmarkManager.swift` (bookmark resolution), `MyToob/Models/VideoItem.swift` (bookmark data storage)
- **Security-Scoped Resources:** MUST call `startAccessingSecurityScopedResource()` before accessing file, `stopAccessingSecurityScopedResource()` when done
- **Bookmark Staleness:** Bookmarks can become stale if file moved; regenerate bookmark when `isStale == true`
- **Cleanup Strategy:** Balance between not removing too aggressively (temporary unavailability) and keeping database clean

**Testing Requirements:**
- Unit tests for bookmark creation, resolution, and staleness handling
- Integration tests with app restart to verify persistent access
- Manual tests with file system changes (move, delete, rename files)
- Performance tests with large number of local videos (1000+ bookmarks)

---

## Story 5.3: AVPlayerView Integration for Local Playback 🚧

**Status:** Draft
**Dependencies:** Story 5.2 (Security-Scoped Bookmarks)
**Epic:** Epic 5 - Local File Playback & Management

**Acceptance Criteria:**
1. `LocalPlayerView` SwiftUI view created wrapping `AVPlayerView` (via `NSViewRepresentable`)
2. `AVPlayer` initialized with `AVAsset` loaded from `VideoItem.localURL`
3. AVPlayerView displays with native transport controls (play/pause, scrubbing, volume, full-screen)
4. Playback starts when `LocalPlayerView` appears with valid local video
5. Scrubbing timeline shows thumbnails (if supported by video codec)
6. Full-screen mode available via native control
7. Playback error handled gracefully (e.g., unsupported codec): show error message, log details

#### Detailed Task Breakdown

**Phase 1: LocalPlayerView NSViewRepresentable Wrapper (AC: 1)**
- [ ] **Task 5.3.1:** Create LocalPlayerView wrapping AVPlayerView
  - [ ] Subtask: Create `MyToob/Player/LocalPlayerView.swift`
  - [ ] Subtask: Define `struct LocalPlayerView: NSViewRepresentable`
  - [ ] Subtask: Add `@Binding var videoItem: VideoItem` to pass video to play
  - [ ] Subtask: Implement `makeNSView(context:) -> AVPlayerView`: `let playerView = AVPlayerView(); return playerView`
  - [ ] Subtask: Implement `updateNSView(_ nsView: AVPlayerView, context:)`: Update player when `videoItem` changes
  - [ ] Subtask: Create `Coordinator` class to manage AVPlayer instance and delegate callbacks

**Phase 2: AVPlayer and AVAsset Initialization (AC: 2)**
- [ ] **Task 5.3.2:** Initialize AVPlayer with local video file
  - [ ] Subtask: In `updateNSView`, resolve bookmark to get security-scoped URL (use `BookmarkManager` from Story 5.2)
  - [ ] Subtask: Create `AVAsset`: `let asset = AVAsset(url: resolvedURL)`
  - [ ] Subtask: Create `AVPlayerItem`: `let playerItem = AVPlayerItem(asset: asset)`
  - [ ] Subtask: Create `AVPlayer`: `let player = AVPlayer(playerItem: playerItem)`
  - [ ] Subtask: Set player on view: `nsView.player = player`
  - [ ] Subtask: Observe player errors: `playerItem.observe(\.status) { ... }` to detect `AVPlayerItem.Status.failed`

**Phase 3: Native Transport Controls (AC: 3)**
- [ ] **Task 5.3.3:** Enable AVPlayerView native controls
  - [ ] Subtask: AVPlayerView shows controls by default (no additional code needed)
  - [ ] Subtask: Verify controls visible: Play/pause button, scrubbing slider, volume control, full-screen button
  - [ ] Subtask: Test controls: Click play, verify video plays; drag scrubber, verify seek works
  - [ ] Subtask: Customize controls if needed: `playerView.controlsStyle = .inline` or `.floating`
  - [ ] Subtask: Add keyboard shortcuts support (Space = play/pause, Left/Right = seek, F = full-screen)

**Phase 4: Autoplay on View Appearance (AC: 4)**
- [ ] **Task 5.3.4:** Start playback when LocalPlayerView appears
  - [ ] Subtask: In `makeNSView` or `updateNSView`, call `player.play()` after setting player item
  - [ ] Subtask: Only autoplay if user preference allows (add `@AppStorage("autoplayLocalVideos") var autoplay: Bool = true`)
  - [ ] Subtask: If autoplay disabled, show paused state (user must click play manually)
  - [ ] Subtask: Test: Load `LocalPlayerView` with video, verify playback starts automatically

**Phase 5: Thumbnail Scrubbing (AC: 5)**
- [ ] **Task 5.3.5:** Enable timeline thumbnail previews during scrubbing
  - [ ] Subtask: AVPlayerView supports timeline thumbnails if video has embedded thumbnail track (e.g., H.264 with trick mode)
  - [ ] Subtask: No custom code needed—feature works automatically if video supports it
  - [ ] Subtask: For videos without embedded thumbnails, generate thumbnails manually:
    - [ ] Use `AVAssetImageGenerator` to extract frames at intervals
    - [ ] Create thumbnail track or cache thumbnails for scrubbing
  - [ ] Subtask: Test with videos that have/don't have thumbnail tracks
  - [ ] Subtask: Document limitation: "Thumbnail scrubbing available for videos with embedded thumbnail tracks"

**Phase 6: Full-Screen Mode (AC: 6)**
- [ ] **Task 5.3.6:** Support full-screen playback
  - [ ] Subtask: Full-screen button shown by default in AVPlayerView controls
  - [ ] Subtask: Clicking full-screen enters native macOS full-screen mode
  - [ ] Subtask: Test: Click full-screen button, verify video expands to full screen
  - [ ] Subtask: Test: Exit full-screen (Esc key or exit button), verify returns to windowed mode
  - [ ] Subtask: Ensure playback continues during full-screen transitions

**Phase 7: Playback Error Handling (AC: 7)**
- [ ] **Task 5.3.7:** Handle playback errors gracefully
  - [ ] Subtask: Observe `AVPlayerItem.status`, check for `.failed` status
  - [ ] Subtask: On error, extract error details: `if let error = playerItem.error { ... }`
  - [ ] Subtask: Map error codes to user-friendly messages:
    - [ ] Unsupported codec → "This video format is not supported"
    - [ ] File corrupt → "This video file appears to be corrupted"
    - [ ] Generic error → "An error occurred during playback"
  - [ ] Subtask: Display error message overlay on player view
  - [ ] Subtask: Log error: `logger.error("Playback failed for \(videoItem.title): \(error)")`
  - [ ] Subtask: Provide "Try Again" button to retry playback

**Phase 8: Testing (AC: All)**
- [ ] **Task 5.3.8:** Test AVPlayerView integration
  - [ ] Subtask: Manual test: Load various video formats (MP4, MOV, MKV), verify playback
  - [ ] Subtask: Manual test: Test transport controls (play/pause, seek, volume, full-screen)
  - [ ] Subtask: Manual test: Test thumbnail scrubbing (if video supports it)
  - [ ] Subtask: UI test: Verify LocalPlayerView renders and plays video
  - [ ] Subtask: Error handling test: Load unsupported video (e.g., corrupted file), verify error message
  - [ ] Subtask: Performance test: Load 4K video, verify smooth playback on target hardware
  - [ ] Subtask: Accessibility test: Verify keyboard shortcuts work (Space, Left/Right, F)

**Dev Notes:**
- **Files:** `MyToob/Player/LocalPlayerView.swift` (AVPlayerView wrapper), `MyToob/ViewModels/LocalPlayerViewModel.swift` (player state management)
- **AVPlayerView:** Native AppKit component—provides transport controls, scrubbing, full-screen for free
- **Security-Scoped Access:** Must call `startAccessingSecurityScopedResource()` before creating AVAsset, `stopAccessingSecurityScopedResource()` after player released
- **Thumbnail Scrubbing:** Works automatically for videos with embedded thumbnail tracks (H.264 with trick mode); otherwise requires manual implementation

**Testing Requirements:**
- Manual playback tests with various video formats and resolutions
- UI tests for player rendering and controls
- Error handling tests with invalid/corrupted/unsupported files
- Performance tests with 4K and high-bitrate videos
- Accessibility tests for keyboard navigation

---

## Story 5.4: Playback State Persistence for Local Files 🚧

**Status:** Draft
**Dependencies:** Story 5.3 (AVPlayerView Integration)
**Epic:** Epic 5 - Local File Playback & Management

**Acceptance Criteria:**
1. AVPlayer time updates tracked (every second during playback)
2. Current playback time saved to `VideoItem.watchProgress` in SwiftData
3. When `LocalPlayerView` loads a video, seek to `VideoItem.watchProgress` before starting playback (if >5 seconds)
4. "Mark as Watched" action sets `watchProgress = duration` (100% complete)
5. "Reset Progress" action sets `watchProgress = 0`
6. Progress indicator shown on video thumbnail in library (e.g., progress bar at bottom of thumbnail)
7. Videos with >90% progress marked as "Watched" (visual indicator)

#### Detailed Task Breakdown

**Phase 1: AVPlayer Time Updates Tracking (AC: 1)**
- [ ] **Task 5.4.1:** Track playback time updates
  - [ ] Subtask: In `LocalPlayerView.Coordinator`, add periodic time observer: `player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in ... }`
  - [ ] Subtask: Extract current time: `let currentTime = time.seconds`
  - [ ] Subtask: Update ViewModel or state: `viewModel.currentTime = currentTime`
  - [ ] Subtask: Clean up observer in `deinit`: `player.removeTimeObserver(observer)`
  - [ ] Subtask: Log time updates (debug): `logger.debug("Playback time: \(currentTime)")`

**Phase 2: Save Playback Progress to SwiftData (AC: 2)**
- [ ] **Task 5.4.2:** Persist watch progress to database
  - [ ] Subtask: In time observer callback, update `VideoItem.watchProgress`
  - [ ] Subtask: Calculate progress: `let progress = currentTime / videoItem.duration`
  - [ ] Subtask: Debounce SwiftData saves (max once every 5 seconds to avoid excessive writes)
  - [ ] Subtask: Update `videoItem.watchProgress = progress`
  - [ ] Subtask: Update `videoItem.lastWatchedAt = Date()`
  - [ ] Subtask: Save model context: `try? modelContext.save()`
  - [ ] Subtask: Log progress save: `logger.debug("Saved watch progress: \(progress) for \(videoItem.title)")`

**Phase 3: Resume Playback from Last Position (AC: 3)**
- [ ] **Task 5.4.3:** Seek to last watched position on load
  - [ ] Subtask: When `LocalPlayerView` loads video, check `videoItem.watchProgress`
  - [ ] Subtask: If `watchProgress > 0` and `watchProgress < 0.9` (not near end), seek to resume point
  - [ ] Subtask: Calculate resume time: `let resumeTime = videoItem.watchProgress * videoItem.duration`
  - [ ] Subtask: Only seek if resume time >5 seconds (avoid seeking for minimal progress)
  - [ ] Subtask: Seek player: `player.seek(to: CMTime(seconds: resumeTime, preferredTimescale: 1))`
  - [ ] Subtask: Optionally show toast: "Resuming from \(formatTime(resumeTime))"
  - [ ] Subtask: Test: Partially watch video, reload, verify resumes from last position

**Phase 4: "Mark as Watched" Action (AC: 4)**
- [ ] **Task 5.4.4:** Add "Mark as Watched" context menu action
  - [ ] Subtask: In video library context menu, add "Mark as Watched" action
  - [ ] Subtask: Action sets `videoItem.watchProgress = 1.0` (100%)
  - [ ] Subtask: Update `videoItem.lastWatchedAt = Date()`
  - [ ] Subtask: Save model context
  - [ ] Subtask: Update UI to show "Watched" indicator (checkmark or badge)
  - [ ] Subtask: Test: Mark video as watched, verify progress set to 100%

**Phase 5: "Reset Progress" Action (AC: 5)**
- [ ] **Task 5.4.5:** Add "Reset Progress" context menu action
  - [ ] Subtask: In video library context menu, add "Reset Progress" action
  - [ ] Subtask: Action sets `videoItem.watchProgress = 0.0`
  - [ ] Subtask: Clear `videoItem.lastWatchedAt` (or set to nil)
  - [ ] Subtask: Save model context
  - [ ] Subtask: Update UI to remove progress indicator
  - [ ] Subtask: Test: Reset progress, verify video appears unwatched

**Phase 6: Progress Indicator on Thumbnails (AC: 6)**
- [ ] **Task 5.4.6:** Display progress bar on video thumbnails
  - [ ] Subtask: In video thumbnail view, add progress bar overlay at bottom
  - [ ] Subtask: Progress bar width: `GeometryReader { geo in Rectangle().frame(width: geo.size.width * videoItem.watchProgress) }`
  - [ ] Subtask: Style progress bar: Blue color, 3-4pt height, positioned at bottom of thumbnail
  - [ ] Subtask: Only show progress bar if `watchProgress > 0` and `watchProgress < 1.0`
  - [ ] Subtask: Test: Partially watch video, verify progress bar appears on thumbnail

**Phase 7: "Watched" Visual Indicator (AC: 7)**
- [ ] **Task 5.4.7:** Mark videos with >90% progress as watched
  - [ ] Subtask: Check if `videoItem.watchProgress >= 0.9`
  - [ ] Subtask: If watched, show checkmark badge: `Image(systemName: "checkmark.circle.fill").foregroundColor(.green)` in top-right corner of thumbnail
  - [ ] Subtask: Optionally grey out thumbnail or reduce opacity to indicate completion
  - [ ] Subtask: In video list, show "Watched" text or icon next to title
  - [ ] Subtask: Test: Watch video to >90%, verify "Watched" indicator appears

**Phase 8: Testing (AC: All)**
- [ ] **Task 5.4.8:** Test playback state persistence
  - [ ] Subtask: Integration test: Watch video for 30 seconds, close app, reopen, verify resumes at 30 seconds
  - [ ] Subtask: Integration test: Mark video as watched, verify progress = 100%
  - [ ] Subtask: Integration test: Reset progress, verify progress = 0%
  - [ ] Subtask: UI test: Verify progress bar displayed on thumbnail with correct width
  - [ ] Subtask: UI test: Verify "Watched" indicator appears for videos with >90% progress
  - [ ] Subtask: Manual test: Watch multiple videos, verify each has independent progress tracking
  - [ ] Subtask: Performance test: Load library with 1000+ videos, verify progress indicators render quickly

**Dev Notes:**
- **Files:** `MyToob/Player/LocalPlayerView.swift` (time observer), `MyToob/Views/VideoThumbnailView.swift` (progress indicator), `MyToob/Models/VideoItem.swift` (watchProgress property)
- **Debouncing:** Avoid saving to SwiftData every second—batch updates every 5 seconds
- **Resume Threshold:** Only seek if progress >5 seconds to avoid annoying seeks for minimal progress
- **"Watched" Definition:** >90% progress is standard (allows for minor skips or early stops)

**Testing Requirements:**
- Integration tests for progress persistence across app restarts
- UI tests for progress bar rendering and "Watched" indicator
- Manual tests with various watch patterns (partial, full, multiple sessions)
- Performance tests with large video libraries

---

## Story 5.5: Drag-and-Drop File Import 🚧

**Status:** Draft
**Dependencies:** Story 5.1 (Local File Import)—Done ✅
**Epic:** Epic 5 - Local File Playback & Management

**Acceptance Criteria:**
1. Main content area accepts drop of file URLs from Finder
2. Dropped files filtered to supported video types (same as file picker)
3. Drag-over visual feedback shown (highlight drop zone, "Drop videos here" message)
4. On drop, files processed same as file picker selection (create `VideoItem`, security-scoped bookmarks)
5. Multiple files dropped at once handled correctly
6. Non-video files dropped show toast notification: "Only video files are supported"
7. UI test verifies drag-and-drop flow with test video files

#### Detailed Task Breakdown

**Phase 1: Drop Zone Setup (AC: 1)**
- [ ] **Task 5.5.1:** Configure view to accept file drops
  - [ ] Subtask: In main content view (e.g., library view), add `.onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in ... }`
  - [ ] Subtask: Define `@State var isTargeted: Bool = false` to track drag-over state
  - [ ] Subtask: Handle drop: Extract file URLs from `providers`
  - [ ] Subtask: Example: `for provider in providers { _ = provider.loadObject(ofClass: URL.self) { url, _ in if let url = url { handleDroppedFile(url) } } }`

**Phase 2: File Type Filtering (AC: 2, 6)**
- [ ] **Task 5.5.2:** Filter dropped files to supported video types
  - [ ] Subtask: Define supported video extensions: `let supportedExtensions = ["mp4", "mov", "mkv", "avi", "m4v"]`
  - [ ] Subtask: In `handleDroppedFile(url:)`, check extension: `if supportedExtensions.contains(url.pathExtension.lowercased()) { ... }`
  - [ ] Subtask: If unsupported, increment counter for rejected files
  - [ ] Subtask: After processing all files, if any rejected, show toast: "Only video files are supported. \(rejectedCount) file(s) were ignored."
  - [ ] Subtask: Test: Drop mix of video and non-video files, verify only videos imported

**Phase 3: Drag-Over Visual Feedback (AC: 3)**
- [ ] **Task 5.5.3:** Show drag-over visual feedback
  - [ ] Subtask: When `isTargeted == true` (drag is over view), update UI
  - [ ] Subtask: Add highlight border: `.border(Color.accentColor, width: isTargeted ? 2 : 0)`
  - [ ] Subtask: Show overlay message: `if isTargeted { Text("Drop videos here").font(.title).foregroundColor(.secondary) }`
  - [ ] Subtask: Dim background when dragging: `.opacity(isTargeted ? 0.8 : 1.0)`
  - [ ] Subtask: Test: Drag file over view, verify highlight and message appear

**Phase 4: Process Dropped Files (AC: 4)**
- [ ] **Task 5.5.4:** Import dropped files same as file picker
  - [ ] Subtask: Reuse file import logic from Story 5.1 (create `VideoItem`, security-scoped bookmarks)
  - [ ] Subtask: Extract reusable `importVideoFiles(_ urls: [URL])` function
  - [ ] Subtask: Call `importVideoFiles(droppedURLs)` in drop handler
  - [ ] Subtask: Show import progress if many files dropped (reuse progress UI from Story 5.1)
  - [ ] Subtask: Test: Drop files, verify imported to SwiftData and appear in library

**Phase 5: Multiple File Handling (AC: 5)**
- [ ] **Task 5.5.5:** Handle multiple files dropped simultaneously
  - [ ] Subtask: Drop handler receives array of providers (one per file)
  - [ ] Subtask: Process each provider asynchronously: `Task { for provider in providers { ... } }`
  - [ ] Subtask: Collect all valid URLs into array before calling `importVideoFiles`
  - [ ] Subtask: Show toast: "Importing \(urlsCount) video files..."
  - [ ] Subtask: Test: Drop 10+ files at once, verify all imported correctly

**Phase 6: Accessibility and Empty State (Additional)**
- [ ] **Task 5.5.6:** Improve drop zone discoverability
  - [ ] Subtask: If library empty, show permanent "Drag and drop videos here or click Import" message
  - [ ] Subtask: Add large drop zone icon (e.g., folder with down arrow) in empty state
  - [ ] Subtask: Provide accessibility label: `.accessibilityLabel("Drop zone for video files")`
  - [ ] Subtask: Test with VoiceOver: Verify drop zone announced

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 5.5.7:** Test drag-and-drop functionality
  - [ ] Subtask: UI test: Simulate drag-and-drop (if possible with XCTest)
  - [ ] Subtask: Manual test: Drag single video file from Finder, verify imported
  - [ ] Subtask: Manual test: Drag multiple video files, verify all imported
  - [ ] Subtask: Manual test: Drag non-video file, verify rejected and toast shown
  - [ ] Subtask: Manual test: Drag mix of video and non-video files, verify only videos imported
  - [ ] Subtask: UI test: Verify drag-over highlight and message displayed
  - [ ] Subtask: Integration test: Verify dropped files have security-scoped bookmarks created

**Dev Notes:**
- **Files:** `MyToob/Views/LibraryView.swift` or main content view (drop zone), `MyToob/Services/FileImportService.swift` (shared import logic)
- **SwiftUI `.onDrop`:** Provides `isTargeted` binding for drag-over state
- **File URL Loading:** Use `NSItemProvider.loadObject(ofClass: URL.self)` to extract file URLs from drop providers
- **Reusability:** Extract file import logic into shared service to avoid duplication between file picker and drag-and-drop

**Testing Requirements:**
- Manual drag-and-drop tests with various file types and counts
- UI tests for drag-over visual feedback
- Integration tests to verify imported files have bookmarks and appear in library
- Accessibility tests for VoiceOver support

---

## Story 5.6: Local File Metadata Extraction 🚧

**Status:** Draft
**Dependencies:** Story 5.1 (Local File Import)—Done ✅
**Epic:** Epic 5 - Local File Playback & Management

**Acceptance Criteria:**
1. On import, use `AVAsset` to extract: `duration`, `resolution` (video track dimensions), `codec` (video/audio codec names), `fileSize`
2. Metadata stored in `VideoItem` model (add new properties if needed)
3. Metadata extraction performed asynchronously (doesn't block UI for large files)
4. If metadata extraction fails, store defaults (duration = 0, resolution = unknown)
5. Metadata displayed in video detail view: "Duration: 1h 24m | Resolution: 1920x1080 | Codec: H.264"
6. Filter pills support filtering by duration range, resolution (SD/HD/4K), and file size
7. Unit tests verify metadata extraction with various video formats (MP4, MOV, MKV)

#### Detailed Task Breakdown

**Phase 1: AVAsset Metadata Extraction (AC: 1)**
- [ ] **Task 5.6.1:** Extract metadata using AVAsset
  - [ ] Subtask: Create `MetadataExtractor` service with `extractMetadata(from url: URL) async throws -> VideoMetadata` method
  - [ ] Subtask: Load AVAsset asynchronously: `let asset = AVAsset(url: url)`
  - [ ] Subtask: Extract duration: `let duration = try await asset.load(.duration); let durationSeconds = CMTimeGetSeconds(duration)`
  - [ ] Subtask: Load video tracks: `let videoTracks = try await asset.loadTracks(withMediaType: .video)`
  - [ ] Subtask: Extract resolution from first video track: `let naturalSize = try await videoTracks.first?.load(.naturalSize)` → `resolution = "\(Int(naturalSize.width))x\(Int(naturalSize.height))"`
  - [ ] Subtask: Extract codec: `let formatDescriptions = try await videoTracks.first?.load(.formatDescriptions); let codec = formatDescriptions?.first?.mediaSubType.description`
  - [ ] Subtask: Get file size: `let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path); let fileSize = fileAttributes[.size] as? Int64`

**Phase 2: VideoItem Model Updates (AC: 2)**
- [ ] **Task 5.6.2:** Add metadata properties to VideoItem
  - [ ] Subtask: Add to `VideoItem` model: `@Attribute var resolution: String?` (e.g., "1920x1080")
  - [ ] Subtask: Add `@Attribute var codecName: String?` (e.g., "H.264", "HEVC")
  - [ ] Subtask: Add `@Attribute var fileSize: Int64?` (bytes)
  - [ ] Subtask: `duration` already exists from Story 5.1
  - [ ] Subtask: Create SwiftData migration if schema changed
  - [ ] Subtask: Test: Verify new properties stored correctly in database

**Phase 3: Asynchronous Metadata Extraction (AC: 3)**
- [ ] **Task 5.6.3:** Perform metadata extraction asynchronously
  - [ ] Subtask: In file import flow, call metadata extraction in background task: `Task.detached { ... }`
  - [ ] Subtask: Extract metadata for each imported file without blocking main thread
  - [ ] Subtask: Update `VideoItem` on main thread when extraction completes: `await MainActor.run { videoItem.duration = metadata.duration; ... }`
  - [ ] Subtask: Show loading indicator on thumbnail while metadata extracting
  - [ ] Subtask: Test: Import large video file, verify UI remains responsive

**Phase 4: Fallback for Extraction Failures (AC: 4)**
- [ ] **Task 5.6.4:** Handle metadata extraction failures
  - [ ] Subtask: Wrap extraction in `do-catch` block
  - [ ] Subtask: On error, log warning: `logger.warning("Metadata extraction failed for \(url): \(error)")`
  - [ ] Subtask: Set default values: `duration = 0`, `resolution = "Unknown"`, `codecName = "Unknown"`, `fileSize = 0`
  - [ ] Subtask: Still import video even if metadata extraction fails
  - [ ] Subtask: Test: Use corrupted video file, verify defaults used and video still imported

**Phase 5: Metadata Display in UI (AC: 5)**
- [ ] **Task 5.6.5:** Display metadata in video detail view
  - [ ] Subtask: Create `VideoDetailView` (if not exists) showing full metadata
  - [ ] Subtask: Format duration: `formatDuration(videoItem.duration)` → "1h 24m 35s"
  - [ ] Subtask: Display resolution: `Text("Resolution: \(videoItem.resolution ?? "Unknown")")`
  - [ ] Subtask: Display codec: `Text("Codec: \(videoItem.codecName ?? "Unknown")")`
  - [ ] Subtask: Display file size: `Text("File Size: \(formatFileSize(videoItem.fileSize))")` → "1.2 GB"
  - [ ] Subtask: Layout: Use Grid or VStack with labels aligned
  - [ ] Subtask: Test: Open video detail, verify all metadata displayed correctly

**Phase 6: Metadata-Based Filtering (AC: 6)**
- [ ] **Task 5.6.6:** Add filter pills for metadata properties
  - [ ] Subtask: Add duration range filter: "Short (<5 min)", "Medium (5-30 min)", "Long (>30 min)"
  - [ ] Subtask: Add resolution filter: "SD (<720p)", "HD (720p-1080p)", "4K (>1080p)"
  - [ ] Subtask: Add file size filter: "Small (<100 MB)", "Medium (100MB-1GB)", "Large (>1GB)"
  - [ ] Subtask: Implement filter logic: Query SwiftData with predicates based on selected filters
  - [ ] Subtask: Example: `#Predicate<VideoItem> { $0.resolution?.contains("3840") == true }` for 4K filter
  - [ ] Subtask: Test: Apply filters, verify only matching videos shown

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 5.6.7:** Test metadata extraction
  - [ ] Subtask: Unit test: Extract metadata from MP4 file, verify duration/resolution/codec correct
  - [ ] Subtask: Unit test: Extract metadata from MOV file, verify all properties
  - [ ] Subtask: Unit test: Extract metadata from MKV file (if supported by AVFoundation)
  - [ ] Subtask: Unit test: Test extraction failure, verify defaults used
  - [ ] Subtask: Integration test: Import video, verify metadata displayed in detail view
  - [ ] Subtask: UI test: Apply resolution filter, verify only HD videos shown
  - [ ] Subtask: Performance test: Extract metadata from 100+ files, verify acceptable performance

**Dev Notes:**
- **Files:** `MyToob/Services/MetadataExtractor.swift` (extraction logic), `MyToob/Models/VideoItem.swift` (metadata properties), `MyToob/Views/VideoDetailView.swift` (metadata display)
- **AVAsset Loading:** Use async/await `asset.load()` methods for concurrency-safe metadata extraction
- **Codec Names:** `CMFormatDescription.MediaSubType` provides codec info, map to human-readable names (e.g., `kCMVideoCodecType_H264` → "H.264")
- **File Size Formatting:** Use `ByteCountFormatter` for human-readable file sizes

**Testing Requirements:**
- Unit tests for metadata extraction with various video formats
- Unit tests for error handling and default values
- Integration tests for metadata display in UI
- UI tests for filter pills functionality
- Performance tests with large video libraries

---

## Story 6.1: SwiftData Model Container & Configuration 🚧

**Status:** Draft
**Dependencies:** Story 1.4 (SwiftData Core Models)—Done ✅
**Epic:** Epic 6 - Data Persistence & CloudKit Sync

**Acceptance Criteria:**
1. `ModelContainer` initialized in app entry point with all models: `VideoItem`, `ClusterLabel`, `Note`, `ChannelBlacklist`
2. Model configuration specifies versioned schema: `ModelConfiguration(schema: .version1, isStoredInMemoryOnly: false)`
3. Default storage location: `~/Library/Application Support/MyToob/default.store`
4. Container injected into SwiftUI environment: `.modelContainer(for: [VideoItem.self, ...])`
5. Cold start creates initial schema without migrations
6. Unit tests verify container initialization succeeds and models are queryable
7. No data loss on app restart (persistent storage confirmed)

#### Detailed Task Breakdown

**Phase 1: Model Container Initialization (AC: 1, 2)**
- [ ] **Task 6.1.1:** Create and configure ModelContainer
  - [ ] Subtask: In `MyToobApp.swift`, define ModelContainer: `let container = try ModelContainer(for: VideoItem.self, ClusterLabel.self, Note.self, ChannelBlacklist.self)`
  - [ ] Subtask: Wrap in `do-catch` to handle initialization errors
  - [ ] Subtask: Log initialization: `logger.info("ModelContainer initialized successfully")`
  - [ ] Subtask: On error, show alert to user: "Failed to initialize database. App may not function correctly."
  - [ ] Subtask: Define versioned schema (defer to Story 6.2): `ModelConfiguration(schema: SchemaV1.self)`

**Phase 2: Storage Location Configuration (AC: 3)**
- [ ] **Task 6.1.2:** Configure database storage location
  - [ ] Subtask: Get Application Support directory: `let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!`
  - [ ] Subtask: Create MyToob subdirectory: `let storeURL = appSupport.appendingPathComponent("MyToob")`
  - [ ] Subtask: Create directory if not exists: `try? FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true)`
  - [ ] Subtask: Specify store URL in configuration: `ModelConfiguration(url: storeURL.appendingPathComponent("default.store"))`
  - [ ] Subtask: Verify storage location: `logger.debug("Database location: \(storeURL.path)")`

**Phase 3: Environment Injection (AC: 4)**
- [ ] **Task 6.1.3:** Inject ModelContainer into SwiftUI environment
  - [ ] Subtask: In `MyToobApp.swift`, add `.modelContainer(container)` modifier to `WindowGroup`
  - [ ] Subtask: Example: `WindowGroup { ContentView() }.modelContainer(container)`
  - [ ] Subtask: Verify all views can access `@Environment(\.modelContext)` for database queries
  - [ ] Subtask: Test: In any view, add `@Environment(\.modelContext) var modelContext` and verify no crash

**Phase 4: Cold Start Schema Creation (AC: 5)**
- [ ] **Task 6.1.4:** Ensure schema created on first launch
  - [ ] Subtask: On first launch (no existing store file), SwiftData creates schema automatically
  - [ ] Subtask: Verify all model tables created: VideoItem, ClusterLabel, Note, ChannelBlacklist
  - [ ] Subtask: Insert test record to verify schema: `modelContext.insert(VideoItem(...))`
  - [ ] Subtask: Save context: `try modelContext.save()`
  - [ ] Subtask: Query to confirm persistence: `let items = try modelContext.fetch(FetchDescriptor<VideoItem>())`

**Phase 5: Container Initialization Tests (AC: 6)**
- [ ] **Task 6.1.5:** Unit test ModelContainer initialization
  - [ ] Subtask: Create test case `ModelContainerTests.swift`
  - [ ] Subtask: Test: Initialize container with in-memory storage: `ModelConfiguration(isStoredInMemoryOnly: true)`
  - [ ] Subtask: Test: Verify container accessible via `@MainActor` context
  - [ ] Subtask: Test: Insert VideoItem, save, query—verify round-trip works
  - [ ] Subtask: Test: Verify all 4 models (VideoItem, ClusterLabel, Note, ChannelBlacklist) queryable
  - [ ] Subtask: Test: Verify container initialization with missing models fails gracefully

**Phase 6: Persistence Verification (AC: 7)**
- [ ] **Task 6.1.6:** Verify no data loss on app restart
  - [ ] Subtask: Manual test: Launch app, insert VideoItem, save
  - [ ] Subtask: Manual test: Quit app completely (not just close window)
  - [ ] Subtask: Manual test: Relaunch app, query VideoItem—verify still present
  - [ ] Subtask: Automated test: Write persistence test using XCTest app lifecycle simulation
  - [ ] Subtask: Test: Create container, insert data, save, recreate container, query—verify data persists

**Phase 7: Error Handling (Additional)**
- [ ] **Task 6.1.7:** Handle container initialization failures
  - [ ] Subtask: If container initialization fails, show user error alert
  - [ ] Subtask: Provide "Reset Database" button in error alert (deletes store file and recreates)
  - [ ] Subtask: Log detailed error: `logger.error("ModelContainer initialization failed: \(error)")`
  - [ ] Subtask: Consider fallback to in-memory container if persistent storage fails
  - [ ] Subtask: Test: Simulate initialization failure (corrupt store file), verify error handling

**Dev Notes:**
- **Files:** `MyToob/MyToobApp.swift` (container initialization), `MyToob/Models/` (all SwiftData models)
- **Schema Versioning:** Initial version is `SchemaV1`, future versions handled in Story 6.2
- **Storage Location:** macOS sandboxed apps store data in `~/Library/Containers/[bundle-id]/Data/Library/Application Support/`
- **Testing:** Use `isStoredInMemoryOnly: true` for unit tests to avoid file system dependencies

**Testing Requirements:**
- Unit tests for container initialization with in-memory storage
- Unit tests for all models insertable/queryable
- Integration tests for persistent storage (data survives app restart)
- Error handling tests (initialization failures, corrupt database)

---

## Story 6.2: Versioned Schema Migrations 🚧

**Status:** Draft
**Dependencies:** Story 6.1 (Model Container Configuration)
**Epic:** Epic 6 - Data Persistence & CloudKit Sync

**Acceptance Criteria:**
1. Schema versioning implemented: `SchemaV1`, `SchemaV2`, etc.
2. Migration plan defined: `SchemaMigrationPlan` with `stages` mapping old→new versions
3. Example migration created for testing: add new property to `VideoItem` (e.g., `lastAccessedAt: Date?`)
4. Lightweight migrations handled automatically (adding optional properties)
5. Custom migrations implemented for complex changes (e.g., splitting properties, data transformations)
6. Migration rollback strategy: backup database before migration, restore on failure
7. Migration tests verify data integrity across version upgrades (seed v1 data, migrate to v2, verify no loss)

#### Detailed Task Breakdown

**Phase 1: Schema Versioning Setup (AC: 1)**
- [ ] **Task 6.2.1:** Define versioned schemas
  - [ ] Subtask: Create `MyToob/Models/SchemaV1.swift`
  - [ ] Subtask: Define `enum SchemaV1: VersionedSchema { static var versionIdentifier = Schema.Version(1, 0, 0); static var models: [any PersistentModel.Type] { [VideoItem.self, ClusterLabel.self, Note.self, ChannelBlacklist.self] } }`
  - [ ] Subtask: When adding V2 in future, create `SchemaV2.swift` with version `(2, 0, 0)` and updated models
  - [ ] Subtask: Document schema versions in comments: "V1: Initial schema; V2: Added lastAccessedAt to VideoItem"

**Phase 2: Migration Plan Definition (AC: 2)**
- [ ] **Task 6.2.2:** Create SchemaMigrationPlan
  - [ ] Subtask: Create `MyToob/Models/SchemaMigrationPlan.swift`
  - [ ] Subtask: Define `enum MyToobMigrationPlan: SchemaMigrationPlan { static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }; static var stages: [MigrationStage] { [migrateV1toV2] } }`
  - [ ] Subtask: Define migration stages: `static let migrateV1toV2 = MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)`
  - [ ] Subtask: Update ModelContainer initialization to use migration plan: `ModelConfiguration(schema: SchemaV2.self, migrationPlan: MyToobMigrationPlan.self)`

**Phase 3: Example Lightweight Migration (AC: 3, 4)**
- [ ] **Task 6.2.3:** Implement test migration (add lastAccessedAt property)
  - [ ] Subtask: In `SchemaV2`, update `VideoItem` to add `@Attribute var lastAccessedAt: Date?`
  - [ ] Subtask: Mark property optional (`Date?`) to enable lightweight migration (no data transformation needed)
  - [ ] Subtask: SwiftData handles lightweight migration automatically (adds column, sets existing rows to `nil`)
  - [ ] Subtask: Test migration: Start with V1 database, add data, upgrade to V2, verify `lastAccessedAt` column exists and old data intact

**Phase 4: Custom Migration Implementation (AC: 5)**
- [ ] **Task 6.2.4:** Implement custom migration for complex changes
  - [ ] Subtask: Example custom migration: Split `VideoItem.localURL` into `localPath` and `bookmarkData` (hypothetical)
  - [ ] Subtask: Define custom migration stage: `static let migrateV2toV3 = MigrationStage.custom(fromVersion: SchemaV2.self, toVersion: SchemaV3.self) { context in ... }`
  - [ ] Subtask: In custom migration, iterate over all VideoItems: `let items = try context.fetch(FetchDescriptor<VideoItem>())`
  - [ ] Subtask: Transform data: For each item, extract path from URL, create bookmark, update properties
  - [ ] Subtask: Save context after transformation: `try context.save()`
  - [ ] Subtask: Log custom migration: `logger.info("Custom migration V2→V3 completed for \(items.count) items")`

**Phase 5: Migration Rollback Strategy (AC: 6)**
- [ ] **Task 6.2.5:** Implement database backup and rollback
  - [ ] Subtask: Before migration, copy database file to backup location: `let backupURL = storeURL.appendingPathExtension("backup-\(Date())")`
  - [ ] Subtask: `try FileManager.default.copyItem(at: storeURL, to: backupURL)`
  - [ ] Subtask: Wrap migration in `do-catch` block
  - [ ] Subtask: On migration failure, restore backup: `try? FileManager.default.removeItem(at: storeURL); try FileManager.default.copyItem(at: backupURL, to: storeURL)`
  - [ ] Subtask: Show user alert: "Migration failed. Database restored from backup. Please restart the app."
  - [ ] Subtask: Log rollback: `logger.error("Migration failed, rolled back to backup: \(error)")`

**Phase 6: Backup Cleanup (Additional)**
- [ ] **Task 6.2.6:** Clean up old migration backups
  - [ ] Subtask: After successful migration, keep backup for 7 days then delete
  - [ ] Subtask: Enumerate backup files: `let backups = try FileManager.default.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: [.creationDateKey])`
  - [ ] Subtask: Delete backups older than 7 days: `if creationDate < Date().addingTimeInterval(-7*24*3600) { try FileManager.default.removeItem(at: backupURL) }`
  - [ ] Subtask: Run cleanup on app launch (background task)

**Phase 7: Migration Testing (AC: 7, All)**
- [ ] **Task 6.2.7:** Test schema migrations
  - [ ] Subtask: Unit test: Create V1 database, insert VideoItems, migrate to V2, verify data intact
  - [ ] Subtask: Unit test: Verify `lastAccessedAt` property added and set to `nil` for existing records
  - [ ] Subtask: Unit test: Custom migration test—seed data in V2, migrate to V3, verify transformation correct
  - [ ] Subtask: Integration test: Simulate app upgrade (V1 → V2), verify all data migrates successfully
  - [ ] Subtask: Error test: Simulate migration failure (corrupt database), verify rollback restores backup
  - [ ] Subtask: Performance test: Migrate large database (10,000 VideoItems), verify reasonable time (<10 seconds)
  - [ ] Subtask: Manual test: Install V1 app, add data, upgrade to V2, verify data visible and correct

**Dev Notes:**
- **Files:** `MyToob/Models/SchemaV1.swift`, `MyToob/Models/SchemaV2.swift`, `MyToob/Models/SchemaMigrationPlan.swift`
- **Lightweight Migrations:** Adding optional properties, renaming properties (with `originalName` attribute)
- **Custom Migrations:** Required for data transformations, splitting/merging properties, complex logic
- **Backup Strategy:** Critical for production—always backup before migration, rollback on failure

**Testing Requirements:**
- Unit tests for lightweight migrations (add property, rename property)
- Unit tests for custom migrations (data transformation)
- Integration tests simulating app upgrades
- Error handling tests (migration failures, rollback)
- Performance tests with large datasets

---

## Story 6.3: CloudKit Container & Private Database Setup 🚧

**Status:** Draft
**Dependencies:** Story 6.1 (Model Container Configuration)
**Epic:** Epic 6 - Data Persistence & CloudKit Sync

**Acceptance Criteria:**
1. CloudKit container identifier registered in Apple Developer portal: `iCloud.com.yourdomain.mytoob`
2. CloudKit capability enabled in Xcode: `iCloud > CloudKit`, container selected
3. Private database used (not public—user data only)
4. Record types created in CloudKit Dashboard matching SwiftData models: `VideoItem`, `ClusterLabel`, `Note`, `ChannelBlacklist`
5. SwiftData models annotated with `@CloudKitSync` (if using SwiftData+CloudKit integration, or custom sync implementation)
6. CloudKit sync enabled by default (can be toggled off in Settings)
7. Unit tests verify CloudKit container accessible and records can be created/fetched

#### Detailed Task Breakdown

**Phase 1: CloudKit Container Registration (AC: 1)**
- [ ] **Task 6.3.1:** Register CloudKit container in Developer Portal
  - [ ] Subtask: Log into Apple Developer portal: developer.apple.com
  - [ ] Subtask: Navigate to Certificates, Identifiers & Profiles > Identifiers
  - [ ] Subtask: Create new CloudKit container identifier: `iCloud.com.yourdomain.mytoob`
  - [ ] Subtask: Associate container with app bundle identifier
  - [ ] Subtask: Document container ID in project documentation

**Phase 2: Xcode CloudKit Capability (AC: 2)**
- [ ] **Task 6.3.2:** Enable CloudKit capability in Xcode
  - [ ] Subtask: Open MyToob.xcodeproj, select app target
  - [ ] Subtask: Navigate to Signing & Capabilities tab
  - [ ] Subtask: Click "+ Capability", add "iCloud"
  - [ ] Subtask: Enable "CloudKit" checkbox
  - [ ] Subtask: Select CloudKit container: `iCloud.com.yourdomain.mytoob`
  - [ ] Subtask: Verify entitlements file updated: `MyToob.entitlements` contains CloudKit container ID

**Phase 3: Private Database Configuration (AC: 3)**
- [ ] **Task 6.3.3:** Configure private database usage
  - [ ] Subtask: In code, access private database: `let container = CKContainer(identifier: "iCloud.com.yourdomain.mytoob"); let database = container.privateCloudDatabase`
  - [ ] Subtask: Document: "All user data stored in private database (user-scoped, iCloud account required)"
  - [ ] Subtask: Verify public database NOT used (no app-wide shared data)
  - [ ] Subtask: Test: Query private database, verify requires iCloud account login

**Phase 4: CloudKit Record Types (AC: 4)**
- [ ] **Task 6.3.4:** Create record types in CloudKit Dashboard
  - [ ] Subtask: Open CloudKit Dashboard: icloud.developer.apple.com/dashboard
  - [ ] Subtask: Select container: `iCloud.com.yourdomain.mytoob`
  - [ ] Subtask: Navigate to Schema > Record Types
  - [ ] Subtask: Create `VideoItem` record type with fields: `videoID: String`, `title: String`, `duration: Double`, `watchProgress: Double`, `bookmarkData: Bytes`, etc.
  - [ ] Subtask: Create `ClusterLabel` record type: `id: String`, `name: String`, `videoIDs: List<String>`
  - [ ] Subtask: Create `Note` record type: `id: String`, `videoID: String`, `content: String`, `timestamp: Double`, `createdAt: Date`
  - [ ] Subtask: Create `ChannelBlacklist` record type: `channelID: String`, `channelName: String`, `addedAt: Date`
  - [ ] Subtask: Deploy schema to production environment

**Phase 5: SwiftData CloudKit Integration (AC: 5)**
- [ ] **Task 6.3.5:** Enable CloudKit sync for SwiftData models
  - [ ] Subtask: If using built-in SwiftData+CloudKit: Add `@CloudKitSync` macro to models (check if available in current SwiftData version)
  - [ ] Subtask: If using custom sync: Create `CloudKitSyncManager` service
  - [ ] Subtask: Implement manual sync: Observe SwiftData changes, push to CloudKit
  - [ ] Subtask: Implement pull: Fetch CloudKit records, update SwiftData models
  - [ ] Subtask: Handle CKRecord conversion: Map `VideoItem` ↔ `CKRecord`

**Phase 6: Default Sync Enablement (AC: 6)**
- [ ] **Task 6.3.6:** Enable CloudKit sync by default
  - [ ] Subtask: Add `@AppStorage("cloudKitSyncEnabled") var syncEnabled: Bool = true`
  - [ ] Subtask: On first launch, if iCloud account detected, enable sync automatically
  - [ ] Subtask: If no iCloud account, show prompt: "Sign in to iCloud to enable sync across devices"
  - [ ] Subtask: Add toggle in Settings > iCloud Sync to disable
  - [ ] Subtask: When sync disabled, stop push/pull operations (local-only mode)

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 6.3.7:** Test CloudKit container and sync
  - [ ] Subtask: Unit test: Verify CloudKit container accessible: `CKContainer(identifier: "...").accountStatus() == .available`
  - [ ] Subtask: Unit test: Create VideoItem CKRecord, save to CloudKit, fetch, verify roundtrip
  - [ ] Subtask: Integration test: Insert VideoItem in SwiftData, verify pushed to CloudKit
  - [ ] Subtask: Integration test: Create record in CloudKit Dashboard, verify pulled to SwiftData
  - [ ] Subtask: Manual test: Enable sync on Device A, add VideoItem, verify syncs to Device B
  - [ ] Subtask: Manual test: Disable sync, add VideoItem, verify NOT synced (local-only)
  - [ ] Subtask: Error test: Test with no iCloud account, verify graceful fallback (local-only mode)

**Dev Notes:**
- **Files:** `MyToob/Services/CloudKitSyncManager.swift` (sync logic), `MyToob/Models/VideoItem.swift` (CloudKit mapping)
- **Private Database:** User must be signed into iCloud; all data scoped to user's account
- **Schema Deployment:** After creating record types in Dashboard, deploy to Production (not just Development)
- **Sync Implementation:** Consider using NSPersistentCloudKitContainer approach if SwiftData+CloudKit integration not mature

**Testing Requirements:**
- Unit tests for CloudKit container access and record CRUD
- Integration tests for SwiftData ↔ CloudKit sync
- Manual multi-device sync tests
- iCloud account error handling tests

---

## Story 6.4: CloudKit Sync Conflict Resolution 🚧

**Status:** Draft
**Dependencies:** Story 6.3 (CloudKit Setup)
**Epic:** Epic 6 - Data Persistence & CloudKit Sync

**Acceptance Criteria:**
1. Conflict resolution strategy: "Last Write Wins" (based on `modifiedAt` timestamp)
2. If conflict detected (same record modified on two devices before sync), keep newer version based on timestamp
3. For `Note` conflicts, create conflict copy with suffix " (Conflict Copy)" rather than discarding
4. Conflict resolution logged for debugging: "Resolved conflict for VideoItem {id}: kept device A version (newer)"
5. User notified if conflicts occurred: "Sync completed with 3 conflicts resolved" (non-blocking notification)
6. Manual conflict review UI (optional for Pro tier): show conflicts, let user choose which version to keep
7. Integration tests simulate conflicts by modifying same record on two "devices" (separate CloudKit clients)

#### Detailed Task Breakdown

**Phase 1: Conflict Detection (AC: 1, 2)**
- [ ] **Task 6.4.1:** Detect CloudKit sync conflicts
  - [ ] Subtask: When saving CKRecord, handle `CKError.serverRecordChanged` error
  - [ ] Subtask: Extract server record and client record from error: `let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord`
  - [ ] Subtask: Compare `modifiedAt` timestamps: `let serverTime = serverRecord.modificationDate; let clientTime = clientRecord.modificationDate`
  - [ ] Subtask: Implement "Last Write Wins": If `clientTime > serverTime`, retry save with client version; else discard client changes and keep server version
  - [ ] Subtask: Log conflict detection: `logger.warning("Conflict detected for record \(recordID): server=\(serverTime), client=\(clientTime)")`

**Phase 2: Timestamp-Based Resolution (AC: 2)**
- [ ] **Task 6.4.2:** Implement Last Write Wins strategy
  - [ ] Subtask: Ensure all SwiftData models have `@Attribute var modifiedAt: Date` property
  - [ ] Subtask: Update `modifiedAt` on every save: `videoItem.modifiedAt = Date()`
  - [ ] Subtask: When conflict occurs, compare timestamps and keep newer version
  - [ ] Subtask: If client newer: Retry save with force-overwrite (use `CKModifyRecordsOperation` with `savePolicy: .changedKeys`)
  - [ ] Subtask: If server newer: Discard client changes, pull server version to SwiftData
  - [ ] Subtask: Log resolution: `logger.info("Resolved conflict: kept \(clientTime > serverTime ? "client" : "server") version")`

**Phase 3: Note Conflict Special Handling (AC: 3)**
- [ ] **Task 6.4.3:** Create conflict copies for Note conflicts
  - [ ] Subtask: For `Note` records specifically, don't discard either version
  - [ ] Subtask: When Note conflict detected, create duplicate Note with suffix: `conflictNote.content = note.content + "\n\n(Conflict Copy - \(Date()))" `
  - [ ] Subtask: Insert conflict copy as new Note in SwiftData
  - [ ] Subtask: Keep server version as-is (or client version if newer)
  - [ ] Subtask: Notify user: "Note conflict detected—created conflict copy for review"
  - [ ] Subtask: Conflict copy marked with `isConflict: Bool = true` property (for filtering)

**Phase 4: Conflict Logging (AC: 4)**
- [ ] **Task 6.4.4:** Log all conflict resolutions
  - [ ] Subtask: Use OSLog for conflict events: `logger.warning("Conflict resolution: VideoItem \(id), kept \(winner)")`
  - [ ] Subtask: Include details: record ID, record type, client timestamp, server timestamp, winner
  - [ ] Subtask: Log conflict count per sync cycle: `logger.info("Sync completed: \(conflictCount) conflicts resolved")`
  - [ ] Subtask: Store conflict log in Settings for user review (optional)

**Phase 5: User Notifications (AC: 5)**
- [ ] **Task 6.4.5:** Notify user of conflict resolutions
  - [ ] Subtask: After sync cycle, if conflicts occurred, show toast notification: `"Sync completed with \(conflictCount) conflicts resolved"`
  - [ ] Subtask: Non-blocking notification (doesn't require user action)
  - [ ] Subtask: Notification includes "View Details" button (opens conflict log in Settings)
  - [ ] Subtask: If Note conflicts (with conflict copies), show higher-priority notification: "Note conflicts detected—please review"
  - [ ] Subtask: Test: Simulate conflicts, verify notification shown

**Phase 6: Manual Conflict Review UI (Pro Feature) (AC: 6)**
- [ ] **Task 6.4.6:** Add conflict review UI for Pro users
  - [ ] Subtask: Create Settings > Sync > "Conflict History" view
  - [ ] Subtask: List all conflicts resolved in last 30 days
  - [ ] Subtask: For each conflict, show: Record type, ID, client version, server version, resolution timestamp, winner
  - [ ] Subtask: Pro feature: "Restore Discarded Version" button to manually choose other version
  - [ ] Subtask: Implement restoration: Fetch discarded version (if still in CloudKit history), overwrite current version
  - [ ] Subtask: Free users see "Upgrade to Pro to manually review conflicts" message

**Phase 7: Testing (AC: 7, All)**
- [ ] **Task 6.4.7:** Test conflict resolution
  - [ ] Subtask: Integration test: Create two CloudKit clients (simulate two devices)
  - [ ] Subtask: Test: Modify same VideoItem on both clients, sync, verify Last Write Wins applied
  - [ ] Subtask: Test: Client A has newer timestamp, verify client A version kept
  - [ ] Subtask: Test: Server has newer timestamp, verify server version kept
  - [ ] Subtask: Test: Note conflict, verify conflict copy created and original kept
  - [ ] Subtask: Manual test: Modify same video on two devices, sync, verify conflict resolved correctly
  - [ ] Subtask: UI test: Verify conflict notification shown and conflict log accessible

**Dev Notes:**
- **Files:** `MyToob/Services/CloudKitSyncManager.swift` (conflict resolution), `MyToob/Views/Settings/ConflictHistoryView.swift` (Pro UI)
- **CKError.serverRecordChanged:** Standard CloudKit conflict error, contains server and client records
- **Last Write Wins:** Simple strategy, works well for most data; may lose data if offline edits overlap
- **Note Conflicts:** Special case—preserve both versions since note content is important and not easily merged

**Testing Requirements:**
- Integration tests simulating two-device conflicts
- Unit tests for timestamp comparison and resolution logic
- Manual multi-device conflict tests
- UI tests for conflict notification and review UI

---

## Story 6.5: Sync Status UI & User Controls 🚧

**Status:** Draft
**Dependencies:** Story 6.3 (CloudKit Setup)
**Epic:** Epic 6 - Data Persistence & CloudKit Sync

**Acceptance Criteria:**
1. Sync status indicator in toolbar: "Synced" (green checkmark), "Syncing..." (spinner), "Sync Failed" (red X)
2. Clicking sync status opens sync details popover: "Last synced: 2 minutes ago | 1,234 items | Next sync: automatic"
3. Settings > iCloud Sync toggle: enable/disable CloudKit sync
4. When sync disabled, all data remains local-only (no CloudKit pushes)
5. "Sync Now" button in Settings forces immediate sync (useful for troubleshooting)
6. Sync error details shown to user: "Sync failed: Not signed into iCloud" or "Sync failed: Network unavailable"
7. No automatic sync when user explicitly disabled it (respects user choice)

#### Detailed Task Breakdown

**Phase 1: Sync Status Indicator (AC: 1)**
- [ ] **Task 6.5.1:** Add sync status indicator to toolbar
  - [ ] Subtask: In toolbar, add status icon: `Image(systemName: syncStatus.icon).foregroundColor(syncStatus.color)`
  - [ ] Subtask: Define `enum SyncStatus { case synced, syncing, failed }` with computed properties `icon` and `color`
  - [ ] Subtask: `synced` → `"checkmark.icloud"`, green; `syncing` → `"icloud"`, blue with spinner; `failed` → `"xmark.icloud"`, red
  - [ ] Subtask: Update status based on CloudKitSyncManager state: `@Published var syncStatus: SyncStatus`
  - [ ] Subtask: Test: Manually trigger sync, verify status changes from "Syncing..." to "Synced"

**Phase 2: Sync Details Popover (AC: 2)**
- [ ] **Task 6.5.2:** Show sync details on click
  - [ ] Subtask: Make status indicator clickable: `Button { showSyncDetails.toggle() } label: { ... }`
  - [ ] Subtask: Show popover: `.popover(isPresented: $showSyncDetails) { SyncDetailsView() }`
  - [ ] Subtask: In `SyncDetailsView`, display: `"Last synced: \(relativeTime(lastSyncedAt))"`
  - [ ] Subtask: Show item count: `"Items synced: \(syncedItemCount)"`
  - [ ] Subtask: Show next sync timing: `"Next sync: automatic"` (or "Next sync: in 5 minutes" if scheduled)
  - [ ] Subtask: Add "Sync Now" button in popover (calls `syncManager.syncNow()`)

**Phase 3: Settings Sync Toggle (AC: 3, 4)**
- [ ] **Task 6.5.3:** Add iCloud Sync toggle in Settings
  - [ ] Subtask: In `Settings > iCloud Sync`, add `Toggle("Enable iCloud Sync", isOn: $syncEnabled)`
  - [ ] Subtask: Bind to `@AppStorage("cloudKitSyncEnabled") var syncEnabled: Bool`
  - [ ] Subtask: When toggle OFF, pause CloudKitSyncManager: `syncManager.pause()`
  - [ ] Subtask: When paused, no push/pull operations occur (data remains local-only)
  - [ ] Subtask: When toggle ON, resume sync: `syncManager.resume()`
  - [ ] Subtask: Show info text: `"When disabled, all data remains on this device only"`

**Phase 4: "Sync Now" Button (AC: 5)**
- [ ] **Task 6.5.4:** Add manual sync trigger
  - [ ] Subtask: In Settings > iCloud Sync, add `Button("Sync Now") { syncManager.syncNow() }`
  - [ ] Subtask: Disable button if sync already in progress: `.disabled(syncStatus == .syncing)`
  - [ ] Subtask: Implement `syncNow()`: Force immediate CloudKit push/pull cycle
  - [ ] Subtask: Update sync status to "Syncing...", show progress
  - [ ] Subtask: On completion, update status to "Synced" and last synced timestamp
  - [ ] Subtask: Test: Click "Sync Now", verify immediate sync triggered

**Phase 5: Sync Error Handling (AC: 6)**
- [ ] **Task 6.5.5:** Display sync errors to user
  - [ ] Subtask: When sync fails, capture error: `syncManager.lastSyncError = error`
  - [ ] Subtask: Map errors to user-friendly messages:
    - [ ] `CKError.notAuthenticated` → "Not signed into iCloud. Please sign in to enable sync."
    - [ ] `CKError.networkUnavailable` → "Network unavailable. Sync will retry when connection restored."
    - [ ] `CKError.quotaExceeded` → "iCloud storage full. Free up space to continue syncing."
  - [ ] Subtask: Show error in sync details popover: `Text(syncManager.lastSyncError?.localizedDescription ?? "")`
  - [ ] Subtask: For critical errors (not authenticated, quota exceeded), show alert immediately
  - [ ] Subtask: Log errors: `logger.error("Sync failed: \(error)")`

**Phase 6: Respect User Disable Choice (AC: 7)**
- [ ] **Task 6.5.6:** Ensure no auto-sync when disabled
  - [ ] Subtask: Before any sync operation, check `syncEnabled` flag
  - [ ] Subtask: If `syncEnabled == false`, skip all push/pull operations
  - [ ] Subtask: Don't show "Syncing..." status when sync disabled
  - [ ] Subtask: Show "Sync disabled" in sync details popover
  - [ ] Subtask: Test: Disable sync, make changes, verify NO CloudKit operations triggered

**Phase 7: Testing (AC: All)**
- [ ] **Task 6.5.7:** Test sync status UI and controls
  - [ ] Subtask: UI test: Verify sync status indicator appears in toolbar
  - [ ] Subtask: UI test: Click indicator, verify popover opens with sync details
  - [ ] Subtask: UI test: Toggle sync off, verify status changes to "Sync disabled"
  - [ ] Subtask: UI test: Click "Sync Now", verify status changes to "Syncing..." then "Synced"
  - [ ] Subtask: Manual test: Trigger sync error (disable network), verify error message shown
  - [ ] Subtask: Manual test: Disable sync, make changes, verify no CloudKit operations
  - [ ] Subtask: Integration test: Full sync cycle, verify status updates correctly

**Dev Notes:**
- **Files:** `MyToob/Views/ToolbarView.swift` (status indicator), `MyToob/Views/SyncDetailsView.swift` (popover), `MyToob/Services/CloudKitSyncManager.swift` (sync logic)
- **Status Updates:** Use `@Published` properties in SyncManager to drive SwiftUI updates
- **Error Handling:** Map CloudKit errors to user-friendly messages (avoid technical jargon)
- **User Control:** Respect user choice to disable sync—critical for trust

**Testing Requirements:**
- UI tests for status indicator, popover, and Settings toggle
- Manual tests for sync trigger and error scenarios
- Integration tests for full sync cycle with status updates
- Accessibility tests for VoiceOver support

---

## Story 6.6: Caching Strategy for Metadata & Thumbnails 🚧

**Status:** Draft
**Dependencies:** Story 2.4 (ETag-Based Caching for YouTube API)
**Epic:** Epic 6 - Data Persistence & CloudKit Sync

**Acceptance Criteria:**
1. Metadata cache: key = `videoID`, value = YouTube API response JSON, TTL = 7 days
2. Thumbnail cache: key = `thumbnailURL`, value = image data, respects HTTP `Cache-Control` headers
3. ETag-based revalidation for metadata (implemented in Epic 2)—cache uses ETags
4. Cache stored on disk: `~/Library/Caches/MyToob/metadata/` and `.../thumbnails/`
5. Cache eviction: LRU policy, max 1000 metadata entries, max 500 MB thumbnails
6. "Clear Cache" button in Settings removes all cached data (forces re-download on next access)
7. Cache hit rate monitored: goal >90% for repeated views of same videos
8. No caching of YouTube video/audio streams (policy violation check—ensure no stream URLs cached)

#### Detailed Task Breakdown

**Phase 1: Metadata Cache Implementation (AC: 1, 3)**
- [ ] **Task 6.6.1:** Implement metadata cache with TTL
  - [ ] Subtask: Create `CacheManager` service with `func cacheMetadata(videoID: String, data: Data, etag: String?)` method
  - [ ] Subtask: Cache key: `videoID`, value: JSON data + ETag + timestamp
  - [ ] Subtask: Store in `~/Library/Caches/MyToob/metadata/\(videoID).json`
  - [ ] Subtask: On cache read, check TTL: `if Date() - cacheTimestamp > 7 * 24 * 3600 { // expired, refetch }`
  - [ ] Subtask: If ETag present, use for revalidation (see Epic 2): Send `If-None-Match` header, handle 304 response
  - [ ] Subtask: Test: Cache metadata, verify retrieved within TTL, verify re-fetched after expiry

**Phase 2: Thumbnail Cache Implementation (AC: 2)**
- [ ] **Task 6.6.2:** Implement thumbnail cache with HTTP headers
  - [ ] Subtask: Create `func cacheThumbnail(url: URL, data: Data, headers: [String: String])` method
  - [ ] Subtask: Cache key: Hash of thumbnail URL (e.g., SHA256)
  - [ ] Subtask: Store in `~/Library/Caches/MyToob/thumbnails/\(hash).jpg`
  - [ ] Subtask: Extract `Cache-Control` and `Expires` headers from HTTP response
  - [ ] Subtask: Calculate expiry: If `Cache-Control: max-age=3600`, cache valid for 1 hour
  - [ ] Subtask: On cache read, check if expired based on HTTP headers
  - [ ] Subtask: Test: Cache thumbnail, verify served from cache, verify re-fetched when expired

**Phase 3: Disk Storage Setup (AC: 4)**
- [ ] **Task 6.6.3:** Set up disk cache directories
  - [ ] Subtask: Get Caches directory: `let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!`
  - [ ] Subtask: Create subdirectories: `let metadataCache = cachesURL.appendingPathComponent("MyToob/metadata"); let thumbnailCache = cachesURL.appendingPathComponent("MyToob/thumbnails")`
  - [ ] Subtask: Create directories if not exist: `try? FileManager.default.createDirectory(at: metadataCache, withIntermediateDirectories: true)`
  - [ ] Subtask: Verify cache location: `logger.debug("Cache location: \(cachesURL.path)")`

**Phase 4: LRU Eviction Policy (AC: 5)**
- [ ] **Task 6.6.4:** Implement LRU cache eviction
  - [ ] Subtask: Track cache access times: Update file modification date on cache read: `try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: cachePath)`
  - [ ] Subtask: Periodically (on app launch), check metadata cache size
  - [ ] Subtask: If >1000 entries, sort by modification date (oldest first), delete oldest until <1000
  - [ ] Subtask: For thumbnails, check total size: `let totalSize = thumbnails.reduce(0) { $0 + (try? FileManager.default.attributesOfItem(atPath: $1.path)[.size] as? Int64 ?? 0) ?? 0 }`
  - [ ] Subtask: If >500 MB, delete oldest until <500 MB
  - [ ] Subtask: Log eviction: `logger.info("Evicted \(evictedCount) cache entries to stay under limits")`

**Phase 5: "Clear Cache" Button (AC: 6)**
- [ ] **Task 6.6.5:** Add clear cache functionality in Settings
  - [ ] Subtask: In Settings > Advanced, add `Button("Clear Cache") { clearCache() }`
  - [ ] Subtask: Implement `clearCache()`: `try? FileManager.default.removeItem(at: metadataCache); try? FileManager.default.removeItem(at: thumbnailCache)`
  - [ ] Subtask: Recreate directories after deletion
  - [ ] Subtask: Show confirmation alert: `"Are you sure? This will clear \(cacheSize) of cached data."`
  - [ ] Subtask: Show toast on success: `"Cache cleared successfully"`
  - [ ] Subtask: Test: Click "Clear Cache", verify all cached files deleted

**Phase 6: Cache Hit Rate Monitoring (AC: 7)**
- [ ] **Task 6.6.6:** Monitor cache hit rate
  - [ ] Subtask: Track cache hits and misses: `var cacheHits = 0; var cacheMisses = 0`
  - [ ] Subtask: On cache read: If found, increment `cacheHits`; else increment `cacheMisses`
  - [ ] Subtask: Calculate hit rate: `let hitRate = Double(cacheHits) / Double(cacheHits + cacheMisses)`
  - [ ] Subtask: Log hit rate periodically: `logger.info("Cache hit rate: \(hitRate * 100)%")`
  - [ ] Subtask: Display in Settings > Advanced: `Text("Cache hit rate: \(Int(hitRate * 100))%")`
  - [ ] Subtask: Goal: >90% hit rate for typical usage (repeated video views)

**Phase 7: Policy Compliance Check (AC: 8)**
- [ ] **Task 6.6.7:** Ensure no stream caching
  - [ ] Subtask: Code review: Verify NO caching of URLs containing `googlevideo.com` or stream manifest URLs
  - [ ] Subtask: Add lint rule (if possible): Flag any cache writes with `googlevideo.com` URLs
  - [ ] Subtask: Only cache: YouTube API metadata JSON, thumbnail images
  - [ ] Subtask: Document policy: "Stream URLs MUST NOT be cached per YouTube ToS"
  - [ ] Subtask: Test: Verify playback URLs never cached (only metadata and thumbnails)

**Phase 8: Testing (AC: All)**
- [ ] **Task 6.6.8:** Test caching strategy
  - [ ] Subtask: Unit test: Cache metadata, verify retrieved within TTL
  - [ ] Subtask: Unit test: Cache expired metadata, verify re-fetched
  - [ ] Subtask: Unit test: Thumbnail cache respects HTTP Cache-Control headers
  - [ ] Subtask: Integration test: Load video multiple times, verify served from cache (hit rate >90%)
  - [ ] Subtask: Performance test: Cache 1000+ entries, verify eviction keeps within limits
  - [ ] Subtask: Manual test: Clear cache, reload app, verify all data re-fetched
  - [ ] Subtask: Compliance test: Verify no stream URLs ever cached

**Dev Notes:**
- **Files:** `MyToob/Services/CacheManager.swift` (cache logic), `MyToob/Views/Settings/AdvancedSettingsView.swift` (clear cache button)
- **Cache Location:** `~/Library/Caches/MyToob/` (automatically managed by system, can be purged when space needed)
- **LRU Implementation:** Use file modification dates for LRU tracking (simple and efficient)
- **Compliance:** CRITICAL—never cache video/audio streams, only metadata/thumbnails

**Testing Requirements:**
- Unit tests for cache storage, retrieval, and expiry
- Unit tests for LRU eviction logic
- Integration tests for cache hit rate
- Compliance tests for stream URL caching prevention
- Manual tests for "Clear Cache" functionality

---


---

### Epic 7: On-Device AI Embeddings & Vector Index (6 stories)

## Story 7.1: Core ML Embedding Model Integration

**Status:** Not Started  
**Dependencies:** None (foundational AI infrastructure)  
**Epic:** 7 - On-Device AI Embeddings & Vector Index

**Full Acceptance Criteria:**
1. Small sentence-transformer model (e.g., all-MiniLM-L6-v2) converted to Core ML format (`.mlmodel` or `.mlpackage`)
2. Model quantized to 8-bit for performance (reduces model size, speeds up inference)
3. Model added to Xcode project as resource, loaded at app startup
4. Swift wrapper created: `EmbeddingService.generateEmbedding(text: String) async -> [Float]`
5. Input text preprocessed: lowercased, truncated to model's max length (typically 256 tokens)
6. Output: 384-element Float array (embedding vector)
7. Inference latency measured: <10ms average on M1 Mac (target met)
8. Unit tests verify embeddings are consistent (same input → same output)

**Implementation Phases:**

**Phase 1: Model Selection & Conversion (AC: 1, 2)**
- [ ] **Task 7.1.1:** Research and select appropriate sentence-transformer model
  - [ ] Subtask: Evaluate all-MiniLM-L6-v2 (384-dim, good balance of size/performance)
  - [ ] Subtask: Verify model license allows commercial use (Apache 2.0 or MIT preferred)
  - [ ] Subtask: Download pre-trained model from HuggingFace (sentence-transformers/all-MiniLM-L6-v2)
  - [ ] Subtask: Test model locally with Python to verify output dimensions and quality
  - [ ] Subtask: Document model choice in `docs/AI_MODELS.md` (architecture, license, performance characteristics)

- [ ] **Task 7.1.2:** Convert model to Core ML format
  - [ ] Subtask: Install `coremltools` Python package: `pip install coremltools transformers torch`
  - [ ] Subtask: Create conversion script `scripts/convert_embedding_model.py`
  - [ ] Subtask: Use `ct.convert()` to convert PyTorch model to Core ML with quantization
  - [ ] Subtask: Apply 8-bit quantization: `ct.models.neural_network.quantization_utils.quantize_weights(model, nbits=8)`
  - [ ] Subtask: Verify quantized model output matches original (within acceptable tolerance, e.g., cosine similarity > 0.98)
  - [ ] Subtask: Export as `.mlpackage` format (preferred for Xcode 14+)
  - [ ] Subtask: Test converted model with sample text: "swift programming tutorial"
  - [ ] Subtask: Measure model file size (target: <50 MB after quantization)

**Phase 2: Xcode Project Integration (AC: 3)**
- [ ] **Task 7.1.3:** Add Core ML model to Xcode project
  - [ ] Subtask: Copy `.mlpackage` to `MyToob/AI/Models/SentenceEmbedding.mlpackage`
  - [ ] Subtask: Add model to Xcode project (drag to navigator, ensure "Copy items if needed" checked)
  - [ ] Subtask: Verify model appears in Xcode's ML Model viewer (check input/output types)
  - [ ] Subtask: Confirm "Target Membership" set to MyToob target
  - [ ] Subtask: Check generated Swift interface: `SentenceEmbedding.swift` auto-generated by Xcode

- [ ] **Task 7.1.4:** Model loading at app startup
  - [ ] Subtask: Create `MyToob/AI/EmbeddingService.swift` with `@Observable class EmbeddingService`
  - [ ] Subtask: Add property: `private var model: SentenceEmbedding?`
  - [ ] Subtask: Implement `loadModel()` function: `model = try SentenceEmbedding(configuration: MLModelConfiguration())`
  - [ ] Subtask: Call `loadModel()` in `MyToobApp.init()` or environment setup
  - [ ] Subtask: Handle loading errors gracefully: log error, show user alert if model fails to load
  - [ ] Subtask: Add logging: "Core ML embedding model loaded successfully"

**Phase 3: Text Preprocessing (AC: 5)**
- [ ] **Task 7.1.5:** Implement input text preprocessing
  - [ ] Subtask: Create `preprocessText(_ text: String) -> String` function in `EmbeddingService`
  - [ ] Subtask: Lowercase input: `text.lowercased()`
  - [ ] Subtask: Truncate to max length (256 tokens ≈ 1024 characters): `text.prefix(1024)`
  - [ ] Subtask: Handle empty input: return default text like "[EMPTY]" or throw error
  - [ ] Subtask: Optional: Remove excessive whitespace with regex: `text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)`
  - [ ] Subtask: Validate preprocessing with test cases: long text, empty text, unicode text

**Phase 4: Embedding Generation API (AC: 4, 6)**
- [ ] **Task 7.1.6:** Implement embedding generation wrapper
  - [ ] Subtask: Create `generateEmbedding(text: String) async throws -> [Float]` function
  - [ ] Subtask: Preprocess input text: `let processedText = preprocessText(text)`
  - [ ] Subtask: Create Core ML input: `let input = SentenceEmbeddingInput(text: processedText)`
  - [ ] Subtask: Run prediction: `let output = try await model?.prediction(input: input)`
  - [ ] Subtask: Extract embedding vector from output (typically named "embedding" or "output")
  - [ ] Subtask: Convert MLMultiArray to [Float]: iterate over array and cast elements
  - [ ] Subtask: Validate output dimension: `assert(embedding.count == 384)`
  - [ ] Subtask: Return embedding array: `return embedding`

- [ ] **Task 7.1.7:** Error handling and edge cases
  - [ ] Subtask: Handle model not loaded: throw custom error `EmbeddingError.modelNotLoaded`
  - [ ] Subtask: Handle prediction failure: catch Core ML errors and wrap in domain error
  - [ ] Subtask: Handle invalid input: throw `EmbeddingError.invalidInput` for empty text
  - [ ] Subtask: Add retry logic for transient failures (e.g., Core ML resource contention)
  - [ ] Subtask: Log errors with context: "Failed to generate embedding for text: '\(text.prefix(50))...'"

**Phase 5: Performance Measurement (AC: 7)**
- [ ] **Task 7.1.8:** Measure and optimize inference latency
  - [ ] Subtask: Add performance logging in `generateEmbedding`: `let start = Date(); ...; let duration = Date().timeIntervalSince(start)`
  - [ ] Subtask: Log inference time: "Embedding generated in \(duration * 1000)ms"
  - [ ] Subtask: Run benchmark with 100 sample texts, calculate average latency
  - [ ] Subtask: Verify <10ms average on M1 Mac (AC target)
  - [ ] Subtask: If target not met, investigate: check Core ML compute units (CPU vs GPU vs Neural Engine)
  - [ ] Subtask: Optimize by setting `MLModelConfiguration.computeUnits = .all` (use Neural Engine if available)
  - [ ] Subtask: Document performance results in `docs/AI_MODELS.md`: "Average latency: 7ms (M1), 12ms (Intel Mac)"

**Phase 6: Unit Testing (AC: 8)**
- [ ] **Task 7.1.9:** Write comprehensive unit tests
  - [ ] Subtask: Create `MyToobTests/AI/EmbeddingServiceTests.swift`
  - [ ] Subtask: Test: `testEmbeddingConsistency()` - same input generates same embedding
  - [ ] Subtask: Test: `testEmbeddingDimension()` - output is always 384 elements
  - [ ] Subtask: Test: `testPreprocessing()` - text is lowercased and truncated correctly
  - [ ] Subtask: Test: `testEmptyInput()` - empty text throws or returns default
  - [ ] Subtask: Test: `testLongInput()` - text >1024 chars is truncated
  - [ ] Subtask: Test: `testModelNotLoaded()` - appropriate error when model missing
  - [ ] Subtask: Test: `testPerformance()` - embedding generation completes in <20ms (with margin)
  - [ ] Subtask: Run all tests and verify 100% pass rate

**Phase 7: Integration & Documentation**
- [ ] **Task 7.1.10:** Integration with VideoItem model
  - [ ] Subtask: In `VideoItem.swift`, add property: `@Attribute var embedding: [Float]?`
  - [ ] Subtask: Mark as `@Transient` if embeddings should be regenerated on demand (optional)
  - [ ] Subtask: Add helper: `func generateEmbedding(using service: EmbeddingService) async throws`
  - [ ] Subtask: Store embedding in SwiftData: `self.embedding = try await service.generateEmbedding(text: combinedText)`

- [ ] **Task 7.1.11:** Documentation
  - [ ] Subtask: Create `docs/AI_MODELS.md` with model details (architecture, license, performance)
  - [ ] Subtask: Document API usage in code comments: `/// Generates 384-dim embedding from text using Core ML`
  - [ ] Subtask: Add example usage in doc comments: `let embedding = try await service.generateEmbedding(text: "example")`
  - [ ] Subtask: Document performance characteristics and benchmarks

**Dev Notes:**
- **Files to Create:** `MyToob/AI/EmbeddingService.swift`, `MyToob/AI/Models/SentenceEmbedding.mlpackage`, `scripts/convert_embedding_model.py`, `MyToobTests/AI/EmbeddingServiceTests.swift`, `docs/AI_MODELS.md`
- **Model Conversion:** Use `coremltools` to convert HuggingFace model to Core ML with 8-bit quantization
- **Performance Optimization:** Neural Engine provides best performance for embeddings on Apple Silicon
- **Model Source:** `sentence-transformers/all-MiniLM-L6-v2` from HuggingFace (384-dim, Apache 2.0 license)
- **Testing Strategy:** Use known test vectors to verify embeddings are consistent and dimensionally correct

**Testing Requirements:**
- Unit tests for preprocessing, embedding generation, error handling (8 tests in `EmbeddingServiceTests`)
- Performance benchmarks (verify <10ms average on M1 Mac)
- Integration test: generate embedding for VideoItem and verify stored correctly
- Edge case tests: empty text, very long text, special characters

---

## Story 7.2: Metadata Text Preparation for Embeddings

**Status:** Not Started  
**Dependencies:** Story 7.1 (Core ML model must be integrated first)  
**Epic:** 7 - On-Device AI Embeddings & Vector Index

**Full Acceptance Criteria:**
1. For each `VideoItem`, concatenate: `title + " " + description + " " + tags.joined(separator: " ")`
2. Text cleaned: remove URLs, HTML tags, excessive whitespace, non-ASCII characters (optional, if they hurt model performance)
3. Text truncated to model's max input length (typically 256 tokens ≈ 1000 characters)
4. Title weighted more heavily (optional: repeat title 2-3 times in concatenated text for emphasis)
5. If metadata is minimal (e.g., local file with only filename), fall back to filename only
6. Empty or very short text (<10 characters) handled gracefully: generate default embedding or skip
7. Unit tests verify text preparation with various input scenarios (long description, missing title, etc.)

**Implementation Phases:**

**Phase 1: Text Concatenation Logic (AC: 1)**
- [ ] **Task 7.2.1:** Create metadata text builder
  - [ ] Subtask: In `VideoItem.swift`, add computed property: `var embeddingText: String { get }`
  - [ ] Subtask: Concatenate components: `let parts = [title, description, tags.joined(separator: " ")]`
  - [ ] Subtask: Filter empty parts: `let validParts = parts.filter { !$0.isEmpty }`
  - [ ] Subtask: Join with space: `return validParts.joined(separator: " ")`
  - [ ] Subtask: Handle nil values: use `title ?? ""`, `description ?? ""`

- [ ] **Task 7.2.2:** YouTube-specific metadata handling
  - [ ] Subtask: For YouTube videos, include `channelName` if available
  - [ ] Subtask: Include `aiTopicTags` if already generated (for re-embedding after tagging)
  - [ ] Subtask: Optionally include `categoryID` as text (e.g., "category: education")

**Phase 2: Text Cleaning (AC: 2)**
- [ ] **Task 7.2.3:** Implement text cleaning utilities
  - [ ] Subtask: Create `TextCleaner.swift` in `MyToob/AI/` with static cleaning functions
  - [ ] Subtask: Implement `removeURLs(_ text: String) -> String` using regex: `text.replacingOccurrences(of: "https?://\\S+", with: "", options: .regularExpression)`
  - [ ] Subtask: Implement `removeHTMLTags(_ text: String) -> String`: `text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)`
  - [ ] Subtask: Implement `normalizeWhitespace(_ text: String) -> String`: replace multiple spaces/newlines with single space
  - [ ] Subtask: Implement `removeNonASCII(_ text: String) -> String` (optional): `text.filter { $0.isASCII }`
  - [ ] Subtask: Test with YouTube descriptions containing URLs and HTML entities

- [ ] **Task 7.2.4:** Apply cleaning pipeline
  - [ ] Subtask: In `embeddingText` property, apply cleaning: `var cleaned = TextCleaner.removeURLs(combinedText)`
  - [ ] Subtask: Chain cleaners: `cleaned = TextCleaner.removeHTMLTags(cleaned)`
  - [ ] Subtask: Normalize whitespace: `cleaned = TextCleaner.normalizeWhitespace(cleaned)`
  - [ ] Subtask: Optionally remove non-ASCII (test if it improves embedding quality)
  - [ ] Subtask: Trim leading/trailing whitespace: `cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)`

**Phase 3: Text Truncation (AC: 3)**
- [ ] **Task 7.2.5:** Implement smart truncation
  - [ ] Subtask: Define max length constant: `let maxEmbeddingTextLength = 1000` (approx 256 tokens)
  - [ ] Subtask: Check text length: `if cleaned.count > maxEmbeddingTextLength { ... }`
  - [ ] Subtask: Truncate: `cleaned = String(cleaned.prefix(maxEmbeddingTextLength))`
  - [ ] Subtask: Optional: Truncate at last complete word to avoid cutting mid-word
  - [ ] Subtask: Add truncation indicator: `cleaned += "..."` (optional, for clarity)
  - [ ] Subtask: Test with very long descriptions (>5000 characters)

**Phase 4: Title Emphasis (AC: 4)**
- [ ] **Task 7.2.6:** Implement title weighting
  - [ ] Subtask: Add Settings toggle: `@AppStorage("emphasizeTitleInEmbeddings") var emphasizeTitle = true`
  - [ ] Subtask: If enabled, repeat title 2-3 times in concatenated text
  - [ ] Subtask: Modified concatenation: `let parts = [title, title, title, description, tags.joined()]` (if emphasis enabled)
  - [ ] Subtask: Ensure total text still respects max length (truncate after concatenation)
  - [ ] Subtask: Test impact on search quality: compare embeddings with/without title emphasis
  - [ ] Subtask: Document in `docs/AI_MODELS.md`: "Title emphasis improves relevance for title-based searches"

**Phase 5: Fallback Handling (AC: 5, 6)**
- [ ] **Task 7.2.7:** Handle minimal metadata
  - [ ] Subtask: For local files, check if metadata is minimal: `if title.isEmpty && description.isEmpty`
  - [ ] Subtask: Fall back to filename: `let fallbackText = localURL?.lastPathComponent ?? "Untitled"`
  - [ ] Subtask: Remove file extension from filename: `fallbackText.replacingOccurrences(of: ".mp4", with: "")`
  - [ ] Subtask: Use fallback in `embeddingText` if metadata empty

- [ ] **Task 7.2.8:** Handle empty/short text
  - [ ] Subtask: Check final text length: `if embeddingText.count < 10 { ... }`
  - [ ] Subtask: Option 1: Skip embedding generation, set `embedding = nil`
  - [ ] Subtask: Option 2: Use default text: `embeddingText = "[No metadata available]"`
  - [ ] Subtask: Log warning: "Video '\(videoID)' has insufficient metadata for embedding"
  - [ ] Subtask: Test with edge cases: empty title, empty description, no tags

**Phase 6: Unit Testing (AC: 7)**
- [ ] **Task 7.2.9:** Write comprehensive tests for text preparation
  - [ ] Subtask: Create `MyToobTests/AI/TextPreparationTests.swift`
  - [ ] Subtask: Test: `testBasicConcatenation()` - title + description + tags combined correctly
  - [ ] Subtask: Test: `testURLRemoval()` - YouTube description with URLs cleaned
  - [ ] Subtask: Test: `testHTMLTagRemoval()` - description with HTML tags cleaned
  - [ ] Subtask: Test: `testLongDescription()` - text truncated to max length
  - [ ] Subtask: Test: `testMissingTitle()` - handles nil title gracefully
  - [ ] Subtask: Test: `testLocalFileWithMinimalMetadata()` - falls back to filename
  - [ ] Subtask: Test: `testEmptyMetadata()` - handles empty text appropriately
  - [ ] Subtask: Test: `testTitleEmphasis()` - title repeated when setting enabled
  - [ ] Subtask: Run all tests and verify 100% pass rate

**Phase 7: Integration & Performance**
- [ ] **Task 7.2.10:** Integrate with embedding generation pipeline
  - [ ] Subtask: Update `VideoItem.generateEmbedding()` to use `embeddingText` property
  - [ ] Subtask: Example: `let embedding = try await service.generateEmbedding(text: self.embeddingText)`
  - [ ] Subtask: Profile text preparation performance (should be <1ms, negligible vs. embedding inference)
  - [ ] Subtask: Cache `embeddingText` if computed property is expensive (use lazy var if needed)

- [ ] **Task 7.2.11:** Documentation
  - [ ] Subtask: Document text preparation pipeline in `docs/AI_MODELS.md`
  - [ ] Subtask: Add code comments explaining cleaning steps and rationale
  - [ ] Subtask: Document title emphasis setting and when to use it
  - [ ] Subtask: Include example before/after text cleaning: "Original: '<a href=...>Watch</a> Learn Swift' → Cleaned: 'Watch Learn Swift'"

**Dev Notes:**
- **Files to Create:** `MyToob/AI/TextCleaner.swift`, `MyToobTests/AI/TextPreparationTests.swift`
- **Files to Modify:** `MyToob/Models/VideoItem.swift` (add `embeddingText` computed property)
- **Text Cleaning:** Regex-based cleaning for URLs and HTML tags, whitespace normalization
- **Title Emphasis:** Experimental feature to improve title-based search relevance (A/B test effectiveness)
- **Truncation:** 1000 chars ≈ 256 tokens (approximate, actual tokenization varies by model)
- **Local Files:** Filename fallback ensures all videos have some text for embedding generation

**Testing Requirements:**
- Unit tests for all text cleaning functions (9 tests in `TextPreparationTests`)
- Edge case tests: nil values, empty strings, very long text (>10k chars)
- Integration test: prepare text for YouTube video and local file, verify cleaned correctly
- Performance test: text preparation should add <1ms to embedding pipeline


---

## Story 7.3: Thumbnail OCR Text Extraction

**Status:** Not Started  
**Dependencies:** Story 7.2 (text preparation must be implemented first)  
**Epic:** 7 - On-Device AI Embeddings & Vector Index

**Full Acceptance Criteria:**
1. `VNRecognizeTextRequest` used to extract text from thumbnail images
2. Thumbnail downloaded (or loaded from cache) as `NSImage`/`CGImage`
3. OCR runs asynchronously (doesn't block main thread)
4. Extracted text combined with metadata text before embedding generation
5. OCR failures handled gracefully (if no text found, continue without OCR text)
6. OCR text cleaned: remove low-confidence results (<0.5 confidence threshold)
7. Performance acceptable: OCR adds <100ms to embedding pipeline (measured)
8. Unit tests verify OCR extraction with sample thumbnails (text-heavy vs. text-free)

**Implementation Phases:**

**Phase 1: Vision Framework Setup (AC: 1)**
- [ ] **Task 7.3.1:** Import and configure Vision framework
  - [ ] Subtask: Add `import Vision` to `MyToob/AI/ThumbnailOCRService.swift` (create file)
  - [ ] Subtask: Create `@Observable class ThumbnailOCRService` with OCR methods
  - [ ] Subtask: Add property: `private let textRecognitionLevel: VNRequestTextRecognitionLevel = .accurate`
  - [ ] Subtask: Create `VNRecognizeTextRequest` instance: `let request = VNRecognizeTextRequest(completionHandler: ...)`
  - [ ] Subtask: Configure request: `request.recognitionLevel = .accurate`, `request.recognitionLanguages = ["en-US"]`
  - [ ] Subtask: Set minimum text height: `request.minimumTextHeight = 0.05` (ignore very small text)

**Phase 2: Thumbnail Image Loading (AC: 2)**
- [ ] **Task 7.3.2:** Thumbnail image acquisition
  - [ ] Subtask: Create `loadThumbnail(for videoItem: VideoItem) async -> NSImage?` function
  - [ ] Subtask: For YouTube videos, load from cache: check `~/Library/Caches/MyToob/thumbnails/{videoID}.jpg`
  - [ ] Subtask: If not cached, download from `VideoItem.thumbnailURL` using `URLSession`
  - [ ] Subtask: For local files, generate thumbnail using AVAssetImageGenerator (covered in Story 5.6)
  - [ ] Subtask: Convert NSImage to CGImage: `let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)`
  - [ ] Subtask: Handle loading failures: return nil if thumbnail unavailable
  - [ ] Subtask: Cache downloaded thumbnails for reuse

**Phase 3: OCR Execution (AC: 3)**
- [ ] **Task 7.3.3:** Implement asynchronous OCR processing
  - [ ] Subtask: Create `extractText(from image: CGImage) async throws -> String` function
  - [ ] Subtask: Wrap synchronous Vision API in async task: `await Task.detached { ... }.value`
  - [ ] Subtask: Create Vision request handler: `let handler = VNImageRequestHandler(cgImage: image, options: [:])`
  - [ ] Subtask: Perform request: `try handler.perform([textRequest])`
  - [ ] Subtask: Extract results in completion handler: `guard let observations = request.results as? [VNRecognizedTextObservation] else { return }`
  - [ ] Subtask: Ensure OCR runs on background queue, not main thread
  - [ ] Subtask: Test async behavior: verify UI remains responsive during OCR

**Phase 4: Text Extraction & Filtering (AC: 6)**
- [ ] **Task 7.3.4:** Process OCR results
  - [ ] Subtask: Iterate over observations: `for observation in observations { ... }`
  - [ ] Subtask: Get top candidate: `guard let topCandidate = observation.topCandidates(1).first else { continue }`
  - [ ] Subtask: Filter by confidence: `if topCandidate.confidence < 0.5 { continue }`
  - [ ] Subtask: Extract text: `let recognizedText = topCandidate.string`
  - [ ] Subtask: Collect all high-confidence text: `ocrTexts.append(recognizedText)`
  - [ ] Subtask: Join extracted text: `let finalOCRText = ocrTexts.joined(separator: " ")`
  - [ ] Subtask: Clean OCR text: apply same `TextCleaner` utilities as metadata (remove URLs, normalize whitespace)

**Phase 5: Integration with Metadata Text (AC: 4)**
- [ ] **Task 7.3.5:** Combine OCR text with metadata
  - [ ] Subtask: Modify `VideoItem.embeddingText` to include OCR text
  - [ ] Subtask: Add stored property: `@Attribute var thumbnailOCRText: String?` (cache OCR results)
  - [ ] Subtask: Run OCR during embedding generation: `let ocrText = try? await ocrService.extractText(from: thumbnailImage)`
  - [ ] Subtask: Store OCR result: `self.thumbnailOCRText = ocrText`
  - [ ] Subtask: Combine with metadata: `embeddingText = "\(title) \(description) \(tags.joined()) \(thumbnailOCRText ?? "")"`
  - [ ] Subtask: Ensure OCR text doesn't exceed max length (truncate combined text after adding OCR)

**Phase 6: Error Handling (AC: 5)**
- [ ] **Task 7.3.6:** Handle OCR failures gracefully
  - [ ] Subtask: Wrap OCR calls in try-catch: `do { let text = try await extractText(...) } catch { ... }`
  - [ ] Subtask: Log OCR errors: "OCR failed for video '\(videoID)': \(error.localizedDescription)"
  - [ ] Subtask: If OCR fails, continue without OCR text: `thumbnailOCRText = nil`
  - [ ] Subtask: Handle no text found (empty OCR result): set `thumbnailOCRText = nil` instead of empty string
  - [ ] Subtask: Don't block embedding generation on OCR failure (OCR is enhancement, not requirement)
  - [ ] Subtask: Optional: Add retry logic for transient Vision framework errors

**Phase 7: Performance Optimization (AC: 7)**
- [ ] **Task 7.3.7:** Measure and optimize OCR performance
  - [ ] Subtask: Add performance logging: `let start = Date(); ...; let duration = Date().timeIntervalSince(start)`
  - [ ] Subtask: Log OCR time: "OCR completed in \(duration * 1000)ms"
  - [ ] Subtask: Run benchmark with 50 sample thumbnails, calculate average latency
  - [ ] Subtask: Verify <100ms average (AC target)
  - [ ] Subtask: If target not met, reduce accuracy: `request.recognitionLevel = .fast` instead of `.accurate`
  - [ ] Subtask: Optimize image size: downscale large thumbnails before OCR (e.g., max 640x480)
  - [ ] Subtask: Document performance: "Average OCR time: 75ms (accurate), 30ms (fast)"

**Phase 8: Unit Testing (AC: 8)**
- [ ] **Task 7.3.8:** Write comprehensive OCR tests
  - [ ] Subtask: Create `MyToobTests/AI/ThumbnailOCRTests.swift`
  - [ ] Subtask: Create test images in `MyToobTests/Resources/TestThumbnails/`
  - [ ] Subtask: Test image 1: Thumbnail with clear text (e.g., "SWIFT TUTORIAL" overlaid)
  - [ ] Subtask: Test image 2: Thumbnail with no text (landscape photo)
  - [ ] Subtask: Test: `testOCRWithTextHeavyThumbnail()` - verify text extracted correctly
  - [ ] Subtask: Test: `testOCRWithTextFreeThumbnail()` - verify no false positives
  - [ ] Subtask: Test: `testOCRConfidenceFiltering()` - low-confidence text excluded
  - [ ] Subtask: Test: `testOCRPerformance()` - completes in <150ms (with margin)
  - [ ] Subtask: Test: `testOCRErrorHandling()` - handles invalid image gracefully
  - [ ] Subtask: Run all tests and verify 100% pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/AI/ThumbnailOCRService.swift`, `MyToobTests/AI/ThumbnailOCRTests.swift`, test thumbnail images
- **Files to Modify:** `MyToob/Models/VideoItem.swift` (add `thumbnailOCRText` property, update `embeddingText`)
- **Vision Framework:** Use `.accurate` recognition level for quality, `.fast` if performance issues
- **Confidence Threshold:** 0.5 is standard for balancing precision/recall; adjust if needed
- **Performance:** OCR is slowest part of embedding pipeline (75-100ms typical), but acceptable for background processing
- **Caching:** Store OCR results in `thumbnailOCRText` to avoid re-running OCR on every embedding regeneration
- **Language:** Default to English (`en-US`), can add multi-language support later if needed

**Testing Requirements:**
- Unit tests for OCR extraction with various thumbnail types (5 tests in `ThumbnailOCRTests`)
- Performance test: verify OCR adds <100ms to embedding pipeline
- Integration test: generate embedding for video with OCR text, verify OCR text included
- Edge case tests: invalid image, empty image, very small text, non-English text

---

## Story 7.4: Batch Embedding Generation Pipeline

**Status:** Not Started  
**Dependencies:** Stories 7.1, 7.2, 7.3 (embedding model, text prep, OCR must be ready)  
**Epic:** 7 - On-Device AI Embeddings & Vector Index

**Full Acceptance Criteria:**
1. On video import (YouTube or local), trigger embedding generation in background queue
2. Batch processing: process up to 10 videos at a time (parallel inference using Core ML)
3. Progress indicator shown: "Generating embeddings: 45/120 videos..."
4. Embedding stored in `VideoItem.embedding` (transformable [Float] array in SwiftData)
5. If embedding generation fails (e.g., Core ML error), log error and retry later
6. "Re-generate Embeddings" action in Settings forces regeneration for all videos (useful after model update)
7. App usable while embeddings generate (non-blocking background task)
8. Embeddings persist across app restarts (stored in SwiftData)

**Implementation Phases:**

**Phase 1: Background Queue Setup (AC: 1, 7)**
- [ ] **Task 7.4.1:** Create embedding generation coordinator
  - [ ] Subtask: Create `MyToob/AI/EmbeddingCoordinator.swift` with `@Observable class EmbeddingCoordinator`
  - [ ] Subtask: Add property: `@Published var isGenerating = false`
  - [ ] Subtask: Add property: `@Published var progress: Double = 0.0` (0.0 to 1.0)
  - [ ] Subtask: Add property: `@Published var statusMessage = ""`
  - [ ] Subtask: Create background queue: `private let embeddingQueue = DispatchQueue(label: "com.mytoob.embeddings", qos: .utility)`
  - [ ] Subtask: Inject dependencies: `init(embeddingService: EmbeddingService, ocrService: ThumbnailOCRService, modelContext: ModelContext)`

- [ ] **Task 7.4.2:** Trigger embedding generation on import
  - [ ] Subtask: Add observer for new `VideoItem` insertions in SwiftData
  - [ ] Subtask: In `ContentView` or app-level coordinator, call `embeddingCoordinator.generateEmbeddings(for: [newVideo])`
  - [ ] Subtask: Enqueue new videos for processing: `pendingVideos.append(contentsOf: videos)`
  - [ ] Subtask: Start processing if not already running: `if !isGenerating { startProcessing() }`

**Phase 2: Batch Processing Logic (AC: 2)**
- [ ] **Task 7.4.3:** Implement parallel batch processing
  - [ ] Subtask: Define batch size: `let batchSize = 10`
  - [ ] Subtask: Create `processBatch(_ videos: [VideoItem]) async` function
  - [ ] Subtask: Use `TaskGroup` for parallel processing: `await withTaskGroup(of: Void.self) { group in ... }`
  - [ ] Subtask: For each video in batch, add task: `group.addTask { try await self.generateEmbedding(for: video) }`
  - [ ] Subtask: Limit concurrency to 10 (batch size)
  - [ ] Subtask: Wait for all tasks in batch to complete before starting next batch
  - [ ] Subtask: Test batch processing with 50 videos, verify 10 run in parallel

**Phase 3: Embedding Generation Per Video (AC: 4)**
- [ ] **Task 7.4.4:** Generate and store embedding for single video
  - [ ] Subtask: Create `generateEmbedding(for video: VideoItem) async throws` function
  - [ ] Subtask: Prepare text: `let text = video.embeddingText` (includes metadata + OCR)
  - [ ] Subtask: Generate embedding: `let embedding = try await embeddingService.generateEmbedding(text: text)`
  - [ ] Subtask: Store in SwiftData: `video.embedding = embedding`
  - [ ] Subtask: Save context: `try modelContext.save()`
  - [ ] Subtask: Update progress: `progress += 1.0 / Double(totalVideos)`
  - [ ] Subtask: Log success: "Embedding generated for video '\(video.title)'"

**Phase 4: Progress Tracking (AC: 3)**
- [ ] **Task 7.4.5:** Implement progress UI
  - [ ] Subtask: In `SettingsView` or toolbar, add progress indicator: `ProgressView(value: embeddingCoordinator.progress)`
  - [ ] Subtask: Show status message: `Text(embeddingCoordinator.statusMessage)` (e.g., "Generating embeddings: 45/120 videos...")
  - [ ] Subtask: Update status message: `statusMessage = "Generating embeddings: \(completed)/\(total) videos..."`
  - [ ] Subtask: Hide progress view when complete: `if !embeddingCoordinator.isGenerating { ... }`
  - [ ] Subtask: Show completion notification: "Embedding generation complete" toast

**Phase 5: Error Handling & Retry Logic (AC: 5)**
- [ ] **Task 7.4.6:** Handle embedding generation failures
  - [ ] Subtask: Wrap embedding generation in try-catch: `do { try await generateEmbedding(for: video) } catch { ... }`
  - [ ] Subtask: Log error: "Failed to generate embedding for '\(video.title)': \(error.localizedDescription)"
  - [ ] Subtask: Add video to retry queue: `failedVideos.append(video)`
  - [ ] Subtask: Retry failed videos after initial batch: `await retryFailedVideos()`
  - [ ] Subtask: Implement exponential backoff for retries (1s, 2s, 4s delays)
  - [ ] Subtask: Max retry attempts: 3 per video
  - [ ] Subtask: After max retries, mark video as failed: `video.embeddingFailed = true` (add property if needed)
  - [ ] Subtask: User can manually retry failed videos later

**Phase 6: Manual Regeneration (AC: 6)**
- [ ] **Task 7.4.7:** Implement "Re-generate Embeddings" action
  - [ ] Subtask: Add button in Settings: "Re-generate All Embeddings"
  - [ ] Subtask: Show confirmation alert: "This will regenerate embeddings for all videos. Continue?"
  - [ ] Subtask: On confirm, fetch all videos: `let allVideos = try modelContext.fetch(FetchDescriptor<VideoItem>())`
  - [ ] Subtask: Clear existing embeddings: `for video in allVideos { video.embedding = nil }`
  - [ ] Subtask: Trigger batch processing: `embeddingCoordinator.generateEmbeddings(for: allVideos)`
  - [ ] Subtask: Show progress UI during regeneration
  - [ ] Subtask: Use case: After updating embedding model or OCR settings

**Phase 7: Persistence (AC: 8)**
- [ ] **Task 7.4.8:** Verify embeddings persist across app restarts
  - [ ] Subtask: Ensure `VideoItem.embedding` is stored in SwiftData (not transient)
  - [ ] Subtask: Test: Generate embeddings, quit app, relaunch, verify embeddings still present
  - [ ] Subtask: Check SwiftData schema: `embedding` should be `.transformable` or `[Float]` array
  - [ ] Subtask: Handle migration if embedding property added later (schema v2)
  - [ ] Subtask: Log on startup: "Loaded \(videosWithEmbeddings.count) videos with embeddings"

**Phase 8: Testing & Validation**
- [ ] **Task 7.4.9:** Write comprehensive tests
  - [ ] Subtask: Create `MyToobTests/AI/EmbeddingCoordinatorTests.swift`
  - [ ] Subtask: Test: `testBatchProcessing()` - verify 10 videos processed in parallel
  - [ ] Subtask: Test: `testProgressTracking()` - progress updates correctly
  - [ ] Subtask: Test: `testErrorHandling()` - failed videos added to retry queue
  - [ ] Subtask: Test: `testManualRegeneration()` - all embeddings cleared and regenerated
  - [ ] Subtask: Test: `testPersistence()` - embeddings saved and loaded correctly
  - [ ] Subtask: Integration test: Import 20 videos, verify embeddings generated for all
  - [ ] Subtask: Performance test: 100 videos embedded in <30 seconds (with 10-parallel processing)

**Dev Notes:**
- **Files to Create:** `MyToob/AI/EmbeddingCoordinator.swift`, `MyToobTests/AI/EmbeddingCoordinatorTests.swift`
- **Files to Modify:** `MyToob/Models/VideoItem.swift` (ensure `embedding` property exists), Settings UI
- **Batch Size:** 10 parallel tasks balances performance and resource usage (Core ML can handle multiple concurrent predictions)
- **Background Processing:** Use `.utility` QoS to avoid blocking user interactions
- **Error Recovery:** Retry logic handles transient Core ML errors (e.g., resource contention)
- **Progress UI:** Show in toolbar or Settings, non-blocking, dismissible
- **Startup Check:** On app launch, check for videos missing embeddings and offer to generate

**Testing Requirements:**
- Unit tests for batch processing, progress tracking, error handling (5 tests in `EmbeddingCoordinatorTests`)
- Integration test: End-to-end embedding generation for YouTube and local videos
- Performance test: 100 videos embedded in <30 seconds (10 concurrent, ~7ms per embedding = ~70ms per batch)
- Persistence test: Verify embeddings survive app restart
- UI test: Verify progress indicator updates correctly


---

## Story 7.5: HNSW Vector Index Construction

**Status:** Not Started  
**Dependencies:** Story 7.4 (embeddings must be generated before indexing)  
**Epic:** 7 - On-Device AI Embeddings & Vector Index

**Full Acceptance Criteria:**
1. HNSW index implementation integrated (use existing Swift/C++ library or implement custom)
2. Index built from all `VideoItem.embedding` vectors on app launch (if embeddings exist)
3. Index parameters tuned: M=16 (connections per layer), ef_construction=200 (construction search depth)
4. Index stored on disk for persistence: `~/Library/Application Support/MyToob/vector-index.bin`
5. Index incrementally updated when new videos added (no full rebuild required)
6. Index rebuild time measured: <5 seconds for 1,000 videos on M1 Mac (target met)
7. Query interface: `VectorIndex.search(query: [Float], k: Int) async -> [VideoItem]` returns top-k nearest neighbors
8. Unit tests verify index returns correct neighbors (known similar vectors)

**Implementation Phases:**

**Phase 1: HNSW Library Selection & Integration (AC: 1)**
- [ ] **Task 7.5.1:** Research and select HNSW library
  - [ ] Subtask: Evaluate options: hnswlib (C++), Swift HNSW implementations, custom implementation
  - [ ] Subtask: Recommended: Use hnswlib (C++ library) with Swift bridging header
  - [ ] Subtask: Add hnswlib to project: Download from GitHub (nmslib/hnswlib)
  - [ ] Subtask: Create bridging header: `MyToob-Bridging-Header.h` with `#include "hnswlib/hnswlib.h"`
  - [ ] Subtask: Add C++ compatibility: Set "Objective-C Bridging Header" in build settings
  - [ ] Subtask: Alternative: Create Swift wrapper around Accelerate framework for basic kNN (slower but no C++ dependency)
  - [ ] Subtask: Test library integration: Build project, verify C++ code compiles

- [ ] **Task 7.5.2:** Create Swift wrapper for HNSW index
  - [ ] Subtask: Create `MyToob/AI/VectorIndex.swift` with `@Observable class VectorIndex`
  - [ ] Subtask: Add property: `private var hnswIndex: OpaquePointer?` (pointer to C++ HNSW index)
  - [ ] Subtask: Define index parameters: `let dimension = 384`, `let maxElements = 100_000`, `let M = 16`, `let efConstruction = 200`
  - [ ] Subtask: Implement initializer: `init(dimension: Int, maxElements: Int)`
  - [ ] Subtask: Create index in C++: `hnswIndex = hnsw_create_index(dimension, maxElements, M, efConstruction)`

**Phase 2: Index Construction (AC: 2, 3)**
- [ ] **Task 7.5.3:** Build index from existing embeddings
  - [ ] Subtask: Create `buildIndex(from videos: [VideoItem]) async` function
  - [ ] Subtask: Filter videos with embeddings: `let videosWithEmbeddings = videos.filter { $0.embedding != nil }`
  - [ ] Subtask: Add vectors to index: `for (index, video) in videosWithEmbeddings.enumerated() { hnsw_add_point(hnswIndex, video.embedding!, UInt64(index)) }`
  - [ ] Subtask: Store mapping: `private var indexToVideoID: [Int: String] = [:]` (index position → videoID)
  - [ ] Subtask: Update mapping: `indexToVideoID[index] = video.id`
  - [ ] Subtask: Run on background queue: `await Task.detached { ... }.value`
  - [ ] Subtask: Log progress: "Building HNSW index: \(processed)/\(total) vectors..."

- [ ] **Task 7.5.4:** Index initialization on app launch
  - [ ] Subtask: In `MyToobApp` or app coordinator, check if index file exists on disk
  - [ ] Subtask: If index file exists, load from disk (Phase 3)
  - [ ] Subtask: If no index file, build from scratch: `await vectorIndex.buildIndex(from: allVideos)`
  - [ ] Subtask: Show progress UI during initial index build (can take 5-10 seconds for large libraries)
  - [ ] Subtask: Log completion: "HNSW index built with \(videosWithEmbeddings.count) vectors"

**Phase 3: Index Persistence (AC: 4)**
- [ ] **Task 7.5.5:** Save index to disk
  - [ ] Subtask: Define save path: `let indexPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("MyToob/vector-index.bin")`
  - [ ] Subtask: Create directory if needed: `try FileManager.default.createDirectory(at: indexPath.deletingLastPathComponent(), withIntermediateDirectories: true)`
  - [ ] Subtask: Call C++ save function: `hnsw_save_index(hnswIndex, indexPath.path)`
  - [ ] Subtask: Save mapping separately: serialize `indexToVideoID` as JSON to `vector-index-mapping.json`
  - [ ] Subtask: Implement `saveIndex()` function: called after index build or update
  - [ ] Subtask: Auto-save on app termination: hook into `NSApplication.willTerminateNotification`

- [ ] **Task 7.5.6:** Load index from disk
  - [ ] Subtask: Check if index file exists: `FileManager.default.fileExists(atPath: indexPath.path)`
  - [ ] Subtask: Load C++ index: `hnswIndex = hnsw_load_index(indexPath.path, dimension, maxElements)`
  - [ ] Subtask: Load mapping: deserialize `indexToVideoID` from JSON
  - [ ] Subtask: Verify index integrity: check loaded element count matches mapping count
  - [ ] Subtask: Handle load failures: if corrupted, rebuild index from embeddings
  - [ ] Subtask: Log on successful load: "Loaded HNSW index with \(elementCount) vectors"

**Phase 4: Incremental Updates (AC: 5)**
- [ ] **Task 7.5.7:** Add new vectors to existing index
  - [ ] Subtask: Create `addVector(_ embedding: [Float], for videoID: String)` function
  - [ ] Subtask: Get next index position: `let nextIndex = indexToVideoID.count`
  - [ ] Subtask: Add to HNSW index: `hnsw_add_point(hnswIndex, embedding, UInt64(nextIndex))`
  - [ ] Subtask: Update mapping: `indexToVideoID[nextIndex] = videoID`
  - [ ] Subtask: Save updated index to disk (incremental save)
  - [ ] Subtask: Call from `EmbeddingCoordinator` after embedding generation: `vectorIndex.addVector(embedding, for: video.id)`

- [ ] **Task 7.5.8:** Handle video deletions
  - [ ] Subtask: Create `removeVector(for videoID: String)` function (optional, HNSW doesn't support efficient deletion)
  - [ ] Subtask: Mark vector as deleted in mapping: `deletedVideoIDs.insert(videoID)`
  - [ ] Subtask: Filter deleted videos from search results
  - [ ] Subtask: Rebuild index periodically to compact (e.g., monthly, or when >10% videos deleted)

**Phase 5: Query Interface (AC: 7)**
- [ ] **Task 7.5.9:** Implement vector search
  - [ ] Subtask: Create `search(query: [Float], k: Int) async -> [VideoItem]` function
  - [ ] Subtask: Validate query dimension: `assert(query.count == dimension)`
  - [ ] Subtask: Call HNSW search: `let results = hnsw_search_knn(hnswIndex, query, k)` (returns array of indices and distances)
  - [ ] Subtask: Map indices to video IDs: `let videoIDs = results.indices.compactMap { indexToVideoID[$0] }`
  - [ ] Subtask: Fetch videos from SwiftData: `let videos = try modelContext.fetch(FetchDescriptor<VideoItem>(predicate: #Predicate { videoIDs.contains($0.id) }))`
  - [ ] Subtask: Sort by search result order (HNSW returns sorted by similarity)
  - [ ] Subtask: Return video array: `return sortedVideos`
  - [ ] Subtask: Run on background queue to avoid blocking UI

**Phase 6: Performance Measurement (AC: 6)**
- [ ] **Task 7.5.10:** Benchmark index performance
  - [ ] Subtask: Create test dataset: 1,000 videos with random embeddings
  - [ ] Subtask: Measure index build time: `let start = Date(); await buildIndex(from: videos); let duration = Date().timeIntervalSince(start)`
  - [ ] Subtask: Log result: "Index built in \(duration) seconds for \(videos.count) vectors"
  - [ ] Subtask: Verify <5 seconds for 1,000 videos on M1 Mac (AC target)
  - [ ] Subtask: If target not met, tune parameters: reduce `efConstruction` to 100, or `M` to 8
  - [ ] Subtask: Measure query time: <50ms for top-20 search (verified in Story 7.6)
  - [ ] Subtask: Document performance in `docs/AI_MODELS.md`: "Index build: 3.2s (1k videos), 15s (5k videos)"

**Phase 7: Unit Testing (AC: 8)**
- [ ] **Task 7.5.11:** Write comprehensive index tests
  - [ ] Subtask: Create `MyToobTests/AI/VectorIndexTests.swift`
  - [ ] Subtask: Test: `testIndexBuild()` - build index with 100 test vectors
  - [ ] Subtask: Test: `testIndexPersistence()` - save and load index from disk
  - [ ] Subtask: Test: `testIncrementalUpdate()` - add new vector to existing index
  - [ ] Subtask: Test: `testSearchAccuracy()` - known similar vectors returned correctly
  - [ ] Subtask: Create known test vectors: `vec1 = [1, 0, 0, ...]`, `vec2 = [0.9, 0.1, ...]` (similar), `vec3 = [0, 0, 1, ...]` (dissimilar)
  - [ ] Subtask: Test: Search for `vec1`, verify `vec2` in top-5 results, `vec3` not in top-5
  - [ ] Subtask: Test: `testPerformance()` - index build completes in <10 seconds (with margin)
  - [ ] Subtask: Run all tests and verify 100% pass rate

**Phase 8: Integration & Documentation**
- [ ] **Task 7.5.12:** Integrate with app lifecycle
  - [ ] Subtask: Inject `VectorIndex` into SwiftUI environment: `.environmentObject(vectorIndex)`
  - [ ] Subtask: Initialize on app launch: `let vectorIndex = VectorIndex(dimension: 384, maxElements: 100_000)`
  - [ ] Subtask: Load or build index: `await vectorIndex.loadOrBuildIndex(from: allVideos)`
  - [ ] Subtask: Hook into embedding generation: auto-update index when new embeddings created

- [ ] **Task 7.5.13:** Documentation
  - [ ] Subtask: Document HNSW parameters in `docs/AI_MODELS.md`: M, efConstruction, performance trade-offs
  - [ ] Subtask: Add code comments explaining index lifecycle (build → save → load → update)
  - [ ] Subtask: Document index file format and location
  - [ ] Subtask: Include troubleshooting: "If index is corrupted, delete vector-index.bin to rebuild"

**Dev Notes:**
- **Files to Create:** `MyToob/AI/VectorIndex.swift`, `MyToob-Bridging-Header.h`, `MyToobTests/AI/VectorIndexTests.swift`
- **Library:** hnswlib (C++) recommended for performance, or use Swift Accelerate for simpler integration
- **Parameters:** M=16 and efConstruction=200 are good defaults (balance between accuracy and speed)
- **Index Size:** ~4 KB per vector (384 floats × 4 bytes + HNSW graph overhead) ≈ 4 MB for 1,000 videos
- **Incremental Updates:** HNSW supports adding vectors efficiently, but not deletion (rebuild needed for compaction)
- **Query Performance:** HNSW is extremely fast (sub-millisecond for top-k search with k=20)
- **Mapping:** `indexToVideoID` must be persisted alongside index to resolve search results to videos

**Testing Requirements:**
- Unit tests for index build, save/load, incremental update, search accuracy (7 tests in `VectorIndexTests`)
- Performance benchmarks: index build time (<5s for 1k videos), query time (<50ms in Story 7.6)
- Integration test: Build index from real embeddings, verify search returns relevant videos
- Persistence test: Save index, restart app, verify index loaded correctly

---

## Story 7.6: Vector Similarity Search API

**Status:** Not Started  
**Dependencies:** Story 7.5 (HNSW index must be implemented)  
**Epic:** 7 - On-Device AI Embeddings & Vector Index

**Full Acceptance Criteria:**
1. User types query in search bar: "swift concurrency tutorials"
2. Query text converted to embedding using same Core ML model
3. Query embedding used to search HNSW index for top-20 nearest neighbors
4. Results sorted by cosine similarity score (higher = more similar)
5. Search completes in <50ms (P95 latency target met)
6. Results displayed in main content area with similarity scores (optional: show % match)
7. Empty results handled: "No similar videos found. Try a different query."
8. UI test verifies search returns expected results for sample queries

**Implementation Phases:**

**Phase 1: Search Bar UI (AC: 1)**
- [ ] **Task 7.6.1:** Create search interface
  - [ ] Subtask: Add search bar to toolbar in `ContentView`: `@State private var searchQuery = ""`
  - [ ] Subtask: Use `TextField` with search style: `TextField("Search videos...", text: $searchQuery)`
  - [ ] Subtask: Add `.onSubmit` modifier: trigger search when user presses Enter
  - [ ] Subtask: Add search icon button: `Button(action: { performSearch() }) { Image(systemName: "magnifyingglass") }`
  - [ ] Subtask: Add clear button: show "X" when `searchQuery` is not empty
  - [ ] Subtask: Optional: Add search suggestions dropdown (autocomplete from past queries)

**Phase 2: Query Embedding Generation (AC: 2)**
- [ ] **Task 7.6.2:** Convert search query to embedding
  - [ ] Subtask: Create `performSearch()` async function
  - [ ] Subtask: Get query text: `let query = searchQuery.trimmingCharacters(in: .whitespaces)`
  - [ ] Subtask: Validate query: if empty, clear results and return
  - [ ] Subtask: Generate embedding: `let queryEmbedding = try await embeddingService.generateEmbedding(text: query)`
  - [ ] Subtask: Handle embedding errors: show user error message if Core ML fails
  - [ ] Subtask: Show loading indicator while embedding generates (typically <10ms, but visible for UX)

**Phase 3: Vector Index Search (AC: 3)**
- [ ] **Task 7.6.3:** Query HNSW index for nearest neighbors
  - [ ] Subtask: Call vector index: `let results = await vectorIndex.search(query: queryEmbedding, k: 20)`
  - [ ] Subtask: Results contain top-20 most similar videos (sorted by similarity)
  - [ ] Subtask: Handle index not ready: if index not built yet, show message "Index is being built..."
  - [ ] Subtask: Handle empty index: if no embeddings exist, prompt user to generate embeddings first

**Phase 4: Similarity Scoring (AC: 4)**
- [ ] **Task 7.6.4:** Calculate and attach similarity scores
  - [ ] Subtask: HNSW returns distances, convert to cosine similarity: `similarity = 1 - distance / 2` (if using L2 distance)
  - [ ] Subtask: Alternative: Store cosine similarity directly by configuring HNSW metric
  - [ ] Subtask: Attach scores to results: `let scoredResults = results.map { (video: $0, score: calculateSimilarity($0.embedding!, queryEmbedding)) }`
  - [ ] Subtask: Sort by score descending: `scoredResults.sort { $0.score > $1.score }`
  - [ ] Subtask: Normalize scores to 0-100% range for display: `let percentage = Int(score * 100)`

- [ ] **Task 7.6.5:** Implement cosine similarity calculation
  - [ ] Subtask: Create `cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float` function
  - [ ] Subtask: Use Accelerate framework for performance: `import Accelerate`
  - [ ] Subtask: Compute dot product: `var dotProduct: Float = 0; vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))`
  - [ ] Subtask: Compute magnitudes: `var magA: Float = 0; vDSP_svesq(a, 1, &magA, vDSP_Length(a.count)); magA = sqrt(magA)`
  - [ ] Subtask: Calculate similarity: `let similarity = dotProduct / (magA * magB)`
  - [ ] Subtask: Return similarity (range -1 to 1, typically 0.3 to 0.9 for relevant results)

**Phase 5: Performance Optimization (AC: 5)**
- [ ] **Task 7.6.6:** Measure and optimize search latency
  - [ ] Subtask: Add performance logging: `let start = Date(); ...; let duration = Date().timeIntervalSince(start)`
  - [ ] Subtask: Log search time: "Search completed in \(duration * 1000)ms"
  - [ ] Subtask: Run benchmark: 100 random queries, calculate P95 latency
  - [ ] Subtask: Verify <50ms P95 (AC target)
  - [ ] Subtask: If target not met, optimize HNSW query parameter: increase `ef_search` (default 50, try 100)
  - [ ] Subtask: Profile with Instruments: identify bottlenecks (embedding generation, index search, SwiftData fetch)
  - [ ] Subtask: Document performance: "Average search: 12ms (embedding 7ms + index 3ms + fetch 2ms)"

**Phase 6: Results Display (AC: 6)**
- [ ] **Task 7.6.7:** Display search results in UI
  - [ ] Subtask: Add `@State private var searchResults: [(VideoItem, score: Float)] = []` in `ContentView`
  - [ ] Subtask: Update results after search: `searchResults = scoredResults`
  - [ ] Subtask: Display in list: `ForEach(searchResults, id: \.0.id) { video, score in ... }`
  - [ ] Subtask: Show video thumbnail, title, and similarity score: `Text("\(Int(score * 100))% match")`
  - [ ] Subtask: Optional: Color-code scores (green >80%, yellow 60-80%, gray <60%)
  - [ ] Subtask: Tapping result navigates to video detail view or starts playback
  - [ ] Subtask: Clear results when search query cleared

**Phase 7: Empty State Handling (AC: 7)**
- [ ] **Task 7.6.8:** Handle no results scenario
  - [ ] Subtask: Check if results empty: `if searchResults.isEmpty { ... }`
  - [ ] Subtask: Show empty state message: "No similar videos found. Try a different query."
  - [ ] Subtask: Suggest alternatives: "Tip: Use broader terms or add more videos to your library"
  - [ ] Subtask: Optional: Show related searches or popular queries
  - [ ] Subtask: Test with query that has no matches (e.g., "xyzabc123" gibberish)

**Phase 8: UI Testing (AC: 8)**
- [ ] **Task 7.6.9:** Write UI tests for search
  - [ ] Subtask: Create `MyToobUITests/SearchUITests.swift`
  - [ ] Subtask: Test: `testBasicSearch()` - enter query, verify results appear
  - [ ] Subtask: Create seed data: 10 videos with known embeddings and topics
  - [ ] Subtask: Test query: "swift programming" should return videos with "Swift" in title
  - [ ] Subtask: Test: `testEmptyResults()` - query with no matches shows empty state
  - [ ] Subtask: Test: `testSearchClearing()` - clearing query clears results
  - [ ] Subtask: Test: `testResultSelection()` - tapping result navigates to video
  - [ ] Subtask: Test: `testPerformance()` - search completes in <100ms (UI-visible latency)
  - [ ] Subtask: Run all UI tests and verify pass rate

**Phase 9: Advanced Search Features (Optional Enhancements)**
- [ ] **Task 7.6.10:** Add search filters and refinements
  - [ ] Subtask: Filter by video source: "YouTube only" or "Local files only"
  - [ ] Subtask: Filter by date range: "Last week", "Last month"
  - [ ] Subtask: Filter by duration: "Short (<5 min)", "Medium (5-20 min)", "Long (>20 min)"
  - [ ] Subtask: Combine vector search with keyword search (hybrid search covered in Epic 9)
  - [ ] Subtask: Save search queries for history: store in UserDefaults or SwiftData

- [ ] **Task 7.6.11:** Search analytics and improvements
  - [ ] Subtask: Track search queries (locally, privacy-first): log query + result count
  - [ ] Subtask: Identify failed searches (queries with 0 results)
  - [ ] Subtask: Use failed searches to improve embeddings or suggest content gaps
  - [ ] Subtask: Add telemetry (optional, opt-in): search latency, result click-through rate

**Dev Notes:**
- **Files to Create:** `MyToobUITests/SearchUITests.swift`
- **Files to Modify:** `MyToob/ContentView.swift` (add search bar and results view)
- **Performance:** Total search latency <50ms = embedding (7ms) + HNSW search (3-5ms) + SwiftData fetch (5-10ms) + UI update (5ms)
- **Cosine Similarity:** Use Accelerate framework (`vDSP_dotpr`, `vDSP_svesq`) for fast vector operations
- **HNSW Parameter:** `ef_search` controls search quality vs. speed trade-off (default 50, increase for better accuracy)
- **UI/UX:** Show similarity scores to help users understand relevance, but make it optional (can hide in settings)
- **Search History:** Store recent queries for autocomplete and analysis (local only, no cloud)
- **Empty Results:** Always provide helpful feedback, never just blank screen

**Testing Requirements:**
- UI tests for search flow (7 tests in `SearchUITests`)
- Performance test: verify search completes in <50ms P95 latency
- Integration test: End-to-end search with real embeddings and HNSW index
- Accuracy test: Known query returns expected videos (e.g., "swift" returns Swift-related content)
- Edge case tests: empty query, very long query, special characters, no results

---

**Epic 7 Summary:**
All 6 stories in Epic 7 - On-Device AI Embeddings & Vector Index have been fully expanded with detailed task breakdowns. This epic establishes the foundational AI capabilities for MyToob, enabling semantic search and intelligent content discovery without cloud dependencies.

**Key Deliverables:**
- Core ML sentence embedding model (384-dim, 8-bit quantized)
- Text preparation pipeline (metadata + OCR text)
- Vision framework OCR for thumbnail text extraction
- Batch embedding generation with progress tracking
- HNSW vector index for fast similarity search
- Vector search API with <50ms query latency

**Next Epic:** Epic 8 - AI Clustering & Auto-Collections


---

### Epic 8: AI Clustering & Auto-Collections (6 stories)

## Story 8.1: kNN Graph Construction from Embeddings

**Status:** Not Started  
**Dependencies:** Story 7.5 (HNSW index must be available for nearest neighbor queries)  
**Epic:** 8 - AI Clustering & Auto-Collections

**Full Acceptance Criteria:**
1. For each video embedding, find k=10 nearest neighbors using HNSW index
2. Construct undirected graph: nodes = videos, edges = k-nearest-neighbor connections
3. Edge weights = cosine similarity between embeddings (higher weight = more similar)
4. Graph stored in memory (adjacency list representation)
5. Graph construction time measured: <2 seconds for 1,000 videos on M1 Mac
6. Graph updated incrementally when new videos added (add new node + edges, no full rebuild)
7. Unit tests verify graph structure (degree distribution, connectivity)

**Implementation Phases:**

**Phase 1: Graph Data Structure Setup (AC: 2, 4)**
- [ ] **Task 8.1.1:** Create graph representation
  - [ ] Subtask: Create `MyToob/AI/Clustering/Graph.swift` with `struct Graph`
  - [ ] Subtask: Define node: `struct Node { let id: String; var neighbors: [Edge] }` (id = videoID)
  - [ ] Subtask: Define edge: `struct Edge { let to: String; let weight: Float }` (to = neighbor videoID, weight = similarity)
  - [ ] Subtask: Store graph as adjacency list: `var adjacencyList: [String: [Edge]] = [:]` (videoID → edges)
  - [ ] Subtask: Add convenience methods: `addNode(_ videoID: String)`, `addEdge(from: String, to: String, weight: Float)`
  - [ ] Subtask: Ensure undirected: when adding edge A→B, also add B→A

- [ ] **Task 8.1.2:** Graph initialization
  - [ ] Subtask: Create `initializeGraph(from videos: [VideoItem])` function
  - [ ] Subtask: Filter videos with embeddings: `let videosWithEmbeddings = videos.filter { $0.embedding != nil }`
  - [ ] Subtask: Create nodes for all videos: `for video in videosWithEmbeddings { graph.addNode(video.id) }`
  - [ ] Subtask: Prepare for edge construction (Phase 2)

**Phase 2: kNN Edge Construction (AC: 1, 3)**
- [ ] **Task 8.1.3:** Find k-nearest neighbors for each video
  - [ ] Subtask: Define k parameter: `let k = 10` (find 10 nearest neighbors per video)
  - [ ] Subtask: For each video, query HNSW index: `let neighbors = await vectorIndex.search(query: video.embedding!, k: k + 1)` (+1 to exclude self)
  - [ ] Subtask: Filter out self: `let filteredNeighbors = neighbors.filter { $0.id != video.id }.prefix(k)`
  - [ ] Subtask: Calculate similarity for each neighbor: `let similarity = cosineSimilarity(video.embedding!, neighbor.embedding!)`
  - [ ] Subtask: Add edges: `graph.addEdge(from: video.id, to: neighbor.id, weight: similarity)`
  - [ ] Subtask: Ensure undirected graph: reciprocal edges added automatically in `addEdge`

- [ ] **Task 8.1.4:** Batch processing for graph construction
  - [ ] Subtask: Process videos in batches to show progress: `let batchSize = 50`
  - [ ] Subtask: Update progress UI: "Building kNN graph: \(processed)/\(total) videos..."
  - [ ] Subtask: Run on background queue: `await Task.detached { ... }.value`
  - [ ] Subtask: Log completion: "kNN graph built with \(nodeCount) nodes and \(edgeCount) edges"

**Phase 3: Graph Storage & Serialization (AC: 4)**
- [ ] **Task 8.1.5:** Implement in-memory graph storage
  - [ ] Subtask: Store graph in coordinator: `@Observable class ClusteringCoordinator { var graph: Graph? }`
  - [ ] Subtask: Load graph on app launch: `await clusteringCoordinator.buildGraph(from: allVideos)`
  - [ ] Subtask: Keep graph in memory for fast access (re-build only when needed)

- [ ] **Task 8.1.6:** Optional: Persist graph to disk for faster startup
  - [ ] Subtask: Serialize graph to JSON: encode adjacency list as `[String: [[String: Any]]]` (videoID → neighbors array)
  - [ ] Subtask: Save to file: `~/Library/Application Support/MyToob/knn-graph.json`
  - [ ] Subtask: Load graph on startup: deserialize JSON to `Graph` struct
  - [ ] Subtask: Validate loaded graph: check if all videoIDs still exist in SwiftData
  - [ ] Subtask: Rebuild graph if validation fails or embeddings changed

**Phase 4: Incremental Graph Updates (AC: 6)**
- [ ] **Task 8.1.7:** Add new videos to existing graph
  - [ ] Subtask: Create `addVideoToGraph(_ video: VideoItem) async` function
  - [ ] Subtask: Add new node: `graph.addNode(video.id)`
  - [ ] Subtask: Find k-nearest neighbors for new video: `let neighbors = await vectorIndex.search(query: video.embedding!, k: 10)`
  - [ ] Subtask: Add edges to neighbors: `for neighbor in neighbors { graph.addEdge(from: video.id, to: neighbor.id, weight: similarity) }`
  - [ ] Subtask: Update existing nodes: for each neighbor, check if new video is in their top-k (re-query if needed)
  - [ ] Subtask: Call from `EmbeddingCoordinator` after embedding generation

- [ ] **Task 8.1.8:** Remove videos from graph
  - [ ] Subtask: Create `removeVideoFromGraph(_ videoID: String)` function
  - [ ] Subtask: Remove node: `graph.adjacencyList.removeValue(forKey: videoID)`
  - [ ] Subtask: Remove all edges to this video: iterate through all nodes, remove edges pointing to videoID
  - [ ] Subtask: Call when user deletes video from library

**Phase 5: Performance Measurement (AC: 5)**
- [ ] **Task 8.1.9:** Benchmark graph construction
  - [ ] Subtask: Measure graph build time: `let start = Date(); await buildGraph(from: videos); let duration = Date().timeIntervalSince(start)`
  - [ ] Subtask: Log result: "kNN graph built in \(duration) seconds for \(videos.count) videos"
  - [ ] Subtask: Verify <2 seconds for 1,000 videos on M1 Mac (AC target)
  - [ ] Subtask: Profile bottlenecks: kNN queries (most expensive), edge additions, similarity calculations
  - [ ] Subtask: Optimize: batch kNN queries, use Accelerate for similarity calculations
  - [ ] Subtask: Document performance: "Graph build: 1.8s (1k videos), 9s (5k videos)"

**Phase 6: Graph Analytics (AC: 7)**
- [ ] **Task 8.1.10:** Implement graph statistics
  - [ ] Subtask: Calculate degree distribution: `func degreeDistribution() -> [Int: Int]` (degree → count of nodes with that degree)
  - [ ] Subtask: Calculate average degree: `let avgDegree = Float(totalEdges) / Float(nodeCount)`
  - [ ] Subtask: Check connectivity: verify graph is connected (all nodes reachable from any node)
  - [ ] Subtask: Log stats: "Graph stats: \(nodeCount) nodes, \(edgeCount) edges, avg degree: \(avgDegree)"
  - [ ] Subtask: Detect disconnected components: use BFS/DFS to find isolated subgraphs
  - [ ] Subtask: Warning if graph is fragmented: "Graph has \(componentCount) disconnected components"

**Phase 7: Unit Testing (AC: 7)**
- [ ] **Task 8.1.11:** Write comprehensive graph tests
  - [ ] Subtask: Create `MyToobTests/AI/Clustering/GraphTests.swift`
  - [ ] Subtask: Test: `testGraphConstruction()` - build graph from 50 test vectors
  - [ ] Subtask: Test: `testUndirectedEdges()` - verify A→B implies B→A
  - [ ] Subtask: Test: `testDegreeDistribution()` - all nodes have degree ≈ k (10)
  - [ ] Subtask: Test: `testIncrementalUpdate()` - add new video, verify edges created
  - [ ] Subtask: Test: `testGraphConnectivity()` - verify graph is connected
  - [ ] Subtask: Test: `testEdgeWeights()` - verify similarity scores are correct
  - [ ] Subtask: Test: `testPerformance()` - graph build completes in <5 seconds (with margin)
  - [ ] Subtask: Run all tests and verify 100% pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/AI/Clustering/Graph.swift`, `MyToob/AI/Clustering/ClusteringCoordinator.swift`, `MyToobTests/AI/Clustering/GraphTests.swift`
- **Graph Representation:** Adjacency list is efficient for sparse graphs (k=10 edges per node)
- **kNN Parameter:** k=10 is typical for clustering (balance between local structure and global connectivity)
- **Edge Weights:** Cosine similarity range [0, 1], higher = more similar
- **Undirected Graph:** Essential for community detection algorithms (Leiden/Louvain)
- **Incremental Updates:** Add new nodes efficiently without full rebuild (query kNN for new node only)
- **Graph Persistence:** Optional optimization for faster app startup (graph build takes 1-2s for 1k videos)

**Testing Requirements:**
- Unit tests for graph construction, edge operations, statistics (7 tests in `GraphTests`)
- Performance benchmark: graph build <2 seconds for 1,000 videos
- Integration test: Build graph from real embeddings, verify connectivity and degree distribution
- Incremental update test: Add 10 new videos, verify graph updated correctly

---

## Story 8.2: Leiden Community Detection Algorithm

**Status:** Not Started  
**Dependencies:** Story 8.1 (kNN graph must be constructed first)  
**Epic:** 8 - AI Clustering & Auto-Collections

**Full Acceptance Criteria:**
1. Leiden algorithm implemented (or integrated from existing Swift/C++ library)
2. Algorithm runs on kNN graph to detect communities (clusters)
3. Leiden parameters tuned: resolution=1.0 (controls cluster granularity)
4. Output: assignment of each video to a cluster ID (e.g., video A → cluster 3)
5. Cluster count reasonable: typically 5-20 clusters for 1,000 videos (not too many, not too few)
6. Clustering time measured: <3 seconds for 1,000-video graph on M1 Mac
7. Re-clustering triggered when library grows significantly (e.g., +100 videos)
8. Unit tests verify algorithm produces non-trivial clustering (not all videos in one cluster)

**Implementation Phases:**

**Phase 1: Leiden Algorithm Integration (AC: 1)**
- [ ] **Task 8.2.1:** Research Leiden algorithm implementations
  - [ ] Subtask: Evaluate options: louvain-swift (GitHub), C++ igraph library, python-louvain (convert to Swift)
  - [ ] Subtask: Recommended: Use igraph C library with Swift bridging (mature, well-tested)
  - [ ] Subtask: Alternative: Implement Louvain algorithm first (simpler), then upgrade to Leiden if needed
  - [ ] Subtask: Add igraph to project: Download from https://igraph.org
  - [ ] Subtask: Create bridging header: `MyToob-Bridging-Header.h` with `#include <igraph/igraph.h>`
  - [ ] Subtask: Link igraph library in build settings

- [ ] **Task 8.2.2:** Create Swift wrapper for Leiden/Louvain
  - [ ] Subtask: Create `MyToob/AI/Clustering/LeidenClustering.swift` with `class LeidenClustering`
  - [ ] Subtask: Implement `detectCommunities(graph: Graph, resolution: Float) -> [String: Int]` (videoID → clusterID)
  - [ ] Subtask: Convert Swift `Graph` to igraph format: `igraph_t` C struct
  - [ ] Subtask: Call Leiden algorithm: `igraph_community_leiden(graph, NULL, resolution, ...)`
  - [ ] Subtask: Extract cluster assignments from igraph result
  - [ ] Subtask: Convert back to Swift dictionary: `[String: Int]` (videoID → clusterID)

**Phase 2: Algorithm Execution (AC: 2)**
- [ ] **Task 8.2.3:** Run Leiden algorithm on kNN graph
  - [ ] Subtask: In `ClusteringCoordinator`, add `runClustering() async -> [String: Int]` function
  - [ ] Subtask: Get graph from coordinator: `let graph = self.graph`
  - [ ] Subtask: Run Leiden: `let assignments = LeidenClustering.detectCommunities(graph: graph, resolution: 1.0)`
  - [ ] Subtask: Run on background queue: `await Task.detached { ... }.value`
  - [ ] Subtask: Log progress: "Running community detection..."
  - [ ] Subtask: Return cluster assignments

**Phase 3: Parameter Tuning (AC: 3, 5)**
- [ ] **Task 8.2.4:** Tune resolution parameter
  - [ ] Subtask: Default resolution: `let resolution: Float = 1.0`
  - [ ] Subtask: Experiment with resolution values: 0.5 (fewer clusters), 1.0 (moderate), 2.0 (more clusters)
  - [ ] Subtask: Measure cluster count for each resolution: "Resolution 1.0 → \(clusterCount) clusters"
  - [ ] Subtask: Verify cluster count reasonable: typically 5-20 clusters for 1,000 videos
  - [ ] Subtask: If cluster count too high (>30), decrease resolution
  - [ ] Subtask: If cluster count too low (<5), increase resolution
  - [ ] Subtask: Add resolution as user setting (advanced): Settings > AI > Cluster Granularity (slider)

- [ ] **Task 8.2.5:** Validate cluster quality
  - [ ] Subtask: Calculate modularity: measure of clustering quality (higher = better)
  - [ ] Subtask: Use igraph modularity function: `igraph_modularity(graph, membership, &modularity)`
  - [ ] Subtask: Log modularity: "Clustering modularity: \(modularity)" (typical range 0.3-0.7)
  - [ ] Subtask: Warn if modularity <0.2: "Low clustering quality—consider adjusting resolution"
  - [ ] Subtask: Check cluster size distribution: avoid one giant cluster + tiny clusters
  - [ ] Subtask: Log distribution: "Cluster sizes: \(sortedSizes)" (e.g., [250, 180, 150, ...])

**Phase 4: Cluster Assignment Storage (AC: 4)**
- [ ] **Task 8.2.6:** Store cluster assignments in VideoItem
  - [ ] Subtask: Add property to `VideoItem`: `@Attribute var clusterID: Int?`
  - [ ] Subtask: Update VideoItems with cluster assignments: `for (videoID, clusterID) in assignments { video.clusterID = clusterID }`
  - [ ] Subtask: Save to SwiftData: `try modelContext.save()`
  - [ ] Subtask: Query videos by cluster: `FetchDescriptor<VideoItem>(predicate: #Predicate { $0.clusterID == targetClusterID })`

**Phase 5: Performance Measurement (AC: 6)**
- [ ] **Task 8.2.7:** Benchmark clustering performance
  - [ ] Subtask: Measure clustering time: `let start = Date(); let assignments = await runClustering(); let duration = Date().timeIntervalSince(start)`
  - [ ] Subtask: Log result: "Clustering completed in \(duration) seconds for \(graph.nodeCount) videos"
  - [ ] Subtask: Verify <3 seconds for 1,000 videos on M1 Mac (AC target)
  - [ ] Subtask: Profile bottlenecks: Leiden algorithm (most expensive), graph conversion
  - [ ] Subtask: If target not met, optimize: use faster Louvain algorithm instead of Leiden
  - [ ] Subtask: Document performance: "Clustering: 2.5s (1k videos), 12s (5k videos)"

**Phase 6: Re-Clustering Triggers (AC: 7)**
- [ ] **Task 8.2.8:** Implement re-clustering logic
  - [ ] Subtask: Track last clustering size: `@AppStorage("lastClusteringVideoCount") var lastCount = 0`
  - [ ] Subtask: On app launch, check if re-clustering needed: `if currentCount - lastCount > 100 { ... }`
  - [ ] Subtask: Trigger re-clustering: `await clusteringCoordinator.runClustering()`
  - [ ] Subtask: Update last clustering count: `lastCount = currentCount`
  - [ ] Subtask: Show notification: "Re-clustering your library..." (non-blocking)
  - [ ] Subtask: Optional: Ask user before re-clustering (confirmation dialog)

- [ ] **Task 8.2.9:** Manual re-clustering action
  - [ ] Subtask: Add "Re-cluster Now" button in Settings > AI
  - [ ] Subtask: On click, show confirmation: "Re-clustering will reorganize your Smart Collections. Continue?"
  - [ ] Subtask: Run clustering on background queue
  - [ ] Subtask: Show progress UI: "Re-clustering in progress..."
  - [ ] Subtask: On completion, update cluster labels (Story 8.3) and UI

**Phase 7: Unit Testing (AC: 8)**
- [ ] **Task 8.2.10:** Write comprehensive clustering tests
  - [ ] Subtask: Create `MyToobTests/AI/Clustering/LeidenClusteringTests.swift`
  - [ ] Subtask: Test: `testClusteringNonTrivial()` - verify not all videos in one cluster
  - [ ] Subtask: Test: `testClusterCount()` - verify cluster count is reasonable (5-20 for 1k videos)
  - [ ] Subtask: Test: `testModularity()` - verify modularity >0.2
  - [ ] Subtask: Test: `testResolutionParameter()` - higher resolution → more clusters
  - [ ] Subtask: Test: `testClusterAssignments()` - all videos assigned to a cluster
  - [ ] Subtask: Test: `testPerformance()` - clustering completes in <5 seconds (with margin)
  - [ ] Subtask: Integration test: Run clustering on real graph with 100 videos
  - [ ] Subtask: Run all tests and verify 100% pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/AI/Clustering/LeidenClustering.swift`, `MyToobTests/AI/Clustering/LeidenClusteringTests.swift`
- **Files to Modify:** `MyToob/Models/VideoItem.swift` (add `clusterID` property)
- **Algorithm:** Leiden is improvement over Louvain (better quality, similar speed)
- **Resolution Parameter:** Controls trade-off between few large clusters vs. many small clusters
- **Modularity:** Measure of clustering quality (range -0.5 to 1.0, typical 0.3-0.7 for good clustering)
- **Re-Clustering:** Only re-cluster when library grows significantly (avoids constant churn in Smart Collections)
- **Library:** igraph provides battle-tested implementations of Leiden, Louvain, and modularity calculation

**Testing Requirements:**
- Unit tests for clustering algorithm, modularity, cluster count (7 tests in `LeidenClusteringTests`)
- Performance benchmark: clustering <3 seconds for 1,000 videos
- Integration test: End-to-end clustering with real kNN graph
- Quality test: Verify modularity >0.2 and reasonable cluster count


---

## Story 8.3: Cluster Centroid Computation & Label Generation

**Status:** Not Started  
**Dependencies:** Story 8.2 (cluster assignments must exist)  
**Epic:** 8 - AI Clustering & Auto-Collections

**Full Acceptance Criteria:**
1. For each cluster, compute centroid: average of all member video embeddings
2. Extract keywords from member video titles using TF-IDF or frequency analysis
3. Select top 3-5 keywords as cluster label (e.g., "Swift, Concurrency, Async")
4. Label formatted: "Swift Concurrency" (title case, comma-separated keywords)
5. Labels stored in `ClusterLabel` model with `clusterID`, `label`, `centroid`, `itemCount`
6. Labels unique (no duplicate labels across clusters—append disambiguation if needed)
7. "Rename Cluster" action allows user to override auto-generated label
8. UI test verifies cluster labels are generated correctly for sample data

**Implementation Phases:**

**Phase 1: Centroid Computation (AC: 1)**
- [ ] **Task 8.3.1:** Calculate cluster centroids
  - [ ] Subtask: Create `computeCentroid(for clusterID: Int, videos: [VideoItem]) -> [Float]` function
  - [ ] Subtask: Collect embeddings: `let embeddings = videos.compactMap { $0.embedding }`
  - [ ] Subtask: Initialize centroid: `var centroid = [Float](repeating: 0.0, count: 384)`
  - [ ] Subtask: Sum embeddings: `for embedding in embeddings { for i in 0..<384 { centroid[i] += embedding[i] } }`
  - [ ] Subtask: Average: `centroid = centroid.map { $0 / Float(embeddings.count) }`
  - [ ] Subtask: Normalize centroid (optional, for cosine similarity): `let magnitude = sqrt(centroid.reduce(0) { $0 + $1 * $1 }); centroid = centroid.map { $0 / magnitude }`
  - [ ] Subtask: Return centroid vector

- [ ] **Task 8.3.2:** Store centroids in ClusterLabel
  - [ ] Subtask: Verify `ClusterLabel.centroid` property exists: `@Attribute var centroid: [Float]?`
  - [ ] Subtask: Save centroid: `clusterLabel.centroid = computeCentroid(for: clusterID, videos: clusterVideos)`

**Phase 2: Keyword Extraction (AC: 2)**
- [ ] **Task 8.3.3:** Implement TF-IDF keyword extraction
  - [ ] Subtask: Create `MyToob/AI/Clustering/KeywordExtractor.swift` with `class KeywordExtractor`
  - [ ] Subtask: Collect all titles in cluster: `let titles = videos.map { $0.title }`
  - [ ] Subtask: Tokenize titles: split into words, lowercase, remove stopwords (e.g., "the", "a", "and")
  - [ ] Subtask: Calculate term frequency (TF): count of each word in cluster
  - [ ] Subtask: Calculate document frequency (DF): count of clusters containing each word (across all clusters)
  - [ ] Subtask: Calculate TF-IDF: `tfidf = tf * log(totalClusters / df)`
  - [ ] Subtask: Sort words by TF-IDF score descending
  - [ ] Subtask: Select top 3-5 keywords: `let topKeywords = sortedWords.prefix(5)`

- [ ] **Task 8.3.4:** Alternative: Simple frequency-based extraction
  - [ ] Subtask: If TF-IDF is complex, use simpler frequency analysis
  - [ ] Subtask: Count word frequency: `let wordCounts = titles.flatMap { $0.split(separator: " ") }.reduce(into: [:]) { $0[String($1), default: 0] += 1 }`
  - [ ] Subtask: Filter stopwords: exclude common words ("the", "a", "in", "on", "to", etc.)
  - [ ] Subtask: Sort by frequency: `let sortedWords = wordCounts.sorted { $0.value > $1.value }`
  - [ ] Subtask: Select top 3-5 keywords: `let topKeywords = sortedWords.prefix(5).map { $0.key }`

**Phase 3: Label Formatting (AC: 3, 4)**
- [ ] **Task 8.3.5:** Format cluster labels
  - [ ] Subtask: Combine keywords: `let keywords = extractKeywords(from: titles)`
  - [ ] Subtask: Title case each keyword: `let titleCased = keywords.map { $0.capitalized }`
  - [ ] Subtask: Join with separator: `let label = titleCased.joined(separator: " ")` (e.g., "Swift Concurrency Async")
  - [ ] Subtask: Alternative format: comma-separated if preferred: `titleCased.joined(separator: ", ")`
  - [ ] Subtask: Truncate if too long: `if label.count > 50 { label = String(label.prefix(47)) + "..." }`
  - [ ] Subtask: Test with sample cluster: verify label is readable and meaningful

**Phase 4: ClusterLabel Model Update (AC: 5)**
- [ ] **Task 8.3.6:** Store labels in SwiftData
  - [ ] Subtask: Verify `ClusterLabel` model properties: `clusterID: Int`, `label: String`, `centroid: [Float]?`, `itemCount: Int`
  - [ ] Subtask: Create or update ClusterLabel: `let clusterLabel = ClusterLabel(clusterID: clusterID, label: generatedLabel, centroid: centroid, itemCount: videos.count)`
  - [ ] Subtask: Save to SwiftData: `modelContext.insert(clusterLabel); try modelContext.save()`
  - [ ] Subtask: Query ClusterLabels: `FetchDescriptor<ClusterLabel>(sortBy: [SortDescriptor(\..itemCount, order: .reverse)])`

**Phase 5: Label Uniqueness (AC: 6)**
- [ ] **Task 8.3.7:** Ensure unique labels across clusters
  - [ ] Subtask: Check for duplicate labels: `let existingLabels = allClusterLabels.map { $0.label }`
  - [ ] Subtask: If duplicate found, append disambiguation: `label = "\(label) (\(clusterID))"` or `label = "\(label) 2"`
  - [ ] Subtask: Alternative: Add most distinctive keyword from cluster: `label = "\(label) - \(uniqueKeyword)"`
  - [ ] Subtask: Test with intentionally similar clusters (e.g., two "Swift" clusters)
  - [ ] Subtask: Verify all labels unique after generation

**Phase 6: User Renaming (AC: 7)**
- [ ] **Task 8.3.8:** Implement custom label override
  - [ ] Subtask: Add property to `ClusterLabel`: `@Attribute var customLabel: String?`
  - [ ] Subtask: Display logic: `let displayLabel = customLabel ?? label` (prefer custom if set)
  - [ ] Subtask: Add "Rename Cluster" action in cluster detail view
  - [ ] Subtask: Show text field: `TextField("Cluster Name", text: $customName)`
  - [ ] Subtask: On save, update: `clusterLabel.customLabel = customName; try modelContext.save()`
  - [ ] Subtask: Preserve custom labels during re-clustering: map old clusterID to new based on centroid similarity

**Phase 7: Label Generation Pipeline**
- [ ] **Task 8.3.9:** Integrate label generation with clustering
  - [ ] Subtask: In `ClusteringCoordinator`, add `generateLabels() async` function
  - [ ] Subtask: After clustering completes, generate labels for all clusters
  - [ ] Subtask: For each unique clusterID, fetch videos: `let videos = allVideos.filter { $0.clusterID == clusterID }`
  - [ ] Subtask: Compute centroid and extract keywords: `let label = generateLabel(for: clusterID, videos: videos)`
  - [ ] Subtask: Save ClusterLabel to SwiftData
  - [ ] Subtask: Log completion: "Generated labels for \(clusterCount) clusters"

**Phase 8: UI Testing (AC: 8)**
- [ ] **Task 8.3.10:** Write UI tests for label generation
  - [ ] Subtask: Create `MyToobUITests/ClusterLabelTests.swift`
  - [ ] Subtask: Create seed data: 3 clusters with known titles (Swift, Python, Machine Learning topics)
  - [ ] Subtask: Test: `testLabelGeneration()` - verify labels match expected keywords
  - [ ] Subtask: Test: `testLabelUniqueness()` - verify no duplicate labels
  - [ ] Subtask: Test: `testCustomLabel()` - rename cluster, verify custom label displayed
  - [ ] Subtask: Test: `testLabelFormatting()` - verify title case and separator correct
  - [ ] Subtask: Run all UI tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/AI/Clustering/KeywordExtractor.swift`, `MyToobUITests/ClusterLabelTests.swift`
- **Files to Modify:** `MyToob/Models/ClusterLabel.swift` (add `customLabel` property if not exists)
- **Keyword Extraction:** TF-IDF is more sophisticated, but frequency analysis is simpler and often sufficient
- **Stopwords:** Common words like "the", "a", "in" should be filtered out before keyword extraction
- **Label Format:** "Swift Concurrency Async" (space-separated) is cleaner than "Swift, Concurrency, Async" (comma-separated)
- **Centroid Usage:** Centroids can be used for mapping old clusters to new during re-clustering (find nearest old centroid)
- **Custom Labels:** Always prioritize user-defined labels over auto-generated ones

**Testing Requirements:**
- Unit tests for centroid calculation, keyword extraction, label formatting (6 tests)
- UI tests for label generation with sample clusters (4 tests in `ClusterLabelTests`)
- Integration test: End-to-end clustering + label generation
- Uniqueness test: Verify no duplicate labels across 20 clusters

---

## Story 8.4: Auto-Collections UI in Sidebar

**Status:** Not Started  
**Dependencies:** Story 8.3 (cluster labels must be generated)  
**Epic:** 8 - AI Clustering & Auto-Collections

**Full Acceptance Criteria:**
1. Sidebar section added: "Smart Collections" (above or below manual collections)
2. Each `ClusterLabel` displayed as a sidebar item: label + count (e.g., "Swift Concurrency (24)")
3. Clicking cluster loads videos in that cluster in main content area
4. Cluster icon: system icon indicating AI-generated (e.g., sparkles icon)
5. Clusters sorted by size (largest first) or alphabetically (user preference in Settings)
6. Empty clusters (0 videos) not shown in sidebar
7. "Hide Smart Collections" toggle in Settings for users who prefer manual organization only

**Implementation Phases:**

**Phase 1: Sidebar Section UI (AC: 1)**
- [ ] **Task 8.4.1:** Add Smart Collections section to sidebar
  - [ ] Subtask: In `SidebarView`, add new section: `Section("Smart Collections") { ... }`
  - [ ] Subtask: Position below or above "Collections" section (user preference, default below)
  - [ ] Subtask: Add section header with icon: `Label("Smart Collections", systemImage: "sparkles")`
  - [ ] Subtask: Optional: Collapsible section with disclosure group

**Phase 2: Cluster Item Display (AC: 2, 4)**
- [ ] **Task 8.4.2:** Display cluster labels in sidebar
  - [ ] Subtask: Fetch cluster labels: `@Query var clusterLabels: [ClusterLabel]` (sorted, filtered)
  - [ ] Subtask: For each cluster, display as NavigationLink: `NavigationLink(value: clusterLabel) { ... }`
  - [ ] Subtask: Label format: `Text(clusterLabel.displayLabel)` + `Text("(\(clusterLabel.itemCount))")`
  - [ ] Subtask: Add sparkles icon: `Label { ... } icon: { Image(systemName: "sparkles") }`
  - [ ] Subtask: Style icon with accent color to distinguish from manual collections

**Phase 3: Cluster Selection & Navigation (AC: 3)**
- [ ] **Task 8.4.3:** Load cluster videos on selection
  - [ ] Subtask: In `ContentView`, handle cluster navigation: `NavigationStack { ... .navigationDestination(for: ClusterLabel.self) { ... } }`
  - [ ] Subtask: On cluster selected, fetch videos: `let videos = fetchVideos(for: clusterLabel.clusterID)`
  - [ ] Subtask: Display videos in main content area (grid or list view)
  - [ ] Subtask: Show cluster name as title: `Text(clusterLabel.displayLabel).font(.largeTitle)`
  - [ ] Subtask: Optional: Show cluster centroid similarity scores for each video

**Phase 4: Sorting & Filtering (AC: 5, 6)**
- [ ] **Task 8.4.4:** Implement cluster sorting
  - [ ] Subtask: Add sort preference: `@AppStorage("clusterSortOrder") var sortOrder: ClusterSortOrder = .bySize`
  - [ ] Subtask: Define enum: `enum ClusterSortOrder { case bySize, alphabetical }`
  - [ ] Subtask: Sort by size: `FetchDescriptor<ClusterLabel>(sortBy: [SortDescriptor(\.itemCount, order: .reverse)])`
  - [ ] Subtask: Sort alphabetically: `FetchDescriptor<ClusterLabel>(sortBy: [SortDescriptor(\.label)])`
  - [ ] Subtask: Add sort toggle in Settings: "Sort Smart Collections by: Size / Name"

- [ ] **Task 8.4.5:** Filter empty clusters
  - [ ] Subtask: Filter out clusters with 0 videos: `@Query(filter: #Predicate<ClusterLabel> { $0.itemCount > 0 })`
  - [ ] Subtask: Update itemCount when videos added/removed from cluster
  - [ ] Subtask: Recalculate itemCount during re-clustering

**Phase 5: Settings Toggle (AC: 7)**
- [ ] **Task 8.4.6:** Implement hide Smart Collections setting
  - [ ] Subtask: Add toggle in Settings: `@AppStorage("showSmartCollections") var showSmartCollections = true`
  - [ ] Subtask: Toggle in Settings > Collections: "Show Smart Collections"
  - [ ] Subtask: Conditional rendering in sidebar: `if showSmartCollections { Section("Smart Collections") { ... } }`
  - [ ] Subtask: Default to enabled (show Smart Collections by default)

**Phase 6: Visual Polish**
- [ ] **Task 8.4.7:** Refine Smart Collections UI
  - [ ] Subtask: Add visual separator between manual and Smart Collections sections
  - [ ] Subtask: Use distinct icon style for Smart Collections (sparkles, wand.and.stars)
  - [ ] Subtask: Optional: Subtle background color to distinguish Smart Collections
  - [ ] Subtask: Ensure consistent spacing and alignment with other sidebar items
  - [ ] Subtask: Test with dark mode and light mode

**Phase 7: Integration Testing**
- [ ] **Task 8.4.8:** Test Smart Collections sidebar
  - [ ] Subtask: Create `MyToobUITests/SmartCollectionsSidebarTests.swift`
  - [ ] Subtask: Test: `testSmartCollectionsVisible()` - section appears in sidebar
  - [ ] Subtask: Test: `testClusterSelection()` - clicking cluster loads videos
  - [ ] Subtask: Test: `testSorting()` - clusters sorted by size or name
  - [ ] Subtask: Test: `testEmptyClustersHidden()` - clusters with 0 videos not shown
  - [ ] Subtask: Test: `testHideSmartCollections()` - toggle hides section
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `MyToob/Views/SidebarView.swift`, `MyToob/Views/ContentView.swift`
- **Sidebar Section:** Place Smart Collections below manual collections to emphasize user-created content
- **Icon:** "sparkles" SF Symbol clearly indicates AI-generated content
- **Sorting:** Default to by-size for most relevant clusters first, but allow alphabetical for browsing
- **Empty Clusters:** Filter out empty clusters to avoid clutter (can occur after deleting videos)
- **Settings:** Allow users to hide Smart Collections entirely if they prefer manual organization only

**Testing Requirements:**
- UI tests for sidebar display, navigation, sorting, filtering (6 tests in `SmartCollectionsSidebarTests`)
- Integration test: Create clusters, verify displayed in sidebar correctly
- Visual test: Verify UI looks good in dark/light mode


---

## Story 8.5: Cluster Stability & Re-Clustering Trigger

**Status:** Not Started  
**Dependencies:** Story 8.2 (clustering must be implemented), Story 8.3 (labels must persist)  
**Epic:** 8 - AI Clustering & Auto-Collections

**Full Acceptance Criteria:**
1. Cluster assignments persisted in SwiftData (add `clusterID` property to `VideoItem`)
2. On app launch, load existing clusters from SwiftData (no re-clustering unless needed)
3. Re-clustering triggered when: user manually requests, library grows by >10% since last clustering, AI model updated
4. Re-clustering runs in background (doesn't block UI)
5. After re-clustering, old cluster IDs mapped to new clusters to preserve user edits (e.g., renamed labels)
6. "Re-cluster Now" action in Settings forces full re-clustering
7. Cluster stability measured: >90% of videos remain in same cluster after re-clustering (goal: minimize churn)

**Implementation Phases:**

**Phase 1: Cluster Persistence (AC: 1)**
- [ ] **Task 8.5.1:** Ensure cluster assignments are stored
  - [ ] Subtask: Verify `VideoItem.clusterID` property exists: `@Attribute var clusterID: Int?`
  - [ ] Subtask: Cluster assignments saved after clustering: `video.clusterID = assignedClusterID; try modelContext.save()`
  - [ ] Subtask: ClusterLabel entries persist in SwiftData
  - [ ] Subtask: Test persistence: run clustering, quit app, relaunch, verify clusters still exist

**Phase 2: Load Existing Clusters (AC: 2)**
- [ ] **Task 8.5.2:** Skip clustering on app launch if clusters exist
  - [ ] Subtask: On app launch, check if clusters exist: `let clusterCount = try modelContext.fetchCount(FetchDescriptor<ClusterLabel>())`
  - [ ] Subtask: If clusterCount > 0, skip clustering: use existing assignments
  - [ ] Subtask: Log: "Loaded \(clusterCount) existing clusters from SwiftData"
  - [ ] Subtask: Only build kNN graph and run clustering if no clusters exist or re-clustering needed

**Phase 3: Re-Clustering Triggers (AC: 3)**
- [ ] **Task 8.5.3:** Track library growth for auto re-clustering
  - [ ] Subtask: Store last clustering size: `@AppStorage("lastClusteringVideoCount") var lastCount = 0`
  - [ ] Subtask: On app launch, compare current video count to last: `let currentCount = allVideos.count`
  - [ ] Subtask: Calculate growth: `let growth = Float(currentCount - lastCount) / Float(lastCount)`
  - [ ] Subtask: If growth >0.10 (10%), trigger re-clustering: `if growth > 0.10 { await recluster() }`
  - [ ] Subtask: Update last clustering count after re-clustering: `lastCount = currentCount`

- [ ] **Task 8.5.4:** Detect AI model updates
  - [ ] Subtask: Store model version hash: `@AppStorage("embeddingModelVersion") var modelVersion = ""`
  - [ ] Subtask: On app launch, check if model version changed (e.g., compare model file hash or version string)
  - [ ] Subtask: If model updated, trigger re-clustering: `if modelVersion != currentModelVersion { await recluster() }`
  - [ ] Subtask: Update model version after re-clustering: `modelVersion = currentModelVersion`

**Phase 4: Background Re-Clustering (AC: 4)**
- [ ] **Task 8.5.5:** Run re-clustering in background
  - [ ] Subtask: Create `recluster() async` function in `ClusteringCoordinator`
  - [ ] Subtask: Run on background queue: `await Task.detached { ... }.value`
  - [ ] Subtask: Show non-blocking progress UI: "Re-clustering your library..." (toast or toolbar indicator)
  - [ ] Subtask: Don't block app UI: user can continue browsing while re-clustering
  - [ ] Subtask: On completion, update clusters and UI

**Phase 5: Cluster ID Mapping (AC: 5)**
- [ ] **Task 8.5.6:** Preserve user customizations during re-clustering
  - [ ] Subtask: Before re-clustering, store old cluster centroids: `let oldCentroids = clusterLabels.map { ($0.clusterID, $0.centroid) }`
  - [ ] Subtask: After re-clustering, compute new cluster centroids
  - [ ] Subtask: Map old clusterID to new clusterID: find new cluster with most similar centroid (cosine similarity)
  - [ ] Subtask: Transfer custom labels: `if let mapping = mapOldToNew[oldID] { newCluster.customLabel = oldCluster.customLabel }`
  - [ ] Subtask: Log mapping: "Cluster \(oldID) mapped to \(newID) (similarity: \(similarity))"
  - [ ] Subtask: Preserve user edits: custom labels, manual cluster modifications

**Phase 6: Manual Re-Clustering (AC: 6)**
- [ ] **Task 8.5.7:** Implement "Re-cluster Now" action
  - [ ] Subtask: Add button in Settings > AI: "Re-cluster Library"
  - [ ] Subtask: Show confirmation dialog: "Re-clustering will reorganize your Smart Collections. Custom labels will be preserved. Continue?"
  - [ ] Subtask: On confirm, clear existing clusters: `for video in allVideos { video.clusterID = nil }`
  - [ ] Subtask: Delete old ClusterLabels (or keep for mapping): `modelContext.delete(oldCluster)`
  - [ ] Subtask: Trigger full re-clustering: `await clusteringCoordinator.runFullClustering()`
  - [ ] Subtask: Update UI after completion

**Phase 7: Cluster Stability Measurement (AC: 7)**
- [ ] **Task 8.5.8:** Measure and log cluster stability
  - [ ] Subtask: Before re-clustering, store old assignments: `let oldAssignments = allVideos.map { ($0.id, $0.clusterID) }`
  - [ ] Subtask: After re-clustering, compare assignments: count videos with same clusterID
  - [ ] Subtask: Calculate stability: `let stability = Float(sameClusterCount) / Float(totalVideos)`
  - [ ] Subtask: Log stability: "Cluster stability: \(stability * 100)% of videos in same cluster"
  - [ ] Subtask: Goal: >90% stability (AC target)
  - [ ] Subtask: If stability <90%, investigate: resolution parameter too high, graph changed significantly

- [ ] **Task 8.5.9:** Optional: Incremental clustering
  - [ ] Subtask: Instead of full re-clustering, add new videos to existing clusters
  - [ ] Subtask: For each new video, find nearest cluster centroid: `let nearestCluster = findNearestCentroid(video.embedding!)`
  - [ ] Subtask: Assign video to nearest cluster: `video.clusterID = nearestCluster.id`
  - [ ] Subtask: Update cluster centroid: recalculate with new member
  - [ ] Subtask: Only full re-cluster every N months or when >20% growth

**Phase 8: Testing**
- [ ] **Task 8.5.10:** Write stability tests
  - [ ] Subtask: Create `MyToobTests/AI/Clustering/ClusterStabilityTests.swift`
  - [ ] Subtask: Test: `testClusterPersistence()` - clusters persist across app restart
  - [ ] Subtask: Test: `testReClusteringTrigger()` - 10% growth triggers re-clustering
  - [ ] Subtask: Test: `testCustomLabelPreservation()` - custom labels preserved after re-clustering
  - [ ] Subtask: Test: `testClusterStability()` - >90% videos in same cluster after re-clustering
  - [ ] Subtask: Integration test: Full re-clustering with 200 videos
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `MyToob/Models/VideoItem.swift` (ensure `clusterID` exists), `MyToob/AI/Clustering/ClusteringCoordinator.swift`
- **Stability Goal:** >90% stability ensures Smart Collections don't churn excessively, maintaining user familiarity
- **Cluster Mapping:** Use centroid similarity to map old→new clusters (preserves semantic meaning)
- **Re-Clustering Frequency:** Avoid re-clustering too often (limit to 10% growth, manual request, or model update)
- **Incremental Clustering:** Alternative to full re-clustering, faster but less accurate over time
- **Custom Labels:** Always preserve user customizations (custom labels, manual edits)

**Testing Requirements:**
- Unit tests for persistence, re-clustering triggers, stability measurement (6 tests in `ClusterStabilityTests`)
- Integration test: Full re-clustering workflow with stability verification
- Persistence test: Verify clusters survive app restart

---

## Story 8.6: Cluster Detail View & Refinement

**Status:** Not Started  
**Dependencies:** Story 8.4 (Smart Collections UI must be implemented)  
**Epic:** 8 - AI Clustering & Auto-Collections

**Full Acceptance Criteria:**
1. Clicking cluster in sidebar loads cluster detail view
2. Detail view shows: cluster label, video count, member videos in grid/list
3. "Rename Cluster" button allows custom label (overrides auto-generated)
4. "Merge with..." action combines two clusters into one (user selects second cluster)
5. "Remove from Cluster" action on individual videos (moves video out of cluster)
6. "Convert to Manual Collection" creates a user collection from cluster (preserves videos, removes from smart collections)
7. Changes to clusters persist across app restarts

**Implementation Phases:**

**Phase 1: Cluster Detail View UI (AC: 1, 2)**
- [ ] **Task 8.6.1:** Create cluster detail view
  - [ ] Subtask: Create `MyToob/Views/ClusterDetailView.swift` with `struct ClusterDetailView: View`
  - [ ] Subtask: Accept cluster label as parameter: `let clusterLabel: ClusterLabel`
  - [ ] Subtask: Show cluster name as title: `Text(clusterLabel.displayLabel).font(.largeTitle)`
  - [ ] Subtask: Show video count: `Text("\(clusterLabel.itemCount) videos")`
  - [ ] Subtask: Fetch cluster videos: `@Query(filter: #Predicate<VideoItem> { $0.clusterID == clusterLabel.clusterID })`
  - [ ] Subtask: Display videos in grid or list (user preference)

**Phase 2: Rename Cluster Action (AC: 3)**
- [ ] **Task 8.6.2:** Implement cluster renaming
  - [ ] Subtask: Add "Rename" button in toolbar or cluster header
  - [ ] Subtask: Show rename sheet: `.sheet(isPresented: $showingRenameSheet) { ... }`
  - [ ] Subtask: Text field for new name: `TextField("Cluster Name", text: $newName)`
  - [ ] Subtask: Save button updates custom label: `clusterLabel.customLabel = newName; try modelContext.save()`
  - [ ] Subtask: Dismiss sheet and update UI
  - [ ] Subtask: Test renaming: verify custom label displayed in sidebar

**Phase 3: Merge Clusters Action (AC: 4)**
- [ ] **Task 8.6.3:** Implement cluster merging
  - [ ] Subtask: Add "Merge with..." button in toolbar
  - [ ] Subtask: Show picker: select second cluster from all clusters
  - [ ] Subtask: Confirm merge: "Merge '\(cluster1.label)' with '\(cluster2.label)'? This cannot be undone."
  - [ ] Subtask: On confirm, move all videos from cluster2 to cluster1: `for video in cluster2Videos { video.clusterID = cluster1.clusterID }`
  - [ ] Subtask: Update cluster1 itemCount: `cluster1.itemCount += cluster2.itemCount`
  - [ ] Subtask: Delete cluster2: `modelContext.delete(cluster2)`
  - [ ] Subtask: Recalculate cluster1 centroid (optional, for accuracy)
  - [ ] Subtask: Save changes and update UI

**Phase 4: Remove Video from Cluster (AC: 5)**
- [ ] **Task 8.6.4:** Implement video removal from cluster
  - [ ] Subtask: Add context menu to each video in cluster view: `.contextMenu { ... }`
  - [ ] Subtask: "Remove from Cluster" action: `video.clusterID = nil; try modelContext.save()`
  - [ ] Subtask: Update cluster itemCount: `clusterLabel.itemCount -= 1`
  - [ ] Subtask: Remove video from view (UI update)
  - [ ] Subtask: Optional: Assign removed video to "Unclustered" pseudo-cluster

**Phase 5: Convert to Manual Collection (AC: 6)**
- [ ] **Task 8.6.5:** Implement conversion to manual collection
  - [ ] Subtask: Add "Convert to Manual Collection" button in toolbar
  - [ ] Subtask: Show confirmation: "Create a manual collection from this Smart Collection?"
  - [ ] Subtask: On confirm, create new user Collection: `let collection = UserCollection(name: clusterLabel.displayLabel, videoIDs: clusterVideos.map { $0.id })`
  - [ ] Subtask: Save collection to SwiftData
  - [ ] Subtask: Remove cluster from Smart Collections: `modelContext.delete(clusterLabel)`
  - [ ] Subtask: Clear cluster IDs from videos: `for video in clusterVideos { video.clusterID = nil }`
  - [ ] Subtask: Navigate to new manual collection
  - [ ] Subtask: Show success message: "Converted to manual collection '\(collection.name)'"

**Phase 6: Persistence (AC: 7)**
- [ ] **Task 8.6.6:** Verify changes persist
  - [ ] Subtask: All cluster modifications (rename, merge, remove, convert) save to SwiftData
  - [ ] Subtask: Test: Make changes, quit app, relaunch, verify changes persisted
  - [ ] Subtask: Ensure SwiftData save calls after each action

**Phase 7: UI Polish & Testing**
- [ ] **Task 8.6.7:** Refine cluster detail view
  - [ ] Subtask: Add video thumbnails in grid layout
  - [ ] Subtask: Show video titles and durations
  - [ ] Subtask: Optional: Sort videos by similarity to cluster centroid (most representative first)
  - [ ] Subtask: Add "Select All" for bulk actions (optional future enhancement)
  - [ ] Subtask: Test with large clusters (100+ videos)

- [ ] **Task 8.6.8:** Write UI tests
  - [ ] Subtask: Create `MyToobUITests/ClusterDetailViewTests.swift`
  - [ ] Subtask: Test: `testRenameCluster()` - rename cluster, verify label updated
  - [ ] Subtask: Test: `testMergeClusters()` - merge two clusters, verify videos combined
  - [ ] Subtask: Test: `testRemoveVideoFromCluster()` - remove video, verify clusterID cleared
  - [ ] Subtask: Test: `testConvertToManualCollection()` - convert cluster, verify collection created
  - [ ] Subtask: Test: `testPersistence()` - make changes, restart app, verify persisted
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/Views/ClusterDetailView.swift`, `MyToobUITests/ClusterDetailViewTests.swift`
- **Files to Modify:** `MyToob/Models/ClusterLabel.swift` (ensure all properties exist), `MyToob/Models/UserCollection.swift` (for conversion)
- **Merge Action:** Combines two clusters into one, useful for similar topics incorrectly split
- **Remove Action:** Allows manual curation of clusters (remove outliers or misclassified videos)
- **Convert Action:** Power-user feature to "graduate" Smart Collections to manual control
- **Persistence:** All actions must save to SwiftData to survive app restart

**Testing Requirements:**
- UI tests for rename, merge, remove, convert actions (5 tests in `ClusterDetailViewTests`)
- Integration test: End-to-end cluster refinement workflow
- Persistence test: Verify all changes survive app restart

---

**Epic 8 Summary:**
All 6 stories in Epic 8 - AI Clustering & Auto-Collections have been fully expanded with detailed task breakdowns. This epic enables intelligent, automatic organization of video libraries using graph-based clustering and AI-generated labels.

**Key Deliverables:**
- kNN graph construction from video embeddings
- Leiden community detection algorithm for clustering
- Auto-generated cluster labels using keyword extraction
- Smart Collections UI in sidebar
- Cluster stability and re-clustering logic
- Cluster refinement tools (rename, merge, remove, convert)

**Next Epic:** Epic 9 - Hybrid Search & Discovery UX


---

### Epic 9: Hybrid Search & Discovery UX (6 stories)

## Story 9.1: Search Bar & Query Input

**Status:** Not Started  
**Dependencies:** None (foundational UI component)  
**Epic:** 9 - Hybrid Search & Discovery UX

**Full Acceptance Criteria:**
1. Search bar positioned in toolbar (top of window, always visible)
2. Search bar placeholder text: "Search videos..." or "Search by title, topic, or description..."
3. Search activates on Return key press or after 500ms debounce (user stops typing)
4. Search input cleared with "X" button when text present
5. Search history (recent queries) shown in dropdown below search bar (optional, Pro feature)
6. Keyboard shortcut: ⌘F focuses search bar
7. Search works in all views (YouTube library, local files, collections)

**Implementation Phases:**

**Phase 1: Search Bar UI (AC: 1, 2)**
- [ ] **Task 9.1.1:** Create search bar component
  - [ ] Subtask: In `ContentView` toolbar, add search bar: `ToolbarItem(placement: .navigation) { ... }`
  - [ ] Subtask: Create `TextField`: `TextField("Search videos...", text: $searchQuery)`
  - [ ] Subtask: Style as search field: `.textFieldStyle(.roundedBorder)` with search icon
  - [ ] Subtask: Alternative placeholder: "Search by title, topic, or description..." (longer, more helpful)
  - [ ] Subtask: Position in toolbar: prominent, always visible
  - [ ] Subtask: Ensure proper width: `.frame(minWidth: 250, idealWidth: 400)`

**Phase 2: Search Activation (AC: 3)**
- [ ] **Task 9.1.2:** Implement search triggers
  - [ ] Subtask: Add `.onSubmit` modifier: `TextField(...).onSubmit { performSearch() }`
  - [ ] Subtask: Implement debounce: delay search until user stops typing for 500ms
  - [ ] Subtask: Use `onChange(of: searchQuery) { ... }` with debounce timer
  - [ ] Subtask: Cancel pending search if user types again within 500ms
  - [ ] Subtask: Create `performSearch()` function: triggers hybrid search (Story 9.4)

**Phase 3: Clear Button (AC: 4)**
- [ ] **Task 9.1.3:** Add clear button to search bar
  - [ ] Subtask: Show "X" button when `searchQuery` not empty: `if !searchQuery.isEmpty { ... }`
  - [ ] Subtask: Button clears query: `Button(action: { searchQuery = "" }) { Image(systemName: "xmark.circle.fill") }`
  - [ ] Subtask: Position button at trailing edge of search field
  - [ ] Subtask: Clear also resets search results: `searchResults = []`

**Phase 4: Search History (AC: 5 - Optional Pro Feature)**
- [ ] **Task 9.1.4:** Implement search history dropdown
  - [ ] Subtask: Store recent queries: `@AppStorage("recentSearches") var recentSearches: [String] = []` (or use SwiftData)
  - [ ] Subtask: Save query to history after search: `recentSearches.insert(searchQuery, at: 0)`
  - [ ] Subtask: Limit history size: keep last 20 queries
  - [ ] Subtask: Show dropdown below search bar when focused (popover or menu)
  - [ ] Subtask: List recent searches: `ForEach(recentSearches, id: \.self) { query in ... }`
  - [ ] Subtask: Clicking history item fills search bar and triggers search
  - [ ] Subtask: "Clear History" action: `recentSearches = []`
  - [ ] Subtask: Mark as Pro feature: show upgrade prompt if not Pro subscriber

**Phase 5: Keyboard Shortcut (AC: 6)**
- [ ] **Task 9.1.5:** Add ⌘F keyboard shortcut
  - [ ] Subtask: Create menu command: `.commands { CommandGroup(replacing: .textEditing) { ... } }`
  - [ ] Subtask: Add "Find" command: `Button("Find") { focusSearchBar() }.keyboardShortcut("f", modifiers: .command)`
  - [ ] Subtask: Implement focus: use `@FocusState` to focus search field
  - [ ] Subtask: Test shortcut: press ⌘F, verify search bar focused and selected

**Phase 6: Global Search (AC: 7)**
- [ ] **Task 9.1.6:** Ensure search works in all views
  - [ ] Subtask: Search bar always visible in toolbar (not view-specific)
  - [ ] Subtask: Search queries entire library, not just current view
  - [ ] Subtask: Optional: Filter results by current context (e.g., only Local Files if in Local Files view)
  - [ ] Subtask: Test search in: YouTube library, Local Files, Collections, Smart Collections

**Phase 7: Testing**
- [ ] **Task 9.1.7:** Write UI tests for search bar
  - [ ] Subtask: Create `MyToobUITests/SearchBarTests.swift`
  - [ ] Subtask: Test: `testSearchBarVisible()` - search bar appears in toolbar
  - [ ] Subtask: Test: `testSearchActivation()` - typing + Return triggers search
  - [ ] Subtask: Test: `testDebounce()` - search waits 500ms after typing stops
  - [ ] Subtask: Test: `testClearButton()` - X button clears query and results
  - [ ] Subtask: Test: `testKeyboardShortcut()` - ⌘F focuses search bar
  - [ ] Subtask: Test: `testSearchHistory()` - recent searches shown and clickable
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `MyToob/Views/ContentView.swift` (add search bar to toolbar)
- **Search History:** Store in `@AppStorage` for simplicity, or SwiftData for richer features (timestamps, frequency)
- **Debounce:** Prevents excessive search queries while typing (improves performance and UX)
- **Global vs. Contextual:** Default to global search, optionally filter by current view
- **Placeholder Text:** Longer placeholder helps users understand search capabilities

**Testing Requirements:**
- UI tests for search bar display, activation, clear, keyboard shortcut (7 tests in `SearchBarTests`)
- Debounce test: Verify search only fires after 500ms of inactivity
- Integration test: Search from different views (YouTube, Local, Collections)

---

## Story 9.2: Keyword Search Implementation

**Status:** Not Started  
**Dependencies:** Story 9.1 (search bar must exist)  
**Epic:** 9 - Hybrid Search & Discovery UX

**Full Acceptance Criteria:**
1. Query tokenized into keywords (split by whitespace, remove stop words)
2. Each keyword matched against `VideoItem.title`, `.description`, `.aiTopicTags` using case-insensitive substring match
3. Results ranked by number of keyword matches (more matches = higher rank)
4. Exact phrase matching supported: query in quotes "swift concurrency" matches exact phrase
5. Boolean operators supported (optional, advanced): "swift AND concurrency", "tutorial OR guide"
6. Search completes in <100ms for 10,000-video library
7. Unit tests verify keyword matching with various query patterns

**Implementation Phases:**

**Phase 1: Query Tokenization (AC: 1)**
- [ ] **Task 9.2.1:** Implement query parsing
  - [ ] Subtask: Create `MyToob/Search/QueryParser.swift` with `class QueryParser`
  - [ ] Subtask: Tokenize query: `func tokenize(_ query: String) -> [String]` splits by whitespace
  - [ ] Subtask: Lowercase tokens: `let tokens = query.lowercased().split(separator: " ").map { String($0) }`
  - [ ] Subtask: Remove stop words: filter out ["the", "a", "an", "in", "on", "at", "to", "of", "for", ...]
  - [ ] Subtask: Define stop words list: `let stopWords: Set<String> = ["the", "a", ...]`
  - [ ] Subtask: Filter: `let filteredTokens = tokens.filter { !stopWords.contains($0) }`

**Phase 2: Keyword Matching (AC: 2)**
- [ ] **Task 9.2.2:** Implement keyword search
  - [ ] Subtask: Create `keywordSearch(_ query: String, in videos: [VideoItem]) -> [VideoItem]` function
  - [ ] Subtask: Tokenize query: `let keywords = QueryParser.tokenize(query)`
  - [ ] Subtask: For each video, check if keywords match title, description, or tags
  - [ ] Subtask: Case-insensitive substring match: `video.title.lowercased().contains(keyword.lowercased())`
  - [ ] Subtask: Match against all fields: `let matchesTitle = video.title.lowercased().contains(keyword.lowercased())`
  - [ ] Subtask: Count matches per video: `let matchCount = keywords.filter { video.matches($0) }.count`
  - [ ] Subtask: Filter videos with at least one match: `let results = videos.filter { matchCount($0) > 0 }`

**Phase 3: Ranking by Match Count (AC: 3)**
- [ ] **Task 9.2.3:** Rank results by relevance
  - [ ] Subtask: Calculate match score: count of keywords matched per video
  - [ ] Subtask: Bonus for title matches: if keyword in title, score += 2 (title more important than description)
  - [ ] Subtask: Bonus for tag matches: if keyword in tags, score += 1.5
  - [ ] Subtask: Sort results by score descending: `results.sort { matchScore($0) > matchScore($1) }`
  - [ ] Subtask: Return ranked results

**Phase 4: Exact Phrase Matching (AC: 4)**
- [ ] **Task 9.2.4:** Support quoted phrases
  - [ ] Subtask: Detect quotes in query: `if query.contains("\"") { ... }`
  - [ ] Subtask: Extract quoted phrases: use regex or manual parsing
  - [ ] Subtask: Example: `"swift concurrency"` extracts as single token (not split into "swift" and "concurrency")
  - [ ] Subtask: Match exact phrase: `video.title.lowercased().contains(phrase.lowercased())`
  - [ ] Subtask: Combine with regular keywords: query can have both quoted and unquoted terms

**Phase 5: Boolean Operators (AC: 5 - Optional)**
- [ ] **Task 9.2.5:** Implement AND/OR operators
  - [ ] Subtask: Parse query for boolean operators: detect "AND", "OR", "NOT"
  - [ ] Subtask: Default behavior (no operator): AND logic (all keywords must match)
  - [ ] Subtask: AND operator: "swift AND concurrency" → video must match both
  - [ ] Subtask: OR operator: "tutorial OR guide" → video matches either
  - [ ] Subtask: NOT operator: "swift NOT beginner" → video matches "swift" but not "beginner"
  - [ ] Subtask: Precedence: handle complex queries like "(swift OR python) AND tutorial"
  - [ ] Subtask: Optional: Use query parser library for complex boolean logic

**Phase 6: Performance Optimization (AC: 6)**
- [ ] **Task 9.2.6:** Optimize keyword search performance
  - [ ] Subtask: Measure search time: `let start = Date(); ...; let duration = Date().timeIntervalSince(start)`
  - [ ] Subtask: Log search time: "Keyword search completed in \(duration * 1000)ms"
  - [ ] Subtask: Verify <100ms for 10,000 videos (AC target)
  - [ ] Subtask: Optimize: Use SwiftData predicate for filtering (database-level search)
  - [ ] Subtask: Example: `FetchDescriptor<VideoItem>(predicate: #Predicate { $0.title.localizedStandardContains(keyword) })`
  - [ ] Subtask: Profile with Instruments: identify bottlenecks
  - [ ] Subtask: Cache search results for repeated queries (optional)

**Phase 7: Unit Testing (AC: 7)**
- [ ] **Task 9.2.7:** Write comprehensive keyword search tests
  - [ ] Subtask: Create `MyToobTests/Search/KeywordSearchTests.swift`
  - [ ] Subtask: Test: `testBasicKeywordMatch()` - single keyword matches title
  - [ ] Subtask: Test: `testMultipleKeywords()` - multiple keywords all match
  - [ ] Subtask: Test: `testCaseInsensitive()` - "Swift" matches "swift" and "SWIFT"
  - [ ] Subtask: Test: `testStopWordRemoval()` - "the swift tutorial" matches "swift tutorial"
  - [ ] Subtask: Test: `testExactPhrase()` - "swift concurrency" matches exact phrase only
  - [ ] Subtask: Test: `testBooleanOperators()` - "swift AND tutorial" matches both
  - [ ] Subtask: Test: `testPerformance()` - search completes in <150ms (with margin)
  - [ ] Subtask: Run all tests and verify 100% pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/Search/QueryParser.swift`, `MyToob/Search/KeywordSearch.swift`, `MyToobTests/Search/KeywordSearchTests.swift`
- **Stop Words:** Common words that add noise to search (e.g., "the", "a", "is")
- **Ranking:** Title matches should be weighted higher than description matches
- **Exact Phrases:** Use quotes to search for multi-word phrases as a unit
- **Boolean Operators:** Optional advanced feature, useful for power users
- **Performance:** SwiftData predicates are fastest (database-level filtering), followed by in-memory filtering

**Testing Requirements:**
- Unit tests for tokenization, matching, ranking, phrases, boolean operators (7 tests in `KeywordSearchTests`)
- Performance test: <100ms for 10,000 videos
- Integration test: End-to-end keyword search from UI


---

## Story 9.3: Vector Similarity Search Integration

**Status:** Not Started  
**Dependencies:** Story 7.6 (vector search API must be implemented)  
**Epic:** 9 - Hybrid Search & Discovery UX

**Full Acceptance Criteria:**
1. Query converted to embedding using Core ML model (same as Story 7.1)
2. Query embedding used to search HNSW index for top-20 nearest neighbors (same as Story 7.6)
3. Vector search results include similarity scores (cosine similarity, 0-1 range)
4. Vector search completes in <50ms (same latency target as keyword search)
5. Empty query handled: don't run vector search (fall back to showing all videos or recents)
6. Unit tests verify vector search returns semantically similar results (e.g., "async programming" matches "concurrency tutorials")

**Implementation Phases:**

**Phase 1: Query Embedding (AC: 1)**
- [ ] **Task 9.3.1:** Convert search query to embedding
  - [ ] Subtask: Reuse `EmbeddingService` from Story 7.1
  - [ ] Subtask: In search function, generate embedding: `let queryEmbedding = try await embeddingService.generateEmbedding(text: searchQuery)`
  - [ ] Subtask: Handle embedding errors: catch and log, fall back to keyword-only search
  - [ ] Subtask: Log embedding generation: "Query embedding generated in \(duration)ms"

**Phase 2: HNSW Index Query (AC: 2)**
- [ ] **Task 9.3.2:** Query vector index for similar videos
  - [ ] Subtask: Reuse `VectorIndex` from Story 7.5
  - [ ] Subtask: Search index: `let vectorResults = await vectorIndex.search(query: queryEmbedding, k: 20)`
  - [ ] Subtask: Results are top-20 nearest neighbors, sorted by similarity

**Phase 3: Similarity Scoring (AC: 3)**
- [ ] **Task 9.3.3:** Attach similarity scores to results
  - [ ] Subtask: HNSW returns distances, convert to cosine similarity if needed (depends on metric used)
  - [ ] Subtask: If using cosine distance: `similarity = 1 - distance`
  - [ ] Subtask: Ensure similarity range is 0-1 (0 = dissimilar, 1 = identical)
  - [ ] Subtask: Attach scores to results: `let scoredResults = vectorResults.map { (video: $0, score: similarity) }`

**Phase 4: Performance Verification (AC: 4)**
- [ ] **Task 9.3.4:** Verify vector search latency
  - [ ] Subtask: Measure search time: `let start = Date(); ...; let duration = Date().timeIntervalSince(start)`
  - [ ] Subtask: Log search time: "Vector search completed in \(duration * 1000)ms"
  - [ ] Subtask: Verify <50ms (AC target, same as Story 7.6)
  - [ ] Subtask: If target not met, optimize HNSW parameters (ef_search)

**Phase 5: Empty Query Handling (AC: 5)**
- [ ] **Task 9.3.5:** Handle empty search query
  - [ ] Subtask: Check if query empty: `if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty { ... }`
  - [ ] Subtask: Don't run vector search (skip embedding generation and index query)
  - [ ] Subtask: Fall back to showing all videos or recent videos
  - [ ] Subtask: Alternative: Show "Start typing to search" placeholder

**Phase 6: Unit Testing (AC: 6)**
- [ ] **Task 9.3.6:** Write vector search tests
  - [ ] Subtask: Create `MyToobTests/Search/VectorSearchTests.swift`
  - [ ] Subtask: Test: `testSemanticMatch()` - "async programming" returns videos about concurrency
  - [ ] Subtask: Create seed data: videos with known topics (Swift, Python, ML)
  - [ ] Subtask: Test query: "asynchronous code" should match "async await tutorial" (even without exact keyword match)
  - [ ] Subtask: Test: `testSimilarityScores()` - results include scores in 0-1 range
  - [ ] Subtask: Test: `testEmptyQuery()` - empty query doesn't run vector search
  - [ ] Subtask: Test: `testPerformance()` - search completes in <75ms (with margin)
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToobTests/Search/VectorSearchTests.swift`
- **Reuse:** Vector search logic already implemented in Story 7.6, just need to integrate into hybrid search
- **Semantic Matching:** Vector search's key advantage is finding conceptually similar videos without exact keyword matches
- **Performance:** <50ms latency ensures vector search doesn't slow down overall search experience
- **Empty Query:** Avoid unnecessary computation for empty searches

**Testing Requirements:**
- Unit tests for semantic matching, similarity scoring, empty query handling (6 tests in `VectorSearchTests`)
- Performance test: <50ms vector search latency
- Semantic test: Verify "async" matches "concurrency" even without keyword overlap

---

## Story 9.4: Hybrid Search Result Fusion

**Status:** Not Started  
**Dependencies:** Stories 9.2 (keyword search), 9.3 (vector search)  
**Epic:** 9 - Hybrid Search & Discovery UX

**Full Acceptance Criteria:**
1. Hybrid search runs both keyword and vector search in parallel
2. Results merged using reciprocal rank fusion (RRF): score = 1/(k + keyword_rank) + 1/(k + vector_rank), k=60
3. Final results sorted by fused score (higher = better)
4. De-duplication: if same video in both result sets, use single entry with combined score
5. Top-100 results returned (reasonable limit for UI display)
6. "Search Mode" toggle in UI: "Smart" (hybrid, default), "Keyword" (exact match), "Semantic" (vector only)
7. Unit tests verify RRF scoring with sample result sets

**Implementation Phases:**

**Phase 1: Parallel Search Execution (AC: 1)**
- [ ] **Task 9.4.1:** Run keyword and vector search concurrently
  - [ ] Subtask: Create `performHybridSearch(_ query: String) async -> [VideoItem]` function
  - [ ] Subtask: Run searches in parallel using async let: `async let keywordResults = keywordSearch(query); async let vectorResults = vectorSearch(query)`
  - [ ] Subtask: Await both results: `let (kwResults, vecResults) = await (keywordResults, vectorResults)`
  - [ ] Subtask: Measure total search time: should be ~max(keyword_time, vector_time), not sum

**Phase 2: Reciprocal Rank Fusion (AC: 2)**
- [ ] **Task 9.4.2:** Implement RRF scoring
  - [ ] Subtask: Create `reciprocalRankFusion(keywordResults: [VideoItem], vectorResults: [VideoItem], k: Int = 60) -> [VideoItem]` function
  - [ ] Subtask: Build rank maps: `let kwRanks = keywordResults.enumerated().reduce(into: [:]) { $0[$1.element.id] = $1.offset }`
  - [ ] Subtask: Similarly for vector results
  - [ ] Subtask: Calculate RRF score for each video: `score = 1.0 / Float(k + kwRank) + 1.0 / Float(k + vecRank)`
  - [ ] Subtask: If video only in keyword results: `score = 1.0 / Float(k + kwRank)`
  - [ ] Subtask: If video only in vector results: `score = 1.0 / Float(k + vecRank)`
  - [ ] Subtask: Sort by RRF score descending: `fusedResults.sort { $0.score > $1.score }`

**Phase 3: Sorting & De-duplication (AC: 3, 4)**
- [ ] **Task 9.4.3:** Merge and de-duplicate results
  - [ ] Subtask: Collect all unique video IDs from both result sets: `let allVideoIDs = Set(kwResults.map { $0.id }).union(vecResults.map { $0.id })`
  - [ ] Subtask: Calculate RRF score for each video
  - [ ] Subtask: De-duplicate: each video appears only once in final results
  - [ ] Subtask: Sort by fused score: highest score first
  - [ ] Subtask: Return sorted, de-duplicated results

**Phase 4: Result Limiting (AC: 5)**
- [ ] **Task 9.4.4:** Limit to top-100 results
  - [ ] Subtask: After sorting, take top 100: `let topResults = fusedResults.prefix(100)`
  - [ ] Subtask: Ensure UI can handle 100 results (scrolling performance)
  - [ ] Subtask: Optional: Load more results on demand (pagination)

**Phase 5: Search Mode Toggle (AC: 6)**
- [ ] **Task 9.4.5:** Add search mode selector
  - [ ] Subtask: Add `@AppStorage("searchMode") var searchMode: SearchMode = .smart` in ContentView
  - [ ] Subtask: Define enum: `enum SearchMode { case smart, keyword, semantic }`
  - [ ] Subtask: Add picker in toolbar or Settings: `Picker("Search Mode", selection: $searchMode) { ... }`
  - [ ] Subtask: Options: "Smart" (hybrid), "Keyword" (exact match), "Semantic" (vector only)
  - [ ] Subtask: In `performHybridSearch`, check mode:
    - If `.keyword`: run only keyword search
    - If `.semantic`: run only vector search
    - If `.smart`: run hybrid fusion
  - [ ] Subtask: Default to "Smart" mode (best of both worlds)

**Phase 6: Unit Testing (AC: 7)**
- [ ] **Task 9.4.6:** Write RRF fusion tests
  - [ ] Subtask: Create `MyToobTests/Search/HybridSearchTests.swift`
  - [ ] Subtask: Test: `testRRFScoring()` - verify RRF formula correct with sample ranks
  - [ ] Subtask: Example: keyword results = [A, B, C], vector results = [B, D, E]
  - [ ] Subtask: Expected RRF scores: B (appears in both, highest), A, C, D, E
  - [ ] Subtask: Test: `testDeDuplication()` - video in both result sets appears once
  - [ ] Subtask: Test: `testParallelExecution()` - both searches run concurrently
  - [ ] Subtask: Test: `testSearchModes()` - keyword-only, vector-only, hybrid modes work
  - [ ] Subtask: Test: `testTopLimit()` - returns max 100 results
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/Search/HybridSearch.swift`, `MyToobTests/Search/HybridSearchTests.swift`
- **RRF Formula:** Reciprocal rank fusion is proven method for combining ranked lists (better than simple score averaging)
- **k Parameter:** k=60 is standard in literature, balances contribution of top-ranked and lower-ranked results
- **Parallel Execution:** Async let ensures keyword and vector search run concurrently (faster than sequential)
- **Search Modes:** Power users may prefer keyword-only (exact matching) or semantic-only (exploratory discovery)

**Testing Requirements:**
- Unit tests for RRF scoring, de-duplication, parallel execution, search modes (7 tests in `HybridSearchTests`)
- Integration test: End-to-end hybrid search with real keyword and vector results
- Performance test: Verify parallel execution (total time ≈ max, not sum)

---

## Story 9.5: Filter Pills for Faceted Search

**Status:** Not Started  
**Dependencies:** Story 9.4 (hybrid search must be implemented)  
**Epic:** 9 - Hybrid Search & Discovery UX

**Full Acceptance Criteria:**
1. Filter pills shown below search bar when search active: "Duration", "Date", "Source", "Topic"
2. **Duration filter:** Short (<5min), Medium (5-20min), Long (>20min)
3. **Date filter:** Today, This Week, This Month, This Year, Custom Range
4. **Source filter:** YouTube, Local Files, Specific Channel (dropdown)
5. **Topic filter:** Select from cluster labels (multi-select)
6. Filters applied cumulatively (AND logic): "Long + This Month + Swift Concurrency"
7. Active filters shown as dismissible pills (click X to remove)
8. Filter state persists during session (cleared on new query or app restart)
9. Filters applied after search fusion (filter final result set, not individual search results)

**Implementation Phases:**

**Phase 1: Filter UI Layout (AC: 1)**
- [ ] **Task 9.5.1:** Create filter pills bar
  - [ ] Subtask: Below search bar, add HStack for filter pills
  - [ ] Subtask: Show filter buttons: "Duration", "Date", "Source", "Topic"
  - [ ] Subtask: Only show when search is active: `if !searchQuery.isEmpty { ... }`
  - [ ] Subtask: Style as pills: rounded buttons with SF Symbols icons

**Phase 2: Duration Filter (AC: 2)**
- [ ] **Task 9.5.2:** Implement duration filter
  - [ ] Subtask: Add duration picker: `Menu("Duration") { ... }`
  - [ ] Subtask: Options: "Short (<5 min)", "Medium (5-20 min)", "Long (>20 min)", "Any"
  - [ ] Subtask: Store selected duration: `@State private var durationFilter: DurationFilter = .any`
  - [ ] Subtask: Apply filter: `results.filter { video in ... }` based on `video.duration`
  - [ ] Subtask: Convert duration to seconds for comparison: 5 min = 300s, 20 min = 1200s

**Phase 3: Date Filter (AC: 3)**
- [ ] **Task 9.5.3:** Implement date filter
  - [ ] Subtask: Add date picker: `Menu("Date") { ... }`
  - [ ] Subtask: Options: "Today", "This Week", "This Month", "This Year", "Custom Range", "Any"
  - [ ] Subtask: Store selected date: `@State private var dateFilter: DateFilter = .any`
  - [ ] Subtask: Apply filter: compare `video.createdAt` or `video.publishedAt` to date range
  - [ ] Subtask: Custom range: show date range picker (start date, end date)

**Phase 4: Source Filter (AC: 4)**
- [ ] **Task 9.5.4:** Implement source filter
  - [ ] Subtask: Add source picker: `Menu("Source") { ... }`
  - [ ] Subtask: Options: "All", "YouTube", "Local Files"
  - [ ] Subtask: Optionally: Specific channel dropdown (list all channels from YouTube videos)
  - [ ] Subtask: Store selected source: `@State private var sourceFilter: SourceFilter = .all`
  - [ ] Subtask: Apply filter: `results.filter { video in ... }` based on `video.isLocal` or `video.channelID`

**Phase 5: Topic Filter (AC: 5)**
- [ ] **Task 9.5.5:** Implement topic filter
  - [ ] Subtask: Fetch all cluster labels: `@Query var clusterLabels: [ClusterLabel]`
  - [ ] Subtask: Show multi-select menu: `Menu("Topic") { ForEach(clusterLabels) { label in ... } }`
  - [ ] Subtask: Store selected topics: `@State private var topicFilters: Set<Int> = []` (clusterIDs)
  - [ ] Subtask: Apply filter: `results.filter { video in topicFilters.contains(video.clusterID ?? -1) }`

**Phase 6: Cumulative Filtering (AC: 6, 9)**
- [ ] **Task 9.5.6:** Apply all filters cumulatively
  - [ ] Subtask: After hybrid search fusion, apply filters in sequence
  - [ ] Subtask: Filter by duration: `results = results.filter { durationMatches($0) }`
  - [ ] Subtask: Filter by date: `results = results.filter { dateMatches($0) }`
  - [ ] Subtask: Filter by source: `results = results.filter { sourceMatches($0) }`
  - [ ] Subtask: Filter by topic: `results = results.filter { topicMatches($0) }`
  - [ ] Subtask: Return filtered results

**Phase 7: Active Filter Pills (AC: 7)**
- [ ] **Task 9.5.7:** Display active filters as dismissible pills
  - [ ] Subtask: Show active filters below filter buttons
  - [ ] Subtask: For each active filter, show pill: `Text("Long videos").padding(.small).background(.blue).cornerRadius(8)`
  - [ ] Subtask: Add X button to dismiss: `Button(action: { clearFilter() }) { Image(systemName: "xmark") }`
  - [ ] Subtask: Clicking X removes filter and re-runs search

**Phase 8: Filter Persistence (AC: 8)**
- [ ] **Task 9.5.8:** Persist filter state during session
  - [ ] Subtask: Filters remain active as user types new queries
  - [ ] Subtask: Clear filters on explicit action (e.g., "Clear All Filters" button)
  - [ ] Subtask: Optional: Persist filters across app restarts using `@AppStorage`

**Phase 9: Testing**
- [ ] **Task 9.5.9:** Write filter tests
  - [ ] Subtask: Create `MyToobUITests/FilterPillsTests.swift`
  - [ ] Subtask: Test: `testDurationFilter()` - filter by short/medium/long duration
  - [ ] Subtask: Test: `testDateFilter()` - filter by today/this week/this month
  - [ ] Subtask: Test: `testSourceFilter()` - filter by YouTube/Local Files
  - [ ] Subtask: Test: `testTopicFilter()` - filter by cluster label
  - [ ] Subtask: Test: `testCumulativeFilters()` - multiple filters applied together
  - [ ] Subtask: Test: `testFilterPillDismissal()` - clicking X removes filter
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/Views/FilterPillsView.swift`, `MyToobUITests/FilterPillsTests.swift`
- **Filter Logic:** AND logic means all filters must match (e.g., Long videos + This Month + Swift topic)
- **Date Handling:** Use `Calendar` for date comparisons (today, this week, etc.)
- **Source Filter:** Distinguish YouTube (videoID exists) vs. Local (localURL exists)
- **Topic Filter:** Multi-select allows filtering by multiple topics (OR logic within topics)

**Testing Requirements:**
- UI tests for each filter type and cumulative filtering (7 tests in `FilterPillsTests`)
- Integration test: Apply multiple filters, verify correct results
- UX test: Verify filters are intuitive and easy to use


---

## Story 9.6: Search Results Display & Ranking

**Status:** Not Started  
**Dependencies:** Story 9.4 (hybrid search), Story 9.5 (filters)  
**Epic:** 9 - Hybrid Search & Discovery UX

**Full Acceptance Criteria:**
1. Search results shown in main content area as grid or list (user preference in Settings)
2. Each result shows: thumbnail, title, channel/source, duration, relevance score (optional: show % match)
3. Query terms highlighted in title and description (bold or background color)
4. Results sorted by fused score (highest relevance first)
5. Pagination or infinite scroll if >100 results (load more on scroll)
6. Empty results state: "No videos found for 'query'. Try a different search or remove filters."
7. Result click opens video detail view or starts playback
8. "Related Videos" section below each result (optional, shows vector-similar videos)

**Implementation Phases:**

**Phase 1: Results View Layout (AC: 1)**
- [ ] **Task 9.6.1:** Create search results view
  - [ ] Subtask: In `ContentView`, add search results section: `if !searchResults.isEmpty { ... }`
  - [ ] Subtask: Support grid and list views: `@AppStorage("searchResultsLayout") var layout: ResultLayout = .grid`
  - [ ] Subtask: Define enum: `enum ResultLayout { case grid, list }`
  - [ ] Subtask: Grid view: `LazyVGrid(columns: gridColumns) { ForEach(searchResults) { ... } }`
  - [ ] Subtask: List view: `List(searchResults) { ... }`
  - [ ] Subtask: Toggle in toolbar or Settings: switch between grid and list

**Phase 2: Result Item Display (AC: 2)**
- [ ] **Task 9.6.2:** Design result item card
  - [ ] Subtask: Show thumbnail: `AsyncImage(url: video.thumbnailURL)`
  - [ ] Subtask: Show title: `Text(video.title).font(.headline)`
  - [ ] Subtask: Show channel/source: `Text(video.channelName ?? "Local File").font(.subheadline).foregroundColor(.secondary)`
  - [ ] Subtask: Show duration: format as "5:42" or "1:23:45"
  - [ ] Subtask: Optional: Show relevance score: `Text("\(Int(score * 100))% match").font(.caption).foregroundColor(.blue)`
  - [ ] Subtask: Position score as badge on thumbnail or below title

**Phase 3: Query Highlighting (AC: 3)**
- [ ] **Task 9.6.3:** Highlight search terms in results
  - [ ] Subtask: Extract query keywords: `let keywords = QueryParser.tokenize(searchQuery)`
  - [ ] Subtask: Highlight in title: use `AttributedString` to bold matching keywords
  - [ ] Subtask: Example: Title "Swift Async Tutorial" with query "swift" → **Swift** Async Tutorial
  - [ ] Subtask: Alternative: Background color highlight (yellow background for matches)
  - [ ] Subtask: Also highlight in description snippet (if shown)
  - [ ] Subtask: Case-insensitive matching for highlighting

**Phase 4: Sorting by Relevance (AC: 4)**
- [ ] **Task 9.6.4:** Ensure results sorted by fused score
  - [ ] Subtask: Hybrid search already returns results sorted by RRF score (from Story 9.4)
  - [ ] Subtask: Verify sort order maintained after filtering (Story 9.5)
  - [ ] Subtask: Display results in sorted order (highest relevance first)

**Phase 5: Pagination / Infinite Scroll (AC: 5)**
- [ ] **Task 9.6.5:** Implement result pagination
  - [ ] Subtask: If >100 results, show first 100 initially
  - [ ] Subtask: Add "Load More" button or infinite scroll
  - [ ] Subtask: Infinite scroll: detect scroll to bottom, load next 100 results
  - [ ] Subtask: Use `.onAppear` on last item to trigger load: `if video == searchResults.last { loadMore() }`
  - [ ] Subtask: Show loading indicator while fetching more results
  - [ ] Subtask: Ensure smooth scrolling performance (lazy loading)

**Phase 6: Empty State (AC: 6)**
- [ ] **Task 9.6.6:** Handle no results scenario
  - [ ] Subtask: Check if results empty: `if searchResults.isEmpty && !searchQuery.isEmpty { ... }`
  - [ ] Subtask: Show empty state message: "No videos found for '\(searchQuery)'"
  - [ ] Subtask: Add suggestions: "Try a different search or remove filters"
  - [ ] Subtask: Show tips: "Tip: Use broader terms or check spelling"
  - [ ] Subtask: Optional: Show "Clear Filters" button if filters active

**Phase 7: Result Interaction (AC: 7)**
- [ ] **Task 9.6.7:** Handle result clicks
  - [ ] Subtask: Wrap result item in NavigationLink: `NavigationLink(value: video) { ... }`
  - [ ] Subtask: Navigate to video detail view: `.navigationDestination(for: VideoItem.self) { video in VideoDetailView(video: video) }`
  - [ ] Subtask: Alternative: Start playback immediately on click (user preference)
  - [ ] Subtask: Track click analytics (optional, opt-in): log which results are clicked

**Phase 8: Related Videos (AC: 8 - Optional)**
- [ ] **Task 9.6.8:** Show related videos section
  - [ ] Subtask: For each result, find similar videos using vector similarity
  - [ ] Subtask: Query HNSW index: `let relatedVideos = await vectorIndex.search(query: video.embedding!, k: 5)`
  - [ ] Subtask: Show related videos below main result (collapsible section)
  - [ ] Subtask: Display: "Related: [Video1, Video2, Video3]"
  - [ ] Subtask: Optional feature: Enable in Settings > Search > "Show Related Videos"

**Phase 9: Testing**
- [ ] **Task 9.6.9:** Write search results UI tests
  - [ ] Subtask: Create `MyToobUITests/SearchResultsTests.swift`
  - [ ] Subtask: Test: `testResultsDisplay()` - results shown after search
  - [ ] Subtask: Test: `testGridAndListLayout()` - toggle between grid and list views
  - [ ] Subtask: Test: `testQueryHighlighting()` - search terms highlighted in title
  - [ ] Subtask: Test: `testRelevanceScores()` - scores displayed (optional)
  - [ ] Subtask: Test: `testEmptyState()` - empty state shown when no results
  - [ ] Subtask: Test: `testResultClick()` - clicking result navigates to detail view
  - [ ] Subtask: Test: `testPagination()` - load more results on scroll
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/Views/SearchResultsView.swift`, `MyToobUITests/SearchResultsTests.swift`
- **Layout Options:** Grid for visual browsing, list for detailed scanning (both useful)
- **Query Highlighting:** Use `AttributedString` for inline highlighting (SwiftUI native)
- **Relevance Scores:** Optional display, useful for understanding search quality but can be hidden
- **Pagination:** Infinite scroll preferred over "Load More" button (smoother UX)
- **Related Videos:** Powerful discovery feature but optional (can add performance overhead)

**Testing Requirements:**
- UI tests for results display, layout toggle, highlighting, empty state, clicks, pagination (8 tests in `SearchResultsTests`)
- Integration test: End-to-end search and result display
- Performance test: Verify smooth scrolling with 1,000+ results

---

**Epic 9 Summary:**
All 6 stories in Epic 9 - Hybrid Search & Discovery UX have been fully expanded with detailed task breakdowns. This epic delivers the primary content discovery mechanism for MyToob, combining keyword and vector search with rich filtering and ranking.

**Key Deliverables:**
- Prominent search bar with keyboard shortcut (⌘F)
- Keyword search with exact matching and boolean operators
- Vector similarity search for semantic discovery
- Hybrid search with reciprocal rank fusion (RRF)
- Filter pills for faceted search (duration, date, source, topic)
- Rich results display with highlighting and pagination

**Next Epic:** Epic 10 - Collections & Organization


---

### Epic 10: Collections & Organization (6 stories)

## Story 10.1: Create & Manage Collections

**Status:** Not Started  
**Dependencies:** SwiftData model layer (Epic 1)  
**Epic:** 10 - Collections & Organization

**Full Acceptance Criteria:**
1. "New Collection" button in sidebar under "Collections" section
2. Clicking button shows dialog: "Collection Name" text field + Create/Cancel buttons
3. Collection created in SwiftData with: `name`, `createdAt`, `updatedAt`, `itemCount`, `isAutomatic = false`
4. New collection appears in sidebar under "Collections" section
5. Collection names must be unique (validation error if duplicate)
6. "Rename Collection" context menu action (shows same dialog, updates name)
7. "Delete Collection" context menu action (confirmation dialog: "Delete collection 'Name'? Videos will not be deleted.")
8. Deleted collections removed from sidebar, videos remain in library

**Implementation Phases:**

**Phase 1: Collection Data Model (AC: 3)**
- [ ] **Task 10.1.1:** Create Collection model
  - [ ] Subtask: Create `MyToob/Models/Collection.swift` with `@Model class Collection`
  - [ ] Subtask: Add properties: `@Attribute(.unique) var name: String`, `var createdAt: Date`, `var updatedAt: Date`, `var itemCount: Int`, `var isAutomatic: Bool = false`
  - [ ] Subtask: Add relationship to videos: `@Relationship var videos: [VideoItem] = []` (many-to-many)
  - [ ] Subtask: Add optional description: `var description: String?`
  - [ ] Subtask: Update ModelContainer to include Collection: `.modelContainer(for: [VideoItem.self, ClusterLabel.self, Collection.self])`

**Phase 2: New Collection Button (AC: 1, 2)**
- [ ] **Task 10.1.2:** Add "New Collection" UI
  - [ ] Subtask: In `SidebarView`, under "Collections" section, add button: `Button("New Collection", systemImage: "plus") { showingNewCollection = true }`
  - [ ] Subtask: Add state: `@State private var showingNewCollection = false`
  - [ ] Subtask: Show sheet: `.sheet(isPresented: $showingNewCollection) { NewCollectionView() }`

- [ ] **Task 10.1.3:** Create NewCollectionView
  - [ ] Subtask: Create `MyToob/Views/NewCollectionView.swift` with `struct NewCollectionView: View`
  - [ ] Subtask: Add text field: `TextField("Collection Name", text: $collectionName)`
  - [ ] Subtask: Add Create button: `Button("Create") { createCollection() }`
  - [ ] Subtask: Add Cancel button: `Button("Cancel") { dismiss() }`
  - [ ] Subtask: Validate name not empty: disable Create button if `collectionName.isEmpty`

**Phase 3: Collection Creation (AC: 3, 4)**
- [ ] **Task 10.1.4:** Implement collection creation
  - [ ] Subtask: In `NewCollectionView`, add `createCollection()` function
  - [ ] Subtask: Create new collection: `let collection = Collection(name: collectionName, createdAt: Date(), updatedAt: Date(), itemCount: 0, isAutomatic: false)`
  - [ ] Subtask: Insert into SwiftData: `modelContext.insert(collection); try modelContext.save()`
  - [ ] Subtask: Dismiss sheet: `dismiss()`
  - [ ] Subtask: Collection appears in sidebar immediately (SwiftData @Query reactivity)

**Phase 4: Name Uniqueness Validation (AC: 5)**
- [ ] **Task 10.1.5:** Enforce unique collection names
  - [ ] Subtask: Before creating, check if name exists: `let existing = try modelContext.fetch(FetchDescriptor<Collection>(predicate: #Predicate { $0.name == collectionName }))`
  - [ ] Subtask: If exists, show error: `@State private var errorMessage: String?`
  - [ ] Subtask: Display error below text field: `if let error = errorMessage { Text(error).foregroundColor(.red) }`
  - [ ] Subtask: Error message: "A collection with this name already exists"
  - [ ] Subtask: Prevent creation until name is unique

**Phase 5: Rename Collection (AC: 6)**
- [ ] **Task 10.1.6:** Implement rename action
  - [ ] Subtask: Add context menu to collection in sidebar: `.contextMenu { ... }`
  - [ ] Subtask: "Rename" action: `Button("Rename") { showingRename = true }`
  - [ ] Subtask: Show rename sheet (reuse NewCollectionView or create EditCollectionView)
  - [ ] Subtask: Pre-fill text field with current name: `@State private var newName = collection.name`
  - [ ] Subtask: On save, update: `collection.name = newName; collection.updatedAt = Date(); try modelContext.save()`
  - [ ] Subtask: Validate new name is unique (same logic as creation)

**Phase 6: Delete Collection (AC: 7, 8)**
- [ ] **Task 10.1.7:** Implement delete action
  - [ ] Subtask: Add context menu action: `Button("Delete", role: .destructive) { showingDeleteConfirmation = true }`
  - [ ] Subtask: Show confirmation alert: `.alert("Delete collection '\(collection.name)'?", isPresented: $showingDeleteConfirmation) { ... }`
  - [ ] Subtask: Confirmation message: "Videos will not be deleted."
  - [ ] Subtask: Delete button: `Button("Delete", role: .destructive) { deleteCollection() }`
  - [ ] Subtask: Delete from SwiftData: `modelContext.delete(collection); try modelContext.save()`
  - [ ] Subtask: Videos remain in library (many-to-many relationship, deleting collection doesn't delete videos)

**Phase 7: Testing**
- [ ] **Task 10.1.8:** Write collection management tests
  - [ ] Subtask: Create `MyToobTests/Collections/CollectionManagementTests.swift`
  - [ ] Subtask: Test: `testCreateCollection()` - create collection, verify exists in SwiftData
  - [ ] Subtask: Test: `testUniqueNameValidation()` - duplicate name shows error
  - [ ] Subtask: Test: `testRenameCollection()` - rename updates name and updatedAt
  - [ ] Subtask: Test: `testDeleteCollection()` - delete removes collection, videos remain
  - [ ] Subtask: UI test: Create, rename, delete collection via UI
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/Models/Collection.swift`, `MyToob/Views/NewCollectionView.swift`, `MyToobTests/Collections/CollectionManagementTests.swift`
- **Files to Modify:** `SidebarView.swift` (add "New Collection" button)
- **Model Relationship:** Many-to-many (video can be in multiple collections, collection contains multiple videos)
- **Automatic Flag:** `isAutomatic = false` distinguishes manual collections from Smart Collections (clusters)
- **Validation:** Unique names prevent confusion, standard UX pattern for collections/folders

**Testing Requirements:**
- Unit tests for CRUD operations (6 tests in `CollectionManagementTests`)
- UI test: End-to-end collection creation, rename, delete
- Validation test: Verify unique name enforcement


---

## Story 10.2: Add Videos to Collections

**Status:** Not Started  
**Dependencies:** Story 10.1 (collections must exist)  
**Epic:** 10 - Collections & Organization

**Full Acceptance Criteria:**
1. **Drag-and-drop:** Drag video thumbnail from content area to collection in sidebar, video added to collection
2. **Context menu:** Right-click video → "Add to Collection" → select collection from submenu
3. **Multi-select:** Select multiple videos (Shift+click or Cmd+click), add all to collection in one action
4. Video can belong to multiple collections (many-to-many relationship)
5. Visual feedback: collection highlights on drag-over, shows "+" icon on drop
6. "Already in collection" handled gracefully: no error, video not duplicated
7. Collections show updated video count immediately after add

**Implementation Phases:**

**Phase 1: Drag-and-Drop Infrastructure (AC: 1, 5)**
- [ ] **Task 10.2.1:** Implement video dragging
  - [ ] Subtask: Make video thumbnails draggable: `.draggable(video)` on video view
  - [ ] Subtask: Set drag data: `NSItemProvider(object: video.id as NSString)`
  - [ ] Subtask: Add drag preview: thumbnail image

- [ ] **Task 10.2.2:** Implement collection drop target
  - [ ] Subtask: Make collection items in sidebar accept drops: `.dropDestination(for: String.self) { ... }`
  - [ ] Subtask: On drag over, highlight collection: change background color or show outline
  - [ ] Subtask: Show "+" icon during drag-over: overlay plus icon on collection item
  - [ ] Subtask: On drop, add video to collection: `collection.videos.append(video); try modelContext.save()`

**Phase 2: Context Menu "Add to Collection" (AC: 2)**
- [ ] **Task 10.2.3:** Add context menu action
  - [ ] Subtask: On video thumbnail, add context menu: `.contextMenu { ... }`
  - [ ] Subtask: Add "Add to Collection" submenu: `Menu("Add to Collection") { ... }`
  - [ ] Subtask: List all collections: `ForEach(collections) { collection in Button(collection.name) { addToCollection(video, collection) } }`
  - [ ] Subtask: Fetch collections: `@Query var collections: [Collection]`

- [ ] **Task 10.2.4:** Implement add to collection logic
  - [ ] Subtask: Create `addToCollection(_ video: VideoItem, _ collection: Collection)` function
  - [ ] Subtask: Check if video already in collection: `if collection.videos.contains(video) { return }`
  - [ ] Subtask: Add video: `collection.videos.append(video)`
  - [ ] Subtask: Update metadata: `collection.updatedAt = Date(); collection.itemCount += 1`
  - [ ] Subtask: Save: `try modelContext.save()`

**Phase 3: Multi-Select Support (AC: 3)**
- [ ] **Task 10.2.5:** Implement multi-select
  - [ ] Subtask: Add selection state: `@State private var selectedVideos: Set<VideoItem.ID> = []`
  - [ ] Subtask: Shift+click: select range from last selected to clicked item
  - [ ] Subtask: Cmd+click: toggle individual item selection
  - [ ] Subtask: Show selection visually: checkmark or highlighted border on thumbnail

- [ ] **Task 10.2.6:** Bulk add to collection
  - [ ] Subtask: Context menu on selected videos: "Add \(selectedVideos.count) videos to Collection"
  - [ ] Subtask: Show collection picker
  - [ ] Subtask: Add all selected videos to chosen collection: `for videoID in selectedVideos { addToCollection(video, collection) }`
  - [ ] Subtask: Show confirmation: "Added \(count) videos to '\(collection.name)'"

**Phase 4: Many-to-Many Relationship (AC: 4)**
- [ ] **Task 10.2.7:** Verify many-to-many works
  - [ ] Subtask: SwiftData `@Relationship` already supports many-to-many
  - [ ] Subtask: Test: Add same video to multiple collections, verify appears in both
  - [ ] Subtask: Test: Remove video from one collection, verify still in others

**Phase 5: Duplicate Handling (AC: 6)**
- [ ] **Task 10.2.8:** Handle adding video already in collection
  - [ ] Subtask: Check before adding: `if collection.videos.contains(where: { $0.id == video.id }) { return }`
  - [ ] Subtask: Silent no-op (don't show error, just ignore duplicate add)
  - [ ] Subtask: Optionally: Show toast "Video already in collection" (informational, not error)

**Phase 6: Item Count Updates (AC: 7)**
- [ ] **Task 10.2.9:** Update collection item counts
  - [ ] Subtask: After adding video: `collection.itemCount = collection.videos.count`
  - [ ] Subtask: Alternative: Use computed property: `var itemCount: Int { videos.count }`
  - [ ] Subtask: Sidebar updates immediately (SwiftData reactivity)

**Phase 7: Testing**
- [ ] **Task 10.2.10:** Write video addition tests
  - [ ] Subtask: Create `MyToobTests/Collections/AddToCollectionTests.swift`
  - [ ] Subtask: Test: `testDragAndDrop()` - drag video to collection
  - [ ] Subtask: Test: `testContextMenuAdd()` - add via context menu
  - [ ] Subtask: Test: `testMultiSelectAdd()` - add multiple videos at once
  - [ ] Subtask: Test: `testManyToMany()` - video in multiple collections
  - [ ] Subtask: Test: `testDuplicatePrevention()` - adding twice doesn't duplicate
  - [ ] Subtask: UI test: Drag-and-drop workflow
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `VideoThumbnailView.swift` (add drag and context menu), `SidebarView.swift` (drop destination)
- **Drag-and-Drop:** Use `.draggable()` and `.dropDestination()` modifiers (SwiftUI native)
- **Multi-Select:** Standard macOS pattern (Shift for range, Cmd for toggle)
- **Many-to-Many:** SwiftData handles inverse relationships automatically
- **Item Count:** Can be computed property or stored (computed is safer, always accurate)

**Testing Requirements:**
- Unit tests for add logic, many-to-many, duplicate prevention (6 tests in `AddToCollectionTests`)
- UI test: Drag-and-drop and context menu workflows
- Integration test: Multi-select bulk add

---

## Story 10.3: Collection Detail View

**Status:** Not Started  
**Dependencies:** Story 10.2 (videos must be in collections)  
**Epic:** 10 - Collections & Organization

**Full Acceptance Criteria:**
1. Clicking collection in sidebar loads collection detail view in main content area
2. Detail view shows: collection name (editable), description (optional text field), video count, creation date
3. Videos displayed in grid/list (same layout as library view)
4. Videos reorderable via drag-and-drop within collection (custom sort order)
5. "Remove from Collection" action on individual videos (right-click menu or delete key)
6. "Play All" button starts playback queue of all videos in collection
7. Empty collection shows: "This collection is empty. Drag videos here to add them."

**Implementation Phases:**

**Phase 1: Navigation to Detail View (AC: 1)**
- [ ] **Task 10.3.1:** Set up navigation
  - [ ] Subtask: Wrap sidebar collection items in NavigationLink: `NavigationLink(value: collection) { ... }`
  - [ ] Subtask: Add navigation destination: `.navigationDestination(for: Collection.self) { collection in CollectionDetailView(collection: collection) }`

**Phase 2: Detail View Header (AC: 2)**
- [ ] **Task 10.3.2:** Create CollectionDetailView
  - [ ] Subtask: Create `MyToob/Views/CollectionDetailView.swift` with `struct CollectionDetailView: View`
  - [ ] Subtask: Accept collection: `let collection: Collection`
  - [ ] Subtask: Show editable name: `TextField("Collection Name", text: $collection.name)`
  - [ ] Subtask: Show description: `TextEditor(text: $collection.description ?? "")`
  - [ ] Subtask: Show metadata: `Text("\(collection.itemCount) videos • Created \(collection.createdAt, format: .date)")`

**Phase 3: Video Grid/List Display (AC: 3)**
- [ ] **Task 10.3.3:** Display collection videos
  - [ ] Subtask: Fetch videos: `let videos = collection.videos`
  - [ ] Subtask: Show in grid or list (user preference): reuse VideoGridView or VideoListView
  - [ ] Subtask: Grid layout: `LazyVGrid(columns: gridColumns) { ForEach(videos) { ... } }`

**Phase 4: Video Reordering (AC: 4)**
- [ ] **Task 10.3.4:** Implement custom sort order
  - [ ] Subtask: Add `sortOrder` property to Collection-Video relationship (if needed): store index
  - [ ] Subtask: Make videos draggable within collection: `.draggable(video)`
  - [ ] Subtask: On drop, reorder: move video to new position in array
  - [ ] Subtask: Update sort indices: `for (index, video) in videos.enumerated() { video.sortOrder = index }`
  - [ ] Subtask: Save order: `try modelContext.save()`

**Phase 5: Remove from Collection (AC: 5)**
- [ ] **Task 10.3.5:** Implement removal action
  - [ ] Subtask: Add context menu to videos: `.contextMenu { Button("Remove from Collection", role: .destructive) { removeFromCollection(video) } }`
  - [ ] Subtask: Implement `removeFromCollection(_ video: VideoItem)`:
    - `collection.videos.removeAll { $0.id == video.id }`
    - `collection.itemCount -= 1`
    - `try modelContext.save()`
  - [ ] Subtask: Support Delete key: `.onDeleteCommand { removeSelectedVideos() }`

**Phase 6: Play All Button (AC: 6)**
- [ ] **Task 10.3.6:** Implement playback queue
  - [ ] Subtask: Add "Play All" button in toolbar: `Button("Play All", systemImage: "play.fill") { playAll() }`
  - [ ] Subtask: Create playback queue: `let queue = collection.videos`
  - [ ] Subtask: Start playback with first video: navigate to player with queue
  - [ ] Subtask: Auto-advance to next video on completion (Story 3.3 integration)

**Phase 7: Empty State (AC: 7)**
- [ ] **Task 10.3.7:** Show empty collection state
  - [ ] Subtask: Check if collection empty: `if collection.videos.isEmpty { ... }`
  - [ ] Subtask: Show placeholder: `ContentUnavailableView("This collection is empty", systemImage: "tray", description: Text("Drag videos here to add them"))`
  - [ ] Subtask: Make entire view a drop target for adding videos

**Phase 8: Testing**
- [ ] **Task 10.3.8:** Write collection detail tests
  - [ ] Subtask: Create `MyToobUITests/CollectionDetailViewTests.swift`
  - [ ] Subtask: Test: `testNavigationToDetail()` - clicking collection opens detail view
  - [ ] Subtask: Test: `testEditName()` - edit collection name
  - [ ] Subtask: Test: `testReorderVideos()` - drag to reorder
  - [ ] Subtask: Test: `testRemoveVideo()` - remove video from collection
  - [ ] Subtask: Test: `testPlayAll()` - play all button starts playback
  - [ ] Subtask: Test: `testEmptyState()` - empty collection shows placeholder
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/Views/CollectionDetailView.swift`, `MyToobUITests/CollectionDetailViewTests.swift`
- **Editable Name:** Use `TextField` bound to collection.name (SwiftData auto-saves on edit)
- **Reordering:** Store sort order as relationship property or use array indices
- **Play All:** Create playback queue from collection videos (sequential playback)
- **Empty State:** Use `ContentUnavailableView` (iOS 17+/macOS 14+) for polished empty state

**Testing Requirements:**
- UI tests for navigation, editing, reordering, removal, playback (6 tests in `CollectionDetailViewTests`)
- Integration test: End-to-end collection detail view workflow


---

## Story 10.4: Collection Export to Markdown

**Status:** Not Started  
**Dependencies:** Story 10.3 (collection detail view)  
**Epic:** 10 - Collections & Organization

**Full Acceptance Criteria:**
1. "Export Collection..." button in collection detail view
2. Clicking button shows save dialog (file picker, default filename: "CollectionName.md")
3. Exported Markdown includes: collection name as H1, description (if present), video list with YouTube links or local file paths, timestamps, notes (if any)
4. Format example (from AC)
5. Export succeeds with confirmation: "Collection exported to [path]"
6. Exported file opens in default Markdown viewer (optional)

**Implementation Phases:**

**Phase 1: Export Button UI (AC: 1)**
- [ ] **Task 10.4.1:** Add export button
  - [ ] Subtask: In `CollectionDetailView` toolbar, add button: `Button("Export...", systemImage: "square.and.arrow.up") { showingExport = true }`
  - [ ] Subtask: Add state: `@State private var showingExport = false`

**Phase 2: File Save Dialog (AC: 2)**
- [ ] **Task 10.4.2:** Show file picker
  - [ ] Subtask: Use `NSOpenPanel` for save dialog (macOS): `let panel = NSSavePanel()`
  - [ ] Subtask: Set default filename: `panel.nameFieldStringValue = "\(collection.name).md"`
  - [ ] Subtask: Set allowed file types: `panel.allowedContentTypes = [.markdown]`
  - [ ] Subtask: Show panel: `panel.begin { response in ... }`
  - [ ] Subtask: On OK, get selected URL: `if response == .OK, let url = panel.url { ... }`

**Phase 3: Markdown Generation (AC: 3, 4)**
- [ ] **Task 10.4.3:** Generate Markdown content
  - [ ] Subtask: Create `generateMarkdown(for collection: Collection) -> String` function
  - [ ] Subtask: Start with H1: `var markdown = "# \(collection.name)\n\n"`
  - [ ] Subtask: Add description: `if let description = collection.description { markdown += "\(description)\n\n" }`
  - [ ] Subtask: Add "## Videos" header: `markdown += "## Videos\n\n"`
  - [ ] Subtask: For each video, format entry:
    ```swift
    for (index, video) in collection.videos.enumerated() {
      markdown += "\(index + 1). **\(video.title)**"
      if let videoID = video.videoID {
        markdown += " ([Watch on YouTube](https://youtube.com/watch?v=\(videoID)))\n"
      } else if let localURL = video.localURL {
        markdown += " (\(localURL.path))\n"
      }
      markdown += "   - Duration: \(formatDuration(video.duration))\n"
      if let createdAt = video.createdAt {
        markdown += "   - Added: \(createdAt.formatted(date: .abbreviated, time: .omitted))\n"
      }
      if let notes = video.notes, !notes.isEmpty {
        markdown += "   - Notes: \(notes)\n"
      }
      markdown += "\n"
    }
    ```
  - [ ] Subtask: Return complete Markdown string

**Phase 4: File Writing (AC: 3)**
- [ ] **Task 10.4.4:** Write Markdown to file
  - [ ] Subtask: Generate markdown: `let markdown = generateMarkdown(for: collection)`
  - [ ] Subtask: Write to file: `try markdown.write(to: url, atomically: true, encoding: .utf8)`
  - [ ] Subtask: Handle errors: catch and show alert if write fails

**Phase 5: Export Confirmation (AC: 5)**
- [ ] **Task 10.4.5:** Show success message
  - [ ] Subtask: On successful export, show toast or alert: "Collection exported to \(url.path)"
  - [ ] Subtask: Log export: "Exported collection '\(collection.name)' to \(url.path)"

**Phase 6: Open in Markdown Viewer (AC: 6 - Optional)**
- [ ] **Task 10.4.6:** Open exported file
  - [ ] Subtask: After export, prompt user: "Export complete. Open file?"
  - [ ] Subtask: On Yes, open in default app: `NSWorkspace.shared.open(url)`
  - [ ] Subtask: This opens file in default Markdown viewer/editor (e.g., Typora, VSCode, TextEdit)

**Phase 7: Testing**
- [ ] **Task 10.4.7:** Write export tests
  - [ ] Subtask: Create `MyToobTests/Collections/CollectionExportTests.swift`
  - [ ] Subtask: Test: `testMarkdownGeneration()` - verify Markdown format correct
  - [ ] Subtask: Test with YouTube video: verify YouTube link included
  - [ ] Subtask: Test with local video: verify file path included
  - [ ] Subtask: Test with notes: verify notes appear in output
  - [ ] Subtask: Test: `testFileExport()` - write to temp file, verify content
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `MyToob/Views/CollectionDetailView.swift` (add export button and logic)
- **Markdown Format:** Follow standard Markdown conventions (H1, H2, numbered lists, links)
- **YouTube Links:** Format as `https://youtube.com/watch?v={videoID}`
- **Local Files:** Include full file path or relative path (consider user preference)
- **Duration Formatting:** Convert seconds to "HH:MM:SS" or "MM:SS" format
- **Use Case:** Sharing research collections, archiving playlists, exporting to note-taking apps

**Testing Requirements:**
- Unit tests for Markdown generation with various video types (5 tests in `CollectionExportTests`)
- Integration test: Export collection, read file, verify content matches expected format

---

## Story 10.5: AI-Suggested Tags

**Status:** Not Started  
**Dependencies:** Story 8.3 (cluster labels), Story 7.1 (embeddings)  
**Epic:** 10 - Collections & Organization

**Full Acceptance Criteria:**
1. "Suggested Tags" shown in video detail view (below title/description)
2. Tags generated from: cluster membership (cluster label keywords), frequent keywords in similar videos, metadata analysis
3. Tags displayed as chips/pills (clickable)
4. Clicking suggested tag applies it to video (adds to `VideoItem.aiTopicTags`)
5. Applied tags shown separately from suggestions (visual distinction)
6. "Dismiss" button on suggested tags (removes suggestion, doesn't apply tag)
7. Suggestions refreshed when AI model or clustering updates

**Implementation Phases:**

**Phase 1: Tag Generation Logic (AC: 2)**
- [ ] **Task 10.5.1:** Generate tag suggestions
  - [ ] Subtask: Create `generateTagSuggestions(for video: VideoItem) -> [String]` function
  - [ ] Subtask: **Source 1 - Cluster keywords:** If video in cluster, extract keywords from cluster label
  - [ ] Subtask: Example: Cluster "Swift Concurrency Async" → suggest tags ["Swift", "Concurrency", "Async"]
  - [ ] Subtask: **Source 2 - Similar videos:** Find top-5 similar videos using vector search
  - [ ] Subtask: Extract frequent keywords from similar videos' titles and tags
  - [ ] Subtask: **Source 3 - Metadata:** Analyze video title/description for important keywords (TF-IDF or frequency)
  - [ ] Subtask: Combine suggestions: union of all sources, limit to top 5-10 tags
  - [ ] Subtask: Filter out already-applied tags: `suggestions.filter { !video.aiTopicTags.contains($0) }`

**Phase 2: Suggested Tags UI (AC: 1, 3)**
- [ ] **Task 10.5.2:** Display suggested tags
  - [ ] Subtask: In `VideoDetailView`, add "Suggested Tags" section
  - [ ] Subtask: Generate suggestions: `let suggestions = generateTagSuggestions(for: video)`
  - [ ] Subtask: Display as chips: `ForEach(suggestions, id: \.self) { tag in Button(tag) { applySuggestedTag(tag) } }`
  - [ ] Subtask: Style as pills: `.buttonStyle(.bordered)`, rounded corners
  - [ ] Subtask: Position below title/description, above video metadata

**Phase 3: Apply Suggested Tag (AC: 4)**
- [ ] **Task 10.5.3:** Implement tag application
  - [ ] Subtask: Create `applySuggestedTag(_ tag: String)` function
  - [ ] Subtask: Add to video tags: `video.aiTopicTags.append(tag)`
  - [ ] Subtask: Remove from suggestions: `suggestions.removeAll { $0 == tag }`
  - [ ] Subtask: Save: `try modelContext.save()`
  - [ ] Subtask: Show feedback: briefly highlight added tag

**Phase 4: Applied vs. Suggested Tags (AC: 5)**
- [ ] **Task 10.5.4:** Distinguish applied and suggested tags
  - [ ] Subtask: Show applied tags separately: "Tags" section with existing `video.aiTopicTags`
  - [ ] Subtask: Style applied tags differently: solid background color (e.g., blue)
  - [ ] Subtask: Style suggested tags: outline only or lighter color (e.g., gray border)
  - [ ] Subtask: Applied tags not clickable (or click to remove)
  - [ ] Subtask: Suggested tags clickable to apply

**Phase 5: Dismiss Suggestion (AC: 6)**
- [ ] **Task 10.5.5:** Add dismiss action
  - [ ] Subtask: Add X button to each suggested tag: `Button(action: { dismissSuggestion(tag) }) { Image(systemName: "xmark") }`
  - [ ] Subtask: Implement `dismissSuggestion(_ tag: String)`: remove from suggestions, don't apply
  - [ ] Subtask: Optional: Store dismissed tags to avoid re-suggesting: `video.dismissedTagSuggestions = [tag]`

**Phase 6: Refresh Suggestions (AC: 7)**
- [ ] **Task 10.5.6:** Update suggestions on AI changes
  - [ ] Subtask: Regenerate suggestions when clustering updates (Story 8.5 re-clustering)
  - [ ] Subtask: Regenerate when embedding model updates
  - [ ] Subtask: Add "Refresh Suggestions" button for manual refresh
  - [ ] Subtask: Suggestions auto-refresh when video detail view appears (`.onAppear { refreshSuggestions() }`)

**Phase 7: Testing**
- [ ] **Task 10.5.7:** Write tag suggestion tests
  - [ ] Subtask: Create `MyToobTests/Collections/TagSuggestionTests.swift`
  - [ ] Subtask: Test: `testSuggestionGeneration()` - suggestions from cluster keywords
  - [ ] Subtask: Test: `testSimilarVideoTags()` - suggestions from similar videos
  - [ ] Subtask: Test: `testApplyTag()` - applying tag adds to video.aiTopicTags
  - [ ] Subtask: Test: `testDismissTag()` - dismissing removes from suggestions
  - [ ] Subtask: Test: `testFilterAppliedTags()` - already-applied tags not suggested
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `MyToob/Views/VideoDetailView.swift` (add suggested tags section)
- **Tag Sources:** Cluster keywords (most relevant), similar videos (contextual), metadata (fallback)
- **UX:** Clickable chips make tagging fast and intuitive
- **Distinction:** Visual difference between applied and suggested tags prevents confusion
- **Dismiss:** Allows users to hide irrelevant suggestions without applying them
- **Refresh:** Suggestions improve as AI models and clustering evolve

**Testing Requirements:**
- Unit tests for tag generation, application, dismissal (5 tests in `TagSuggestionTests`)
- Integration test: Generate suggestions for video in cluster, verify cluster keywords suggested

---

## Story 10.6: Bulk Operations on Multiple Videos

**Status:** Not Started  
**Dependencies:** Story 10.2 (multi-select), Story 10.1 (collections)  
**Epic:** 10 - Collections & Organization

**Full Acceptance Criteria:**
1. Multi-select supported: Shift+click (range select), Cmd+click (individual select)
2. Selection shown visually (checkmarks or highlighted borders on thumbnails)
3. Bulk actions available: "Add to Collection", "Remove from Collection", "Add Tag", "Mark as Watched", "Delete"
4. Bulk action confirmation dialog: "Add 15 videos to 'Swift Tutorials'?"
5. Bulk operations atomic: all succeed or all fail (rollback on error)
6. Progress indicator for slow bulk operations (e.g., deleting 1000 videos)
7. "Select All" / "Deselect All" actions (keyboard shortcuts: Cmd+A, Escape)

**Implementation Phases:**

**Phase 1: Multi-Select Implementation (AC: 1)**
- [ ] **Task 10.6.1:** Implement selection state
  - [ ] Subtask: Add selection state: `@State private var selectedVideoIDs: Set<VideoItem.ID> = []`
  - [ ] Subtask: Track last selected: `@State private var lastSelectedID: VideoItem.ID?` (for range selection)

- [ ] **Task 10.6.2:** Implement click handlers
  - [ ] Subtask: On video click, check modifiers:
    - No modifier: Clear selection, select clicked video
    - Cmd: Toggle clicked video in selection
    - Shift: Select range from last selected to clicked video
  - [ ] Subtask: Shift+click range: find indices of last and clicked, select all between

**Phase 2: Visual Selection Feedback (AC: 2)**
- [ ] **Task 10.6.3:** Show selection visually
  - [ ] Subtask: Add checkmark overlay on selected videos: `if selectedVideoIDs.contains(video.id) { Image(systemName: "checkmark.circle.fill") }`
  - [ ] Subtask: Alternative: Highlight border with blue outline
  - [ ] Subtask: Selection count shown in toolbar: `Text("\(selectedVideoIDs.count) selected")`

**Phase 3: Bulk Actions Menu (AC: 3)**
- [ ] **Task 10.6.4:** Add bulk actions toolbar
  - [ ] Subtask: When videos selected, show bulk actions: `if !selectedVideoIDs.isEmpty { ... }`
  - [ ] Subtask: "Add to Collection" button: shows collection picker
  - [ ] Subtask: "Remove from Collection" button (only in collection detail view)
  - [ ] Subtask: "Add Tag" button: shows tag input field
  - [ ] Subtask: "Mark as Watched" button: sets watchProgress = duration for all selected
  - [ ] Subtask: "Delete" button (destructive action, red color)

**Phase 4: Confirmation Dialogs (AC: 4)**
- [ ] **Task 10.6.5:** Show confirmations for bulk actions
  - [ ] Subtask: Before action, show alert: `"Add \(selectedVideoIDs.count) videos to '\(collection.name)'?"`
  - [ ] Subtask: Confirmation for destructive actions: "Delete \(selectedVideoIDs.count) videos? This cannot be undone."
  - [ ] Subtask: Optional: "Don't ask again" checkbox (store preference)

**Phase 5: Atomic Operations (AC: 5)**
- [ ] **Task 10.6.6:** Ensure all-or-nothing execution
  - [ ] Subtask: Wrap bulk operations in transaction: SwiftData `modelContext` handles atomicity
  - [ ] Subtask: On error, rollback: catch errors and don't save context
  - [ ] Subtask: Example: `do { for id in selectedVideoIDs { ... } try modelContext.save() } catch { modelContext.rollback() }`
  - [ ] Subtask: Show error message if operation fails: "Bulk operation failed: \(error.localizedDescription)"

**Phase 6: Progress Indicators (AC: 6)**
- [ ] **Task 10.6.7:** Show progress for slow operations
  - [ ] Subtask: For operations on >100 videos, show progress bar
  - [ ] Subtask: Update progress: `@State private var operationProgress: Double = 0.0`
  - [ ] Subtask: Display: `ProgressView(value: operationProgress)`
  - [ ] Subtask: Example: Deleting 1000 videos shows progress from 0% to 100%

**Phase 7: Select All / Deselect All (AC: 7)**
- [ ] **Task 10.6.8:** Add select/deselect actions
  - [ ] Subtask: "Select All" action: `selectedVideoIDs = Set(videos.map { $0.id })`
  - [ ] Subtask: Keyboard shortcut: Cmd+A triggers select all
  - [ ] Subtask: "Deselect All" action: `selectedVideoIDs = []`
  - [ ] Subtask: Keyboard shortcut: Escape clears selection
  - [ ] Subtask: Add menu items: Edit > Select All / Deselect All

**Phase 8: Testing**
- [ ] **Task 10.6.9:** Write bulk operations tests
  - [ ] Subtask: Create `MyToobTests/Collections/BulkOperationsTests.swift`
  - [ ] Subtask: Test: `testMultiSelect()` - Shift+click selects range, Cmd+click toggles
  - [ ] Subtask: Test: `testBulkAddToCollection()` - add multiple videos to collection
  - [ ] Subtask: Test: `testBulkMarkWatched()` - mark multiple videos as watched
  - [ ] Subtask: Test: `testAtomicity()` - error rolls back entire operation
  - [ ] Subtask: Test: `testSelectAll()` - Cmd+A selects all videos
  - [ ] Subtask: UI test: Multi-select and bulk add workflow
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `VideoGridView.swift` or `VideoListView.swift` (add selection state and bulk actions)
- **Selection State:** Track selected IDs in Set for O(1) lookup
- **Keyboard Shortcuts:** Standard macOS shortcuts (Cmd+A, Shift+click, Escape)
- **Atomicity:** SwiftData ModelContext provides transaction-like behavior (save or rollback)
- **Progress:** Show for operations >100 items or taking >2 seconds
- **Use Cases:** Organizing large libraries, cleaning up watched videos, batch tagging

**Testing Requirements:**
- Unit tests for selection logic, bulk actions, atomicity (6 tests in `BulkOperationsTests`)
- UI test: End-to-end multi-select and bulk operation workflow
- Performance test: Bulk operation on 1000 videos completes in reasonable time (<10 seconds)

---

**Epic 10 Summary:**
All 6 stories in Epic 10 - Collections & Organization have been fully expanded with detailed task breakdowns. This epic enables manual curation and organization of video libraries, complementing AI-powered Smart Collections.

**Key Deliverables:**
- Create and manage custom collections (CRUD operations)
- Add videos to collections via drag-and-drop and context menu
- Collection detail view with reordering and playback queue
- Export collections to Markdown for sharing and archiving
- AI-suggested tags for quick labeling
- Bulk operations for efficient library management

**Next Epic:** Epic 11 - Research Tools & Note-Taking


---

### Epic 11: Research Tools & Note-Taking (6 stories)

## Story 11.1: Inline Note Editor for Videos

**Status:** Not Started  
**Dependencies:** VideoItem model (Epic 1), Video detail view  
**Epic:** 11 - Research Tools & Note-Taking

**Full Acceptance Criteria:**
1. Video detail view shows note editor panel (below or beside video player)
2. Note editor supports Markdown formatting: headings, bold, italic, lists, code blocks
3. Markdown preview toggle (show formatted output vs. raw Markdown)
4. Note autosaved every 5 seconds or on focus loss
5. Notes stored in `Note` model with relationship to `VideoItem`
6. Multiple notes per video supported (user can create "New Note" button)
7. Note editor accessible via keyboard shortcut: ⌘N (while viewing video)

**Implementation Phases:**

**Phase 1: Note Data Model (AC: 5)**
- [ ] **Task 11.1.1:** Create Note model
  - [ ] Subtask: Create `MyToob/Models/Note.swift` with `@Model class Note`
  - [ ] Subtask: Add properties: `var content: String = ""`, `var createdAt: Date`, `var updatedAt: Date`, `var title: String?`
  - [ ] Subtask: Add relationship to video: `@Relationship(inverse: \VideoItem.notes) var video: VideoItem?`
  - [ ] Subtask: Update VideoItem: `@Relationship var notes: [Note] = []`
  - [ ] Subtask: Update ModelContainer to include Note: `.modelContainer(for: [VideoItem.self, ClusterLabel.self, Collection.self, Note.self])`

**Phase 2: Note Editor UI (AC: 1)**
- [ ] **Task 11.1.2:** Add note editor to video detail view
  - [ ] Subtask: In `VideoDetailView`, add note editor panel: position below player or in sidebar
  - [ ] Subtask: Use splitscreen layout: video player top/left, note editor bottom/right
  - [ ] Subtask: Resizable split: user can adjust relative sizes
  - [ ] Subtask: Create `NoteEditorView` component

**Phase 3: Markdown Editor (AC: 2)**
- [ ] **Task 11.1.3:** Implement Markdown text editor
  - [ ] Subtask: Use `TextEditor` for input: `TextEditor(text: $note.content)`
  - [ ] Subtask: Add Markdown toolbar: buttons for bold, italic, heading, list, code block
  - [ ] Subtask: Bold button: wrap selection with `**text**`
  - [ ] Subtask: Italic button: wrap selection with `*text*`
  - [ ] Subtask: Heading button: prepend `## ` to line
  - [ ] Subtask: List button: prepend `- ` to line
  - [ ] Subtask: Code block button: wrap selection with ``` (triple backticks)
  - [ ] Subtask: Keyboard shortcuts for formatting: Cmd+B (bold), Cmd+I (italic), etc.

**Phase 4: Markdown Preview (AC: 3)**
- [ ] **Task 11.1.4:** Add preview toggle
  - [ ] Subtask: Add toggle button: "Edit" / "Preview"
  - [ ] Subtask: In preview mode, render Markdown: use `AttributedString` or external library (e.g., swift-markdown)
  - [ ] Subtask: Show formatted output: headings, bold, italic, lists, code blocks styled
  - [ ] Subtask: Optional: Side-by-side preview (editor left, preview right)

**Phase 5: Autosave (AC: 4)**
- [ ] **Task 11.1.5:** Implement autosave
  - [ ] Subtask: Add timer: `Timer.publish(every: 5, on: .main, in: .common).autoconnect()`
  - [ ] Subtask: On timer fire, save note: `note.updatedAt = Date(); try modelContext.save()`
  - [ ] Subtask: Save on focus loss: `.onDisappear { saveNote() }`
  - [ ] Subtask: Show autosave indicator: "Saved" or timestamp of last save

**Phase 6: Multiple Notes Per Video (AC: 6)**
- [ ] **Task 11.1.6:** Support multiple notes
  - [ ] Subtask: Show list of notes for video: `List(video.notes) { note in ... }`
  - [ ] Subtask: Add "New Note" button: creates new Note, adds to video.notes
  - [ ] Subtask: Clicking note in list switches to that note in editor
  - [ ] Subtask: Default title: "Note {index}" or first line of content

**Phase 7: Keyboard Shortcut (AC: 7)**
- [ ] **Task 11.1.7:** Add ⌘N shortcut
  - [ ] Subtask: Create menu command: `CommandGroup { Button("New Note") { createNote() }.keyboardShortcut("n", modifiers: .command) }`
  - [ ] Subtask: Only active when viewing video (contextual shortcut)
  - [ ] Subtask: Creates new note and focuses editor

**Phase 8: Testing**
- [ ] **Task 11.1.8:** Write note editor tests
  - [ ] Subtask: Create `MyToobTests/Notes/NoteEditorTests.swift`
  - [ ] Subtask: Test: `testNoteCreation()` - create note, verify stored in SwiftData
  - [ ] Subtask: Test: `testMarkdownFormatting()` - apply bold/italic, verify syntax correct
  - [ ] Subtask: Test: `testAutosave()` - wait 5 seconds, verify note saved
  - [ ] Subtask: Test: `testMultipleNotes()` - create multiple notes per video
  - [ ] Subtask: UI test: Type in editor, verify preview renders correctly
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Create:** `MyToob/Models/Note.swift`, `MyToob/Views/NoteEditorView.swift`, `MyToobTests/Notes/NoteEditorTests.swift`
- **Markdown Library:** Use `swift-markdown` (Apple) or `MarkdownKit` for parsing and rendering
- **Autosave:** Balance between frequent saves and performance (5 seconds is standard)
- **Multiple Notes:** Useful for different aspects (summary, quotes, action items)
- **Split Layout:** Adjustable split allows users to optimize for reading vs. note-taking

**Testing Requirements:**
- Unit tests for note CRUD, autosave, formatting (5 tests in `NoteEditorTests`)
- UI test: Create note, apply formatting, verify preview
- Integration test: Notes persist across app restart

---

(Continuing with remaining 5 stories in Epic 11...)


## Story 11.2: Timestamp-Anchored Notes

**Status:** Not Started  
**Dependencies:** Story 11.1 (note editor), Story 3.3 (player state)  
**Epic:** 11 - Research Tools & Note-Taking

**Full Acceptance Criteria:**
1. "Insert Timestamp" button in note editor (or keyboard shortcut: ⌘T)
2. Clicking button inserts current video playback time into note: `[15:30]` (MM:SS format)
3. Timestamp rendered as clickable link in Markdown preview
4. Clicking timestamp seeks video to that time and starts playback
5. Timestamps shown in sidebar "Notes" list with preview text
6. Notes automatically sorted by first timestamp (chronological order within video)
7. Timestamp format respects video length (HH:MM:SS for videos >1 hour)

**Implementation Phases:**

**Phase 1: Insert Timestamp Button (AC: 1)**
- [ ] **Task 11.2.1:** Add timestamp insertion UI
  - [ ] Subtask: In note editor toolbar, add "Insert Timestamp" button: `Button("Insert Timestamp", systemImage: "clock") { insertTimestamp() }`
  - [ ] Subtask: Keyboard shortcut: `.keyboardShortcut("t", modifiers: .command)`
  - [ ] Subtask: Button enabled only when video is playing or paused (not when no video loaded)

**Phase 2: Get Current Playback Time (AC: 2)**
- [ ] **Task 11.2.2:** Retrieve current video time
  - [ ] Subtask: Access player state from video player (IFrame or AVPlayer)
  - [ ] Subtask: For YouTube IFrame Player: call `getCurrentTime()` via JavaScript bridge
  - [ ] Subtask: For local AVPlayer: get `currentTime()` from AVPlayer instance
  - [ ] Subtask: Convert time to seconds: `let currentSeconds = player.currentTime`

**Phase 3: Format and Insert Timestamp (AC: 2, 7)**
- [ ] **Task 11.2.3:** Format timestamp string
  - [ ] Subtask: Create `formatTimestamp(_ seconds: Double, videoDuration: Double) -> String` function
  - [ ] Subtask: If video duration < 3600s (1 hour): format as MM:SS
  - [ ] Subtask: If video duration >= 3600s: format as HH:MM:SS
  - [ ] Subtask: Example: 930 seconds → "15:30" or "0:15:30"
  - [ ] Subtask: Pad with zeros: 5 seconds → "0:05"

- [ ] **Task 11.2.4:** Insert into note
  - [ ] Subtask: Get cursor position in TextEditor
  - [ ] Subtask: Insert timestamp at cursor: `note.content.insert(contentsOf: "[\(formattedTime)]", at: cursorPosition)`
  - [ ] Subtask: Alternative format: `[15:30](timestamp:930)` (includes both display and actual seconds)

**Phase 4: Render Timestamp as Link (AC: 3)**
- [ ] **Task 11.2.5:** Parse timestamps in Markdown preview
  - [ ] Subtask: Detect timestamp pattern: regex `\[(\d{1,2}:\d{2}(:\d{2})?)\]`
  - [ ] Subtask: Render as clickable link in preview: `Button("[15:30]") { seekToTimestamp(930) }`
  - [ ] Subtask: Style as link: blue color, underline on hover

**Phase 5: Seek to Timestamp (AC: 4)**
- [ ] **Task 11.2.6:** Implement timestamp navigation
  - [ ] Subtask: Parse timestamp string to seconds: `parseTimestamp("15:30") -> 930`
  - [ ] Subtask: For YouTube: call `seekTo(seconds)` via JavaScript bridge
  - [ ] Subtask: For local video: call `player.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))`
  - [ ] Subtask: Start playback after seek: call `playVideo()` or `player.play()`

**Phase 6: Timestamps in Notes List (AC: 5)**
- [ ] **Task 11.2.7:** Show timestamps in note previews
  - [ ] Subtask: In notes list, extract first timestamp from note content
  - [ ] Subtask: Display: "[15:30] Key concept about async..." (timestamp + preview text)
  - [ ] Subtask: Clicking note in list seeks to first timestamp if present

**Phase 7: Chronological Sorting (AC: 6)**
- [ ] **Task 11.2.8:** Sort notes by timestamp
  - [ ] Subtask: Extract first timestamp from each note: `func firstTimestamp(in note: Note) -> Double?`
  - [ ] Subtask: Sort notes: `video.notes.sorted { firstTimestamp(in: $0) ?? 0 < firstTimestamp(in: $1) ?? 0 }`
  - [ ] Subtask: Notes without timestamps appear at end (or beginning, user preference)

**Phase 8: Testing**
- [ ] **Task 11.2.9:** Write timestamp tests
  - [ ] Subtask: Create `MyToobTests/Notes/TimestampTests.swift`
  - [ ] Subtask: Test: `testInsertTimestamp()` - insert timestamp at cursor position
  - [ ] Subtask: Test: `testFormatTimestamp()` - verify MM:SS and HH:MM:SS formats
  - [ ] Subtask: Test: `testParseTimestamp()` - parse string to seconds
  - [ ] Subtask: Test: `testSeekToTimestamp()` - clicking timestamp seeks video
  - [ ] Subtask: Test: `testChronologicalSort()` - notes sorted by first timestamp
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `NoteEditorView.swift` (add timestamp insertion), Markdown preview rendering
- **Timestamp Format:** Use bracket notation `[MM:SS]` for readability
- **Parsing:** Support both MM:SS and HH:MM:SS formats
- **Player Integration:** Requires access to player state (currentTime) and seek functionality
- **Use Case:** Critical for research notes, lecture notes, tutorial annotations

**Testing Requirements:**
- Unit tests for timestamp formatting, parsing, insertion, seeking (6 tests in `TimestampTests`)
- Integration test: Insert timestamp, seek via click, verify video jumps to correct time
- UI test: Click "Insert Timestamp", verify formatted timestamp appears in note

---

## Story 11.3: Bidirectional Links Between Notes

**Status:** Not Started  
**Dependencies:** Story 11.1 (notes exist)  
**Epic:** 11 - Research Tools & Note-Taking

**Full Acceptance Criteria:**
1. Wiki-link syntax supported: `[[Note Title]]` or `[[Video Title > Note]]`
2. Typing `[[` shows autocomplete dropdown with matching note/video titles
3. Links rendered as clickable in Markdown preview
4. Clicking link navigates to linked note/video
5. "Backlinks" section in note editor shows notes that link to current note
6. Orphaned links (linking to non-existent notes) shown in different color (red or gray)
7. "Create Note from Link" action on orphaned links (creates new note with that title)

**Implementation Phases:**

**Phase 1: Wiki-Link Syntax Support (AC: 1)**
- [ ] **Task 11.3.1:** Detect wiki-link syntax
  - [ ] Subtask: Parse note content for `[[...]]` pattern using regex: `\[\[(.*?)\]\]`
  - [ ] Subtask: Extract link text: "Note Title" or "Video Title > Note"
  - [ ] Subtask: Support both formats: `[[Note Title]]` (note only) and `[[Video > Note]]` (note within specific video)

**Phase 2: Autocomplete Dropdown (AC: 2)**
- [ ] **Task 11.3.2:** Implement link autocomplete
  - [ ] Subtask: Detect typing `[[` in TextEditor (monitor text changes)
  - [ ] Subtask: Show dropdown menu below cursor position
  - [ ] Subtask: Fetch all notes and videos: `@Query var allNotes: [Note]`, `@Query var allVideos: [VideoItem]`
  - [ ] Subtask: Filter by query: user types "swift" → show notes/videos with "swift" in title
  - [ ] Subtask: Display format: "Note Title (Video: YouTube video title)" or "Video Title"
  - [ ] Subtask: Selecting item inserts: `[[Selected Title]]`
  - [ ] Subtask: Close dropdown on Escape or clicking outside

**Phase 3: Render Links in Preview (AC: 3)**
- [ ] **Task 11.3.3:** Parse and render wiki-links
  - [ ] Subtask: In Markdown preview, detect `[[...]]` patterns
  - [ ] Subtask: Render as clickable link: `Button(linkText) { navigateToLink(linkText) }`
  - [ ] Subtask: Style as internal link: distinct from external URLs (e.g., purple color)

**Phase 4: Link Navigation (AC: 4)**
- [ ] **Task 11.3.4:** Implement link following
  - [ ] Subtask: Parse link text to determine target: note title or video title
  - [ ] Subtask: For `[[Note Title]]`: find note by title, navigate to video with that note visible
  - [ ] Subtask: For `[[Video Title > Note]]`: find video by title, then find note within that video
  - [ ] Subtask: Navigate: use NavigationStack to push video detail view with note selected
  - [ ] Subtask: If target not found, show error: "Note not found: {title}"

**Phase 5: Backlinks Section (AC: 5)**
- [ ] **Task 11.3.5:** Display backlinks
  - [ ] Subtask: For current note, find all notes that link to it
  - [ ] Subtask: Query: fetch all notes, parse content for `[[Current Note Title]]`
  - [ ] Subtask: Show in "Backlinks" section: `List(backlinks) { note in NavigationLink(note.title) { ... } }`
  - [ ] Subtask: Show count: "3 notes link here"
  - [ ] Subtask: Clicking backlink navigates to that note

**Phase 6: Orphaned Links (AC: 6, 7)**
- [ ] **Task 11.3.6:** Handle orphaned links
  - [ ] Subtask: When rendering link, check if target exists
  - [ ] Subtask: If not found, style differently: red or gray color, dashed underline
  - [ ] Subtask: Show tooltip on hover: "Note not found"

- [ ] **Task 11.3.7:** Create note from orphaned link
  - [ ] Subtask: Right-click orphaned link: "Create Note '{title}'"
  - [ ] Subtask: On click, create new note with that title
  - [ ] Subtask: Add to current video's notes
  - [ ] Subtask: Navigate to new note for editing

**Phase 7: Testing**
- [ ] **Task 11.3.8:** Write bidirectional link tests
  - [ ] Subtask: Create `MyToobTests/Notes/WikiLinksTests.swift`
  - [ ] Subtask: Test: `testParsing()` - parse `[[Note Title]]` correctly
  - [ ] Subtask: Test: `testAutocomplete()` - typing `[[` shows matching notes
  - [ ] Subtask: Test: `testNavigation()` - clicking link navigates to target note
  - [ ] Subtask: Test: `testBacklinks()` - backlinks correctly identified
  - [ ] Subtask: Test: `testOrphanedLink()` - orphaned link styled differently
  - [ ] Subtask: Test: `testCreateFromOrphan()` - create note from orphaned link
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** `NoteEditorView.swift` (autocomplete), Markdown preview (link rendering)
- **Wiki-Link Format:** Standard format used by Obsidian, Roam Research, Notion
- **Autocomplete:** Fuzzy matching improves usability (e.g., "async" matches "Async/Await Tutorial")
- **Backlinks:** Core feature of knowledge management tools (creates graph structure)
- **Orphaned Links:** Allow forward-referencing notes not yet created (common in research)
- **Use Case:** Building connected knowledge base from video research

**Testing Requirements:**
- Unit tests for parsing, autocomplete, navigation, backlinks (6 tests in `WikiLinksTests`)
- Integration test: Create linked notes, verify navigation works both directions
- UI test: Type `[[`, select from autocomplete, verify link inserted

---

## Story 11.4: Note Search & Filtering

**Status:** Not Started  
**Dependencies:** Story 11.1 (notes exist), Story 9.1 (search bar)  
**Epic:** 11 - Research Tools & Note-Taking

**Full Acceptance Criteria:**
1. "Search Notes" tab or filter in main search bar
2. Query matches note content (full-text search on Markdown text)
3. Search highlights matching terms in note previews
4. Filter by: note creation date, associated video, tags
5. Results show note preview with context (2 lines before/after match)
6. Clicking result opens video detail view with note visible
7. "Recent Notes" view shows last 20 edited notes for quick access

**Implementation Phases:**

**Phase 1: Search Notes UI (AC: 1)**
- [ ] **Task 11.4.1:** Add notes search option
  - [ ] Subtask: In main search bar, add scope selector: "Videos" / "Notes" / "All"
  - [ ] Subtask: Alternative: Dedicated "Search Notes" button or tab
  - [ ] Subtask: When "Notes" selected, search queries notes instead of videos

**Phase 2: Full-Text Search (AC: 2)**
- [ ] **Task 11.4.2:** Implement note content search
  - [ ] Subtask: Query all notes: `@Query var allNotes: [Note]`
  - [ ] Subtask: Filter by query: `notes.filter { $0.content.localizedStandardContains(searchQuery) }`
  - [ ] Subtask: Case-insensitive search
  - [ ] Subtask: Support keyword tokenization (like video search in Story 9.2)

**Phase 3: Highlight Matching Terms (AC: 3)**
- [ ] **Task 11.4.3:** Show highlighted previews
  - [ ] Subtask: Extract preview snippet: find first match in note content
  - [ ] Subtask: Get 2 lines before and after match: ~200 characters of context
  - [ ] Subtask: Highlight search terms in preview: use `AttributedString` to bold/color matches
  - [ ] Subtask: Display: "...previous context **match** following context..."

**Phase 4: Filters (AC: 4)**
- [ ] **Task 11.4.4:** Add note filters
  - [ ] Subtask: Filter by date: "Today", "This Week", "This Month", custom range
  - [ ] Subtask: Compare `note.createdAt` or `note.updatedAt` to date range
  - [ ] Subtask: Filter by video: dropdown showing all videos, select to show only notes from that video
  - [ ] Subtask: Filter by tags: if notes have tags, show tag picker (multi-select)
  - [ ] Subtask: Combine filters: AND logic (all filters must match)

**Phase 5: Context Previews (AC: 5)**
- [ ] **Task 11.4.5:** Generate context snippets
  - [ ] Subtask: Find match position in note content
  - [ ] Subtask: Extract text before match: up to 2 lines or ~100 chars
  - [ ] Subtask: Extract text after match: up to 2 lines or ~100 chars
  - [ ] Subtask: Combine: "...before **match** after..."
  - [ ] Subtask: Truncate with ellipsis if context exceeds limit

**Phase 6: Result Navigation (AC: 6)**
- [ ] **Task 11.4.6:** Open note from search result
  - [ ] Subtask: Clicking result navigates to video detail view
  - [ ] Subtask: Scroll to and highlight the matching note
  - [ ] Subtask: Optionally: Jump to match position within note (scroll to matching line)

**Phase 7: Recent Notes View (AC: 7)**
- [ ] **Task 11.4.7:** Implement recent notes
  - [ ] Subtask: Add "Recent Notes" sidebar section or view
  - [ ] Subtask: Query notes sorted by `updatedAt` descending: `FetchDescriptor<Note>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])`
  - [ ] Subtask: Show last 20 notes: `.limit(20)`
  - [ ] Subtask: Display: note title (or first line), video title, last edit time
  - [ ] Subtask: Clicking note opens video detail view with note visible

**Phase 8: Testing**
- [ ] **Task 11.4.8:** Write note search tests
  - [ ] Subtask: Create `MyToobTests/Notes/NoteSearchTests.swift`
  - [ ] Subtask: Test: `testFullTextSearch()` - query matches note content
  - [ ] Subtask: Test: `testHighlighting()` - matching terms highlighted in preview
  - [ ] Subtask: Test: `testDateFilter()` - filter by creation date works
  - [ ] Subtask: Test: `testVideoFilter()` - filter by associated video works
  - [ ] Subtask: Test: `testRecentNotes()` - last 20 edited notes shown
  - [ ] Subtask: Run all tests and verify pass rate

**Dev Notes:**
- **Files to Modify:** Search UI (add Notes scope), NoteSearchView (dedicated view for note results)
- **Full-Text Search:** SwiftData supports `.localizedStandardContains()` predicate
- **Context Snippets:** Standard search result format (like Google search results)
- **Recent Notes:** Useful for quick access to active research
- **Use Case:** Finding specific insights from past notes without re-watching videos

**Testing Requirements:**
- Unit tests for search, filtering, highlighting (6 tests in `NoteSearchTests`)
- Integration test: Search notes, verify results correct
- UI test: Search notes, click result, verify navigation


## Story 11.5: Note Export & Citation

**Status:** Not Started  
**Dependencies:** Stories 11.1 (Note model), 11.2 (Timestamps)  
**Epic:** Epic 11 - Research Tools & Note-Taking

**Acceptance Criteria:**
1. "Export Notes..." button in video detail view or Settings
2. Export single video's notes or all notes (global export)
3. Exported Markdown includes: note content, video title/link, timestamps, creation date
4. Citation format configurable: YouTube format (APA/MLA/Chicago), local file path, or custom
5. Example exported note format provided in PRD
6. Export format options: Markdown (.md), Plain Text (.txt), PDF (optional)
7. Export success notification: "Notes exported to [path]"

---

### Implementation Phases

**Phase 1: Export UI & Dialog (AC: 1, 7)**

- [ ] **Task 11.5.1:** Add export button to video detail view
  - [ ] Subtask: Add toolbar button: "Export Notes..." (SF Symbol: `square.and.arrow.up`)
  - [ ] Subtask: Position in video detail view toolbar (right side)
  - [ ] Subtask: Keyboard shortcut: ⌘E (Export)
  - [ ] Subtask: Button enabled only if video has notes (disable if `notes.isEmpty`)
  - [ ] Subtask: Tooltip: "Export notes to Markdown file"

- [ ] **Task 11.5.2:** Add global export option in Settings
  - [ ] Subtask: Add "Export All Notes..." button in Settings > Notes section
  - [ ] Subtask: Button triggers export for all notes across all videos
  - [ ] Subtask: Confirmation dialog: "Export all notes? This will create a file with notes from all videos."
  - [ ] Subtask: Cancel and Export buttons

- [ ] **Task 11.5.3:** Implement file save dialog
  - [ ] Subtask: Use `NSOpenPanel` for save destination selection
  - [ ] Subtask: Default filename: `VideoTitle_Notes.md` (single video) or `MyToob_All_Notes.md` (global)
  - [ ] Subtask: Sanitize filename (replace invalid characters: `/`, `\`, `:`, etc.)
  - [ ] Subtask: Allowed file types: `.md`, `.txt`, `.pdf` (if implemented)
  - [ ] Subtask: Remember last export directory (persist in UserDefaults)

- [ ] **Task 11.5.4:** Show export success notification
  - [ ] Subtask: Display banner: "Notes exported to [filename]"
  - [ ] Subtask: Include "Open" button in notification (opens file in default Markdown viewer)
  - [ ] Subtask: Handle export errors: "Export failed: [error message]"
  - [ ] Subtask: Notification auto-dismisses after 5 seconds

**Phase 2: Markdown Export Generation (AC: 3, 5)**

- [ ] **Task 11.5.5:** Create Markdown exporter
  - [ ] Subtask: Create `NoteExporter` class in `MyToob/Services/NoteExporter.swift`
  - [ ] Subtask: Function: `exportNotes(_ notes: [Note], video: VideoItem, format: ExportFormat) -> String`
  - [ ] Subtask: Generate Markdown header: `# [Video Title] (Video Notes)`
  - [ ] Subtask: Add metadata section: Source (YouTube link or local path), Date Watched, Duration

- [ ] **Task 11.5.6:** Format note content for export
  - [ ] Subtask: For each note, add H2 header with note title (or "Note 1", "Note 2" if untitled)
  - [ ] Subtask: Include note creation date: `**Created:** 2024-01-15`
  - [ ] Subtask: Convert timestamps to clickable Markdown links (if possible, or plain text)
  - [ ] Subtask: Preserve Markdown formatting (headings, lists, code blocks)
  - [ ] Subtask: Escape special characters if needed

- [ ] **Task 11.5.7:** Handle empty notes case
  - [ ] Subtask: If video has no notes, show message: "No notes to export for this video."
  - [ ] Subtask: For global export, skip videos with no notes
  - [ ] Subtask: Add summary at end of global export: "Exported notes from X videos."

**Phase 3: Citation Format Configuration (AC: 4)**

- [ ] **Task 11.5.8:** Add citation format settings
  - [ ] Subtask: Add "Citation Format" dropdown in Settings > Notes
  - [ ] Subtask: Options: YouTube (APA), YouTube (MLA), YouTube (Chicago), Local File Path, Custom
  - [ ] Subtask: Store selected format in UserDefaults: `citationFormatPreference`
  - [ ] Subtask: Default: YouTube (APA)

- [ ] **Task 11.5.9:** Implement YouTube citation formats
  - [ ] Subtask: APA: Author (Channel). (Year). Title [Video]. YouTube. URL
  - [ ] Subtask: MLA: Channel Name. "Title." YouTube, Date, URL.
  - [ ] Subtask: Chicago: Channel Name. "Title." Video. YouTube, Date. URL.
  - [ ] Subtask: Extract channel name from `VideoItem.channelName`
  - [ ] Subtask: Extract publication date from `VideoItem.publishedDate` (if available)
  - [ ] Subtask: Construct YouTube URL: `https://youtube.com/watch?v={videoID}`

- [ ] **Task 11.5.10:** Implement local file path citation
  - [ ] Subtask: For local videos: use `file://` URL format
  - [ ] Subtask: Citation: `**Source:** file:///Users/.../Video.mp4`
  - [ ] Subtask: Optionally include file modification date

- [ ] **Task 11.5.11:** Implement custom citation format
  - [ ] Subtask: Add text field in Settings: "Custom Citation Template"
  - [ ] Subtask: Support variables: `{channel}`, `{title}`, `{url}`, `{date}`
  - [ ] Subtask: Example template: `{title} by {channel} ({date}) - {url}`
  - [ ] Subtask: Replace variables with actual values during export

**Phase 4: Multiple Export Formats (AC: 6)**

- [ ] **Task 11.5.12:** Add export format selection
  - [ ] Subtask: Add dropdown in export dialog: "Export As:" [Markdown, Plain Text, PDF]
  - [ ] Subtask: Default: Markdown
  - [ ] Subtask: Update file extension based on selection

- [ ] **Task 11.5.13:** Implement Plain Text export
  - [ ] Subtask: Strip Markdown formatting (convert to plain text)
  - [ ] Subtask: Preserve line breaks and structure
  - [ ] Subtask: Save as `.txt` file

- [ ] **Task 11.5.14:** Implement PDF export (optional)
  - [ ] Subtask: Convert Markdown to attributed string
  - [ ] Subtask: Render attributed string to PDF using `NSPrintOperation` or third-party library
  - [ ] Subtask: Save as `.pdf` file
  - [ ] Subtask: Handle PDF generation errors

**Phase 5: Global Export (All Notes) (AC: 2)**

- [ ] **Task 11.5.15:** Implement global export logic
  - [ ] Subtask: Query all notes: `@Query var allNotes: [Note]`
  - [ ] Subtask: Group notes by video: `Dictionary<VideoItem, [Note]>`
  - [ ] Subtask: Sort videos by title or date
  - [ ] Subtask: Export each video's notes as separate section in file

- [ ] **Task 11.5.16:** Format global export Markdown
  - [ ] Subtask: Add main header: `# MyToob Library Notes`
  - [ ] Subtask: Add export date: `**Exported:** 2024-01-15`
  - [ ] Subtask: For each video, add H2 header with video title
  - [ ] Subtask: Include video metadata and notes (same as single video export)
  - [ ] Subtask: Add table of contents at top (optional, for long exports)

**Phase 6: Error Handling & Edge Cases**

- [ ] **Task 11.5.17:** Handle export failures
  - [ ] Subtask: Catch file write errors (permissions, disk full, etc.)
  - [ ] Subtask: Show error alert: "Export failed: [error message]"
  - [ ] Subtask: Log error for debugging
  - [ ] Subtask: Offer to try different location or format

- [ ] **Task 11.5.18:** Handle special characters in filenames
  - [ ] Subtask: Sanitize video title for filename (remove `/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`)
  - [ ] Subtask: Limit filename length to 255 characters
  - [ ] Subtask: Replace spaces with underscores (optional, user preference)

- [ ] **Task 11.5.19:** Handle large exports
  - [ ] Subtask: For global exports with >1000 notes, show progress indicator
  - [ ] Subtask: Export in background (async operation)
  - [ ] Subtask: Allow cancellation during export
  - [ ] Subtask: Show progress: "Exporting notes: 450/1000..."

---

### Dev Notes

**File Locations:**
- `MyToob/Services/NoteExporter.swift` - Export logic and Markdown generation
- `MyToob/Views/VideoDetailView.swift` - Export button in toolbar
- `MyToob/Views/SettingsView.swift` - Global export and citation format settings
- `MyToob/Models/ExportFormat.swift` - Enum for export formats (Markdown, PlainText, PDF)
- `MyToob/Models/CitationFormat.swift` - Enum for citation formats (APA, MLA, Chicago, Custom)

**Key Patterns:**
- Use `NSOpenPanel` for save dialog (macOS-native file picker)
- Use `FileManager` for writing files: `data.write(to: url)`
- Markdown generation: simple string concatenation or template-based approach
- PDF generation: consider `NSAttributedString` → `NSPrintOperation` or third-party library (e.g., `MarkdownKit`)

**Compliance:**
- No YouTube ToS concerns (exporting user's own notes, not YouTube content)
- Ensure citations respect fair use guidelines (attribution, no misleading claims)

---

### Testing Requirements

**Unit Tests (10 tests):**
1. Test Markdown export generation for single video with 3 notes
2. Test global export with 10 videos
3. Test APA citation format for YouTube video
4. Test MLA citation format for YouTube video
5. Test Chicago citation format for YouTube video
6. Test local file path citation for local video
7. Test custom citation format with variable substitution
8. Test Plain Text export (Markdown formatting stripped)
9. Test filename sanitization (invalid characters removed)
10. Test export with empty notes (no crash, appropriate message)

**UI Tests (5 tests):**
1. Test export button in video detail view (enabled/disabled states)
2. Test file save dialog appears on export click
3. Test export success notification displays
4. Test global export from Settings
5. Test citation format selection in Settings

**Integration Tests (3 tests):**
1. Test exported Markdown file can be opened in macOS Finder
2. Test exported file contains correct video metadata and note content
3. Test global export with 100 videos completes without error

---


## Story 11.6: Note Templates (Pro Feature)

**Status:** Not Started  
**Dependencies:** Stories 11.1 (Note model), 1.7 (Pro unlock/paywall)  
**Epic:** Epic 11 - Research Tools & Note-Taking

**Acceptance Criteria:**
1. "Templates" dropdown in note editor (Pro users only)
2. Built-in templates: "Video Summary", "Key Takeaways", "Quote + Reflection", "Meeting Notes"
3. Template inserts structured Markdown into note editor (example provided in PRD)
4. User can create custom templates (saved in Settings)
5. Templates support variables: `{video_title}`, `{current_time}`, `{today_date}`
6. Template selection dialog shows preview of template structure
7. Free users see "Unlock templates with Pro" message in dropdown

---

### Implementation Phases

**Phase 1: Pro Feature Gating (AC: 1, 7)**

- [ ] **Task 11.6.1:** Add templates dropdown to note editor
  - [ ] Subtask: Add toolbar button: "Templates" (SF Symbol: `doc.text.fill`)
  - [ ] Subtask: Position in note editor toolbar (right side, after formatting buttons)
  - [ ] Subtask: Show dropdown menu on click
  - [ ] Subtask: Keyboard shortcut: ⌘T (Templates)

- [ ] **Task 11.6.2:** Check Pro status on dropdown click
  - [ ] Subtask: Query `UserProStatus.shared.isPro`
  - [ ] Subtask: If Pro: show template selection menu
  - [ ] Subtask: If Free: show paywall alert

- [ ] **Task 11.6.3:** Implement Pro paywall for templates
  - [ ] Subtask: Show alert: "Unlock templates with Pro"
  - [ ] Subtask: Message: "Templates help structure your notes with predefined formats. Upgrade to Pro for unlimited templates."
  - [ ] Subtask: Buttons: "Upgrade to Pro" (opens paywall), "Cancel"
  - [ ] Subtask: Link to paywall view (Story 1.7)

**Phase 2: Built-in Templates (AC: 2, 3)**

- [ ] **Task 11.6.4:** Define built-in template models
  - [ ] Subtask: Create `NoteTemplate` struct in `MyToob/Models/NoteTemplate.swift`
  - [ ] Subtask: Properties: `id: UUID`, `name: String`, `content: String`, `isBuiltIn: Bool`
  - [ ] Subtask: Create enum `BuiltInTemplate` with cases: `.videoSummary`, `.keyTakeaways`, `.quoteReflection`, `.meetingNotes`

- [ ] **Task 11.6.5:** Implement "Video Summary" template
  - [ ] Subtask: Template content:
    ```markdown
    ## Video Summary

    **Main Topic:**

    **Key Points:**
    -

    **Action Items:**
    -
    ```
  - [ ] Subtask: Add to built-in templates list

- [ ] **Task 11.6.6:** Implement "Key Takeaways" template
  - [ ] Subtask: Template content:
    ```markdown
    ## Key Takeaways

    1. 
    2. 
    3. 

    **Why this matters:**
    ```
  - [ ] Subtask: Add to built-in templates list

- [ ] **Task 11.6.7:** Implement "Quote + Reflection" template
  - [ ] Subtask: Template content:
    ```markdown
    ## Quote

    > "[Quote from video]" - [{current_time}]

    **My Reflection:**
    ```
  - [ ] Subtask: Add to built-in templates list

- [ ] **Task 11.6.8:** Implement "Meeting Notes" template
  - [ ] Subtask: Template content:
    ```markdown
    ## Meeting Notes - {today_date}

    **Attendees:**
    -

    **Agenda:**
    1.

    **Discussion:**

    **Action Items:**
    - [ ] 
    ```
  - [ ] Subtask: Add to built-in templates list

**Phase 3: Template Selection UI (AC: 6)**

- [ ] **Task 11.6.9:** Create template selection menu
  - [ ] Subtask: Show menu with built-in template names
  - [ ] Subtask: Section header: "Built-in Templates"
  - [ ] Subtask: Section header: "My Templates" (custom templates, if any)
  - [ ] Subtask: Divider between sections

- [ ] **Task 11.6.10:** Show template preview on hover
  - [ ] Subtask: On menu item hover, show popover with template content preview
  - [ ] Subtask: Preview shows first 5 lines of template
  - [ ] Subtask: Preview styled as Markdown (formatted text)
  - [ ] Subtask: Popover positioned next to menu item

- [ ] **Task 11.6.11:** Insert template on selection
  - [ ] Subtask: On menu item click, insert template content at cursor position
  - [ ] Subtask: If note editor is empty, replace entire content
  - [ ] Subtask: If note has content, insert at cursor with preceding newline
  - [ ] Subtask: Set cursor position after inserted content

**Phase 4: Template Variables (AC: 5)**

- [ ] **Task 11.6.12:** Define supported variables
  - [ ] Subtask: Create enum `TemplateVariable` with cases: `.videoTitle`, `.currentTime`, `.todayDate`
  - [ ] Subtask: Variable syntax: `{video_title}`, `{current_time}`, `{today_date}`
  - [ ] Subtask: Case-insensitive matching

- [ ] **Task 11.6.13:** Implement variable substitution
  - [ ] Subtask: Function: `substituteVariables(in template: String, video: VideoItem, currentTime: Double?) -> String`
  - [ ] Subtask: Replace `{video_title}` with `video.title`
  - [ ] Subtask: Replace `{current_time}` with formatted timestamp (e.g., `[15:30]`)
  - [ ] Subtask: Replace `{today_date}` with `Date().formatted(date: .long, time: .omitted)`

- [ ] **Task 11.6.14:** Handle missing variables
  - [ ] Subtask: If variable value is nil, replace with placeholder: `[Not available]`
  - [ ] Subtask: Example: `{current_time}` when video is paused → `[--:--]`
  - [ ] Subtask: Example: `{video_title}` for untitled video → `[Untitled]`

**Phase 5: Custom Templates (AC: 4)**

- [ ] **Task 11.6.15:** Add custom template creation UI
  - [ ] Subtask: Add "Manage Templates..." button in Settings > Notes
  - [ ] Subtask: Opens template management view
  - [ ] Subtask: List all custom templates (editable, deletable)

- [ ] **Task 11.6.16:** Implement template creation form
  - [ ] Subtask: Show sheet: "Create Custom Template"
  - [ ] Subtask: Fields: Template Name (required), Template Content (Markdown text area)
  - [ ] Subtask: Placeholder text in content area: "Enter Markdown template. Use {video_title}, {current_time}, {today_date} for variables."
  - [ ] Subtask: Preview pane shows rendered Markdown
  - [ ] Subtask: Buttons: "Save", "Cancel"

- [ ] **Task 11.6.17:** Persist custom templates
  - [ ] Subtask: Store custom templates in SwiftData: `@Model class CustomTemplate`
  - [ ] Subtask: Properties: `id: UUID`, `name: String`, `content: String`, `createdDate: Date`
  - [ ] Subtask: Query custom templates: `@Query var customTemplates: [CustomTemplate]`
  - [ ] Subtask: Sync via CloudKit (optional, for cross-device templates)

- [ ] **Task 11.6.18:** Allow editing/deleting custom templates
  - [ ] Subtask: Edit button in template list (opens edit form)
  - [ ] Subtask: Delete button with confirmation: "Delete template '[name]'?"
  - [ ] Subtask: Swipe to delete in list (macOS: swipe on trackpad)

**Phase 6: Template Management & UX**

- [ ] **Task 11.6.19:** Add template sorting and search
  - [ ] Subtask: Sort templates alphabetically by name
  - [ ] Subtask: Search bar in template management view
  - [ ] Subtask: Filter templates by name match

- [ ] **Task 11.6.20:** Export/import custom templates
  - [ ] Subtask: "Export Template..." button in template management (saves as `.json`)
  - [ ] Subtask: "Import Template..." button (loads from `.json` file)
  - [ ] Subtask: JSON format: `{ "name": "...", "content": "..." }`
  - [ ] Subtask: Validate imported JSON (schema check)

- [ ] **Task 11.6.21:** Template usage analytics (optional)
  - [ ] Subtask: Track template usage count: `usageCount` property
  - [ ] Subtask: Sort by popularity: "Most Used" option
  - [ ] Subtask: Show usage count in template list: "Video Summary (42 uses)"

**Phase 7: Error Handling & Edge Cases**

- [ ] **Task 11.6.22:** Handle empty template content
  - [ ] Subtask: Validate template content is not empty on save
  - [ ] Subtask: Show error: "Template content cannot be empty."

- [ ] **Task 11.6.23:** Handle duplicate template names
  - [ ] Subtask: Check for duplicate names before saving
  - [ ] Subtask: Show error: "A template with this name already exists."
  - [ ] Subtask: Suggest appending number: "Template Name (2)"

- [ ] **Task 11.6.24:** Handle variable syntax errors
  - [ ] Subtask: Validate variable syntax: `{variable_name}` format
  - [ ] Subtask: Show warning for unrecognized variables: "{unknown_var} will not be replaced."
  - [ ] Subtask: List supported variables in help text

---

### Dev Notes

**File Locations:**
- `MyToob/Models/NoteTemplate.swift` - Template model and built-in templates enum
- `MyToob/Models/CustomTemplate.swift` - SwiftData model for custom templates
- `MyToob/Views/NoteEditorView.swift` - Templates dropdown button
- `MyToob/Views/TemplateSelectionMenu.swift` - Template selection menu with preview
- `MyToob/Views/TemplateManagementView.swift` - Custom template management UI
- `MyToob/Services/TemplateService.swift` - Variable substitution and template logic

**Key Patterns:**
- Templates stored as plain Markdown strings (easy to edit and preview)
- Variable substitution: simple string replacement (regex or `replacingOccurrences`)
- Pro feature check: `@ObservedObject var proStatus = UserProStatus.shared`
- Custom templates: SwiftData model with CloudKit sync for cross-device availability

**Pro Feature Integration:**
- Check `UserProStatus.shared.isPro` before showing templates
- Show paywall for free users (Story 1.7 paywall view)
- Consider freemium approach: offer 1-2 built-in templates to free users, full library for Pro

**Variable System:**
- Extensible: easy to add new variables (e.g., `{channel_name}`, `{video_duration}`)
- Case-insensitive: `{Video_Title}` and `{video_title}` both work
- Safe: unknown variables left as-is (no crashes)

---

### Testing Requirements

**Unit Tests (12 tests):**
1. Test built-in template "Video Summary" content is correct
2. Test built-in template "Key Takeaways" content is correct
3. Test built-in template "Quote + Reflection" content is correct
4. Test built-in template "Meeting Notes" content is correct
5. Test variable substitution: `{video_title}` replaced with video title
6. Test variable substitution: `{current_time}` replaced with timestamp
7. Test variable substitution: `{today_date}` replaced with current date
8. Test variable substitution with missing value (nil handling)
9. Test custom template creation and persistence
10. Test custom template editing
11. Test custom template deletion
12. Test template export/import (JSON serialization)

**UI Tests (6 tests):**
1. Test templates dropdown button visible in note editor
2. Test Pro users see template selection menu
3. Test Free users see paywall on dropdown click
4. Test template insertion at cursor position
5. Test template preview popover on hover
6. Test custom template management view

**Integration Tests (3 tests):**
1. Test template insertion with variable substitution in real note editor
2. Test custom template syncs via CloudKit (if implemented)
3. Test template usage across multiple note sessions

---


---

# Epic 12: UGC Safeguards & Compliance Features

## Story 12.1: Report Content Action

**Status:** Not Started  
**Dependencies:** Story 3.1 (YouTube OAuth/API setup), Story 9.1 (Search/content UI)  
**Epic:** Epic 12 - UGC Safeguards & Compliance Features

**Acceptance Criteria:**
1. "Report Content" action in video context menu (right-click on YouTube video)
2. Clicking action shows dialog: "Report this video for violating YouTube's Community Guidelines?"
3. Dialog includes "Report on YouTube" button (primary) and "Cancel" button
4. "Report on YouTube" opens YouTube's reporting page in default web browser: `https://www.youtube.com/watch?v={videoID}&report=1`
5. Action only available for YouTube videos (hidden for local files)
6. "Report" action logged for compliance audit: "User reported video {videoID} at {timestamp}"
7. UI test verifies report action opens correct URL

---

### Implementation Phases

**Phase 1: Context Menu Implementation (AC: 1, 5)**

- [ ] **Task 12.1.1:** Add "Report Content" to video context menu
  - [ ] Subtask: In `VideoThumbnailView`, add context menu item
  - [ ] Subtask: Menu label: "Report Content..."
  - [ ] Subtask: SF Symbol: `exclamationmark.shield.fill` (red color)
  - [ ] Subtask: Position at bottom of context menu (after other actions)

- [ ] **Task 12.1.2:** Conditionally show action for YouTube videos only
  - [ ] Subtask: Check `videoItem.isLocal` property
  - [ ] Subtask: If `isLocal == true`: hide "Report Content" action
  - [ ] Subtask: If `isLocal == false` AND `videoItem.videoID != nil`: show action
  - [ ] Subtask: Action disabled if `videoID` is missing

- [ ] **Task 12.1.3:** Handle action trigger
  - [ ] Subtask: On menu item click, call `reportContentAction(for: videoItem)`
  - [ ] Subtask: Function checks `videoID` validity before proceeding
  - [ ] Subtask: If invalid: show error alert: "Cannot report this video."

**Phase 2: Confirmation Dialog (AC: 2, 3)**

- [ ] **Task 12.1.4:** Show confirmation dialog
  - [ ] Subtask: Use SwiftUI `.alert()` modifier
  - [ ] Subtask: Title: "Report Content"
  - [ ] Subtask: Message: "Report this video for violating YouTube's Community Guidelines? This will open YouTube's reporting page in your browser."
  - [ ] Subtask: Icon: warning symbol

- [ ] **Task 12.1.5:** Implement dialog buttons
  - [ ] Subtask: Primary button: "Report on YouTube" (destructive style)
  - [ ] Subtask: Secondary button: "Cancel" (default style)
  - [ ] Subtask: On "Cancel": dismiss dialog, no action
  - [ ] Subtask: On "Report on YouTube": open browser URL

**Phase 3: Open YouTube Reporting Page (AC: 4)**

- [ ] **Task 12.1.6:** Construct reporting URL
  - [ ] Subtask: Base URL: `https://www.youtube.com/watch?v={videoID}&report=1`
  - [ ] Subtask: Replace `{videoID}` with `videoItem.videoID`
  - [ ] Subtask: Validate URL format (ensure `videoID` is URL-safe)

- [ ] **Task 12.1.7:** Open URL in default browser
  - [ ] Subtask: Use `NSWorkspace.shared.open(url)`
  - [ ] Subtask: Handle errors if browser fails to open
  - [ ] Subtask: Show error alert: "Could not open browser. Please try again."

- [ ] **Task 12.1.8:** Verify browser opens correct page
  - [ ] Subtask: Test manually with sample `videoID`
  - [ ] Subtask: Confirm YouTube's report page loads
  - [ ] Subtask: Confirm `report=1` parameter triggers report flow

**Phase 4: Compliance Audit Logging (AC: 6)**

- [ ] **Task 12.1.9:** Implement compliance logger
  - [ ] Subtask: Create `ComplianceLogger` service in `MyToob/Services/ComplianceLogger.swift`
  - [ ] Subtask: Use OSLog with subsystem: `com.mytoob.compliance`
  - [ ] Subtask: Category: `content-moderation`
  - [ ] Subtask: Function: `logReportAction(videoID: String)`

- [ ] **Task 12.1.10:** Log report event
  - [ ] Subtask: Log message: "User reported video {videoID} at {timestamp}"
  - [ ] Subtask: Include timestamp: `Date().ISO8601Format()`
  - [ ] Subtask: Do NOT log video title or user PII (GDPR compliance)
  - [ ] Subtask: Log level: `.info` (not error, not fault)

- [ ] **Task 12.1.11:** Ensure log persistence
  - [ ] Subtask: OSLog automatically persists to system logs
  - [ ] Subtask: Logs accessible via Console.app (developer only)
  - [ ] Subtask: Logs included in diagnostics export (Story 12.6)

**Phase 5: Error Handling & Edge Cases**

- [ ] **Task 12.1.12:** Handle missing videoID
  - [ ] Subtask: If `videoID == nil`: disable "Report Content" action
  - [ ] Subtask: If user somehow triggers action: show alert "Cannot report this video."

- [ ] **Task 12.1.13:** Handle browser open failure
  - [ ] Subtask: Catch `NSWorkspace.open()` errors
  - [ ] Subtask: Show alert: "Could not open browser. URL: {reportURL}"
  - [ ] Subtask: Allow user to copy URL manually

- [ ] **Task 12.1.14:** Handle offline scenario
  - [ ] Subtask: Check network reachability before opening URL
  - [ ] Subtask: If offline: show alert "No internet connection. Cannot report content."
  - [ ] Subtask: Option to retry when online

**Phase 6: Testing & Validation (AC: 7)**

- [ ] **Task 12.1.15:** Write UI test for report action
  - [ ] Subtask: Test: Right-click YouTube video → "Report Content" visible
  - [ ] Subtask: Test: Click "Report Content" → confirmation dialog appears
  - [ ] Subtask: Test: Click "Report on YouTube" → browser opens
  - [ ] Subtask: Test: Verify URL contains `report=1` parameter
  - [ ] Subtask: Test: Local video → "Report Content" hidden

- [ ] **Task 12.1.16:** Verify YouTube ToS compliance
  - [ ] Subtask: Ensure report action aligns with YouTube Developer Policies
  - [ ] Subtask: Confirm deep-link URL is correct (test with real YouTube video)
  - [ ] Subtask: Document compliance in reviewer notes

---

### Dev Notes

**File Locations:**
- `MyToob/Views/VideoThumbnailView.swift` - Context menu with "Report Content" action
- `MyToob/Services/ComplianceLogger.swift` - Audit logging for compliance events
- `MyToob/Extensions/VideoItem+Reporting.swift` - Helper methods for report URL generation

**Key Patterns:**
- Context menu: `.contextMenu { ... }` modifier in SwiftUI
- Alert: `.alert(isPresented: $showReportAlert) { Alert(...) }`
- Open URL: `NSWorkspace.shared.open(URL(string: reportURL)!)`
- OSLog: `let logger = Logger(subsystem: "com.mytoob.compliance", category: "content-moderation")`

**YouTube ToS Compliance:**
- Using YouTube's official report URL: `https://www.youtube.com/watch?v={videoID}&report=1`
- Not implementing in-app reporting (which would violate ToS)
- Delegating to YouTube for content moderation (required by YouTube API policies)

**App Store Guideline 1.2 (UGC):**
- This feature demonstrates "ability for users to report offensive content"
- Required for any app displaying user-generated content (YouTube videos qualify)

---

### Testing Requirements

**Unit Tests (8 tests):**
1. Test report URL generation for valid `videoID`
2. Test report URL includes `report=1` parameter
3. Test action hidden for local files (`isLocal == true`)
4. Test action shown for YouTube videos
5. Test compliance log entry created on report
6. Test log message format correct
7. Test log includes timestamp
8. Test log does NOT include PII (no video title)

**UI Tests (5 tests):**
1. Test "Report Content" visible in context menu for YouTube video
2. Test "Report Content" hidden for local file
3. Test confirmation dialog appears on action click
4. Test "Cancel" dismisses dialog without action
5. Test "Report on YouTube" opens browser

**Integration Tests (2 tests):**
1. Test full report flow: context menu → dialog → browser opens with correct URL
2. Test compliance log entry persisted to system logs

---


## Story 12.2: Hide & Blacklist Channels

**Status:** Not Started  
**Dependencies:** Story 1.4 (SwiftData models), Story 3.1 (YouTube API)  
**Epic:** Epic 12 - UGC Safeguards & Compliance Features

**Acceptance Criteria:**
1. "Hide Channel" action in video context menu for YouTube videos
2. Clicking action shows confirmation: "Hide all videos from [Channel Name]? You can unhide channels in Settings."
3. Channel added to `ChannelBlacklist` model with `channelID`, `reason = "User hidden"`, `blockedAt`
4. All videos from blacklisted channel hidden from library and search results
5. "Hidden Channels" list in Settings shows all blacklisted channels
6. "Unhide" button in Settings removes channel from blacklist (videos reappear)
7. Blacklist syncs via CloudKit (if sync enabled) so channel is hidden across devices

---

### Implementation Phases

**Phase 1: Context Menu Action (AC: 1, 2)**

- [ ] **Task 12.2.1:** Add "Hide Channel" to video context menu
  - [ ] Subtask: In `VideoThumbnailView`, add context menu item
  - [ ] Subtask: Menu label: "Hide Channel"
  - [ ] Subtask: SF Symbol: `eye.slash.fill`
  - [ ] Subtask: Position near "Report Content" action

- [ ] **Task 12.2.2:** Show action only for YouTube videos
  - [ ] Subtask: Check `videoItem.isLocal == false`
  - [ ] Subtask: Check `videoItem.channelID != nil`
  - [ ] Subtask: If conditions met: show action
  - [ ] Subtask: Otherwise: hide action

- [ ] **Task 12.2.3:** Show confirmation dialog
  - [ ] Subtask: On action click, show `.confirmationDialog()`
  - [ ] Subtask: Title: "Hide Channel"
  - [ ] Subtask: Message: "Hide all videos from {channelName}? You can unhide channels in Settings."
  - [ ] Subtask: Replace `{channelName}` with `videoItem.channelName` (or "this channel" if nil)
  - [ ] Subtask: Buttons: "Hide Channel" (destructive), "Cancel"

**Phase 2: ChannelBlacklist Model (AC: 3)**

- [ ] **Task 12.2.4:** Define ChannelBlacklist SwiftData model
  - [ ] Subtask: Create `ChannelBlacklist.swift` in `MyToob/Models/`
  - [ ] Subtask: Properties: `id: UUID`, `channelID: String`, `channelName: String?`, `reason: String`, `blockedAt: Date`
  - [ ] Subtask: Add `@Model` macro for SwiftData persistence
  - [ ] Subtask: Add to modelContainer in `MyToobApp.swift`

- [ ] **Task 12.2.5:** Implement addToBlacklist function
  - [ ] Subtask: Function: `addToBlacklist(channelID: String, channelName: String?, reason: String = "User hidden")`
  - [ ] Subtask: Create `ChannelBlacklist` instance
  - [ ] Subtask: Set `blockedAt = Date()`
  - [ ] Subtask: Insert into SwiftData context: `modelContext.insert(blacklistEntry)`
  - [ ] Subtask: Save context: `try? modelContext.save()`

- [ ] **Task 12.2.6:** Add channel to blacklist on confirmation
  - [ ] Subtask: On "Hide Channel" button click, call `addToBlacklist()`
  - [ ] Subtask: Pass `videoItem.channelID` and `videoItem.channelName`
  - [ ] Subtask: Show success toast: "Channel hidden. Videos from this channel will no longer appear."

**Phase 3: Filter Blacklisted Videos (AC: 4)**

- [ ] **Task 12.2.7:** Query blacklisted channel IDs
  - [ ] Subtask: Create `@Query var blacklistedChannels: [ChannelBlacklist]`
  - [ ] Subtask: Extract channel IDs: `let blacklistedIDs = Set(blacklistedChannels.map { $0.channelID })`
  - [ ] Subtask: Cache blacklisted IDs for performance (avoid repeated queries)

- [ ] **Task 12.2.8:** Filter videos in library view
  - [ ] Subtask: In video list query, add predicate: `#Predicate<VideoItem> { !blacklistedIDs.contains($0.channelID) }`
  - [ ] Subtask: Alternatively, filter in view: `videos.filter { !blacklistedIDs.contains($0.channelID ?? "") }`
  - [ ] Subtask: Videos from blacklisted channels disappear from grid/list

- [ ] **Task 12.2.9:** Filter videos in search results
  - [ ] Subtask: Apply same filter in search results view
  - [ ] Subtask: Ensure hybrid search (Story 9.4) respects blacklist
  - [ ] Subtask: Blacklisted videos excluded from both keyword and vector search

- [ ] **Task 12.2.10:** Filter videos in collections
  - [ ] Subtask: If video in collection is blacklisted, hide from collection view
  - [ ] Subtask: Collection count reflects non-blacklisted videos only
  - [ ] Subtask: Option: Remove blacklisted videos from collections automatically (user preference)

**Phase 4: Hidden Channels Settings UI (AC: 5, 6)**

- [ ] **Task 12.2.11:** Add "Hidden Channels" section in Settings
  - [ ] Subtask: Create `HiddenChannelsView.swift` in `MyToob/Views/Settings/`
  - [ ] Subtask: Show list of all `ChannelBlacklist` entries
  - [ ] Subtask: List items show: Channel name (or ID if name unavailable), Date hidden, "Unhide" button

- [ ] **Task 12.2.12:** Implement unhide action
  - [ ] Subtask: "Unhide" button next to each blacklisted channel
  - [ ] Subtask: On click, delete `ChannelBlacklist` entry from SwiftData
  - [ ] Subtask: `modelContext.delete(blacklistEntry)`
  - [ ] Subtask: Save context: `try? modelContext.save()`

- [ ] **Task 12.2.13:** Show confirmation for unhide
  - [ ] Subtask: Optional confirmation dialog: "Unhide {channelName}? Videos from this channel will reappear."
  - [ ] Subtask: Buttons: "Unhide", "Cancel"
  - [ ] Subtask: On "Unhide": remove from blacklist

- [ ] **Task 12.2.14:** Update UI when channel unhidden
  - [ ] Subtask: Videos from unhidden channel reappear in library
  - [ ] Subtask: UI updates automatically (SwiftData observation)
  - [ ] Subtask: Show success toast: "Channel unhidden."

**Phase 5: CloudKit Sync (AC: 7)**

- [ ] **Task 12.2.15:** Enable CloudKit sync for ChannelBlacklist
  - [ ] Subtask: Add `.modelContainer(for: [VideoItem.self, ChannelBlacklist.self], inMemory: false, isAutosaveEnabled: true, isUndoEnabled: false, modelContainerOptions: [.cloudKitDatabase(.private)])`
  - [ ] Subtask: Ensure `ChannelBlacklist` is part of CloudKit schema
  - [ ] Subtask: Sync strategy: "Last Write Wins" (like other models)

- [ ] **Task 12.2.16:** Handle sync conflicts
  - [ ] Subtask: If same channel blacklisted on multiple devices: merge entries (keep earliest `blockedAt`)
  - [ ] Subtask: If channel unhidden on one device, sync deletion to all devices
  - [ ] Subtask: Test sync with 2 devices (Mac + Mac or Mac + iPhone if iOS version exists)

- [ ] **Task 12.2.17:** Show sync status in Settings
  - [ ] Subtask: Display CloudKit sync status: "Sync enabled" or "Sync disabled"
  - [ ] Subtask: If sync disabled: show warning "Hidden channels are local only. Enable iCloud sync to hide across devices."

**Phase 6: Edge Cases & Performance**

- [ ] **Task 12.2.18:** Handle large blacklists
  - [ ] Subtask: Test performance with 100+ blacklisted channels
  - [ ] Subtask: Optimize filtering: use indexed query or in-memory set for fast lookup
  - [ ] Subtask: Pagination in Settings list if >50 channels

- [ ] **Task 12.2.19:** Handle missing channel name
  - [ ] Subtask: If `channelName == nil`: display `channelID` in Settings list
  - [ ] Subtask: Option: Fetch channel name from YouTube API when blacklisting (async)

- [ ] **Task 12.2.20:** Prevent duplicate blacklist entries
  - [ ] Subtask: Before adding to blacklist, check if `channelID` already exists
  - [ ] Subtask: If exists: show message "Channel is already hidden."

---

### Dev Notes

**File Locations:**
- `MyToob/Models/ChannelBlacklist.swift` - SwiftData model for blacklisted channels
- `MyToob/Views/VideoThumbnailView.swift` - Context menu with "Hide Channel" action
- `MyToob/Views/Settings/HiddenChannelsView.swift` - Settings UI for managing blacklist
- `MyToob/Services/ChannelBlacklistService.swift` - Business logic for blacklisting/unblacklisting

**Key Patterns:**
- Filtering: `videos.filter { !blacklistedIDs.contains($0.channelID ?? "") }`
- SwiftData query: `@Query var blacklistedChannels: [ChannelBlacklist]`
- CloudKit sync: modelContainer configuration with `.cloudKitDatabase(.private)`

**Performance Considerations:**
- Cache blacklisted IDs in memory: `Set<String>` for O(1) lookup
- Avoid repeated queries: query once, observe changes via SwiftData
- Index `channelID` in SwiftData for fast filtering (if supported)

**User Experience:**
- Hiding channel is immediate (no undo, but can unhide in Settings)
- Videos disappear from all views (library, search, collections)
- Clear messaging: "You can unhide channels in Settings" (discoverability)

---

### Testing Requirements

**Unit Tests (10 tests):**
1. Test `addToBlacklist()` creates `ChannelBlacklist` entry
2. Test `ChannelBlacklist` entry has correct `channelID`, `reason`, `blockedAt`
3. Test filtering videos by blacklisted channel IDs
4. Test unhide removes `ChannelBlacklist` entry
5. Test duplicate blacklist prevention (same channel not added twice)
6. Test blacklist with missing channel name (fallback to ID)
7. Test blacklist sync via CloudKit
8. Test sync conflict resolution (Last Write Wins)
9. Test filtering in search results
10. Test filtering in collections

**UI Tests (6 tests):**
1. Test "Hide Channel" visible in context menu for YouTube video
2. Test confirmation dialog appears on action click
3. Test "Hide Channel" button hides channel
4. Test videos from hidden channel disappear from library
5. Test "Hidden Channels" list shows blacklisted channels in Settings
6. Test "Unhide" button removes channel from blacklist

**Integration Tests (3 tests):**
1. Test full hide flow: context menu → confirm → channel hidden → videos disappear
2. Test unhide flow: Settings → unhide → videos reappear
3. Test CloudKit sync: hide on device A → blacklist syncs to device B

---


## Story 12.3: Content Policy Page

**Status:** Not Started  
**Dependencies:** None (standalone web page)  
**Epic:** Epic 12 - UGC Safeguards & Compliance Features

**Acceptance Criteria:**
1. "Content Policy" link in Settings > About section
2. Clicking link opens policy page (in-app web view or external browser)
3. Policy page includes:
   - Clear explanation of content standards (links to YouTube's Community Guidelines for YouTube content)
   - How to report violations (Report Content action)
   - How to hide unwanted content (Hide Channel action)
   - Statement that user is responsible for local file content
   - Contact information for policy questions
4. Policy page accessible without authentication (public page)
5. Policy page URL: `https://yourwebsite.com/mytoob/content-policy` (hosted on static site)
6. Policy page language clear, non-technical, user-friendly

---

### Implementation Phases

**Phase 1: Settings Link (AC: 1, 2)**

- [ ] **Task 12.3.1:** Add "Content Policy" link to Settings
  - [ ] Subtask: In `SettingsView.swift`, add "About" section (if not exists)
  - [ ] Subtask: Add button: "Content Policy"
  - [ ] Subtask: SF Symbol: `doc.text.fill`
  - [ ] Subtask: Position below "Terms of Service" or "Privacy Policy"

- [ ] **Task 12.3.2:** Open policy page on click
  - [ ] Subtask: Define policy URL: `let policyURL = URL(string: "https://yourwebsite.com/mytoob/content-policy")!`
  - [ ] Subtask: Option 1: Open in external browser: `NSWorkspace.shared.open(policyURL)`
  - [ ] Subtask: Option 2: Open in-app web view (WKWebView sheet)
  - [ ] Subtask: Recommendation: External browser for simplicity

- [ ] **Task 12.3.3:** Handle link open failure
  - [ ] Subtask: Catch errors if browser fails to open
  - [ ] Subtask: Show alert: "Could not open policy page. URL: {policyURL}"
  - [ ] Subtask: Allow user to copy URL manually

**Phase 2: Policy Page Content (AC: 3, 6)**

- [ ] **Task 12.3.4:** Write content policy document
  - [ ] Subtask: Create Markdown document: `docs/policies/content-policy.md`
  - [ ] Subtask: Sections:
    - Introduction (what MyToob is)
    - Content Standards
    - YouTube Content (link to YouTube Community Guidelines)
    - Local File Content (user responsibility)
    - Reporting Violations
    - Hiding Unwanted Content
    - Contact Information
  - [ ] Subtask: Use clear, user-friendly language (no legal jargon)

- [ ] **Task 12.3.5:** Content Standards section
  - [ ] Subtask: Explain app does not host content (YouTube videos, local files)
  - [ ] Subtask: For YouTube: content must comply with YouTube Community Guidelines
  - [ ] Subtask: Link: [YouTube Community Guidelines](https://www.youtube.com/howyoutubeworks/policies/community-guidelines/)
  - [ ] Subtask: For local files: user is responsible for content they import

- [ ] **Task 12.3.6:** Reporting Violations section
  - [ ] Subtask: Explain "Report Content" action (Story 12.1)
  - [ ] Subtask: Steps: Right-click video → "Report Content" → Opens YouTube reporting page
  - [ ] Subtask: Note: Reports are handled by YouTube, not MyToob

- [ ] **Task 12.3.7:** Hiding Unwanted Content section
  - [ ] Subtask: Explain "Hide Channel" action (Story 12.2)
  - [ ] Subtask: Steps: Right-click video → "Hide Channel" → Videos from channel no longer appear
  - [ ] Subtask: How to unhide: Settings > Hidden Channels > Unhide button

- [ ] **Task 12.3.8:** Contact Information section
  - [ ] Subtask: Email: support@yourapp.com (Story 12.4)
  - [ ] Subtask: Response time: "We aim to respond within 48 hours."
  - [ ] Subtask: Alternative: GitHub issues (if open-source)

**Phase 3: Host Policy Page (AC: 4, 5)**

- [ ] **Task 12.3.9:** Convert Markdown to HTML
  - [ ] Subtask: Use static site generator (e.g., Jekyll, Hugo, Next.js) to generate HTML
  - [ ] Subtask: Apply clean, readable styling (dark mode support)
  - [ ] Subtask: Include navigation: Home, Privacy Policy, Terms of Service, Content Policy

- [ ] **Task 12.3.10:** Host on static site
  - [ ] Subtask: Deploy to static hosting: Vercel, Netlify, GitHub Pages, or custom domain
  - [ ] Subtask: URL: `https://yourwebsite.com/mytoob/content-policy`
  - [ ] Subtask: Ensure HTTPS enabled (required for security)
  - [ ] Subtask: Verify page loads in browser (no authentication required)

- [ ] **Task 12.3.11:** Test accessibility
  - [ ] Subtask: Ensure page is readable without JavaScript
  - [ ] Subtask: Test with VoiceOver (accessibility)
  - [ ] Subtask: Ensure mobile-friendly (responsive design)

**Phase 4: Policy Updates & Versioning**

- [ ] **Task 12.3.12:** Add "Last Updated" date to policy
  - [ ] Subtask: Display at top: "Last Updated: January 15, 2024"
  - [ ] Subtask: Update date when policy changes

- [ ] **Task 12.3.13:** Notify users of policy updates (optional)
  - [ ] Subtask: Show in-app notification when policy changes: "Content Policy updated. Review changes."
  - [ ] Subtask: Link to policy page in notification
  - [ ] Subtask: Track last-seen policy version in UserDefaults

**Phase 5: Compliance Documentation**

- [ ] **Task 12.3.14:** Add policy to App Store reviewer notes
  - [ ] Subtask: In App Store Connect, provide policy URL in reviewer notes
  - [ ] Subtask: Highlight UGC safeguards: reporting, hiding, content standards
  - [ ] Subtask: Demonstrate compliance with Guideline 1.2 (UGC)

- [ ] **Task 12.3.15:** Cross-reference in other policies
  - [ ] Subtask: Link to Content Policy from Terms of Service
  - [ ] Subtask: Link to Content Policy from Privacy Policy (data deletion requests)

---

### Dev Notes

**File Locations:**
- `MyToob/Views/Settings/SettingsView.swift` - "Content Policy" link
- `docs/policies/content-policy.md` - Markdown source for policy page
- Static site repository (e.g., `mytoob-website`) - Hosted HTML version

**Key Patterns:**
- External link: `NSWorkspace.shared.open(URL(string: "...")!)`
- In-app web view (alternative): Use WKWebView in sheet
- Static site hosting: Vercel, Netlify, GitHub Pages (free options)

**Content Policy Structure (Example Outline):**
```markdown
# MyToob Content Policy

Last Updated: January 15, 2024

## Introduction
MyToob is a video library manager that helps you organize YouTube videos and local files...

## Content Standards
### YouTube Content
All YouTube videos displayed in MyToob must comply with [YouTube's Community Guidelines](https://www.youtube.com/howyoutubeworks/policies/community-guidelines/).

### Local Files
You are responsible for the content of local video files you import...

## Reporting Violations
If you encounter YouTube content that violates Community Guidelines...

## Hiding Unwanted Content
You can hide videos from specific channels...

## Contact Us
If you have questions about this policy, contact us at support@yourapp.com.
```

**App Store Compliance:**
- Guideline 1.2 requires "method for filtering objectionable material" → Hiding channels
- Guideline 1.2 requires "mechanism for users to report offensive content" → Report action
- Guideline 1.2 requires "ability to block abusive users" → Channel blacklist

---

### Testing Requirements

**Unit Tests (2 tests):**
1. Test policy URL is correctly formatted
2. Test policy URL opens in browser without error

**UI Tests (3 tests):**
1. Test "Content Policy" link visible in Settings > About
2. Test clicking link opens browser
3. Test policy page loads successfully (integration test, requires network)

**Manual Tests (5 tests):**
1. Read policy page, verify all required sections present
2. Verify YouTube Community Guidelines link works
3. Verify contact email is correct
4. Verify page accessible without authentication
5. Verify page is mobile-friendly and accessible (VoiceOver)

---


## Story 12.4: Support & Contact Information

**Status:** Not Started  
**Dependencies:** None  
**Epic:** Epic 12 - UGC Safeguards & Compliance Features

**Acceptance Criteria:**
1. "Support" or "Contact" link in Settings > About section
2. Contact options provided: email (support@yourapp.com), support page URL, GitHub issues (for open-source projects)
3. "Send Diagnostics" button creates sanitized log archive and opens email client with pre-filled support request
4. Support email response time commitment stated (e.g., "We aim to respond within 48 hours")
5. FAQ or Help Center link provided (if available)
6. Support information shown in App Store listing (consistent with in-app info)
7. UI test verifies support links are accessible from Settings

---

### Implementation Phases

**Phase 1: Support Link in Settings (AC: 1, 2)**

- [ ] **Task 12.4.1:** Add "Support" section to Settings
  - [ ] Subtask: In `SettingsView.swift`, add "Support" or "Help" section
  - [ ] Subtask: Position near "About" section
  - [ ] Subtask: Include links: "Contact Support", "Send Diagnostics", "FAQ" (if available)

- [ ] **Task 12.4.2:** Add "Contact Support" button
  - [ ] Subtask: Button label: "Contact Support"
  - [ ] Subtask: SF Symbol: `envelope.fill`
  - [ ] Subtask: On click, open email client with pre-filled template

- [ ] **Task 12.4.3:** Pre-fill support email template
  - [ ] Subtask: Email to: `support@yourapp.com`
  - [ ] Subtask: Subject: "MyToob Support Request"
  - [ ] Subtask: Body template:
    ```
    Hi MyToob Support,

    [Describe your issue here]

    App Version: {appVersion}
    macOS Version: {osVersion}
    Device: {deviceModel}
    ```
  - [ ] Subtask: Replace `{appVersion}` with `Bundle.main.infoDictionary!["CFBundleShortVersionString"]`
  - [ ] Subtask: Replace `{osVersion}` with `ProcessInfo.processInfo.operatingSystemVersionString`
  - [ ] Subtask: Replace `{deviceModel}` with `Sysctl.model` (or similar)

- [ ] **Task 12.4.4:** Open email client
  - [ ] Subtask: Construct mailto URL: `mailto:support@yourapp.com?subject=...&body=...`
  - [ ] Subtask: URL-encode subject and body
  - [ ] Subtask: Use `NSWorkspace.shared.open(mailtoURL)`
  - [ ] Subtask: Handle error if no email client configured

- [ ] **Task 12.4.5:** Add alternative contact options
  - [ ] Subtask: Button: "Report Issue on GitHub" (if open-source)
  - [ ] Subtask: Link: `https://github.com/yourorg/mytoob/issues/new`
  - [ ] Subtask: Button: "Visit Support Page" (if web-based support exists)
  - [ ] Subtask: Link: `https://yourwebsite.com/mytoob/support`

**Phase 2: Send Diagnostics Feature (AC: 3)**

- [ ] **Task 12.4.6:** Add "Send Diagnostics" button
  - [ ] Subtask: Button label: "Send Diagnostics"
  - [ ] Subtask: SF Symbol: `doc.text.magnifyingglass`
  - [ ] Subtask: Tooltip: "Create a log archive to help us diagnose issues"

- [ ] **Task 12.4.7:** Collect diagnostic logs
  - [ ] Subtask: Query OSLog for app logs: `OSLogStore(scope: .currentProcessIdentifier)`
  - [ ] Subtask: Filter by subsystem: `com.mytoob.*`
  - [ ] Subtask: Include last 7 days of logs (or last 1000 entries)
  - [ ] Subtask: Export to temporary file: `/tmp/mytoob-diagnostics-{timestamp}.log`

- [ ] **Task 12.4.8:** Sanitize diagnostic logs
  - [ ] Subtask: Remove PII: email addresses, usernames, video titles (replace with `[REDACTED]`)
  - [ ] Subtask: Regex patterns to detect/remove PII
  - [ ] Subtask: Keep: timestamps, error messages, videoIDs (UUIDs okay), channelIDs
  - [ ] Subtask: Add header: "MyToob Diagnostics - Generated {timestamp}"

- [ ] **Task 12.4.9:** Create log archive (ZIP)
  - [ ] Subtask: Use `FileManager` to create ZIP archive
  - [ ] Subtask: Include: sanitized logs, app version, system info, crash reports (if any)
  - [ ] Subtask: Save to: `~/Downloads/mytoob-diagnostics-{timestamp}.zip`
  - [ ] Subtask: Show save dialog to let user choose location

- [ ] **Task 12.4.10:** Open email with diagnostics attachment
  - [ ] Subtask: Open email client with mailto URL
  - [ ] Subtask: Subject: "MyToob Diagnostics - {timestamp}"
  - [ ] Subtask: Body: "Diagnostics log attached. Please describe your issue below."
  - [ ] Subtask: Note: mailto URLs cannot attach files automatically (limitation)
  - [ ] Subtask: Alternative: Show instruction: "Please attach the saved diagnostics file to your email."

- [ ] **Task 12.4.11:** Show success message
  - [ ] Subtask: Alert: "Diagnostics saved to {path}. Please attach this file to your support email."
  - [ ] Subtask: Button: "Reveal in Finder" (opens Finder at file location)
  - [ ] Subtask: Button: "Open Email" (opens mailto URL)

**Phase 3: Response Time Commitment (AC: 4)**

- [ ] **Task 12.4.12:** Display response time commitment
  - [ ] Subtask: In Settings > Support section, add text: "We aim to respond within 48 hours."
  - [ ] Subtask: Font: `.caption` or `.footnote` (smaller, less prominent)
  - [ ] Subtask: Color: secondary text color

- [ ] **Task 12.4.13:** Set realistic expectations
  - [ ] Subtask: Clarify: "Response times may vary during holidays or high-volume periods."
  - [ ] Subtask: Provide alternative: "For urgent issues, contact us on Twitter: @MyToobApp" (if applicable)

**Phase 4: FAQ / Help Center (AC: 5)**

- [ ] **Task 12.4.14:** Add FAQ link
  - [ ] Subtask: Button: "Frequently Asked Questions"
  - [ ] Subtask: Link: `https://yourwebsite.com/mytoob/faq`
  - [ ] Subtask: Open in browser on click

- [ ] **Task 12.4.15:** Create FAQ page (external task)
  - [ ] Subtask: Host FAQ on static site (like Content Policy)
  - [ ] Subtask: Common questions:
    - How do I import YouTube videos?
    - How do I hide unwanted channels?
    - How do I export my notes?
    - Why isn't my video playing?
    - How do I enable CloudKit sync?
  - [ ] Subtask: Provide answers with screenshots

**Phase 5: App Store Consistency (AC: 6)**

- [ ] **Task 12.4.16:** Update App Store listing
  - [ ] Subtask: In App Store Connect, add "Support URL": `https://yourwebsite.com/mytoob/support`
  - [ ] Subtask: Add "Marketing URL" (if different from support URL)
  - [ ] Subtask: In description, mention: "Support available via email: support@yourapp.com"

- [ ] **Task 12.4.17:** Verify consistency
  - [ ] Subtask: Ensure support email in-app matches App Store listing
  - [ ] Subtask: Ensure response time commitment consistent across platforms
  - [ ] Subtask: Update all documentation (website, README, etc.) with same support info

**Phase 6: Error Handling & Edge Cases**

- [ ] **Task 12.4.18:** Handle no email client configured
  - [ ] Subtask: Catch error when opening mailto URL
  - [ ] Subtask: Show alert: "No email client configured. Please email us at support@yourapp.com"
  - [ ] Subtask: Include "Copy Email Address" button

- [ ] **Task 12.4.19:** Handle diagnostics generation failure
  - [ ] Subtask: If log export fails, show error: "Could not generate diagnostics. Please describe your issue in the email."
  - [ ] Subtask: Still open email client (without attachment)

- [ ] **Task 12.4.20:** Handle large diagnostic files
  - [ ] Subtask: If diagnostics ZIP > 10MB, warn user: "Large file. Consider uploading to cloud service."
  - [ ] Subtask: Provide instructions for alternate upload methods

---

### Dev Notes

**File Locations:**
- `MyToob/Views/Settings/SettingsView.swift` - Support section with links
- `MyToob/Services/DiagnosticsService.swift` - Log collection and sanitization
- `docs/support/faq.md` - FAQ page source (Markdown)

**Key Patterns:**
- mailto URL: `mailto:support@example.com?subject=Subject&body=Body`
- URL encoding: `addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)`
- OSLog query: `try OSLogStore(scope: .currentProcessIdentifier).getEntries()`
- ZIP creation: Use `Compression` framework or `Process` to run `zip` command

**PII Sanitization Regex Examples:**
```swift
// Email addresses
logContent = logContent.replacingOccurrences(of: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", with: "[EMAIL]", options: .regularExpression)

// Video titles (heuristic: quoted strings in logs)
logContent = logContent.replacingOccurrences(of: "\"[^\"]+\"", with: "\"[REDACTED]\"", options: .regularExpression)
```

**Compliance:**
- GDPR: Sanitize PII before exporting logs
- User consent: Inform user that diagnostics may contain technical info
- App Store: Providing support email is recommended but not required

---

### Testing Requirements

**Unit Tests (10 tests):**
1. Test support email URL construction
2. Test subject and body are URL-encoded correctly
3. Test app version inserted into email body
4. Test diagnostics log collection
5. Test log sanitization removes email addresses
6. Test log sanitization removes video titles
7. Test ZIP archive creation
8. Test diagnostics file saved to correct location
9. Test error handling when email client unavailable
10. Test error handling when diagnostics generation fails

**UI Tests (5 tests):**
1. Test "Contact Support" button visible in Settings
2. Test "Send Diagnostics" button visible in Settings
3. Test "FAQ" link visible in Settings
4. Test clicking "Contact Support" opens email client
5. Test clicking "Send Diagnostics" shows save dialog

**Integration Tests (2 tests):**
1. Test full diagnostics flow: collect logs → sanitize → ZIP → save → open email
2. Test support email opens with pre-filled template

---


## Story 12.5: YouTube Disclaimers & Attributions

**Status:** Not Started  
**Dependencies:** Story 1.5 (Basic app shell/About screen)  
**Epic:** Epic 12 - UGC Safeguards & Compliance Features

**Acceptance Criteria:**
1. "Not affiliated with YouTube" disclaimer shown in About screen (Settings > About)
2. YouTube branding attribution: "Powered by YouTube" badge shown near IFrame Player (per YouTube Branding Guidelines)
3. YouTube logo displayed in sidebar "YouTube" section (using official logo, not modified)
4. App name "MyToob" avoids using "YouTube" trademark
5. App icon custom-designed, does not resemble YouTube logo
6. Terms of Service link includes statement: "This app uses YouTube services via official APIs and is subject to YouTube's Terms of Service"
7. Reviewer Notes document includes section explaining compliance with YouTube branding guidelines

---

### Implementation Phases

**Phase 1: About Screen Disclaimer (AC: 1)**

- [ ] **Task 12.5.1:** Add disclaimer to About screen
  - [ ] Subtask: In `SettingsView.swift` or `AboutView.swift`, add disclaimer text
  - [ ] Subtask: Text: "MyToob is not affiliated with, endorsed by, or sponsored by YouTube."
  - [ ] Subtask: Font: `.caption` or `.footnote` (smaller, less prominent)
  - [ ] Subtask: Color: secondary text color

- [ ] **Task 12.5.2:** Position disclaimer appropriately
  - [ ] Subtask: Place below app name/version info
  - [ ] Subtask: Above or below "Terms of Service" and "Privacy Policy" links
  - [ ] Subtask: Ensure visible without scrolling (on default window size)

**Phase 2: "Powered by YouTube" Badge (AC: 2)**

- [ ] **Task 12.5.3:** Research YouTube branding guidelines
  - [ ] Subtask: Review [YouTube Branding Guidelines](https://developers.google.com/youtube/terms/branding-guidelines)
  - [ ] Subtask: Identify required attributions for IFrame Player usage
  - [ ] Subtask: Download official "Powered by YouTube" badge assets

- [ ] **Task 12.5.4:** Add badge near IFrame Player
  - [ ] Subtask: In `YouTubePlayerView.swift` (or wherever IFrame Player is displayed)
  - [ ] Subtask: Add badge image below or next to player controls
  - [ ] Subtask: Use official badge image (PNG or SVG from YouTube)
  - [ ] Subtask: Badge size: small, unobtrusive (e.g., 100x30 pixels)

- [ ] **Task 12.5.5:** Ensure badge visibility
  - [ ] Subtask: Badge visible when player is active
  - [ ] Subtask: Badge not obscured by other UI elements
  - [ ] Subtask: Badge respects dark mode (use light variant for dark backgrounds)

**Phase 3: YouTube Logo in Sidebar (AC: 3)**

- [ ] **Task 12.5.6:** Add YouTube logo to sidebar
  - [ ] Subtask: In sidebar "YouTube" section header, add official YouTube logo
  - [ ] Subtask: Use official logo (download from YouTube brand assets)
  - [ ] Subtask: Logo size: small icon (16x16 or 24x24 pixels)
  - [ ] Subtask: Position: left of "YouTube" section title

- [ ] **Task 12.5.7:** Verify logo usage compliance
  - [ ] Subtask: Do NOT modify logo (no color changes, no distortions)
  - [ ] Subtask: Use appropriate logo variant for light/dark mode
  - [ ] Subtask: Logo clickable (optional): opens YouTube.com in browser

**Phase 4: App Name & Icon (AC: 4, 5)**

- [ ] **Task 12.5.8:** Verify app name compliance
  - [ ] Subtask: App name: "MyToob" (does not include "YouTube" trademark)
  - [ ] Subtask: No "YouTube" in app bundle identifier: `com.yourcompany.mytoob`
  - [ ] Subtask: No "YouTube" in marketing materials or App Store listing

- [ ] **Task 12.5.9:** Design custom app icon
  - [ ] Subtask: Icon design distinct from YouTube logo (no red play button, no "Tube" reference)
  - [ ] Subtask: Icon theme: video library, organization, AI/smart features
  - [ ] Subtask: Example: Stack of videos, folder with play symbol, magnifying glass + video
  - [ ] Subtask: Ensure icon follows macOS design guidelines (rounded square, no transparency)

- [ ] **Task 12.5.10:** Generate icon assets
  - [ ] Subtask: Use icon generator tool (e.g., [App Icon Generator](https://appicon.co/))
  - [ ] Subtask: Generate all required sizes for macOS (16x16, 32x32, 128x128, 256x256, 512x512, 1024x1024)
  - [ ] Subtask: Add to `MyToob/Assets.xcassets/AppIcon.appiconset/`

**Phase 5: Terms of Service Statement (AC: 6)**

- [ ] **Task 12.5.11:** Add YouTube ToS reference to app ToS
  - [ ] Subtask: In Terms of Service document, add section: "Third-Party Services"
  - [ ] Subtask: Text: "This app uses YouTube services via official APIs and is subject to [YouTube's Terms of Service](https://www.youtube.com/t/terms)."
  - [ ] Subtask: Link to YouTube ToS: `https://www.youtube.com/t/terms`

- [ ] **Task 12.5.12:** Add YouTube API Services disclaimer
  - [ ] Subtask: Text: "By using YouTube features in this app, you agree to be bound by [YouTube's Terms of Service](https://www.youtube.com/t/terms)."
  - [ ] Subtask: Position: Near YouTube-related features (login, library sync)

- [ ] **Task 12.5.13:** Link ToS from Settings
  - [ ] Subtask: Add "Terms of Service" link in Settings > About
  - [ ] Subtask: Open ToS page in browser (hosted on static site, like Content Policy)

**Phase 6: Reviewer Notes Documentation (AC: 7)**

- [ ] **Task 12.5.14:** Create reviewer notes document
  - [ ] Subtask: Create `docs/app-store/REVIEWER_NOTES.md`
  - [ ] Subtask: Sections:
    - App Overview
    - YouTube Integration Compliance
    - Branding Guidelines Compliance
    - UGC Safeguards (Stories 12.1-12.4)
    - Privacy & Data Handling
  - [ ] Subtask: Export to PDF for App Store Connect upload

- [ ] **Task 12.5.15:** YouTube Branding Compliance section
  - [ ] Subtask: List all YouTube branding elements used:
    - Official logo in sidebar
    - "Powered by YouTube" badge near player
    - "Not affiliated with YouTube" disclaimer
  - [ ] Subtask: Explain IFrame Player usage (no ad blocking, no overlays)
  - [ ] Subtask: Reference YouTube Branding Guidelines URL

- [ ] **Task 12.5.16:** Include screenshots
  - [ ] Subtask: Screenshot: About screen with disclaimer
  - [ ] Subtask: Screenshot: IFrame Player with "Powered by YouTube" badge
  - [ ] Subtask: Screenshot: Sidebar with YouTube logo
  - [ ] Subtask: Annotate screenshots to highlight compliance features

**Phase 7: Final Verification**

- [ ] **Task 12.5.17:** Checklist review
  - [ ] Subtask: Verify "Not affiliated with YouTube" disclaimer visible
  - [ ] Subtask: Verify "Powered by YouTube" badge near player
  - [ ] Subtask: Verify YouTube logo in sidebar (official, unmodified)
  - [ ] Subtask: Verify app name does not include "YouTube"
  - [ ] Subtask: Verify app icon does not resemble YouTube logo
  - [ ] Subtask: Verify ToS includes YouTube API Services disclaimer
  - [ ] Subtask: Verify reviewer notes document complete

- [ ] **Task 12.5.18:** Legal review (optional but recommended)
  - [ ] Subtask: Have legal counsel review branding usage
  - [ ] Subtask: Confirm compliance with YouTube API ToS
  - [ ] Subtask: Confirm compliance with YouTube Branding Guidelines

---

### Dev Notes

**File Locations:**
- `MyToob/Views/Settings/AboutView.swift` - Disclaimer text
- `MyToob/Views/YouTubePlayerView.swift` - "Powered by YouTube" badge
- `MyToob/Views/SidebarView.swift` - YouTube logo in sidebar
- `MyToob/Assets.xcassets/YouTubeLogo.imageset/` - Official YouTube logo assets
- `MyToob/Assets.xcassets/PoweredByYouTubeBadge.imageset/` - Badge assets
- `docs/app-store/REVIEWER_NOTES.md` - App Store reviewer documentation

**YouTube Branding Guidelines Key Points:**
- Use official YouTube logo (no modifications)
- "Powered by YouTube" badge required for IFrame Player implementations
- Do NOT use "YouTube" in app name
- Do NOT create icon resembling YouTube logo
- Clearly state app is not affiliated with YouTube

**YouTube Logo Sources:**
- Download from: [YouTube Brand Resources](https://www.youtube.com/about/brand-resources/)
- Logo variants: Full color, monochrome, light/dark
- Badge: "Powered by YouTube" (various sizes)

**App Icon Design Tips:**
- Avoid red play button (YouTube's trademark)
- Avoid "tube" or video player imagery that resembles YouTube
- Focus on unique MyToob features: library, organization, AI
- Use distinct color scheme (not red/white/black like YouTube)

---

### Testing Requirements

**Manual Tests (10 tests):**
1. Verify "Not affiliated with YouTube" disclaimer visible in About screen
2. Verify disclaimer text is correct (matches AC)
3. Verify "Powered by YouTube" badge visible near IFrame Player
4. Verify badge uses official YouTube assets
5. Verify YouTube logo visible in sidebar "YouTube" section
6. Verify logo is official and unmodified
7. Verify app name "MyToob" does not include "YouTube"
8. Verify app icon does not resemble YouTube logo
9. Verify ToS includes YouTube API Services disclaimer
10. Verify reviewer notes document complete and accurate

**UI Tests (3 tests):**
1. Test disclaimer visible in Settings > About
2. Test "Powered by YouTube" badge visible when playing YouTube video
3. Test YouTube logo visible in sidebar

**Compliance Checklist (7 items):**
1. [ ] Disclaimer: "Not affiliated with YouTube" shown
2. [ ] Badge: "Powered by YouTube" near player
3. [ ] Logo: Official YouTube logo in sidebar
4. [ ] Name: No "YouTube" in app name
5. [ ] Icon: Custom design, no YouTube resemblance
6. [ ] ToS: YouTube API Services disclaimer included
7. [ ] Docs: Reviewer notes explain branding compliance

---


## Story 12.6: Compliance Audit Logging

**Status:** Not Started  
**Dependencies:** Story 12.1 (Report action), Story 12.2 (Channel blacklist)  
**Epic:** Epic 12 - UGC Safeguards & Compliance Features

**Acceptance Criteria:**
1. Compliance events logged using OSLog with dedicated subsystem: `com.mytoob.compliance`
2. Events logged: "User reported video {videoID}", "User hid channel {channelID}", "User accessed Content Policy", "User contacted support"
3. Logs include: timestamp, user action, video/channel ID, no PII (no video titles, usernames)
4. Logs stored securely, not accessible to users (only via diagnostics export with user consent)
5. Log retention: 90 days, then auto-deleted
6. "Export Compliance Logs" action (hidden, developer-only) for App Store review submission
7. Logs formatted as JSON for machine-readability

---

### Implementation Phases

**Phase 1: Compliance Logger Service (AC: 1, 2)**

- [ ] **Task 12.6.1:** Create ComplianceLogger service
  - [ ] Subtask: Create `ComplianceLogger.swift` in `MyToob/Services/`
  - [ ] Subtask: Define subsystem: `let subsystem = "com.mytoob.compliance"`
  - [ ] Subtask: Define category: `let category = "content-moderation"`
  - [ ] Subtask: Create OSLog logger: `let logger = Logger(subsystem: subsystem, category: category)`

- [ ] **Task 12.6.2:** Define compliance event enum
  - [ ] Subtask: Create enum `ComplianceEvent` with cases:
    - `.reportedVideo(videoID: String)`
    - `.hidChannel(channelID: String)`
    - `.accessedContentPolicy`
    - `.contactedSupport`
  - [ ] Subtask: Each case includes minimal required data (no PII)

- [ ] **Task 12.6.3:** Implement logging methods
  - [ ] Subtask: Function: `log(_ event: ComplianceEvent)`
  - [ ] Subtask: Switch on event case, log appropriate message
  - [ ] Subtask: Example: `.reportedVideo(videoID)` → `logger.info("User reported video \(videoID)")`
  - [ ] Subtask: Include timestamp (OSLog automatically adds timestamp)

**Phase 2: Log Specific Events (AC: 2)**

- [ ] **Task 12.6.4:** Log video report events
  - [ ] Subtask: In `reportContentAction()` (Story 12.1), call `ComplianceLogger.shared.log(.reportedVideo(videoID: videoItem.videoID!))`
  - [ ] Subtask: Log AFTER user confirms report (not on menu click)

- [ ] **Task 12.6.5:** Log channel hide events
  - [ ] Subtask: In `hideChannelAction()` (Story 12.2), call `ComplianceLogger.shared.log(.hidChannel(channelID: channelID))`
  - [ ] Subtask: Log AFTER channel added to blacklist

- [ ] **Task 12.6.6:** Log Content Policy access
  - [ ] Subtask: In `openContentPolicy()` (Story 12.3), call `ComplianceLogger.shared.log(.accessedContentPolicy)`
  - [ ] Subtask: Log when policy page opens (not just link click)

- [ ] **Task 12.6.7:** Log support contact events
  - [ ] Subtask: In `contactSupport()` (Story 12.4), call `ComplianceLogger.shared.log(.contactedSupport)`
  - [ ] Subtask: Log when email client opens or diagnostics exported

**Phase 3: PII Sanitization (AC: 3)**

- [ ] **Task 12.6.8:** Ensure no PII in logs
  - [ ] Subtask: Do NOT log: video titles, channel names, user email, user IP address
  - [ ] Subtask: DO log: videoID (YouTube ID), channelID (YouTube ID), timestamp, event type
  - [ ] Subtask: Reason: videoID and channelID are public identifiers, not PII

- [ ] **Task 12.6.9:** Validate log messages
  - [ ] Subtask: Review all log messages for PII
  - [ ] Subtask: Use unit tests to verify log format
  - [ ] Subtask: Example valid log: "User reported video dQw4w9WgXcQ at 2024-01-15T10:30:00Z"
  - [ ] Subtask: Example invalid log: "User reported video 'Rickroll' by 'RickAstleyVEVO'"

**Phase 4: Secure Log Storage (AC: 4, 5)**

- [ ] **Task 12.6.10:** OSLog default storage
  - [ ] Subtask: OSLog stores logs in system log database (not accessible via app sandbox)
  - [ ] Subtask: Logs accessible only via Console.app (developer) or diagnostics export (user consent)
  - [ ] Subtask: No custom log file storage required (security benefit)

- [ ] **Task 12.6.11:** Implement log retention policy
  - [ ] Subtask: OSLog default retention: ~7 days for `.info` level logs
  - [ ] Subtask: To retain 90 days: use `.default` log level instead of `.info`
  - [ ] Subtask: Alternative: Export logs to custom file with 90-day auto-deletion
  - [ ] Subtask: Recommendation: Stick with OSLog defaults for security

- [ ] **Task 12.6.12:** Prevent user access to raw logs
  - [ ] Subtask: Logs not accessible via app UI (no "View Logs" button for users)
  - [ ] Subtask: Logs only exported via "Send Diagnostics" (Story 12.4) with user consent
  - [ ] Subtask: Diagnostics export sanitizes logs (removes PII, as defined in Story 12.4)

**Phase 5: Developer Export (AC: 6, 7)**

- [ ] **Task 12.6.13:** Create developer-only export action
  - [ ] Subtask: Add hidden keyboard shortcut: ⌘⇧⌥L (Command+Shift+Option+L) to trigger export
  - [ ] Subtask: Or: Add "Export Compliance Logs" button in Settings (hidden behind "Debug Mode" flag)
  - [ ] Subtask: Show confirmation: "Export compliance logs for App Store review?"

- [ ] **Task 12.6.14:** Query compliance logs
  - [ ] Subtask: Use `OSLogStore` to query logs: `try OSLogStore(scope: .currentProcessIdentifier).getEntries()`
  - [ ] Subtask: Filter by subsystem: `com.mytoob.compliance`
  - [ ] Subtask: Filter by time range: last 90 days (or since app install, whichever is shorter)

- [ ] **Task 12.6.15:** Format logs as JSON
  - [ ] Subtask: Convert log entries to JSON array:
    ```json
    [
      {
        "timestamp": "2024-01-15T10:30:00Z",
        "event": "reportedVideo",
        "videoID": "dQw4w9WgXcQ"
      },
      {
        "timestamp": "2024-01-16T14:20:00Z",
        "event": "hidChannel",
        "channelID": "UCuAXFkgsw1L7xaCfnd5JJOw"
      }
    ]
    ```
  - [ ] Subtask: Use `JSONEncoder` to serialize
  - [ ] Subtask: Save to file: `~/Downloads/mytoob-compliance-logs-{timestamp}.json`

- [ ] **Task 12.6.16:** Show export success
  - [ ] Subtask: Alert: "Compliance logs exported to {path}"
  - [ ] Subtask: Button: "Reveal in Finder"
  - [ ] Subtask: Include instructions: "Include this file in your App Store review submission if requested."

**Phase 6: App Store Submission Documentation**

- [ ] **Task 12.6.17:** Document compliance logging in reviewer notes
  - [ ] Subtask: In `REVIEWER_NOTES.md`, add section: "Compliance Audit Logging"
  - [ ] Subtask: Explain what events are logged and why
  - [ ] Subtask: Emphasize no PII in logs
  - [ ] Subtask: Mention 90-day retention policy

- [ ] **Task 12.6.18:** Provide sample logs
  - [ ] Subtask: Generate sample compliance logs (anonymized)
  - [ ] Subtask: Include in reviewer notes as example
  - [ ] Subtask: Demonstrate log format and content

**Phase 7: Testing & Validation**

- [ ] **Task 12.6.19:** Test logging for all events
  - [ ] Subtask: Trigger "Report Content" action → verify log entry created
  - [ ] Subtask: Trigger "Hide Channel" action → verify log entry created
  - [ ] Subtask: Open Content Policy → verify log entry created
  - [ ] Subtask: Contact Support → verify log entry created

- [ ] **Task 12.6.20:** Verify no PII in logs
  - [ ] Subtask: Export compliance logs
  - [ ] Subtask: Manually review JSON output for PII (video titles, channel names, emails)
  - [ ] Subtask: Use regex to scan for common PII patterns (emails, names)

- [ ] **Task 12.6.21:** Test log retention
  - [ ] Subtask: Create test logs with various timestamps
  - [ ] Subtask: Verify logs older than 90 days not included in export
  - [ ] Subtask: Note: Testing 90-day retention in real-time not feasible; document logic for review

---

### Dev Notes

**File Locations:**
- `MyToob/Services/ComplianceLogger.swift` - Centralized compliance logging service
- `MyToob/Views/Settings/DebugSettingsView.swift` - Developer-only export action (optional)
- `docs/app-store/REVIEWER_NOTES.md` - Compliance logging documentation

**Key Patterns:**
- OSLog: `let logger = Logger(subsystem: "com.mytoob.compliance", category: "content-moderation")`
- Log entry: `logger.info("User reported video \(videoID)")`
- Query logs: `try OSLogStore(scope: .currentProcessIdentifier).getEntries()`
- JSON export: `let jsonData = try JSONEncoder().encode(logEntries)`

**Privacy Considerations:**
- OSLog is secure: logs stored in system database, not accessible to other apps
- No PII: videoID and channelID are public identifiers, not personal data
- User consent: diagnostics export requires user to click "Send Diagnostics"
- GDPR compliance: logs can be deleted on user request (delete app data)

**App Store Compliance:**
- Guideline 1.2 (UGC): Demonstrates proactive moderation and user safety measures
- Logging shows app takes UGC seriously (reports, channel blocks tracked)
- JSON format makes logs auditable by App Store reviewers

---

### Testing Requirements

**Unit Tests (12 tests):**
1. Test `ComplianceLogger.log(.reportedVideo)` creates log entry
2. Test log message includes videoID
3. Test log message does NOT include video title
4. Test `ComplianceLogger.log(.hidChannel)` creates log entry
5. Test log message includes channelID
6. Test log message does NOT include channel name
7. Test `.accessedContentPolicy` log entry
8. Test `.contactedSupport` log entry
9. Test log query filters by subsystem `com.mytoob.compliance`
10. Test JSON export format is valid
11. Test JSON includes required fields: timestamp, event, ID
12. Test JSON does NOT include PII

**Integration Tests (3 tests):**
1. Test full report flow creates compliance log entry
2. Test full hide channel flow creates compliance log entry
3. Test developer export generates JSON file with correct data

**Manual Tests (5 tests):**
1. Trigger all 4 compliance events, export logs, verify all events present
2. Review exported JSON for PII (manual scan)
3. Verify logs accessible via Console.app (developer only)
4. Verify logs not accessible to users via app UI
5. Verify reviewer notes document compliance logging correctly

---


---

# Epic 13: macOS System Integration

## Story 13.1: Spotlight Indexing for Videos

**Status:** Not Started  
**Dependencies:** Story 1.4 (SwiftData models with VideoItem)  
**Epic:** Epic 13 - macOS System Integration

**Acceptance Criteria:**
1. `CSSearchableItem` created for each `VideoItem` with metadata: title, description, tags, thumbnail
2. Items indexed on import and updated when metadata changes
3. Spotlight results show video thumbnails and descriptions
4. Clicking Spotlight result launches app and opens video detail view
5. "Index in Spotlight" toggle in Settings (enabled by default, Pro feature)
6. Deleting video removes from Spotlight index
7. Search query in Spotlight: "mytoob swift tutorials" finds relevant videos

---

### Implementation Phases

**Phase 1: Core Spotlight Framework Setup (AC: 1)**

- [ ] **Task 13.1.1:** Import Core Spotlight framework
  - [ ] Subtask: Add `import CoreSpotlight` to relevant files
  - [ ] Subtask: Add `import MobileCoreServices` for UTI constants (if needed)

- [ ] **Task 13.1.2:** Create SpotlightIndexService
  - [ ] Subtask: Create `SpotlightIndexService.swift` in `MyToob/Services/`
  - [ ] Subtask: Singleton pattern: `static let shared = SpotlightIndexService()`
  - [ ] Subtask: Property: `let searchableIndex = CSSearchableIndex.default()`

- [ ] **Task 13.1.3:** Define domain identifier
  - [ ] Subtask: Use domain identifier: `com.mytoob.video` (for videos)
  - [ ] Subtask: Use domain identifier: `com.mytoob.collection` (for collections, if indexing)
  - [ ] Subtask: Domain identifier helps bulk deletion and organization

**Phase 2: Create Searchable Items (AC: 1, 3)**

- [ ] **Task 13.1.4:** Create CSSearchableItem for VideoItem
  - [ ] Subtask: Function: `createSearchableItem(for video: VideoItem) -> CSSearchableItem`
  - [ ] Subtask: Unique identifier: `video.id.uuidString`
  - [ ] Subtask: Domain identifier: `com.mytoob.video`

- [ ] **Task 13.1.5:** Configure searchable attributes
  - [ ] Subtask: Create `CSSearchableItemAttributeSet(contentType: .video)`
  - [ ] Subtask: Set `title = video.title`
  - [ ] Subtask: Set `contentDescription = video.description`
  - [ ] Subtask: Set `keywords = video.aiTopicTags` (array of tags)
  - [ ] Subtask: Set `contentURL = video.localURL` (for local files) or YouTube URL (for YouTube videos)

- [ ] **Task 13.1.6:** Add thumbnail to searchable item
  - [ ] Subtask: Load thumbnail image: `let thumbnail = video.loadThumbnail()`
  - [ ] Subtask: Convert to `NSData`: `let thumbnailData = thumbnail.pngData()`
  - [ ] Subtask: Set `thumbnailData = thumbnailData`
  - [ ] Subtask: Thumbnail appears in Spotlight results

- [ ] **Task 13.1.7:** Set additional metadata
  - [ ] Subtask: Set `duration = video.duration` (in seconds)
  - [ ] Subtask: Set `addedDate = video.importedAt` (when video was added to library)
  - [ ] Subtask: Set `contentModificationDate = video.lastModified` (if metadata updated)
  - [ ] Subtask: Set `rating = video.watchProgress` (optional, for sorting)

**Phase 3: Index on Import & Update (AC: 2)**

- [ ] **Task 13.1.8:** Index video on import
  - [ ] Subtask: In `VideoImportService`, after saving `VideoItem` to SwiftData
  - [ ] Subtask: Call `SpotlightIndexService.shared.indexVideo(video)`
  - [ ] Subtask: Async operation: `Task { await indexVideo(video) }`

- [ ] **Task 13.1.9:** Batch indexing for existing videos
  - [ ] Subtask: On app launch, check if Spotlight indexing enabled
  - [ ] Subtask: Query all videos: `@Query var allVideos: [VideoItem]`
  - [ ] Subtask: For each video, create searchable item
  - [ ] Subtask: Batch index: `searchableIndex.indexSearchableItems(items)`
  - [ ] Subtask: Limit batch size: 100 items per call (avoid overwhelming Spotlight)

- [ ] **Task 13.1.10:** Update index when metadata changes
  - [ ] Subtask: Observe `VideoItem` changes (SwiftData observation)
  - [ ] Subtask: On title/description/tags change, re-index video
  - [ ] Subtask: Call `SpotlightIndexService.shared.indexVideo(updatedVideo)`
  - [ ] Subtask: Spotlight automatically replaces existing item (same unique ID)

**Phase 4: Handle Spotlight Result Clicks (AC: 4)**

- [ ] **Task 13.1.11:** Implement application(_:continue:restorationHandler:)
  - [ ] Subtask: In `MyToobApp.swift` (or AppDelegate if using), implement NSUserActivity continuation
  - [ ] Subtask: Check activity type: `CSSearchableItemActionType`
  - [ ] Subtask: Extract unique identifier: `activity.userInfo?[CSSearchableItemActivityIdentifier]`

- [ ] **Task 13.1.12:** Open video detail view
  - [ ] Subtask: Parse unique identifier to get `video.id` (UUID)
  - [ ] Subtask: Query SwiftData for video: `videoItem = modelContext.fetch(where: #Predicate { $0.id == videoID })`
  - [ ] Subtask: If found: navigate to video detail view
  - [ ] Subtask: If not found: show error "Video not found" (may have been deleted)

- [ ] **Task 13.1.13:** Bring app to foreground
  - [ ] Subtask: If app is backgrounded, bring to foreground
  - [ ] Subtask: Use `NSApp.activate(ignoringOtherApps: true)`
  - [ ] Subtask: Open main window if minimized

**Phase 5: Settings Toggle (AC: 5)**

- [ ] **Task 13.1.14:** Add "Index in Spotlight" toggle to Settings
  - [ ] Subtask: In `SettingsView.swift`, add toggle: `@AppStorage("spotlightIndexingEnabled") var spotlightIndexingEnabled = true`
  - [ ] Subtask: Label: "Index videos in Spotlight"
  - [ ] Subtask: Help text: "Allow macOS to search your video library using Spotlight."

- [ ] **Task 13.1.15:** Implement Pro feature gating (optional)
  - [ ] Subtask: If Spotlight indexing is Pro feature, check `UserProStatus.shared.isPro`
  - [ ] Subtask: If Free user: disable toggle, show "Upgrade to Pro" message
  - [ ] Subtask: If Pro user: enable toggle

- [ ] **Task 13.1.16:** Handle toggle on/off
  - [ ] Subtask: When toggle turned ON: index all videos (batch operation)
  - [ ] Subtask: When toggle turned OFF: remove all videos from Spotlight index
  - [ ] Subtask: Remove all: `searchableIndex.deleteAllSearchableItems(completionHandler:)`

**Phase 6: Delete from Index (AC: 6)**

- [ ] **Task 13.1.17:** Remove video from index on deletion
  - [ ] Subtask: In `VideoItem` deletion logic, before deleting from SwiftData
  - [ ] Subtask: Call `SpotlightIndexService.shared.removeVideo(videoID: video.id)`
  - [ ] Subtask: Remove from index: `searchableIndex.deleteSearchableItems(withIdentifiers: [video.id.uuidString])`

- [ ] **Task 13.1.18:** Bulk deletion handling
  - [ ] Subtask: If deleting multiple videos (bulk operation), collect all IDs
  - [ ] Subtask: Batch remove: `searchableIndex.deleteSearchableItems(withIdentifiers: videoIDs)`

**Phase 7: Testing & Validation (AC: 7)**

- [ ] **Task 13.1.19:** Test Spotlight search
  - [ ] Subtask: Import video with title "Swift Concurrency Tutorial"
  - [ ] Subtask: Open Spotlight (⌘Space), search: "swift concurrency"
  - [ ] Subtask: Verify video appears in results
  - [ ] Subtask: Verify thumbnail and description shown
  - [ ] Subtask: Click result, verify app opens and video detail view loads

- [ ] **Task 13.1.20:** Test Spotlight prefixing
  - [ ] Subtask: Search: "mytoob swift" to filter only MyToob results
  - [ ] Subtask: Verify results are scoped to MyToob videos only

- [ ] **Task 13.1.21:** Test index updates
  - [ ] Subtask: Change video title, wait for index update
  - [ ] Subtask: Search for new title in Spotlight, verify updated

---

### Dev Notes

**File Locations:**
- `MyToob/Services/SpotlightIndexService.swift` - Core Spotlight indexing logic
- `MyToob/MyToobApp.swift` - NSUserActivity continuation for Spotlight results
- `MyToob/Views/Settings/SettingsView.swift` - "Index in Spotlight" toggle

**Key Patterns:**
- Create searchable item: `CSSearchableItem(uniqueIdentifier:, domainIdentifier:, attributeSet:)`
- Index items: `CSSearchableIndex.default().indexSearchableItems([items])`
- Delete items: `CSSearchableIndex.default().deleteSearchableItems(withIdentifiers:)`
- Handle clicks: Implement `application(_:continue:restorationHandler:)` for `CSSearchableItemActionType`

**Performance Considerations:**
- Batch indexing: Index 100 items at a time (avoid blocking main thread)
- Async operations: Use `Task {}` for all Spotlight operations
- Index only when enabled: Check `spotlightIndexingEnabled` before indexing

**Spotlight Limitations:**
- Spotlight may throttle indexing (Apple's internal logic)
- Index updates may take few minutes to appear in search results
- Testing: Use Console.app to debug Spotlight indexing issues (search for CoreSpotlight logs)

---

### Testing Requirements

**Unit Tests (8 tests):**
1. Test `createSearchableItem()` generates valid CSSearchableItem
2. Test searchable item includes title, description, tags
3. Test searchable item includes thumbnail data
4. Test batch indexing with 100 videos
5. Test index update when video metadata changes
6. Test delete from index on video deletion
7. Test toggle OFF removes all items from index
8. Test unique identifier matches video.id

**UI Tests (4 tests):**
1. Test "Index in Spotlight" toggle visible in Settings
2. Test toggle turns indexing on/off
3. Test Spotlight result click opens app and video
4. Test invalid video ID (deleted video) shows error

**Integration Tests (3 tests):**
1. Test full Spotlight flow: import video → search in Spotlight → click result → app opens
2. Test Spotlight search with query "mytoob swift tutorials" finds relevant videos
3. Test index removal on video deletion (verify video no longer in Spotlight)

---


## Story 13.2: App Intents for Shortcuts

**Status:** Not Started  
**Dependencies:** Story 1.4 (SwiftData models), Story 10.1 (Collections)  
**Epic:** Epic 13 - macOS System Integration

**Acceptance Criteria:**
1. App Intents defined: "Play Video", "Add to Collection", "Search Videos", "Get Random Video from Cluster"
2. Intents support parameters: video ID, collection name, search query, cluster ID
3. Intents exposed in Shortcuts app (appear when adding MyToob actions)
4. Example Shortcut: "Morning Briefing" plays unwatched videos from "Learning" collection
5. Intents return results (e.g., "Search Videos" returns list of matching videos for further Shortcuts processing)
6. Intents work when app is backgrounded (use background execution entitlement if needed)
7. UI test verifies intents are discoverable in Shortcuts app

---

### Implementation Phases

**Phase 1: App Intents Framework Setup (AC: 1, 3)**

- [ ] **Task 13.2.1:** Import App Intents framework
  - [ ] Subtask: Add `import AppIntents` to relevant files
  - [ ] Subtask: Ensure deployment target is macOS 13.0+ (App Intents minimum)

- [ ] **Task 13.2.2:** Create Intents group
  - [ ] Subtask: Create folder: `MyToob/Intents/`
  - [ ] Subtask: All App Intent structs go here

- [ ] **Task 13.2.3:** Define app shortcut provider
  - [ ] Subtask: Create `MyToobShortcuts.swift` conforming to `AppShortcutsProvider`
  - [ ] Subtask: List all app shortcuts in `appShortcuts` array
  - [ ] Subtask: Shortcuts automatically appear in Shortcuts app

**Phase 2: "Play Video" Intent (AC: 1, 2)**

- [ ] **Task 13.2.4:** Define PlayVideoIntent
  - [ ] Subtask: Create `PlayVideoIntent.swift` conforming to `AppIntent`
  - [ ] Subtask: Property: `@Parameter(title: "Video") var videoID: String`
  - [ ] Subtask: Metadata: `static var title: LocalizedStringResource = "Play Video"`
  - [ ] Subtask: Description: `static var description: IntentDescription = "Plays a video from your library"`

- [ ] **Task 13.2.5:** Implement perform() method
  - [ ] Subtask: Query video: `let video = modelContext.fetch(where: #Predicate { $0.id.uuidString == videoID })`
  - [ ] Subtask: If found: start playback via `PlaybackService.shared.play(video)`
  - [ ] Subtask: If not found: throw error "Video not found"
  - [ ] Subtask: Return result: `.result(value: "Now playing: \(video.title)")`

- [ ] **Task 13.2.6:** Add video entity type
  - [ ] Subtask: Create `VideoEntity.swift` conforming to `EntityQuery`
  - [ ] Subtask: Allows Shortcuts to search/select videos
  - [ ] Subtask: Properties: `id`, `title`, `thumbnail`
  - [ ] Subtask: Query function returns list of all videos

**Phase 3: "Add to Collection" Intent (AC: 1, 2)**

- [ ] **Task 13.2.7:** Define AddToCollectionIntent
  - [ ] Subtask: Create `AddToCollectionIntent.swift` conforming to `AppIntent`
  - [ ] Subtask: Parameters: `@Parameter(title: "Video") var videoID: String`, `@Parameter(title: "Collection") var collectionName: String`
  - [ ] Subtask: Metadata: `static var title = "Add to Collection"`

- [ ] **Task 13.2.8:** Implement perform() method
  - [ ] Subtask: Query video and collection from SwiftData
  - [ ] Subtask: Add video to collection: `collection.videos.append(video)`
  - [ ] Subtask: Save context: `modelContext.save()`
  - [ ] Subtask: Return result: `.result(value: "Added \(video.title) to \(collection.name)")`

- [ ] **Task 13.2.9:** Handle errors
  - [ ] Subtask: Video not found: throw error "Video does not exist"
  - [ ] Subtask: Collection not found: offer to create collection (optional)
  - [ ] Subtask: Video already in collection: return early (no error, idempotent)

**Phase 4: "Search Videos" Intent (AC: 1, 2, 5)**

- [ ] **Task 13.2.10:** Define SearchVideosIntent
  - [ ] Subtask: Create `SearchVideosIntent.swift` conforming to `AppIntent`
  - [ ] Subtask: Parameter: `@Parameter(title: "Query") var searchQuery: String`
  - [ ] Subtask: Metadata: `static var title = "Search Videos"`

- [ ] **Task 13.2.11:** Implement perform() method
  - [ ] Subtask: Use hybrid search (Story 9.4): keyword + vector similarity
  - [ ] Subtask: Call `SearchService.shared.search(query: searchQuery)`
  - [ ] Subtask: Return top 10 results as array of `VideoEntity`
  - [ ] Subtask: Return result: `.result(value: searchResults)`

- [ ] **Task 13.2.12:** Return structured results
  - [ ] Subtask: Return type: `IntentResult<[VideoEntity]>`
  - [ ] Subtask: Shortcuts can iterate over results (e.g., "For each video in results, add to playlist")

**Phase 5: "Get Random Video from Cluster" Intent (AC: 1, 2)**

- [ ] **Task 13.2.13:** Define GetRandomVideoFromClusterIntent
  - [ ] Subtask: Create `GetRandomVideoFromClusterIntent.swift` conforming to `AppIntent`
  - [ ] Subtask: Parameter: `@Parameter(title: "Cluster") var clusterID: String?` (optional, nil = random from all)
  - [ ] Subtask: Metadata: `static var title = "Get Random Video"`

- [ ] **Task 13.2.14:** Implement perform() method
  - [ ] Subtask: If `clusterID` provided: query videos in cluster
  - [ ] Subtask: If nil: query all videos
  - [ ] Subtask: Select random video: `videos.randomElement()`
  - [ ] Subtask: Return video: `.result(value: VideoEntity(from: randomVideo))`

- [ ] **Task 13.2.15:** Add cluster entity type
  - [ ] Subtask: Create `ClusterEntity.swift` conforming to `EntityQuery`
  - [ ] Subtask: Allows Shortcuts to search/select clusters (Smart Collections)
  - [ ] Subtask: Properties: `id`, `label`, `itemCount`

**Phase 6: Example Shortcut Implementation (AC: 4)**

- [ ] **Task 13.2.16:** Create "Morning Briefing" shortcut template
  - [ ] Subtask: Shortcut steps:
    1. Get videos from "Learning" collection (filter: not watched)
    2. For each video, play video
    3. Wait 30 minutes (or until user stops)
  - [ ] Subtask: Export shortcut as `.shortcut` file
  - [ ] Subtask: Provide download link in app or documentation

- [ ] **Task 13.2.17:** Document shortcut creation
  - [ ] Subtask: Write guide: "How to Create Shortcuts with MyToob"
  - [ ] Subtask: Examples: "Play random video", "Add all videos from URL list to collection"
  - [ ] Subtask: Include screenshots

**Phase 7: Background Execution (AC: 6)**

- [ ] **Task 13.2.18:** Test intents when app backgrounded
  - [ ] Subtask: Close app, run shortcut from Shortcuts app
  - [ ] Subtask: Verify intent executes (app may launch in background)
  - [ ] Subtask: If fails: add background execution entitlement

- [ ] **Task 13.2.19:** Add background modes entitlement (if needed)
  - [ ] Subtask: In Xcode, add "Background Modes" capability
  - [ ] Subtask: Enable "Background fetch" or "Remote notifications" (depending on Apple's requirements)
  - [ ] Subtask: Note: App Intents generally work without additional entitlements on macOS

**Phase 8: Testing & Validation (AC: 7)**

- [ ] **Task 13.2.20:** Test intents in Shortcuts app
  - [ ] Subtask: Open Shortcuts app, create new shortcut
  - [ ] Subtask: Add action: search "MyToob", verify intents appear
  - [ ] Subtask: Test each intent: Play Video, Add to Collection, Search Videos, Get Random Video

- [ ] **Task 13.2.21:** Test intent parameters
  - [ ] Subtask: Test invalid videoID (non-existent video) → error handling
  - [ ] Subtask: Test empty search query → return all videos or error
  - [ ] Subtask: Test nil cluster ID → random video from all clusters

- [ ] **Task 13.2.22:** Test intent results
  - [ ] Subtask: Test "Search Videos" returns array of videos
  - [ ] Subtask: Use results in subsequent shortcut actions (e.g., "For each video...")

---

### Dev Notes

**File Locations:**
- `MyToob/Intents/PlayVideoIntent.swift` - Play video intent
- `MyToob/Intents/AddToCollectionIntent.swift` - Add to collection intent
- `MyToob/Intents/SearchVideosIntent.swift` - Search videos intent
- `MyToob/Intents/GetRandomVideoFromClusterIntent.swift` - Random video intent
- `MyToob/Intents/VideoEntity.swift` - Video entity for Shortcuts
- `MyToob/Intents/ClusterEntity.swift` - Cluster entity for Shortcuts
- `MyToob/Intents/MyToobShortcuts.swift` - App shortcuts provider

**Key Patterns:**
- Intent struct: `struct MyIntent: AppIntent { ... }`
- Parameter: `@Parameter(title: "Name") var param: Type`
- Perform method: `func perform() async throws -> some IntentResult { ... }`
- Entity query: `struct MyEntity: EntityQuery { ... }`

**App Intents Best Practices:**
- Keep perform() methods fast (< 5 seconds)
- Handle errors gracefully (throw descriptive errors)
- Return structured results when possible (arrays, entities)
- Use localized strings for all user-facing text

**Shortcuts App Discovery:**
- Intents automatically appear in Shortcuts app once defined
- No manual registration required (unlike Siri Intents in older APIs)
- Test on fresh macOS install to verify discoverability

---

### Testing Requirements

**Unit Tests (10 tests):**
1. Test PlayVideoIntent with valid videoID
2. Test PlayVideoIntent with invalid videoID (throws error)
3. Test AddToCollectionIntent with valid video and collection
4. Test AddToCollectionIntent with non-existent collection (throws error)
5. Test SearchVideosIntent returns array of videos
6. Test SearchVideosIntent with empty query
7. Test GetRandomVideoFromClusterIntent returns random video
8. Test GetRandomVideoFromClusterIntent with nil clusterID
9. Test VideoEntity query returns all videos
10. Test ClusterEntity query returns all clusters

**UI Tests (3 tests):**
1. Test intents are discoverable in Shortcuts app
2. Test "Play Video" shortcut executes correctly
3. Test "Search Videos" shortcut returns results

**Integration Tests (3 tests):**
1. Test full shortcut: "Get unwatched videos → Play first video"
2. Test shortcut execution when app is backgrounded
3. Test shortcut with multiple intents chained together

---


## Story 13.3: Menu Bar Mini-Controller

**Status:** Not Started  
**Dependencies:** Story 3.5 (Playback controls), Story 4.3 (Local playback)  
**Epic:** Epic 13 - macOS System Integration

**Acceptance Criteria:**
1. Menu bar icon added (custom icon, unobtrusive)
2. Clicking icon shows popover with: current video title, play/pause button, skip forward/back buttons, volume slider
3. Now-playing info updated in real-time (title changes when new video starts)
4. Menu bar controller works for both YouTube and local playback
5. "Hide Menu Bar Controller" toggle in Settings (for users who prefer minimal menu bar)
6. Menu bar icon badge shows play/pause state (optional: animated when playing)
7. Global hotkeys work even when menu bar controller hidden (see Story 13.4)

---

### Implementation Phases

**Phase 1: Menu Bar Icon Setup (AC: 1, 5)**

- [ ] **Task 13.3.1:** Create menu bar status item
  - [ ] Subtask: In `MyToobApp.swift` or `AppDelegate`, create `NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)`
  - [ ] Subtask: Store as property: `var statusItem: NSStatusItem?`
  - [ ] Subtask: Only create if "Show Menu Bar Controller" setting enabled

- [ ] **Task 13.3.2:** Design menu bar icon
  - [ ] Subtask: Create SF Symbol-based icon or custom 16x16px icon
  - [ ] Subtask: Icon design: simple play symbol or "M" for MyToob
  - [ ] Subtask: Template mode: `statusItem.button?.image?.isTemplate = true` (respects dark mode)
  - [ ] Subtask: Set icon: `statusItem.button?.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "MyToob")`

- [ ] **Task 13.3.3:** Add Settings toggle
  - [ ] Subtask: In `SettingsView.swift`, add toggle: `@AppStorage("showMenuBarController") var showMenuBarController = true`
  - [ ] Subtask: Label: "Show Menu Bar Controller"
  - [ ] Subtask: Help text: "Display playback controls in the macOS menu bar."

- [ ] **Task 13.3.4:** Show/hide menu bar icon based on toggle
  - [ ] Subtask: Observe `showMenuBarController` changes
  - [ ] Subtask: If enabled: create status item
  - [ ] Subtask: If disabled: remove status item: `NSStatusBar.system.removeStatusItem(statusItem!)`

**Phase 2: Popover UI (AC: 2)**

- [ ] **Task 13.3.5:** Create popover view
  - [ ] Subtask: Create `MenuBarPopoverView.swift` in `MyToob/Views/MenuBar/`
  - [ ] Subtask: SwiftUI view with: title label, play/pause button, skip buttons, volume slider
  - [ ] Subtask: Use `@ObservedObject var playbackState = PlaybackService.shared.state` for real-time updates

- [ ] **Task 13.3.6:** Show popover on icon click
  - [ ] Subtask: Set button action: `statusItem.button?.action = #selector(showPopover(_:))`
  - [ ] Subtask: Create `NSPopover` instance
  - [ ] Subtask: Set content view: `popover.contentViewController = NSHostingController(rootView: MenuBarPopoverView())`
  - [ ] Subtask: Show popover: `popover.show(relativeTo: statusItem.button!.bounds, of: statusItem.button!, preferredEdge: .minY)`

- [ ] **Task 13.3.7:** Design popover layout
  - [ ] Subtask: Width: 250px, Height: 150px
  - [ ] Subtask: Top: Video title (truncated to 2 lines max)
  - [ ] Subtask: Middle: Play/pause button (large, centered), Skip -10s/+10s buttons (smaller, on sides)
  - [ ] Subtask: Bottom: Volume slider (0-100%)
  - [ ] Subtask: Background: Blurred translucent material (`VisualEffectBlur`)

- [ ] **Task 13.3.8:** Dismiss popover on outside click
  - [ ] Subtask: Set `popover.behavior = .transient` (auto-dismiss on outside click)
  - [ ] Subtask: Alternative: Add "Close" button in popover

**Phase 3: Playback Controls (AC: 2, 4)**

- [ ] **Task 13.3.9:** Implement play/pause button
  - [ ] Subtask: Button shows "Play" or "Pause" based on `playbackState.isPlaying`
  - [ ] Subtask: On click: call `PlaybackService.shared.togglePlayPause()`
  - [ ] Subtask: SF Symbols: `play.fill` / `pause.fill`

- [ ] **Task 13.3.10:** Implement skip buttons
  - [ ] Subtask: Skip back button: `-10s` label, calls `PlaybackService.shared.seek(by: -10)`
  - [ ] Subtask: Skip forward button: `+10s` label, calls `PlaybackService.shared.seek(by: +10)`
  - [ ] Subtask: SF Symbols: `gobackward.10` / `goforward.10`

- [ ] **Task 13.3.11:** Implement volume slider
  - [ ] Subtask: SwiftUI `Slider(value: $volume, in: 0...100)`
  - [ ] Subtask: Bind to `PlaybackService.shared.volume`
  - [ ] Subtask: Volume change updates both YouTube IFrame Player (Story 3.5) and AVPlayer (Story 4.3)

- [ ] **Task 13.3.12:** Ensure controls work for both playback types
  - [ ] Subtask: Test with YouTube video: play/pause, seek, volume all work
  - [ ] Subtask: Test with local file: play/pause, seek, volume all work
  - [ ] Subtask: Handle edge case: no video playing (disable buttons)

**Phase 4: Real-Time Updates (AC: 3)**

- [ ] **Task 13.3.13:** Update title in real-time
  - [ ] Subtask: Bind title label to `playbackState.currentVideo?.title`
  - [ ] Subtask: When new video starts, title updates automatically (SwiftUI observation)
  - [ ] Subtask: Truncate long titles: `"Long Video Title That Is Truncated..."`

- [ ] **Task 13.3.14:** Update play/pause button in real-time
  - [ ] Subtask: Observe `playbackState.isPlaying`
  - [ ] Subtask: Button icon changes when playback state changes

- [ ] **Task 13.3.15:** Update volume slider in real-time
  - [ ] Subtask: Observe `playbackState.volume`
  - [ ] Subtask: Slider value updates when volume changed from main window

**Phase 5: Menu Bar Icon Badge (AC: 6)**

- [ ] **Task 13.3.16:** Show play/pause state in icon
  - [ ] Subtask: When playing: change icon to `pause.fill`
  - [ ] Subtask: When paused: change icon to `play.fill`
  - [ ] Subtask: Observe `playbackState.isPlaying`, update icon

- [ ] **Task 13.3.17:** Animate icon when playing (optional)
  - [ ] Subtask: Add subtle animation: icon pulses or bounces
  - [ ] Subtask: Use `CABasicAnimation` on `statusItem.button?.image`
  - [ ] Subtask: Animation duration: 1 second, repeat
  - [ ] Subtask: Stop animation when paused

- [ ] **Task 13.3.18:** Show badge with playback time (optional)
  - [ ] Subtask: Display elapsed time: "15:30" next to icon
  - [ ] Subtask: Update every second
  - [ ] Subtask: Consider impact on menu bar clutter

**Phase 6: Global Hotkeys Integration (AC: 7)**

- [ ] **Task 13.3.19:** Ensure global hotkeys work when menu bar hidden
  - [ ] Subtask: Global hotkeys implemented in Story 13.4 (keyboard shortcuts)
  - [ ] Subtask: Hotkeys registered at app level, not tied to menu bar controller
  - [ ] Subtask: Test: hide menu bar controller, use global hotkeys (Space for play/pause) → works

**Phase 7: Error Handling & Edge Cases**

- [ ] **Task 13.3.20:** Handle no video playing
  - [ ] Subtask: If `playbackState.currentVideo == nil`: show "No video playing" in popover
  - [ ] Subtask: Disable play/pause, skip, volume controls
  - [ ] Subtask: Option: Show "Open MyToob" button to bring app to foreground

- [ ] **Task 13.3.21:** Handle playback errors
  - [ ] Subtask: If playback fails (network error, etc.), show error message in popover
  - [ ] Subtask: Example: "Playback error. Check your internet connection."

- [ ] **Task 13.3.22:** Handle window closed
  - [ ] Subtask: Menu bar controller persists even when main window closed
  - [ ] Subtask: Controls still functional (playback continues in background)
  - [ ] Subtask: Clicking "Open MyToob" button in popover brings window back

---

### Dev Notes

**File Locations:**
- `MyToob/Views/MenuBar/MenuBarPopoverView.swift` - Popover UI with controls
- `MyToob/Services/MenuBarController.swift` - Menu bar status item management
- `MyToob/MyToobApp.swift` - Status item initialization

**Key Patterns:**
- Status item: `NSStatusBar.system.statusItem(withLength:)`
- Popover: `NSPopover` with `NSHostingController(rootView: SwiftUIView())`
- Template image: `image.isTemplate = true` (respects system appearance)

**Design Principles:**
- Minimal and unobtrusive: Small icon, clean popover
- Real-time updates: Observe `PlaybackService.shared.state`
- Transient behavior: Popover dismisses on outside click

**macOS Native Patterns:**
- Menu bar apps should be lightweight and unobtrusive
- Use SF Symbols for consistency with macOS design
- Support dark mode (template images automatically adapt)

---

### Testing Requirements

**Unit Tests (6 tests):**
1. Test status item created when toggle enabled
2. Test status item removed when toggle disabled
3. Test popover shows on icon click
4. Test play/pause button calls `PlaybackService.togglePlayPause()`
5. Test skip buttons call `PlaybackService.seek()`
6. Test volume slider updates `PlaybackService.volume`

**UI Tests (8 tests):**
1. Test menu bar icon visible when toggle enabled
2. Test menu bar icon hidden when toggle disabled
3. Test popover appears on icon click
4. Test popover shows current video title
5. Test play/pause button toggles playback state
6. Test skip forward button seeks +10 seconds
7. Test skip back button seeks -10 seconds
8. Test volume slider changes volume

**Integration Tests (3 tests):**
1. Test full flow: play video → open menu bar popover → pause from popover → verify playback paused
2. Test menu bar controls work for YouTube video
3. Test menu bar controls work for local file

---


## Story 13.4: Comprehensive Keyboard Shortcuts

**Status:** Not Started  
**Dependencies:** Story 1.5 (Basic app shell), Story 3.5 (Playback controls)  
**Epic:** Epic 13 - macOS System Integration

**Acceptance Criteria:**
1. Keyboard shortcuts defined for:
   - Playback: Space (play/pause), ← → (seek 10s), ↑ ↓ (volume), F (full-screen)
   - Navigation: ⌘1/2/3 (switch sidebar sections), ⌘] [ (next/prev video)
   - Actions: ⌘F (search), ⌘N (new note), ⌘K (command palette), ⌘, (settings)
   - Collections: ⌘D (add to collection), ⌘⇧D (new collection)
2. Shortcuts shown in menus (e.g., File > New Collection shows ⌘⇧N)
3. Shortcuts customizable in Settings > Keyboard (optional, Pro feature)
4. Global hotkeys (work when app backgrounded): Media keys (play/pause/next/prev) if supported
5. "Keyboard Shortcuts" help screen accessible via ⌘? (shows all shortcuts)
6. No conflicts with macOS system shortcuts (test on fresh macOS install)
7. Accessibility: All shortcuts announced by VoiceOver

---

### Implementation Phases

**Phase 1: Playback Shortcuts (AC: 1)**

- [ ] **Task 13.4.1:** Implement Space for play/pause
  - [ ] Subtask: Add key handler in main content view: `.onKeyPress(.space) { PlaybackService.shared.togglePlayPause(); return .handled }`
  - [ ] Subtask: Only active when video player is focused
  - [ ] Subtask: Do NOT trigger when typing in text field (check focus state)

- [ ] **Task 13.4.2:** Implement ← → for seek
  - [ ] Subtask: Left arrow: `PlaybackService.shared.seek(by: -10)`
  - [ ] Subtask: Right arrow: `PlaybackService.shared.seek(by: +10)`
  - [ ] Subtask: Handle modifiers: Shift+← → for 30s seek

- [ ] **Task 13.4.3:** Implement ↑ ↓ for volume
  - [ ] Subtask: Up arrow: `PlaybackService.shared.adjustVolume(by: +5)`
  - [ ] Subtask: Down arrow: `PlaybackService.shared.adjustVolume(by: -5)`
  - [ ] Subtask: Clamp volume: 0-100%

- [ ] **Task 13.4.4:** Implement F for full-screen
  - [ ] Subtask: On F key: toggle full-screen for video player
  - [ ] Subtask: Use `NSWindow.toggleFullScreen(_:)` for main window
  - [ ] Subtask: Exit full-screen: Escape key (handled by system)

**Phase 2: Navigation Shortcuts (AC: 1)**

- [ ] **Task 13.4.5:** Implement ⌘1/2/3 for sidebar sections
  - [ ] Subtask: ⌘1: Switch to "Library" section
  - [ ] Subtask: ⌘2: Switch to "Collections" section
  - [ ] Subtask: ⌘3: Switch to "Smart Collections" section
  - [ ] Subtask: Use `.keyboardShortcut("1", modifiers: .command)` on sidebar items

- [ ] **Task 13.4.6:** Implement ⌘] [ for next/prev video
  - [ ] Subtask: ⌘]: Play next video in queue/collection
  - [ ] Subtask: ⌘[: Play previous video
  - [ ] Subtask: If no queue, show toast: "No next video"

**Phase 3: Action Shortcuts (AC: 1)**

- [ ] **Task 13.4.7:** Implement ⌘F for search
  - [ ] Subtask: Focus search bar: `@FocusState var searchFocused: Bool`
  - [ ] Subtask: On ⌘F: set `searchFocused = true`

- [ ] **Task 13.4.8:** Implement ⌘N for new note
  - [ ] Subtask: Open note editor for current video
  - [ ] Subtask: If no video playing: show alert "Open a video first"

- [ ] **Task 13.4.9:** Implement ⌘K for command palette
  - [ ] Subtask: Show command palette (Story 13.5)
  - [ ] Subtask: Use `.keyboardShortcut("k", modifiers: .command)`

- [ ] **Task 13.4.10:** Implement ⌘, for Settings
  - [ ] Subtask: Open Settings window
  - [ ] Subtask: Use `.settings()` modifier or manual window management

**Phase 4: Collection Shortcuts (AC: 1)**

- [ ] **Task 13.4.11:** Implement ⌘D for add to collection
  - [ ] Subtask: Show "Add to Collection" menu or dialog
  - [ ] Subtask: Select collection from list, add current video

- [ ] **Task 13.4.12:** Implement ⌘⇧D for new collection
  - [ ] Subtask: Show "New Collection" dialog
  - [ ] Subtask: Create collection, optionally add current video

**Phase 5: Menu Integration (AC: 2)**

- [ ] **Task 13.4.13:** Add shortcuts to File menu
  - [ ] Subtask: "New Collection" menu item: `.keyboardShortcut("n", modifiers: [.command, .shift])`
  - [ ] Subtask: "New Note" menu item: `.keyboardShortcut("n", modifiers: .command)`
  - [ ] Subtask: Shortcuts automatically shown next to menu items

- [ ] **Task 13.4.14:** Add shortcuts to View menu
  - [ ] Subtask: "Search" menu item: `.keyboardShortcut("f", modifiers: .command)`
  - [ ] Subtask: "Command Palette" menu item: `.keyboardShortcut("k", modifiers: .command)`

- [ ] **Task 13.4.15:** Add shortcuts to Playback menu
  - [ ] Subtask: "Play/Pause" menu item: `.keyboardShortcut(.space, modifiers: [])`
  - [ ] Subtask: "Next Video" menu item: `.keyboardShortcut("]", modifiers: .command)`
  - [ ] Subtask: "Previous Video" menu item: `.keyboardShortcut("[", modifiers: .command)`

**Phase 6: Global Hotkeys (AC: 4)**

- [ ] **Task 13.4.16:** Register media key handlers
  - [ ] Subtask: Use `MediaKeyTap` library or custom implementation
  - [ ] Subtask: Listen for: Play/Pause, Next, Previous media keys
  - [ ] Subtask: Call `PlaybackService` methods when media keys pressed

- [ ] **Task 13.4.17:** Request accessibility permissions
  - [ ] Subtask: Media key handling requires accessibility permissions on macOS
  - [ ] Subtask: Show permission prompt if needed
  - [ ] Subtask: Fallback: If permissions denied, global hotkeys disabled (app-level shortcuts still work)

- [ ] **Task 13.4.18:** Test global hotkeys when app backgrounded
  - [ ] Subtask: Play video, minimize app, press media keys
  - [ ] Subtask: Verify playback controls work

**Phase 7: Keyboard Shortcuts Help Screen (AC: 5)**

- [ ] **Task 13.4.19:** Create shortcuts help view
  - [ ] Subtask: Create `KeyboardShortcutsHelpView.swift` in `MyToob/Views/Help/`
  - [ ] Subtask: List all shortcuts grouped by category: Playback, Navigation, Actions, Collections
  - [ ] Subtask: Show shortcut keys using SF Symbols: `⌘`, `⇧`, `⌥`, `⌃`

- [ ] **Task 13.4.20:** Show help screen on ⌘?
  - [ ] Subtask: Register shortcut: `.keyboardShortcut("?", modifiers: .command)`
  - [ ] Subtask: Open help view as sheet or new window

- [ ] **Task 13.4.21:** Add "Keyboard Shortcuts" to Help menu
  - [ ] Subtask: Help menu item: "Keyboard Shortcuts" with ⌘? shortcut

**Phase 8: Customizable Shortcuts (AC: 3, Pro Feature)**

- [ ] **Task 13.4.22:** Add keyboard shortcut customization UI
  - [ ] Subtask: In Settings > Keyboard, show list of all shortcuts
  - [ ] Subtask: Each row: Action name, Current shortcut, "Edit" button

- [ ] **Task 13.4.23:** Implement shortcut recorder
  - [ ] Subtask: On "Edit" click, show shortcut recorder: "Press new shortcut..."
  - [ ] Subtask: Capture key combination: modifiers + key
  - [ ] Subtask: Validate: no conflicts with system shortcuts
  - [ ] Subtask: Save to UserDefaults: `customShortcuts[actionID] = shortcut`

- [ ] **Task 13.4.24:** Apply custom shortcuts
  - [ ] Subtask: Load custom shortcuts on app launch
  - [ ] Subtask: Override default shortcuts with custom ones
  - [ ] Subtask: "Reset to Defaults" button restores original shortcuts

**Phase 9: Conflict Detection (AC: 6)**

- [ ] **Task 13.4.25:** Test on fresh macOS install
  - [ ] Subtask: List macOS default shortcuts: ⌘Space (Spotlight), ⌘Tab (app switcher), etc.
  - [ ] Subtask: Ensure no conflicts with MyToob shortcuts
  - [ ] Subtask: Adjust if needed: e.g., use ⌘⇧F instead of ⌘F if conflicts

- [ ] **Task 13.4.26:** Handle shortcut conflicts gracefully
  - [ ] Subtask: If user sets custom shortcut that conflicts with system: show warning
  - [ ] Subtask: Warning: "This shortcut may conflict with macOS system shortcut. Continue?"

**Phase 10: Accessibility (AC: 7)**

- [ ] **Task 13.4.27:** Ensure VoiceOver announces shortcuts
  - [ ] Subtask: Add accessibility labels to shortcut buttons
  - [ ] Subtask: Example: "Play/Pause, Keyboard shortcut: Space"
  - [ ] Subtask: Test with VoiceOver enabled

- [ ] **Task 13.4.28:** Ensure keyboard-only navigation works
  - [ ] Subtask: Tab key navigates through UI elements
  - [ ] Subtask: Enter/Return activates buttons
  - [ ] Subtask: Arrow keys navigate lists

---

### Dev Notes

**File Locations:**
- `MyToob/Services/ShortcutManager.swift` - Centralized shortcut registration and handling
- `MyToob/Views/Help/KeyboardShortcutsHelpView.swift` - Help screen showing all shortcuts
- `MyToob/Views/Settings/KeyboardSettingsView.swift` - Shortcut customization UI

**Key Patterns:**
- SwiftUI shortcuts: `.keyboardShortcut("k", modifiers: .command)`
- Key press handler: `.onKeyPress(.space) { ... }`
- Media keys: Use `MediaKeyTap` library or custom `IOKit` implementation

**Shortcut Conventions:**
- Playback: Spacebar, arrow keys (standard media player conventions)
- Navigation: ⌘1/2/3 (standard tab switching), ⌘] [ (bracket keys for next/prev)
- Actions: ⌘F (search), ⌘K (command palette), ⌘, (settings) (macOS conventions)

**Testing Shortcuts:**
- Test on fresh macOS install to catch conflicts
- Test with different keyboard layouts (QWERTY, AZERTY, etc.)
- Test with accessibility features enabled (VoiceOver, Sticky Keys)

---

### Testing Requirements

**Unit Tests (12 tests):**
1. Test Space key toggles play/pause
2. Test ← → keys seek video
3. Test ↑ ↓ keys adjust volume
4. Test F key toggles full-screen
5. Test ⌘F focuses search bar
6. Test ⌘N opens note editor
7. Test ⌘K opens command palette
8. Test ⌘, opens Settings
9. Test ⌘D opens add to collection dialog
10. Test ⌘⇧D opens new collection dialog
11. Test ⌘] plays next video
12. Test ⌘[ plays previous video

**UI Tests (6 tests):**
1. Test shortcuts shown in menus
2. Test keyboard shortcuts help screen opens with ⌘?
3. Test all shortcuts listed in help screen
4. Test custom shortcut recording in Settings
5. Test shortcut conflict warning
6. Test "Reset to Defaults" button

**Integration Tests (3 tests):**
1. Test media keys control playback when app backgrounded
2. Test no conflicts with macOS system shortcuts
3. Test VoiceOver announces all shortcuts

---


## Story 13.5: Command Palette (⌘K)

**Status:** Not Started  
**Dependencies:** Story 1.5 (Basic app shell), Story 13.4 (Keyboard shortcuts)  
**Epic:** Epic 13 - macOS System Integration

**Acceptance Criteria:**
1. Command palette opened with ⌘K (customizable shortcut)
2. Palette shows searchable list of all actions: "New Collection", "Import Files", "Search Videos", "Settings", etc.
3. Fuzzy search: typing "adcol" matches "Add to Collection"
4. Recent actions shown at top (MRU - most recently used)
5. Actions categorized: Playback, Collections, Search, Settings (filterable by category)
6. Selecting action executes it immediately (e.g., "New Collection" opens dialog)
7. Palette dismissible with Escape or clicking outside
8. UI test verifies palette opens and actions execute correctly

---

### Implementation Phases

**Phase 1: Command Palette UI (AC: 1, 2, 7)**

- [ ] **Task 13.5.1:** Create command palette view
  - [ ] Subtask: Create `CommandPaletteView.swift` in `MyToob/Views/CommandPalette/`
  - [ ] Subtask: SwiftUI sheet or overlay with search bar + list
  - [ ] Subtask: Width: 500px, Height: 400px (or dynamic based on results)

- [ ] **Task 13.5.2:** Show palette on ⌘K
  - [ ] Subtask: Add keyboard shortcut: `.keyboardShortcut("k", modifiers: .command)`
  - [ ] Subtask: Toggle state: `@State var showCommandPalette = false`
  - [ ] Subtask: Show as sheet: `.sheet(isPresented: $showCommandPalette) { CommandPaletteView() }`

- [ ] **Task 13.5.3:** Design palette layout
  - [ ] Subtask: Top: Search text field (auto-focused on open)
  - [ ] Subtask: Middle: Scrollable list of actions
  - [ ] Subtask: Bottom: Hint text: "Use ↑↓ to navigate, Enter to select, Esc to close"

- [ ] **Task 13.5.4:** Dismiss palette on Escape or outside click
  - [ ] Subtask: Add key handler: `.onKeyPress(.escape) { showCommandPalette = false; return .handled }`
  - [ ] Subtask: Click outside: `.interactiveDismissDisabled(false)` (default behavior)

**Phase 2: Define Actions (AC: 2, 6)**

- [ ] **Task 13.5.5:** Create Command model
  - [ ] Subtask: Define `Command` struct: `id: UUID`, `name: String`, `category: CommandCategory`, `action: () -> Void`
  - [ ] Subtask: Enum `CommandCategory`: `.playback`, `.collections`, `.search`, `.settings`, `.help`

- [ ] **Task 13.5.6:** Define all commands
  - [ ] Subtask: Playback: "Play/Pause", "Next Video", "Previous Video", "Seek Forward", "Seek Backward"
  - [ ] Subtask: Collections: "New Collection", "Add to Collection", "View Collections"
  - [ ] Subtask: Search: "Search Videos", "Search Notes", "Filter by Tag"
  - [ ] Subtask: Settings: "Open Settings", "Toggle Dark Mode", "Show Keyboard Shortcuts"
  - [ ] Subtask: Help: "View Documentation", "Contact Support", "Report Bug"

- [ ] **Task 13.5.7:** Implement command actions
  - [ ] Subtask: "New Collection" → call `CollectionService.shared.createCollection()`
  - [ ] Subtask: "Play/Pause" → call `PlaybackService.shared.togglePlayPause()`
  - [ ] Subtask: "Open Settings" → present Settings window
  - [ ] Subtask: Each command executes immediately on selection

**Phase 3: Fuzzy Search (AC: 3)**

- [ ] **Task 13.5.8:** Implement fuzzy search algorithm
  - [ ] Subtask: Use library (e.g., `FuzzySearch`) or custom implementation
  - [ ] Subtask: Algorithm: match subsequences (e.g., "adcol" matches "Add to Collection")
  - [ ] Subtask: Score matches: higher score for exact matches, lower for fuzzy

- [ ] **Task 13.5.9:** Filter commands by search query
  - [ ] Subtask: On search text change, filter commands: `commands.filter { fuzzyMatch($0.name, query) }`
  - [ ] Subtask: Sort by match score (best matches first)
  - [ ] Subtask: Show top 10 results (or all if < 10)

- [ ] **Task 13.5.10:** Highlight matching characters
  - [ ] Subtask: In result list, bold matching characters
  - [ ] Subtask: Example: Search "adcol" → "**Ad**d to **Col**lection"

**Phase 4: Recent Actions (AC: 4)**

- [ ] **Task 13.5.11:** Track recent actions
  - [ ] Subtask: Store recent actions in UserDefaults: `recentCommands: [String]` (command IDs)
  - [ ] Subtask: Max 5 recent actions
  - [ ] Subtask: Update on action execution: prepend to list, remove duplicates

- [ ] **Task 13.5.12:** Show recent actions at top
  - [ ] Subtask: If search query empty: show recent actions section
  - [ ] Subtask: Section header: "Recent"
  - [ ] Subtask: List recent commands first, then all commands

**Phase 5: Category Filtering (AC: 5)**

- [ ] **Task 13.5.13:** Add category filter buttons
  - [ ] Subtask: Below search bar: Buttons for each category: "All", "Playback", "Collections", "Search", "Settings"
  - [ ] Subtask: Selected category highlighted
  - [ ] Subtask: On category select, filter commands: `commands.filter { $0.category == selectedCategory }`

- [ ] **Task 13.5.14:** Show category in command list
  - [ ] Subtask: Each command shows icon and category label
  - [ ] Subtask: Example: "🎵 Play/Pause (Playback)"

**Phase 6: Keyboard Navigation**

- [ ] **Task 13.5.15:** Implement arrow key navigation
  - [ ] Subtask: ↑ key: move selection up
  - [ ] Subtask: ↓ key: move selection down
  - [ ] Subtask: Wrap around: at top, ↑ goes to bottom; at bottom, ↓ goes to top

- [ ] **Task 13.5.16:** Implement Enter to execute
  - [ ] Subtask: Enter key: execute selected command
  - [ ] Subtask: Close palette after execution

**Phase 7: Visual Design**

- [ ] **Task 13.5.17:** Design command list items
  - [ ] Subtask: Icon (SF Symbol), Command name, Category label (lighter color)
  - [ ] Subtask: Hover state: highlight background
  - [ ] Subtask: Selected state: blue background

- [ ] **Task 13.5.18:** Add blur background
  - [ ] Subtask: Use `VisualEffectBlur` for palette background
  - [ ] Subtask: Translucent material: blurs content behind palette

**Phase 8: Testing & Validation (AC: 8)**

- [ ] **Task 13.5.19:** Test command execution
  - [ ] Subtask: Open palette, search "new collection", press Enter
  - [ ] Subtask: Verify "New Collection" dialog opens

- [ ] **Task 13.5.20:** Test fuzzy search
  - [ ] Subtask: Search "adcol", verify "Add to Collection" appears
  - [ ] Subtask: Search "plpa", verify "Play/Pause" appears

- [ ] **Task 13.5.21:** Test recent actions
  - [ ] Subtask: Execute command, reopen palette, verify command in "Recent" section

---

### Dev Notes

**File Locations:**
- `MyToob/Views/CommandPalette/CommandPaletteView.swift` - Main palette UI
- `MyToob/Models/Command.swift` - Command model and actions
- `MyToob/Services/CommandPaletteService.swift` - Command registration and execution

**Key Patterns:**
- Command pattern: `struct Command { let name: String; let action: () -> Void }`
- Fuzzy search: Use FuzzySearch library or custom algorithm
- Keyboard shortcuts: `.keyboardShortcut("k", modifiers: .command)`

**Fuzzy Search Algorithm (Simple Implementation):**
```swift
func fuzzyMatch(_ string: String, _ query: String) -> Bool {
    var stringIndex = string.startIndex
    for char in query.lowercased() {
        guard let index = string[stringIndex...].lowercased().firstIndex(of: char) else {
            return false
        }
        stringIndex = string.index(after: index)
    }
    return true
}
```

**Design Inspiration:**
- VS Code Command Palette (Ctrl+Shift+P)
- Raycast command bar
- Spotlight search

---

### Testing Requirements

**Unit Tests (10 tests):**
1. Test fuzzy match: "adcol" matches "Add to Collection"
2. Test fuzzy match: "plpa" matches "Play/Pause"
3. Test command execution: "New Collection" calls `CollectionService.createCollection()`
4. Test recent actions tracking: action added to recent list on execution
5. Test recent actions limit: max 5 items
6. Test category filtering: filter by "Playback" shows only playback commands
7. Test search query filtering
8. Test arrow key navigation (up/down)
9. Test Enter key executes selected command
10. Test Escape key closes palette

**UI Tests (5 tests):**
1. Test command palette opens on ⌘K
2. Test palette shows all commands when search empty
3. Test palette shows recent actions at top
4. Test selecting command executes action
5. Test palette closes on Escape or outside click

**Integration Tests (2 tests):**
1. Test full flow: open palette → search "new collection" → press Enter → dialog opens
2. Test recent actions: execute command → reopen palette → verify command in recent

---


## Story 13.6: Drag-and-Drop from External Sources

**Status:** Not Started  
**Dependencies:** Story 2.1 (YouTube data fetching), Story 4.5 (Local file import)  
**Epic:** Epic 13 - macOS System Integration

**Acceptance Criteria:**
1. Dragging YouTube URL from browser into app window adds video to library (fetches metadata via API)
2. Dragging video file from Finder into app imports as local file (same as Story 4.5)
3. Drop zones: main content area, collection sidebar items (drops into specific collection)
4. Visual feedback: drop zone highlights, "+" icon on hover
5. Invalid drops handled: non-video URLs or unsupported files show error toast
6. Batch drops supported: drag 10 YouTube links, all imported in sequence
7. UI test verifies drag-and-drop from Finder and browser

---

### Implementation Phases

**Phase 1: Drop Zone Setup (AC: 3, 4)**

- [ ] **Task 13.6.1:** Enable drop support in main content area
  - [ ] Subtask: Add `.onDrop(of: [.url, .fileURL], isTargeted: $dropTargeted) { providers in ... }`
  - [ ] Subtask: Handle both URL and file URL types

- [ ] **Task 13.6.2:** Visual feedback for drop targeting
  - [ ] Subtask: When drag enters drop zone: set `dropTargeted = true`
  - [ ] Subtask: Show border or overlay: "Drop here to import"
  - [ ] Subtask: Show "+" icon or import symbol

- [ ] **Task 13.6.3:** Enable drop support on collection sidebar items
  - [ ] Subtask: Each collection row: `.onDrop(of: [.url, .fileURL]) { providers in ... }`
  - [ ] Subtask: Drop adds video to specific collection
  - [ ] Subtask: Visual feedback: collection row highlights on drag-over

**Phase 2: Handle YouTube URL Drops (AC: 1)**

- [ ] **Task 13.6.4:** Detect YouTube URL in drop
  - [ ] Subtask: Load item providers: `let urls = providers.map { $0.loadObject(ofClass: URL.self) }`
  - [ ] Subtask: Filter YouTube URLs: `urls.filter { $0.host?.contains("youtube.com") || $0.host?.contains("youtu.be") }`

- [ ] **Task 13.6.5:** Extract videoID from URL
  - [ ] Subtask: Parse URL query parameter: `v=dQw4w9WgXcQ` (for youtube.com)
  - [ ] Subtask: Parse path: `/dQw4w9WgXcQ` (for youtu.be)
  - [ ] Subtask: Function: `extractVideoID(from url: URL) -> String?`

- [ ] **Task 13.6.6:** Fetch metadata and import
  - [ ] Subtask: Call `YouTubeDataAPI.shared.fetchVideo(videoID: videoID)`
  - [ ] Subtask: Create `VideoItem` from metadata
  - [ ] Subtask: Save to SwiftData: `modelContext.insert(videoItem)`
  - [ ] Subtask: Show success toast: "Video added: {title}"

**Phase 3: Handle File Drops (AC: 2)**

- [ ] **Task 13.6.7:** Detect file URLs in drop
  - [ ] Subtask: Load file URLs: `let fileURLs = providers.compactMap { $0.loadObject(ofClass: URL.self) }`
  - [ ] Subtask: Filter video files: check extension (`.mp4`, `.mov`, `.avi`, etc.)

- [ ] **Task 13.6.8:** Import local files
  - [ ] Subtask: Reuse logic from Story 4.5: `LocalFileImportService.shared.importFile(fileURL)`
  - [ ] Subtask: Generate thumbnail, extract duration, create `VideoItem`
  - [ ] Subtask: Save to SwiftData
  - [ ] Subtask: Show success toast: "File imported: {filename}"

**Phase 4: Drop into Collections (AC: 3)**

- [ ] **Task 13.6.9:** Handle drops on collection rows
  - [ ] Subtask: On drop, get collection ID from row
  - [ ] Subtask: Import video (URL or file) as usual
  - [ ] Subtask: Add to collection: `collection.videos.append(videoItem)`
  - [ ] Subtask: Show success toast: "Video added to {collectionName}"

**Phase 5: Batch Drops (AC: 6)**

- [ ] **Task 13.6.10:** Handle multiple URLs/files in single drop
  - [ ] Subtask: Item providers return array: `let items = providers.compactMap { ... }`
  - [ ] Subtask: Loop through all items: `for item in items { import(item) }`

- [ ] **Task 13.6.11:** Show batch import progress
  - [ ] Subtask: Progress indicator: "Importing 10 videos..."
  - [ ] Subtask: Update progress: "Importing 5 of 10..."
  - [ ] Subtask: Final toast: "Imported 10 videos"

- [ ] **Task 13.6.12:** Handle errors in batch
  - [ ] Subtask: If some imports fail: show summary "Imported 8 of 10 videos. 2 failed."
  - [ ] Subtask: Option: Show details of failed imports

**Phase 6: Invalid Drop Handling (AC: 5)**

- [ ] **Task 13.6.13:** Validate dropped URLs
  - [ ] Subtask: If URL is not YouTube: show error "Only YouTube URLs are supported"
  - [ ] Subtask: If URL is invalid (malformed): show error "Invalid URL"

- [ ] **Task 13.6.14:** Validate dropped files
  - [ ] Subtask: If file is not video: show error "Unsupported file type: {extension}"
  - [ ] Subtask: Supported extensions: `.mp4`, `.mov`, `.avi`, `.mkv`, `.flv`, `.webm`

- [ ] **Task 13.6.15:** Show error toasts
  - [ ] Subtask: Toast with error icon and message
  - [ ] Subtask: Auto-dismiss after 5 seconds

**Phase 7: Testing & Validation (AC: 7)**

- [ ] **Task 13.6.16:** Test YouTube URL drop
  - [ ] Subtask: Drag URL from Safari to app window
  - [ ] Subtask: Verify video added to library
  - [ ] Subtask: Verify metadata fetched correctly

- [ ] **Task 13.6.17:** Test file drop from Finder
  - [ ] Subtask: Drag `.mp4` file from Finder to app
  - [ ] Subtask: Verify file imported as local video

- [ ] **Task 13.6.18:** Test drop onto collection
  - [ ] Subtask: Drag URL to collection sidebar row
  - [ ] Subtask: Verify video added to that collection

- [ ] **Task 13.6.19:** Test batch drops
  - [ ] Subtask: Select 10 YouTube URLs, drag all to app
  - [ ] Subtask: Verify all 10 videos imported

- [ ] **Task 13.6.20:** Test invalid drops
  - [ ] Subtask: Drag non-YouTube URL (e.g., google.com) → error toast
  - [ ] Subtask: Drag non-video file (e.g., `.txt`) → error toast

---

### Dev Notes

**File Locations:**
- `MyToob/Views/ContentAreaView.swift` - Main drop zone
- `MyToob/Views/SidebarView.swift` - Collection drop zones
- `MyToob/Services/DragDropService.swift` - Centralized drag-and-drop logic

**Key Patterns:**
- Drop support: `.onDrop(of: [.url, .fileURL], isTargeted: $dropTargeted) { providers in ... }`
- Load URLs: `provider.loadObject(ofClass: URL.self)`
- Validate URL: Check host contains "youtube.com" or "youtu.be"

**Supported URL Formats:**
- YouTube: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
- YouTube short: `https://youtu.be/dQw4w9WgXcQ`
- YouTube with timestamp: `https://youtube.com/watch?v=dQw4w9WgXcQ&t=30s`

**Supported File Types:**
- Video: `.mp4`, `.mov`, `.avi`, `.mkv`, `.flv`, `.webm`
- (Extend list as needed based on AVFoundation support)

**Error Handling:**
- Invalid URL: "Not a YouTube URL"
- Invalid file: "Unsupported file type"
- Network error: "Could not fetch video metadata. Check your internet connection."

---

### Testing Requirements

**Unit Tests (12 tests):**
1. Test `extractVideoID()` from `youtube.com` URL
2. Test `extractVideoID()` from `youtu.be` URL
3. Test YouTube URL validation (valid)
4. Test YouTube URL validation (invalid, not YouTube)
5. Test file extension validation (valid: `.mp4`)
6. Test file extension validation (invalid: `.txt`)
7. Test batch import with 10 URLs
8. Test batch import with mixed valid/invalid URLs
9. Test drop on collection adds to collection
10. Test invalid URL shows error
11. Test invalid file shows error
12. Test drop zone highlights on drag-over

**UI Tests (6 tests):**
1. Test drag YouTube URL from browser to app window
2. Test drop zone highlights on drag-over
3. Test video added to library after drop
4. Test drag file from Finder to app
5. Test drop onto collection sidebar row
6. Test error toast for invalid drop

**Integration Tests (3 tests):**
1. Test full YouTube URL drop flow: drag URL → fetch metadata → video added
2. Test full file drop flow: drag file → import → video added
3. Test batch drop: drag 10 URLs → all imported

---


---

# Epic 14: Accessibility & Polish

## Story 14.1: VoiceOver Support for All UI Elements

**Status:** Not Started  
**Dependencies:** All UI stories (basic app shell complete)  
**Epic:** Epic 14 - Accessibility & Polish

**Acceptance Criteria:**
1. All buttons, links, and interactive elements have descriptive accessibility labels (e.g., "Play video", not "Button")
2. Video thumbnails include labels: "Video: {title}, {duration}, {channel}"
3. Custom controls (e.g., seek slider) implement accessibility protocols (`NSAccessibility` for macOS)
4. Focus order logical: top-to-bottom, left-to-right within sections
5. Modal dialogs trap focus (Tab cycles within dialog, Escape dismisses)
6. Dynamic content changes announced: "Search returned 12 results", "Video added to collection"
7. VoiceOver testing conducted with real screen reader users (recruit from accessibility community)

---

### Implementation Phases

**Phase 1: Button & Link Labels (AC: 1)**

- [ ] **Task 14.1.1:** Audit all buttons for accessibility labels
  - [ ] Subtask: List all buttons in app (Play, Pause, Add to Collection, etc.)
  - [ ] Subtask: For each button, add `.accessibilityLabel()` modifier
  - [ ] Subtask: Example: `Button("") { ... }.accessibilityLabel("Play video")`
  - [ ] Subtask: Avoid generic labels: "Button", "Click here"

- [ ] **Task 14.1.2:** Add labels to icon-only buttons
  - [ ] Subtask: SF Symbol buttons without text: add descriptive labels
  - [ ] Subtask: Example: Play button (▶️) → "Play video"
  - [ ] Subtask: Example: Settings gear (⚙️) → "Open Settings"

- [ ] **Task 14.1.3:** Add hints for non-obvious actions
  - [ ] Subtask: Use `.accessibilityHint()` for clarification
  - [ ] Subtask: Example: "Add to Collection" button → Hint: "Opens dialog to select collection"

**Phase 2: Video Thumbnail Labels (AC: 2)**

- [ ] **Task 14.1.4:** Create composite accessibility label for thumbnails
  - [ ] Subtask: Format: "Video: {title}, {duration}, {channel}"
  - [ ] Subtask: Example: "Video: Swift Concurrency Tutorial, 15 minutes 30 seconds, Apple Developer"
  - [ ] Subtask: Function: `thumbnailAccessibilityLabel(video: VideoItem) -> String`

- [ ] **Task 14.1.5:** Add labels to thumbnail views
  - [ ] Subtask: In `VideoThumbnailView.swift`, add `.accessibilityLabel(thumbnailAccessibilityLabel(video))`
  - [ ] Subtask: If thumbnail is clickable: add hint "Double-tap to open video"

- [ ] **Task 14.1.6:** Format duration for readability
  - [ ] Subtask: Convert seconds to human-readable: 930s → "15 minutes 30 seconds"
  - [ ] Subtask: Function: `formatDurationForAccessibility(_ seconds: Double) -> String`

**Phase 3: Custom Control Accessibility (AC: 3)**

- [ ] **Task 14.1.7:** Implement NSAccessibility for seek slider
  - [ ] Subtask: Custom seek slider conforming to `NSAccessibilitySlider`
  - [ ] Subtask: Override `accessibilityValue()` to return current time: "15 minutes 30 seconds"
  - [ ] Subtask: Override `accessibilityLabel()` to return "Video position slider"

- [ ] **Task 14.1.8:** Implement NSAccessibility for volume slider
  - [ ] Subtask: Conform to `NSAccessibilitySlider`
  - [ ] Subtask: `accessibilityValue()` returns volume: "75%"
  - [ ] Subtask: `accessibilityLabel()` returns "Volume slider"

- [ ] **Task 14.1.9:** Add accessibility actions for custom controls
  - [ ] Subtask: Seek slider: "Increment" action (seek forward 10s), "Decrement" action (seek back 10s)
  - [ ] Subtask: Volume slider: "Increment" action (volume +5%), "Decrement" action (volume -5%)

**Phase 4: Focus Order (AC: 4)**

- [ ] **Task 14.1.10:** Define focus order in main view
  - [ ] Subtask: Focus order: Sidebar → Search bar → Content area → Player controls
  - [ ] Subtask: Use `.accessibilitySort Order()` if needed to override default order

- [ ] **Task 14.1.11:** Test focus order with Tab key
  - [ ] Subtask: Enable VoiceOver, press Tab repeatedly
  - [ ] Subtask: Verify focus moves logically (no jumping around)
  - [ ] Subtask: Adjust order if needed

**Phase 5: Modal Dialog Focus Trapping (AC: 5)**

- [ ] **Task 14.1.12:** Trap focus in modal dialogs
  - [ ] Subtask: When modal opens, focus first interactive element
  - [ ] Subtask: Tab key cycles within modal only (does not escape to main window)
  - [ ] Subtask: Escape key dismisses modal

- [ ] **Task 14.1.13:** Implement focus trap for common modals
  - [ ] Subtask: "New Collection" dialog: focus traps inside
  - [ ] Subtask: Settings window: focus traps inside
  - [ ] Subtask: Command Palette (Story 13.5): focus traps inside

**Phase 6: Dynamic Content Announcements (AC: 6)**

- [ ] **Task 14.1.14:** Announce search results
  - [ ] Subtask: After search completes, announce: "Search returned {count} results"
  - [ ] Subtask: Use `NSAccessibility.post(element: self, notification: .announcementRequested, userInfo: [.announcement: message])`

- [ ] **Task 14.1.15:** Announce video actions
  - [ ] Subtask: After adding video to collection: announce "Video added to {collectionName}"
  - [ ] Subtask: After hiding channel: announce "Channel hidden"
  - [ ] Subtask: After report action: announce "Report submitted"

- [ ] **Task 14.1.16:** Announce playback state changes
  - [ ] Subtask: When playback starts: announce "Playing: {videoTitle}"
  - [ ] Subtask: When paused: announce "Paused"
  - [ ] Subtask: When video ends: announce "Video ended"

**Phase 7: VoiceOver Testing (AC: 7)**

- [ ] **Task 14.1.17:** Conduct internal VoiceOver testing
  - [ ] Subtask: Enable VoiceOver (⌘F5), navigate entire app
  - [ ] Subtask: Test all user workflows: import video, play video, create collection, search
  - [ ] Subtask: Document issues in accessibility audit

- [ ] **Task 14.1.18:** Recruit accessibility testers
  - [ ] Subtask: Post to accessibility communities (e.g., AppleVis, r/Blind)
  - [ ] Subtask: Offer TestFlight access to VoiceOver users
  - [ ] Subtask: Collect feedback via survey or email

- [ ] **Task 14.1.19:** Address tester feedback
  - [ ] Subtask: Prioritize issues: critical (blocking), high (confusing), low (minor)
  - [ ] Subtask: Fix critical and high issues before release
  - [ ] Subtask: Document known low-priority issues for future updates

---

### Dev Notes

**File Locations:**
- `MyToob/Views/**/*.swift` - Add accessibility modifiers to all views
- `MyToob/Extensions/VideoItem+Accessibility.swift` - Accessibility label helpers
- `MyToob/Services/AccessibilityService.swift` - Centralized accessibility announcements

**Key Patterns:**
- Accessibility label: `.accessibilityLabel("Descriptive label")`
- Accessibility hint: `.accessibilityHint("Additional context")`
- Accessibility value: `.accessibilityValue("Current value")`
- Announcements: `NSAccessibility.post(element:notification:userInfo:)`

**Apple Resources:**
- [Accessibility for macOS](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [NSAccessibility Protocol Reference](https://developer.apple.com/documentation/appkit/nsaccessibility)
- [VoiceOver Testing](https://developer.apple.com/library/archive/technotes/TestingAccessibilityOfiOSApps/TestAccessibilityonYourDevicewithVoiceOver/TestAccessibilityonYourDevicewithVoiceOver.html)

**VoiceOver Commands (macOS):**
- ⌘F5: Toggle VoiceOver
- VO+Arrow keys: Navigate UI elements
- VO+Space: Activate element
- VO+A: Read all

---

### Testing Requirements

**Manual Tests (15 tests):**
1. Enable VoiceOver, navigate entire app with keyboard only
2. Verify all buttons have descriptive labels (no "Button")
3. Verify video thumbnails have composite labels
4. Verify custom controls (seek slider, volume slider) work with VoiceOver
5. Test focus order: logical top-to-bottom, left-to-right
6. Test modal dialog focus trapping (Tab cycles within dialog)
7. Test Escape dismisses modals
8. Test dynamic announcements: search results announced
9. Test video action announcements: "Video added to collection"
10. Test playback state announcements: "Playing", "Paused"
11. Complete user workflow with VoiceOver: import → play → add to collection
12. Test with real VoiceOver users (recruit from accessibility community)
13. Verify no inaccessible UI elements
14. Verify all images have alt text (if applicable)
15. Verify form labels associated with inputs

**Accessibility Audit (5 checks):**
1. [ ] All interactive elements have labels
2. [ ] Focus order is logical
3. [ ] Modal dialogs trap focus
4. [ ] Dynamic content changes announced
5. [ ] VoiceOver testing conducted with real users

---


## Story 14.2: Keyboard-Only Navigation

**Status:** Not Started  
**Dependencies:** All UI stories, Story 13.4 (Keyboard shortcuts)  
**Epic:** Epic 14 - Accessibility & Polish

**Acceptance Criteria:**
1. Tab key navigates through all interactive elements in logical order
2. Shift+Tab navigates backwards
3. Enter/Space activates buttons and links
4. Arrow keys navigate lists and grids
5. Escape dismisses modals, popovers, and cancels actions
6. Focus indicators visible: selected item highlighted with system accent color
7. "Keyboard-only mode" tested: unplug mouse, complete all user workflows

---

### Implementation Phases

**Phase 1: Tab Navigation (AC: 1, 2)**

- [ ] **Task 14.2.1:** Enable Tab key navigation globally
  - [ ] Subtask: macOS default: Tab navigates interactive elements
  - [ ] Subtask: Ensure no custom code disables Tab navigation
  - [ ] Subtask: Test in all views: sidebar, content area, settings

- [ ] **Task 14.2.2:** Define focus order
  - [ ] Subtask: Focus order: Sidebar → Search bar → Content area → Player controls
  - [ ] Subtask: Within content area: top-to-bottom, left-to-right
  - [ ] Subtask: Use `.focusable()` modifier on custom views

- [ ] **Task 14.2.3:** Test Shift+Tab navigation
  - [ ] Subtask: Press Shift+Tab, verify focus moves backwards
  - [ ] Subtask: At first element, Shift+Tab wraps to last element

**Phase 2: Enter/Space Activation (AC: 3)**

- [ ] **Task 14.2.4:** Ensure Enter/Space activate buttons
  - [ ] Subtask: SwiftUI default: buttons activate on Space
  - [ ] Subtask: Test all buttons: Play, Pause, Add to Collection, etc.
  - [ ] Subtask: If custom button views: add `.onKeyPress(.return)` and `.onKeyPress(.space)` handlers

- [ ] **Task 14.2.5:** Implement Enter to open video
  - [ ] Subtask: In video grid/list, when video thumbnail focused, Enter opens video
  - [ ] Subtask: Add `.onKeyPress(.return) { openVideo(video) }`

**Phase 3: Arrow Key Navigation (AC: 4)**

- [ ] **Task 14.2.6:** Implement arrow key navigation in lists
  - [ ] Subtask: In sidebar: ↑↓ keys move selection
  - [ ] Subtask: In video list: ↑↓ keys move selection
  - [ ] Subtask: Enter key activates selected item

- [ ] **Task 14.2.7:** Implement arrow key navigation in grids
  - [ ] Subtask: In video grid: ↑↓←→ keys move selection
  - [ ] Subtask: Logic: ← moves left, → moves right, ↑ moves up (previous row), ↓ moves down (next row)
  - [ ] Subtask: At edges: wrap around or stop (user preference)

- [ ] **Task 14.2.8:** Add visual feedback for arrow key selection
  - [ ] Subtask: Focused item highlighted with border or background color
  - [ ] Subtask: Use system accent color for focus indicator

**Phase 4: Escape Key Handling (AC: 5)**

- [ ] **Task 14.2.9:** Implement Escape to dismiss modals
  - [ ] Subtask: All `.sheet()` and `.alert()` views: Escape dismisses
  - [ ] Subtask: Test: open "New Collection" dialog, press Escape → dialog closes

- [ ] **Task 14.2.10:** Implement Escape to dismiss popovers
  - [ ] Subtask: Menu bar popover (Story 13.3): Escape dismisses
  - [ ] Subtask: Context menus: Escape dismisses

- [ ] **Task 14.2.11:** Implement Escape to cancel actions
  - [ ] Subtask: During search: Escape clears search query
  - [ ] Subtask: During file import: Escape cancels import (if possible)

**Phase 5: Focus Indicators (AC: 6)**

- [ ] **Task 14.2.12:** Style focus indicators
  - [ ] Subtask: Use system accent color: `Color.accentColor`
  - [ ] Subtask: Border or outline on focused element: `border(Color.accentColor, width: 2)`
  - [ ] Subtask: Ensure contrast: focus indicator visible in light and dark mode

- [ ] **Task 14.2.13:** Apply focus indicators to all interactive elements
  - [ ] Subtask: Buttons: focus ring around button
  - [ ] Subtask: Video thumbnails: border around thumbnail
  - [ ] Subtask: Sidebar items: background highlight

- [ ] **Task 14.2.14:** Respect system focus ring preference
  - [ ] Subtask: macOS "Full Keyboard Access" setting: if enabled, show focus indicators
  - [ ] Subtask: If disabled: focus indicators still visible (accessibility requirement)

**Phase 6: Keyboard-Only Testing (AC: 7)**

- [ ] **Task 14.2.15:** Conduct keyboard-only testing
  - [ ] Subtask: Unplug mouse, use only keyboard
  - [ ] Subtask: Complete all user workflows:
    - Import local file
    - Sign in with YouTube
    - Play video
    - Create collection
    - Add video to collection
    - Search videos
    - Take note
    - Open Settings
  - [ ] Subtask: Document any actions not possible with keyboard

- [ ] **Task 14.2.16:** Fix keyboard-only blockers
  - [ ] Subtask: If any actions require mouse: add keyboard alternative
  - [ ] Subtask: Example: Drag-and-drop (Story 13.6) → add "Add to Collection" keyboard shortcut

- [ ] **Task 14.2.17:** Create keyboard navigation guide
  - [ ] Subtask: Document all keyboard shortcuts and navigation patterns
  - [ ] Subtask: Include in app help: "Keyboard Shortcuts" section

---

### Dev Notes

**File Locations:**
- `MyToob/Views/**/*.swift` - Add keyboard navigation to all views
- `MyToob/Extensions/View+KeyboardNavigation.swift` - Custom keyboard navigation modifiers

**Key Patterns:**
- Tab navigation: `.focusable()` modifier (SwiftUI)
- Arrow key navigation: `.onKeyPress(.upArrow) { ... }`
- Enter/Space activation: `.onKeyPress(.return)` and `.onKeyPress(.space)`
- Escape dismissal: `.keyboardShortcut(.escape, modifiers: [])`

**macOS Accessibility Features:**
- Full Keyboard Access: System Settings → Keyboard → Keyboard Navigation
- When enabled: Tab navigates all controls (not just text fields and lists)

**Focus Indicator Design:**
- Thickness: 2-3px border
- Color: System accent color (blue by default)
- Style: Solid or dashed border
- Contrast: Ensure visible in light and dark mode

---

### Testing Requirements

**Manual Tests (10 tests):**
1. Unplug mouse, use only keyboard for entire session
2. Test Tab key navigates all interactive elements
3. Test Shift+Tab navigates backwards
4. Test Enter/Space activate buttons
5. Test arrow keys navigate lists
6. Test arrow keys navigate grids
7. Test Escape dismisses modals
8. Test Escape dismisses popovers
9. Test focus indicators visible on all elements
10. Complete all user workflows with keyboard only

**Accessibility Audit (7 checks):**
1. [ ] Tab navigation works in all views
2. [ ] Shift+Tab works
3. [ ] Enter/Space activate buttons
4. [ ] Arrow keys navigate lists and grids
5. [ ] Escape dismisses modals and popovers
6. [ ] Focus indicators visible
7. [ ] All workflows possible with keyboard only

---


## Story 14.3: High-Contrast Theme

**Status:** Not Started  
**Dependencies:** Story 1.5 (Basic app shell with theming)  
**Epic:** Epic 14 - Accessibility & Polish

**Acceptance Criteria:**
1. "High Contrast" toggle in Settings > Accessibility
2. High-contrast theme increases contrast ratios: 4.5:1 for body text, 3:1 for large text (WCAG AA)
3. Colors adjusted: darker text on lighter backgrounds, thicker borders, larger focus indicators
4. System high-contrast preference respected: if macOS "Increase Contrast" enabled, app follows automatically
5. High-contrast theme tested with contrast checker tool (e.g., Stark, Color Oracle)
6. All UI elements remain functional and readable in high-contrast mode
7. Theme persists across app restarts (stored in UserDefaults)

---

### Implementation Phases

**Phase 1: Settings Toggle (AC: 1, 7)**

- [ ] **Task 14.3.1:** Add "High Contrast" toggle to Settings
  - [ ] Subtask: In `SettingsView.swift`, add "Accessibility" section
  - [ ] Subtask: Toggle: `@AppStorage("highContrastEnabled") var highContrastEnabled = false`
  - [ ] Subtask: Label: "Enable High Contrast Theme"
  - [ ] Subtask: Help text: "Increases contrast for better readability."

- [ ] **Task 14.3.2:** Persist theme preference
  - [ ] Subtask: `@AppStorage` automatically persists to UserDefaults
  - [ ] Subtask: Test: toggle ON, restart app, verify still ON

**Phase 2: Define High-Contrast Colors (AC: 2, 3)**

- [ ] **Task 14.3.3:** Create high-contrast color palette
  - [ ] Subtask: Define colors in `Colors.swift` or asset catalog
  - [ ] Subtask: Text colors:
    - Body text: Black on white (21:1 contrast ratio)
    - Secondary text: Dark gray (#333333) on white (12.6:1)
    - Large text: Dark gray (#666666) on white (5.74:1)
  - [ ] Subtask: Background colors:
    - Primary background: White (#FFFFFF)
    - Secondary background: Light gray (#F5F5F5)
  - [ ] Subtask: Border colors: Dark gray (#333333), thicker (2-3px instead of 1px)

- [ ] **Task 14.3.4:** Define high-contrast focus indicators
  - [ ] Subtask: Focus indicator: Thick black border (3px)
  - [ ] Subtask: Contrast: Black on white (21:1)

**Phase 3: Apply High-Contrast Theme (AC: 3, 6)**

- [ ] **Task 14.3.5:** Create theme environment value
  - [ ] Subtask: Create `@Environment(\.highContrastEnabled)` environment value
  - [ ] Subtask: Inject at app root: `.environment(\.highContrastEnabled, highContrastEnabled)`

- [ ] **Task 14.3.6:** Apply high-contrast colors throughout app
  - [ ] Subtask: In each view, check `highContrastEnabled`
  - [ ] Subtask: If enabled: use high-contrast colors
  - [ ] Subtask: Example: `Text("Hello").foregroundColor(highContrastEnabled ? .black : .primary)`

- [ ] **Task 14.3.7:** Increase border thickness
  - [ ] Subtask: Normal: 1px borders
  - [ ] Subtask: High-contrast: 2-3px borders
  - [ ] Subtask: Apply to: buttons, thumbnails, cards

- [ ] **Task 14.3.8:** Increase focus indicator size
  - [ ] Subtask: Normal: 2px focus ring
  - [ ] Subtask: High-contrast: 3-4px focus ring

**Phase 4: System Preference Integration (AC: 4)**

- [ ] **Task 14.3.9:** Detect system "Increase Contrast" setting
  - [ ] Subtask: Use `NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast`
  - [ ] Subtask: Observe changes: `NotificationCenter.default.addObserver(..., name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)`

- [ ] **Task 14.3.10:** Auto-enable high-contrast when system preference enabled
  - [ ] Subtask: If system preference ON: enable high-contrast in app (override user toggle)
  - [ ] Subtask: Show message: "High contrast mode enabled automatically (system preference)."

**Phase 5: Contrast Testing (AC: 5)**

- [ ] **Task 14.3.11:** Test with contrast checker tools
  - [ ] Subtask: Use Stark plugin (Figma/Sketch) or Color Oracle
  - [ ] Subtask: Check all text/background combinations
  - [ ] Subtask: Verify: Body text ≥ 4.5:1, Large text ≥ 3:1 (WCAG AA)

- [ ] **Task 14.3.12:** Test in light and dark mode
  - [ ] Subtask: High-contrast theme works in both light and dark mode
  - [ ] Subtask: Light mode: black text on white
  - [ ] Subtask: Dark mode: white text on black (reverse)

- [ ] **Task 14.3.13:** Document contrast ratios
  - [ ] Subtask: Create table: Color combination → Contrast ratio
  - [ ] Subtask: Example:
    - Black (#000000) on White (#FFFFFF): 21:1 ✅
    - Dark gray (#333333) on White: 12.6:1 ✅
    - Light gray (#999999) on White: 2.8:1 ❌ (fails WCAG AA)

**Phase 6: Functional Testing (AC: 6)**

- [ ] **Task 14.3.14:** Test all UI elements in high-contrast mode
  - [ ] Subtask: Enable high-contrast, navigate entire app
  - [ ] Subtask: Verify all text readable
  - [ ] Subtask: Verify all buttons visible and clickable
  - [ ] Subtask: Verify video thumbnails distinguishable

- [ ] **Task 14.3.15:** Test playback controls in high-contrast
  - [ ] Subtask: Play/pause button visible
  - [ ] Subtask: Seek slider visible and usable
  - [ ] Subtask: Volume slider visible and usable

- [ ] **Task 14.3.16:** Test with users who need high-contrast
  - [ ] Subtask: Recruit users with visual impairments
  - [ ] Subtask: Collect feedback: "Is everything readable?"
  - [ ] Subtask: Address issues

---

### Dev Notes

**File Locations:**
- `MyToob/Views/Settings/AccessibilitySettingsView.swift` - High-contrast toggle
- `MyToob/Theme/Colors.swift` - High-contrast color palette
- `MyToob/Extensions/Environment+HighContrast.swift` - Environment value for high-contrast

**Key Patterns:**
- Environment value: `@Environment(\.highContrastEnabled) var highContrastEnabled`
- Conditional colors: `Text("Hello").foregroundColor(highContrastEnabled ? .black : .primary)`
- System preference: `NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast`

**WCAG Contrast Ratios:**
- Level AA: 4.5:1 for body text (14pt), 3:1 for large text (18pt or 14pt bold)
- Level AAA: 7:1 for body text, 4.5:1 for large text
- Recommendation: Aim for AA, exceed where possible

**Contrast Checker Tools:**
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Stark (Figma/Sketch plugin)](https://www.getstark.co/)
- [Color Oracle (desktop app)](https://colororacle.org/)

---

### Testing Requirements

**Manual Tests (10 tests):**
1. Enable high-contrast toggle in Settings
2. Verify theme applied immediately (no restart required)
3. Verify text contrast: body text ≥ 4.5:1
4. Verify text contrast: large text ≥ 3:1
5. Verify borders thicker in high-contrast mode
6. Verify focus indicators larger in high-contrast mode
7. Test in light mode: black text on white
8. Test in dark mode: white text on black
9. Enable macOS "Increase Contrast" → app follows automatically
10. Restart app, verify theme persists

**Accessibility Audit (7 checks):**
1. [ ] High-contrast toggle in Settings
2. [ ] Contrast ratios meet WCAG AA (4.5:1 body, 3:1 large)
3. [ ] Colors adjusted: darker text, thicker borders
4. [ ] System preference respected
5. [ ] Tested with contrast checker tool
6. [ ] All UI elements functional
7. [ ] Theme persists across restarts

---


## Story 14.4: Loading States & Progress Indicators

**Status:** Not Started  
**Dependencies:** All data-fetching stories (YouTube API, embedding generation, search)  
**Epic:** Epic 14 - Accessibility & Polish

**Acceptance Criteria:**
1. Loading spinners shown during: API calls, embedding generation, search queries, video loading
2. Progress bars shown for long operations: importing 100+ videos, generating embeddings for library, exporting notes
3. Skeleton screens used while content loads (e.g., placeholder thumbnails in grid)
4. "Cancel" button available for cancelable operations (e.g., import, export)
5. Loading states don't block entire UI: show partial results while background tasks run
6. Error states handled: if loading fails, show "Retry" button and error message
7. No blank screens: always show loading indicator or empty state

---

### Implementation Phases

**Phase 1: Loading Spinners (AC: 1, 7)**

- [ ] **Task 14.4.1:** Add loading state to API calls
  - [ ] Subtask: Create `@State var isLoading = false` in views with API calls
  - [ ] Subtask: Set `isLoading = true` before API call, `false` after completion
  - [ ] Subtask: Show spinner: `if isLoading { ProgressView() }`

- [ ] **Task 14.4.2:** Add spinner to YouTube data fetching
  - [ ] Subtask: In YouTube library view, show spinner while fetching videos
  - [ ] Subtask: Spinner positioned centrally in content area

- [ ] **Task 14.4.3:** Add spinner to search queries
  - [ ] Subtask: Show spinner while hybrid search runs (keyword + vector)
  - [ ] Subtask: Position spinner in search results area

- [ ] **Task 14.4.4:** Add spinner to video loading
  - [ ] Subtask: Show spinner while IFrame Player loads YouTube video
  - [ ] Subtask: Show spinner while AVPlayer loads local file

**Phase 2: Progress Bars (AC: 2)**

- [ ] **Task 14.4.5:** Implement progress bar for video import
  - [ ] Subtask: Create `@State var importProgress: Double = 0.0` (0.0-1.0)
  - [ ] Subtask: Update progress as each video imports: `importProgress = completed / total`
  - [ ] Subtask: Show `ProgressView(value: importProgress)` with label "Importing 45/100 videos..."

- [ ] **Task 14.4.6:** Implement progress bar for embedding generation
  - [ ] Subtask: Track progress: `embeddingProgress = generated / total`
  - [ ] Subtask: Show progress bar: "Generating embeddings: 75/120..."
  - [ ] Subtask: Run in background (don't block UI)

- [ ] **Task 14.4.7:** Implement progress bar for note export
  - [ ] Subtask: Track progress: `exportProgress = exported / total`
  - [ ] Subtask: Show progress bar: "Exporting notes: 8/10..."

**Phase 3: Skeleton Screens (AC: 3)**

- [ ] **Task 14.4.8:** Create skeleton view for video grid
  - [ ] Subtask: Create `VideoThumbnailSkeleton.swift` view
  - [ ] Subtask: Show placeholder rectangles where thumbnails will appear
  - [ ] Subtask: Animate shimmer effect (optional, polish)

- [ ] **Task 14.4.9:** Show skeleton while loading
  - [ ] Subtask: Before videos load: show grid of skeletons
  - [ ] Subtask: After videos load: replace skeletons with actual thumbnails
  - [ ] Subtask: Animate transition: fade out skeletons, fade in thumbnails

**Phase 4: Cancel Buttons (AC: 4)**

- [ ] **Task 14.4.10:** Add cancel button to import operation
  - [ ] Subtask: Show "Cancel" button during import
  - [ ] Subtask: On cancel: stop import loop, show toast "Import canceled"
  - [ ] Subtask: Already-imported videos remain in library

- [ ] **Task 14.4.11:** Add cancel button to embedding generation
  - [ ] Subtask: Show "Cancel" button during generation
  - [ ] Subtask: On cancel: stop generation loop
  - [ ] Subtask: Already-generated embeddings saved

- [ ] **Task 14.4.12:** Add cancel button to export operation
  - [ ] Subtask: Show "Cancel" button during export
  - [ ] Subtask: On cancel: stop export, delete partial file

**Phase 5: Non-Blocking Loading (AC: 5)**

- [ ] **Task 14.4.13:** Show partial results during search
  - [ ] Subtask: If keyword search completes before vector search: show keyword results immediately
  - [ ] Subtask: When vector search completes: merge and re-rank results (RRF)
  - [ ] Subtask: UI updates incrementally (progressive loading)

- [ ] **Task 14.4.14:** Background tasks don't block UI
  - [ ] Subtask: Embedding generation runs in background: user can still browse library
  - [ ] Subtask: Show non-intrusive progress indicator (e.g., in toolbar or status bar)

**Phase 6: Error States (AC: 6)**

- [ ] **Task 14.4.15:** Show error message on API failure
  - [ ] Subtask: If YouTube API call fails: show error view with message "Could not load videos. Check your internet connection."
  - [ ] Subtask: Show "Retry" button: on click, retry API call

- [ ] **Task 14.4.16:** Show error message on import failure
  - [ ] Subtask: If file import fails: show error "Could not import {filename}. {errorReason}"
  - [ ] Subtask: Continue importing other files (don't fail entire batch)

- [ ] **Task 14.4.17:** Show error message on embedding generation failure
  - [ ] Subtask: If Core ML model fails: show error "Could not generate embeddings. {errorReason}"
  - [ ] Subtask: Option to retry or skip

**Phase 7: Comprehensive Loading Coverage**

- [ ] **Task 14.4.18:** Audit all async operations for loading states
  - [ ] Subtask: List all async operations: API calls, file I/O, database queries, ML inference
  - [ ] Subtask: For each operation, ensure loading state shown
  - [ ] Subtask: Checklist: ✅ Spinner, ✅ Progress bar (if long), ✅ Cancel button (if cancelable), ✅ Error handling

- [ ] **Task 14.4.19:** Test loading states with slow network
  - [ ] Subtask: Use Network Link Conditioner (macOS developer tool) to simulate slow network
  - [ ] Subtask: Verify loading spinners appear during slow API calls

- [ ] **Task 14.4.20:** Test loading states with large data
  - [ ] Subtask: Import 1000 videos: verify progress bar updates
  - [ ] Subtask: Generate 1000 embeddings: verify progress bar updates

---

### Dev Notes

**File Locations:**
- `MyToob/Views/LoadingView.swift` - Reusable loading spinner component
- `MyToob/Views/Skeletons/VideoThumbnailSkeleton.swift` - Skeleton placeholder views
- `MyToob/Extensions/View+LoadingState.swift` - Custom loading state modifiers

**Key Patterns:**
- Loading state: `@State var isLoading = false` + `if isLoading { ProgressView() }`
- Progress bar: `ProgressView(value: progress)` where `progress` is 0.0-1.0
- Skeleton screen: Placeholder views with shimmer animation

**SwiftUI Loading Components:**
- `ProgressView()` - Indeterminate spinner
- `ProgressView(value: 0.5)` - Determinate progress bar (50%)
- `ProgressView("Loading...")` - Spinner with label

**Cancel Button Pattern:**
```swift
@State var isCancelled = false
Task {
    for i in 0..<total {
        if isCancelled { break }
        await importVideo(i)
    }
}
Button("Cancel") { isCancelled = true }
```

---

### Testing Requirements

**Unit Tests (8 tests):**
1. Test loading state: `isLoading = true` shows spinner
2. Test progress bar updates as operation progresses
3. Test cancel button stops operation
4. Test error state shows retry button
5. Test partial results shown during incremental loading
6. Test skeleton screens shown before content loads
7. Test loading states don't block UI (background tasks)
8. Test error handling: retry after failure

**UI Tests (6 tests):**
1. Test spinner shown during API call
2. Test progress bar shown during import (100+ videos)
3. Test skeleton screens shown in video grid
4. Test cancel button stops import
5. Test error view shown on API failure
6. Test retry button retries operation

**Integration Tests (3 tests):**
1. Test full import flow with progress bar and cancel
2. Test full embedding generation with progress bar
3. Test full search flow with incremental results

---


## Story 14.5: Empty States with Helpful Messaging

**Status:** Not Started  
**Dependencies:** All UI views (library, search, collections, notes)  
**Epic:** Epic 14 - Accessibility & Polish

**Acceptance Criteria:**
1. Empty states shown for: no videos in library, no search results, empty collection, no notes
2. Each empty state includes: icon (relevant to context), message explaining why empty, action button (e.g., "Import Videos")
3. Example empty states:
   - Library: "No videos yet. Import local files or sign in with YouTube to get started." + "Import Files" button
   - Search: "No results found for 'query'. Try different keywords or remove filters."
   - Collection: "This collection is empty. Drag videos here to add them."
4. Empty states match app theme (light/dark mode)
5. Empty states not shown during loading (show spinner instead)
6. UI test verifies empty states appear correctly

---

### Implementation Phases

**Phase 1: Library Empty State (AC: 1, 2, 3)**

- [ ] **Task 14.5.1:** Create empty state view for library
  - [ ] Subtask: Create `EmptyLibraryView.swift` in `MyToob/Views/EmptyStates/`
  - [ ] Subtask: Icon: SF Symbol `video.slash` or `tray` (empty tray)
  - [ ] Subtask: Message: "No videos yet. Import local files or sign in with YouTube to get started."

- [ ] **Task 14.5.2:** Add action buttons
  - [ ] Subtask: Button 1: "Import Files" → opens file picker (Story 4.5)
  - [ ] Subtask: Button 2: "Sign In with YouTube" → opens OAuth flow (Story 2.1)

- [ ] **Task 14.5.3:** Show empty state when library is empty
  - [ ] Subtask: If `videos.isEmpty && !isLoading`: show `EmptyLibraryView()`
  - [ ] Subtask: Otherwise: show video grid

**Phase 2: Search Empty State (AC: 1, 2, 3)**

- [ ] **Task 14.5.4:** Create empty state view for search
  - [ ] Subtask: Create `EmptySearchResultsView.swift`
  - [ ] Subtask: Icon: SF Symbol `magnifyingglass` with slash
  - [ ] Subtask: Message: "No results found for '{query}'. Try different keywords or remove filters."

- [ ] **Task 14.5.5:** Add helpful suggestions
  - [ ] Subtask: Suggestions:
    - "Try broader keywords"
    - "Check your spelling"
    - "Remove filters to see more results"

- [ ] **Task 14.5.6:** Show empty state when search returns no results
  - [ ] Subtask: If `searchResults.isEmpty && !isSearching`: show `EmptySearchResultsView()`

**Phase 3: Collection Empty State (AC: 1, 2, 3)**

- [ ] **Task 14.5.7:** Create empty state view for collections
  - [ ] Subtask: Create `EmptyCollectionView.swift`
  - [ ] Subtask: Icon: SF Symbol `folder.badge.plus`
  - [ ] Subtask: Message: "This collection is empty. Drag videos here to add them."

- [ ] **Task 14.5.8:** Add action button
  - [ ] Subtask: Button: "Browse Library" → navigates to library view

- [ ] **Task 14.5.9:** Show empty state for empty collections
  - [ ] Subtask: If `collection.videos.isEmpty`: show `EmptyCollectionView()`

**Phase 4: Notes Empty State (AC: 1, 2)**

- [ ] **Task 14.5.10:** Create empty state view for notes
  - [ ] Subtask: Create `EmptyNotesView.swift`
  - [ ] Subtask: Icon: SF Symbol `note.text.badge.plus`
  - [ ] Subtask: Message: "No notes yet. Start taking notes while watching videos."

- [ ] **Task 14.5.11:** Add action button
  - [ ] Subtask: Button: "Learn More" → opens help page explaining note-taking feature

- [ ] **Task 14.5.12:** Show empty state when no notes exist
  - [ ] Subtask: If `notes.isEmpty`: show `EmptyNotesView()`

**Phase 5: Reusable Empty State Component (AC: 4)**

- [ ] **Task 14.5.13:** Create generic EmptyStateView component
  - [ ] Subtask: Parameters: `icon: String`, `message: String`, `actionTitle: String?`, `action: (() -> Void)?`
  - [ ] Subtask: Example usage:
    ```swift
    EmptyStateView(
      icon: "video.slash",
      message: "No videos yet.",
      actionTitle: "Import Files",
      action: { openFilePicker() }
    )
    ```

- [ ] **Task 14.5.14:** Style empty state for light/dark mode
  - [ ] Subtask: Icon color: secondary (adapts to theme)
  - [ ] Subtask: Message color: primary text
  - [ ] Subtask: Background: transparent (inherits from parent view)

**Phase 6: Loading vs. Empty State (AC: 5)**

- [ ] **Task 14.5.15:** Show spinner during loading, not empty state
  - [ ] Subtask: Logic: `if isLoading { ProgressView() } else if items.isEmpty { EmptyStateView() } else { ContentView() }`
  - [ ] Subtask: Ensure loading state takes precedence

**Phase 7: Testing (AC: 6)**

- [ ] **Task 14.5.16:** Test all empty states
  - [ ] Subtask: Fresh app install → library empty state shown
  - [ ] Subtask: Search with no results → search empty state shown
  - [ ] Subtask: Empty collection → collection empty state shown
  - [ ] Subtask: No notes → notes empty state shown

- [ ] **Task 14.5.17:** Test empty state actions
  - [ ] Subtask: Click "Import Files" → file picker opens
  - [ ] Subtask: Click "Sign In with YouTube" → OAuth flow starts
  - [ ] Subtask: Click "Browse Library" → navigates to library

---

### Dev Notes

**File Locations:**
- `MyToob/Views/EmptyStates/EmptyStateView.swift` - Generic empty state component
- `MyToob/Views/EmptyStates/EmptyLibraryView.swift` - Library-specific empty state
- `MyToob/Views/EmptyStates/EmptySearchResultsView.swift` - Search-specific empty state
- `MyToob/Views/EmptyStates/EmptyCollectionView.swift` - Collection-specific empty state
- `MyToob/Views/EmptyStates/EmptyNotesView.swift` - Notes-specific empty state

**Key Patterns:**
- Conditional rendering: `if items.isEmpty { EmptyStateView() } else { ListView(items) }`
- Generic component: Reusable across all empty states
- Theme-aware: Adapts to light/dark mode automatically

**Empty State Design Principles:**
- **Informative:** Explain why empty
- **Actionable:** Provide next steps (action button)
- **Friendly:** Use conversational language
- **Visual:** Include relevant icon
- **Contextual:** Tailor message to specific view

---

### Testing Requirements

**Unit Tests (5 tests):**
1. Test empty library state shows when `videos.isEmpty`
2. Test empty search state shows when `searchResults.isEmpty`
3. Test empty collection state shows when `collection.videos.isEmpty`
4. Test empty notes state shows when `notes.isEmpty`
5. Test loading state takes precedence over empty state

**UI Tests (6 tests):**
1. Test empty library state visible on fresh install
2. Test empty search state visible after search with no results
3. Test empty collection state visible in empty collection
4. Test empty notes state visible when no notes exist
5. Test "Import Files" button opens file picker
6. Test "Sign In with YouTube" button starts OAuth flow

**Integration Tests (2 tests):**
1. Test empty state → import video → empty state disappears
2. Test empty state → create collection → empty state disappears

---


## Story 14.6: Smooth Animations & Transitions

**Status:** Not Started  
**Dependencies:** All UI views  
**Epic:** Epic 14 - Accessibility & Polish

**Acceptance Criteria:**
1. View transitions animated: fade or slide when switching between library/search/collections
2. Hover effects on interactive elements: thumbnails scale slightly on hover, buttons lighten on hover
3. List/grid insertions animated: new videos fade in when added
4. Modal dialogs animate in/out (scale + fade)
5. Reduced motion respected: if macOS "Reduce Motion" enabled, use simple fades instead of complex animations
6. Animations fast enough to feel responsive (100-300ms duration, not too slow)
7. No janky animations: maintain 60 FPS during transitions (tested with Instruments)

---

### Implementation Phases

**Phase 1: View Transitions (AC: 1)**

- [ ] **Task 14.6.1:** Add fade transition to view changes
  - [ ] Subtask: Use `.transition(.opacity)` on views
  - [ ] Subtask: Example: Switching from library to search view fades out/in
  - [ ] Subtask: Duration: 200ms

- [ ] **Task 14.6.2:** Add slide transition to sidebar navigation
  - [ ] Subtask: When selecting sidebar item, content slides in from right
  - [ ] Subtask: Use `.transition(.slide)` with direction
  - [ ] Subtask: Duration: 250ms

**Phase 2: Hover Effects (AC: 2)**

- [ ] **Task 14.6.3:** Add hover scale effect to video thumbnails
  - [ ] Subtask: On hover: scale thumbnail to 1.05x
  - [ ] Subtask: Use `.scaleEffect(isHovered ? 1.05 : 1.0)` with animation
  - [ ] Subtask: Smooth animation: `.animation(.easeInOut(duration: 0.2), value: isHovered)`

- [ ] **Task 14.6.4:** Add hover effect to buttons
  - [ ] Subtask: On hover: lighten background color
  - [ ] Subtask: Example: Blue button → lighter blue on hover
  - [ ] Subtask: Use `.buttonStyle()` with custom hover styling

**Phase 3: List/Grid Animations (AC: 3)**

- [ ] **Task 14.6.5:** Animate new videos appearing in grid
  - [ ] Subtask: When video added: fade in + slide up animation
  - [ ] Subtask: Use `.transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))`
  - [ ] Subtask: Duration: 300ms

- [ ] **Task 14.6.6:** Animate video removal from grid
  - [ ] Subtask: When video deleted: fade out + scale down
  - [ ] Subtask: Duration: 200ms

**Phase 4: Modal Animations (AC: 4)**

- [ ] **Task 14.6.7:** Animate modal dialogs
  - [ ] Subtask: Dialog appears: scale from 0.9 to 1.0 + fade in
  - [ ] Subtask: Dialog dismisses: scale to 0.9 + fade out
  - [ ] Subtask: Duration: 250ms
  - [ ] Subtask: Use `.transition(.scale.combined(with: .opacity))`

**Phase 5: Reduced Motion Support (AC: 5)**

- [ ] **Task 14.6.8:** Detect Reduce Motion preference
  - [ ] Subtask: Use `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`
  - [ ] Subtask: Create environment value: `@Environment(\.accessibilityReduceMotion) var reduceMotion`

- [ ] **Task 14.6.9:** Simplify animations when Reduce Motion enabled
  - [ ] Subtask: If `reduceMotion == true`: use only fade transitions (no scale, slide, etc.)
  - [ ] Subtask: Example: `if reduceMotion { .transition(.opacity) } else { .transition(.scale.combined(with: .opacity)) }`

**Phase 6: Animation Duration (AC: 6)**

- [ ] **Task 14.6.10:** Set consistent animation durations
  - [ ] Subtask: Fast animations: 100-150ms (hover effects, focus changes)
  - [ ] Subtask: Medium animations: 200-250ms (view transitions, modal dialogs)
  - [ ] Subtask: Slow animations: 300ms (list insertions/removals)

- [ ] **Task 14.6.11:** Test animation responsiveness
  - [ ] Subtask: Trigger animations, verify they feel fast (not sluggish)
  - [ ] Subtask: If too slow: reduce duration
  - [ ] Subtask: If too fast: increase duration slightly

**Phase 7: Performance Testing (AC: 7)**

- [ ] **Task 14.6.12:** Test with Instruments (Time Profiler)
  - [ ] Subtask: Open app in Xcode, run with Instruments
  - [ ] Subtask: Trigger animations: view transitions, modal dialogs, list insertions
  - [ ] Subtask: Monitor FPS: should stay at 60 FPS

- [ ] **Task 14.6.13:** Optimize janky animations
  - [ ] Subtask: If FPS drops below 60: identify bottleneck
  - [ ] Subtask: Common fixes:
    - Reduce complexity (fewer animated elements)
    - Use GPU-accelerated animations (`.drawingGroup()`)
    - Defer heavy operations until after animation completes

- [ ] **Task 14.6.14:** Test on lower-end hardware
  - [ ] Subtask: Test on older Mac (e.g., 2015 MacBook)
  - [ ] Subtask: Verify animations still smooth (may need to adjust durations or simplify)

---

### Dev Notes

**File Locations:**
- `MyToob/Views/**/*.swift` - Add animations to all views
- `MyToob/Extensions/View+Animations.swift` - Custom animation modifiers

**Key Patterns:**
- Transition: `.transition(.opacity)` for fade, `.transition(.scale)` for scale
- Animation: `.animation(.easeInOut(duration: 0.2), value: state)`
- Hover effect: `.onHover { isHovered = $0 }`

**SwiftUI Animation Types:**
- `.easeInOut` - Smooth acceleration and deceleration (most common)
- `.easeIn` - Slow start, fast end
- `.easeOut` - Fast start, slow end
- `.linear` - Constant speed (avoid for UI animations)
- `.spring()` - Bouncy, natural motion

**Animation Duration Guidelines:**
- 100ms: Instant feedback (hover, focus)
- 200ms: Quick transitions (view changes)
- 300ms: Noticeable but not slow (insertions/removals)
- 500ms+: Too slow for most UI interactions

**Reduced Motion Support:**
- Respect user preference: `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`
- Simplified animations: fade only (no scale, slide, rotate)
- Essential for users with vestibular disorders (motion sensitivity)

---

### Testing Requirements

**Manual Tests (12 tests):**
1. Test view transition: library → search (fade animation)
2. Test sidebar navigation: slide animation
3. Test video thumbnail hover: scale effect
4. Test button hover: color change
5. Test new video added: fade in animation
6. Test video deleted: fade out animation
7. Test modal dialog appears: scale + fade animation
8. Test modal dialog dismisses: scale + fade animation
9. Enable "Reduce Motion" → verify only fade transitions used
10. Test animation duration: feels responsive (not too slow)
11. Test with Instruments: maintain 60 FPS during animations
12. Test on older Mac: animations still smooth

**Performance Tests (3 tests):**
1. Profile with Instruments: monitor FPS during animations
2. Test animation performance with 100 videos in grid
3. Test animation performance on 2015 MacBook (or older)

**Accessibility Tests (2 tests):**
1. Test Reduce Motion preference: animations simplified
2. Test without animations: app still fully functional

---


---

# Epic 15: Monetization & App Store Release

## Story 15.1: StoreKit 2 Configuration

**Status:** Not Started  
**Dependencies:** None (standalone configuration)  
**Epic:** Epic 15 - Monetization & App Store Release

**Acceptance Criteria:**
1. App Store Connect: in-app purchase created (non-consumable, product ID: `com.mytoob.pro`)
2. StoreKit configuration file created for local testing (`.storekit`)
3. Purchase flow tested in Xcode with StoreKit testing environment (no real money)
4. Pro tier price set: $9.99 USD (adjust for other regions)
5. Product description written: "Unlock advanced AI organization, vector search, research tools, Spotlight integration, and more."
6. Purchase UI shown to free users: "Upgrade to Pro" button in toolbar or feature-gated screens
7. Receipt validation implemented: verify purchase on app launch, cache result

---

### Implementation Phases

**Phase 1: App Store Connect Setup (AC: 1, 4, 5)**

- [ ] **Task 15.1.1:** Create in-app purchase in App Store Connect
  - [ ] Subtask: Log into App Store Connect, navigate to app
  - [ ] Subtask: Go to "Features" → "In-App Purchases" → "Create"
  - [ ] Subtask: Type: "Non-Consumable" (one-time purchase)
  - [ ] Subtask: Product ID: `com.mytoob.pro`

- [ ] **Task 15.1.2:** Set pricing
  - [ ] Subtask: Base price: $9.99 USD (Tier 10 in App Store pricing)
  - [ ] Subtask: Auto-generate prices for other regions (or manually adjust)
  - [ ] Subtask: Example: EUR €10.99, GBP £9.99, JPY ¥1,200

- [ ] **Task 15.1.3:** Write product description
  - [ ] Subtask: Display name: "MyToob Pro"
  - [ ] Subtask: Description: "Unlock advanced AI organization, vector search, research tools, Spotlight integration, and more."
  - [ ] Subtask: Add bullet points (if supported):
    - AI-powered video clustering
    - Semantic search with embeddings
    - Advanced note-taking with templates
    - Spotlight integration
    - App Intents for Shortcuts

**Phase 2: StoreKit Configuration File (AC: 2)**

- [ ] **Task 15.1.4:** Create StoreKit configuration file
  - [ ] Subtask: In Xcode, File → New → StoreKit Configuration File
  - [ ] Subtask: Filename: `MyToob.storekit`
  - [ ] Subtask: Add in-app purchase: Product ID `com.mytoob.pro`, Type: Non-Consumable

- [ ] **Task 15.1.5:** Configure product details
  - [ ] Subtask: Set display name: "MyToob Pro"
  - [ ] Subtask: Set price: $9.99
  - [ ] Subtask: Set description (same as App Store Connect)

- [ ] **Task 15.1.6:** Enable StoreKit testing in Xcode
  - [ ] Subtask: Edit scheme → Run → Options → StoreKit Configuration: Select `MyToob.storekit`

**Phase 3: Purchase Flow Implementation (AC: 3, 6, 7)**

- [ ] **Task 15.1.7:** Implement StoreKit 2 purchase logic
  - [ ] Subtask: Create `StoreManager.swift` in `MyToob/Services/`
  - [ ] Subtask: Import `StoreKit`
  - [ ] Subtask: Query available products: `let products = try await Product.products(for: ["com.mytoob.pro"])`
  - [ ] Subtask: Function: `purchaseProTier() async throws -> Transaction?`

- [ ] **Task 15.1.8:** Implement purchase method
  - [ ] Subtask: Fetch product: `let product = products.first(where: { $0.id == "com.mytoob.pro" })`
  - [ ] Subtask: Initiate purchase: `let result = try await product.purchase()`
  - [ ] Subtask: Handle result: `switch result { case .success(let verification): ... }`

- [ ] **Task 15.1.9:** Verify transaction
  - [ ] Subtask: Check verification result: `switch verification { case .verified(let transaction): ... }`
  - [ ] Subtask: Finish transaction: `await transaction.finish()`
  - [ ] Subtask: Unlock Pro features: `UserProStatus.shared.isPro = true`

- [ ] **Task 15.1.10:** Implement receipt validation on launch
  - [ ] Subtask: On app launch, check for existing purchase: `for await result in Transaction.currentEntitlements { ... }`
  - [ ] Subtask: If Pro transaction found: unlock features
  - [ ] Subtask: Cache result: `@AppStorage("isPro") var isPro = false`

**Phase 4: Purchase UI (AC: 6)**

- [ ] **Task 15.1.11:** Add "Upgrade to Pro" button in toolbar
  - [ ] Subtask: In main window toolbar, add button: "Upgrade to Pro"
  - [ ] Subtask: SF Symbol: `star.circle.fill`
  - [ ] Subtask: Only shown to free users: `if !UserProStatus.shared.isPro { ... }`

- [ ] **Task 15.1.12:** Show purchase sheet on button click
  - [ ] Subtask: Create `ProUpgradeView.swift` in `MyToob/Views/Pro/`
  - [ ] Subtask: Show as sheet: `.sheet(isPresented: $showUpgrade) { ProUpgradeView() }`

- [ ] **Task 15.1.13:** Design upgrade sheet
  - [ ] Subtask: Title: "Upgrade to MyToob Pro"
  - [ ] Subtask: Feature list: AI clustering, semantic search, notes, Spotlight, etc.
  - [ ] Subtask: Price: "$9.99 (one-time purchase)"
  - [ ] Subtask: Button: "Unlock Pro for $9.99"
  - [ ] Subtask: Dismiss button: "Maybe Later"

**Phase 5: Testing (AC: 3)**

- [ ] **Task 15.1.14:** Test purchase in StoreKit testing environment
  - [ ] Subtask: Run app in Xcode with StoreKit configuration enabled
  - [ ] Subtask: Click "Upgrade to Pro", verify product shown
  - [ ] Subtask: Click "Unlock Pro", simulate purchase (no real money)
  - [ ] Subtask: Verify transaction succeeds, Pro features unlocked

- [ ] **Task 15.1.15:** Test receipt validation
  - [ ] Subtask: Purchase Pro in test environment
  - [ ] Subtask: Quit and relaunch app
  - [ ] Subtask: Verify Pro status persists (receipt validated on launch)

- [ ] **Task 15.1.16:** Test failure scenarios
  - [ ] Subtask: Cancel purchase → verify no features unlocked
  - [ ] Subtask: Simulate network error → show error message "Purchase failed. Please try again."

---

### Dev Notes

**File Locations:**
- `MyToob/Services/StoreManager.swift` - StoreKit 2 purchase logic
- `MyToob/Views/Pro/ProUpgradeView.swift` - Upgrade sheet UI
- `MyToob/Models/UserProStatus.swift` - Pro status observable object
- `MyToob.storekit` - StoreKit configuration file for testing

**Key Patterns:**
- Query products: `Product.products(for: ["com.mytoob.pro"])`
- Purchase: `try await product.purchase()`
- Validate receipt: `for await result in Transaction.currentEntitlements { ... }`

**StoreKit 2 Best Practices:**
- Always verify transactions: `switch verification { case .verified: ... }`
- Finish transactions: `await transaction.finish()`
- Handle all result cases: `.success`, `.userCancelled`, `.pending`

**Testing:**
- Use StoreKit configuration file for local testing (no App Store Connect needed)
- Test on device: Use sandbox test accounts (create in App Store Connect)
- Never test with real Apple ID in development builds

---

### Testing Requirements

**Unit Tests (8 tests):**
1. Test `purchaseProTier()` returns transaction on success
2. Test `purchaseProTier()` throws error on failure
3. Test receipt validation finds existing purchase
4. Test receipt validation returns nil when no purchase
5. Test Pro status cached in UserDefaults
6. Test Pro status unlocks features
7. Test transaction verification (verified vs. unverified)
8. Test transaction finishing

**UI Tests (5 tests):**
1. Test "Upgrade to Pro" button visible to free users
2. Test upgrade sheet appears on button click
3. Test purchase flow: click "Unlock Pro" → purchase succeeds → features unlocked
4. Test "Maybe Later" dismisses sheet
5. Test Pro button hidden after purchase

**Integration Tests (3 tests):**
1. Test full purchase flow in StoreKit testing environment
2. Test receipt validation on app restart
3. Test purchase restore (Story 15.3)

---


## Story 15.2: Paywall & Feature Gating

**Status:** Not Started  
**Dependencies:** Story 15.1 (StoreKit 2 configuration)  
**Epic:** Epic 15 - Monetization & App Store Release

**Acceptance Criteria:**
1. Feature comparison sheet shown when clicking "Upgrade to Pro": Free vs. Pro columns
2. Free tier features: basic playback (YouTube + local), simple search, manual collections
3. Pro tier features: AI embeddings/clustering/search, research notes, Spotlight/App Intents, note templates, advanced filters
4. Gated features show lock icon + "Pro" badge in UI
5. Clicking gated feature shows paywall: "Unlock with Pro" + "Upgrade Now" button
6. Purchase flow: click "Upgrade Now" → StoreKit 2 sheet → authenticate with Apple ID → purchase confirmed → features unlocked
7. No dark patterns: clear value proposition, easy to dismiss paywall, "Restore Purchase" option prominently displayed

---

### Implementation Phases

**Phase 1: Feature Comparison Sheet (AC: 1, 2, 3)**

- [ ] **Task 15.2.1:** Create feature comparison view
  - [ ] Subtask: Create `FeatureComparisonView.swift` in `MyToob/Views/Pro/`
  - [ ] Subtask: Layout: Two columns (Free, Pro)
  - [ ] Subtask: Rows: Feature name, Free checkmark/X, Pro checkmark

- [ ] **Task 15.2.2:** Define Free tier features
  - [ ] Subtask: Playback: YouTube IFrame Player, Local file playback (AVKit)
  - [ ] Subtask: Search: Keyword search (basic)
  - [ ] Subtask: Collections: Manual collections (create, add videos)
  - [ ] Subtask: UI: Grid/list views, sidebar navigation

- [ ] **Task 15.2.3:** Define Pro tier features
  - [ ] Subtask: AI: Embeddings generation, Vector similarity search, Smart Collections (clustering)
  - [ ] Subtask: Notes: Note-taking with timestamps, Wiki-style links, Templates (Story 11.6)
  - [ ] Subtask: Integrations: Spotlight indexing (Story 13.1), App Intents (Story 13.2)
  - [ ] Subtask: Advanced: Hybrid search (keyword + vector), Advanced filters, Command Palette

- [ ] **Task 15.2.4:** Display comparison in upgrade sheet
  - [ ] Subtask: In `ProUpgradeView`, show comparison table
  - [ ] Subtask: Use SF Symbols: ✅ (checkmark.circle.fill) for included, ❌ (xmark.circle.fill) for not included

**Phase 2: Feature Gating UI (AC: 4)**

- [ ] **Task 15.2.5:** Add "Pro" badge to gated features
  - [ ] Subtask: In UI, next to Pro feature name: show "Pro" badge (pill-shaped, gold color)
  - [ ] Subtask: Example: "Smart Collections [Pro]"

- [ ] **Task 15.2.6:** Add lock icon to gated features
  - [ ] Subtask: SF Symbol: `lock.fill`
  - [ ] Subtask: Show next to or inside Pro feature buttons

- [ ] **Task 15.2.7:** Gray out or disable gated features for free users
  - [ ] Subtask: If `!UserProStatus.shared.isPro`: disable button, reduce opacity
  - [ ] Subtask: Show tooltip on hover: "Upgrade to Pro to unlock"

**Phase 3: Paywall on Feature Click (AC: 5)**

- [ ] **Task 15.2.8:** Show paywall when clicking gated feature
  - [ ] Subtask: If free user clicks Pro feature: show upgrade sheet
  - [ ] Subtask: Sheet title: "Unlock with Pro"
  - [ ] Subtask: Message: "This feature requires MyToob Pro. Upgrade to access advanced AI organization, research tools, and more."

- [ ] **Task 15.2.9:** Add "Upgrade Now" button
  - [ ] Subtask: Button: "Upgrade Now for $9.99"
  - [ ] Subtask: On click: trigger purchase flow (Story 15.1)

- [ ] **Task 15.2.10:** Add dismiss option
  - [ ] Subtask: Button: "Not Now" or "Maybe Later"
  - [ ] Subtask: Dismisses sheet, no purchase

**Phase 4: Purchase Flow (AC: 6)**

- [ ] **Task 15.2.11:** Integrate purchase flow
  - [ ] Subtask: On "Upgrade Now" click: call `StoreManager.shared.purchaseProTier()`
  - [ ] Subtask: Show loading indicator during purchase
  - [ ] Subtask: On success: unlock features, dismiss sheet, show success message

- [ ] **Task 15.2.12:** Handle purchase completion
  - [ ] Subtask: Success: Show alert "Welcome to MyToob Pro! All features unlocked."
  - [ ] Subtask: Dismiss paywall, update UI (hide "Pro" badges, enable features)

- [ ] **Task 15.2.13:** Handle purchase errors
  - [ ] Subtask: User cancellation: Dismiss sheet, no alert
  - [ ] Subtask: Payment error: Show alert "Purchase failed. Please try again."

**Phase 5: No Dark Patterns (AC: 7)**

- [ ] **Task 15.2.14:** Clear value proposition
  - [ ] Subtask: Upgrade sheet clearly lists all Pro features
  - [ ] Subtask: Price shown upfront: "$9.99 (one-time purchase)"
  - [ ] Subtask: No hidden fees or subscriptions

- [ ] **Task 15.2.15:** Easy to dismiss paywall
  - [ ] Subtask: "Maybe Later" button always visible
  - [ ] Subtask: Escape key dismisses sheet
  - [ ] Subtask: Click outside sheet dismisses (standard macOS behavior)

- [ ] **Task 15.2.16:** "Restore Purchase" option
  - [ ] Subtask: In upgrade sheet, show link: "Already purchased? Restore Purchase"
  - [ ] Subtask: On click: call restore flow (Story 15.3)

**Phase 6: Feature Gate All Pro Features**

- [ ] **Task 15.2.17:** Gate Smart Collections (Story 8.4)
  - [ ] Subtask: If free user: hide Smart Collections section in sidebar
  - [ ] Subtask: Or: show grayed out with "Pro" badge

- [ ] **Task 15.2.18:** Gate Note Templates (Story 11.6)
  - [ ] Subtask: If free user: "Templates" dropdown shows paywall

- [ ] **Task 15.2.19:** Gate Spotlight Indexing (Story 13.1)
  - [ ] Subtask: If free user: "Index in Spotlight" toggle disabled with "Pro" badge

- [ ] **Task 15.2.20:** Gate App Intents (Story 13.2)
  - [ ] Subtask: If free user: intents show "Requires MyToob Pro" error

---

### Dev Notes

**File Locations:**
- `MyToob/Views/Pro/FeatureComparisonView.swift` - Feature comparison table
- `MyToob/Views/Pro/ProUpgradeView.swift` - Upgrade sheet with paywall
- `MyToob/Models/UserProStatus.swift` - Pro status check: `isPro` property

**Key Patterns:**
- Feature gating: `if UserProStatus.shared.isPro { ... } else { showPaywall() }`
- Pro badge: `Text("Pro").padding(.horizontal, 6).background(Color.yellow).cornerRadius(4)`
- Lock icon: `Image(systemName: "lock.fill")`

**Free vs. Pro Feature Matrix:**
| Feature | Free | Pro |
|---------|------|-----|
| YouTube playback | ✅ | ✅ |
| Local file playback | ✅ | ✅ |
| Keyword search | ✅ | ✅ |
| Manual collections | ✅ | ✅ |
| AI embeddings | ❌ | ✅ |
| Vector search | ❌ | ✅ |
| Smart Collections | ❌ | ✅ |
| Note-taking | ✅ (basic) | ✅ |
| Note templates | ❌ | ✅ |
| Spotlight integration | ❌ | ✅ |
| App Intents | ❌ | ✅ |
| Command Palette | ❌ | ✅ |

**No Dark Patterns Checklist:**
- [ ] Clear pricing ($9.99 upfront)
- [ ] Easy to dismiss paywall
- [ ] Restore Purchase option visible
- [ ] No fake urgency ("Limited time offer!")
- [ ] No misleading claims
- [ ] No forced upgrades (app usable without Pro)

---

### Testing Requirements

**Unit Tests (6 tests):**
1. Test `isPro` check gates Pro features
2. Test paywall shown when free user clicks Pro feature
3. Test "Upgrade Now" triggers purchase flow
4. Test "Maybe Later" dismisses paywall
5. Test "Restore Purchase" triggers restore flow
6. Test Pro features unlocked after purchase

**UI Tests (8 tests):**
1. Test feature comparison table shows Free vs. Pro columns
2. Test "Pro" badges visible on gated features
3. Test lock icons visible on gated features
4. Test clicking gated feature shows paywall
5. Test "Upgrade Now" initiates purchase
6. Test "Maybe Later" dismisses paywall
7. Test "Restore Purchase" link visible
8. Test Pro features enabled after successful purchase

**Integration Tests (2 tests):**
1. Test full upgrade flow: click gated feature → paywall → purchase → features unlocked
2. Test Pro features remain unlocked after app restart

---


## Story 15.3: Restore Purchase & Subscription Management

**Status:** Not Started  
**Dependencies:** Story 15.1 (StoreKit 2 configuration)  
**Epic:** Epic 15 - Monetization & App Store Release

**Acceptance Criteria:**
1. "Restore Purchase" button in Settings > Pro tier section
2. Clicking button calls `AppStore.sync()` (StoreKit 2 receipt sync)
3. If valid purchase found, unlock Pro features immediately
4. If no purchase found, show message: "No Pro purchase found for this Apple ID"
5. "Manage Subscription" link opens App Store subscriptions page (if using subscription model)
6. Purchase status shown in Settings: "Pro (Purchased)" or "Free (Upgrade to Pro)"
7. UI test verifies restore purchase flow in StoreKit testing environment

---

### Implementation Phases

**Phase 1: Settings UI (AC: 1, 6)**

- [ ] **Task 15.3.1:** Add "Pro" section to Settings
  - [ ] Subtask: In `SettingsView.swift`, add "Pro Tier" section
  - [ ] Subtask: Show purchase status: `Text(UserProStatus.shared.isPro ? "Pro (Purchased)" : "Free")`

- [ ] **Task 15.3.2:** Add "Restore Purchase" button
  - [ ] Subtask: Button label: "Restore Purchase"
  - [ ] Subtask: Position below purchase status
  - [ ] Subtask: On click: call `restorePurchase()`

- [ ] **Task 15.3.3:** Add "Upgrade to Pro" button (for free users)
  - [ ] Subtask: If free user: show "Upgrade to Pro" button
  - [ ] Subtask: On click: show upgrade sheet (Story 15.2)

**Phase 2: Restore Purchase Implementation (AC: 2, 3, 4)**

- [ ] **Task 15.3.4:** Implement restore purchase method
  - [ ] Subtask: Function: `restorePurchase() async`
  - [ ] Subtask: Call `try await AppStore.sync()` (syncs receipts with App Store)
  - [ ] Subtask: Query current entitlements: `for await result in Transaction.currentEntitlements { ... }`

- [ ] **Task 15.3.5:** Check for Pro purchase
  - [ ] Subtask: Loop through entitlements, look for `com.mytoob.pro`
  - [ ] Subtask: If found and verified: unlock Pro
  - [ ] Subtask: If not found: show error

- [ ] **Task 15.3.6:** Unlock Pro features on restore
  - [ ] Subtask: Set `UserProStatus.shared.isPro = true`
  - [ ] Subtask: Save to UserDefaults: `@AppStorage("isPro") var isPro = true`
  - [ ] Subtask: Update UI: hide "Pro" badges, enable features

- [ ] **Task 15.3.7:** Handle no purchase found
  - [ ] Subtask: Show alert: "No Pro purchase found for this Apple ID"
  - [ ] Subtask: Message: "If you purchased Pro with a different Apple ID, sign in with that account and try again."

**Phase 3: Manage Subscription (AC: 5)**

- [ ] **Task 15.3.8:** Add "Manage Subscription" link (if subscription model)
  - [ ] Subtask: Link label: "Manage Subscription"
  - [ ] Subtask: On click: open App Store subscriptions page
  - [ ] Subtask: URL: `https://apps.apple.com/account/subscriptions`
  - [ ] Subtask: Use `NSWorkspace.shared.open(URL(string: "...")!)`

- [ ] **Task 15.3.9:** Hide "Manage Subscription" if non-consumable
  - [ ] Subtask: Since Pro is one-time purchase (non-consumable), hide this link
  - [ ] Subtask: Only show for subscription-based Pro (if implementing in future)

**Phase 4: Loading & Error States**

- [ ] **Task 15.3.10:** Show loading indicator during restore
  - [ ] Subtask: Set `@State var isRestoring = false`
  - [ ] Subtask: During restore: `isRestoring = true`, show spinner
  - [ ] Subtask: After restore: `isRestoring = false`

- [ ] **Task 15.3.11:** Handle restore errors
  - [ ] Subtask: Catch errors: `catch { ... }`
  - [ ] Subtask: Show error alert: "Restore failed. Please try again. Error: {errorMessage}"

**Phase 5: Testing (AC: 7)**

- [ ] **Task 15.3.12:** Test restore in StoreKit testing environment
  - [ ] Subtask: Purchase Pro in test environment
  - [ ] Subtask: Delete app, reinstall
  - [ ] Subtask: Open Settings, click "Restore Purchase"
  - [ ] Subtask: Verify Pro status restored

- [ ] **Task 15.3.13:** Test restore with no purchase
  - [ ] Subtask: On fresh install (no purchase), click "Restore Purchase"
  - [ ] Subtask: Verify alert: "No Pro purchase found"

- [ ] **Task 15.3.14:** Test restore on multiple devices
  - [ ] Subtask: Purchase Pro on device A
  - [ ] Subtask: Sign in with same Apple ID on device B
  - [ ] Subtask: Click "Restore Purchase" on device B
  - [ ] Subtask: Verify Pro unlocked on device B

---

### Dev Notes

**File Locations:**
- `MyToob/Views/Settings/ProSettingsView.swift` - Pro tier settings section
- `MyToob/Services/StoreManager.swift` - Restore purchase logic

**Key Patterns:**
- Sync receipts: `try await AppStore.sync()`
- Query entitlements: `for await result in Transaction.currentEntitlements { ... }`
- Unlock Pro: `UserProStatus.shared.isPro = true`

**StoreKit 2 Restore Purchase:**
- `AppStore.sync()` syncs receipts with App Store
- No user authentication required (uses current Apple ID)
- Works across devices signed in with same Apple ID

**Important Notes:**
- Restore is automatic on app launch (Story 15.1), but manual restore useful for troubleshooting
- Manual restore helpful when switching Apple IDs
- Non-consumables don't require "Manage Subscription" (one-time purchase)

---

### Testing Requirements

**Unit Tests (5 tests):**
1. Test `restorePurchase()` unlocks Pro when purchase found
2. Test `restorePurchase()` shows error when no purchase found
3. Test `restorePurchase()` handles network errors
4. Test Pro status persisted after restore
5. Test `AppStore.sync()` called during restore

**UI Tests (4 tests):**
1. Test "Restore Purchase" button visible in Settings
2. Test clicking button shows loading indicator
3. Test successful restore updates UI (Pro status shown)
4. Test failed restore shows error alert

**Integration Tests (3 tests):**
1. Test full restore flow: delete app → reinstall → restore → Pro unlocked
2. Test restore on device B after purchase on device A
3. Test restore in StoreKit testing environment

---


### Story 15.4: App Store Submission Package

**Status:** Not Started  
**Dependencies:** Stories 1.1 (SwiftData models), 12.5 (YouTube disclaimers), 14.1-14.6 (accessibility & polish), 15.1-15.3 (monetization)  
**Epic:** Epic 15 - Monetization & App Store Release

**Acceptance Criteria:**
1. App icon created in all required sizes (1024x1024 for App Store, 512x512, 256x256, etc.)
2. Screenshots created (1280x800, 2560x1600): library view, search, playback, collections, notes (5-10 screenshots)
3. App description written (concise, highlights key features, avoids "YouTube" in name)
4. Keywords selected: video, organizer, research, notes, library, macOS, AI, semantic search (under 100 characters)
5. Privacy Policy URL hosted: `https://yourwebsite.com/mytoob/privacy`
6. Support URL: `https://yourwebsite.com/mytoob/support`
7. App Store Connect listing completed: all metadata fields filled, screenshots uploaded

**Implementation Breakdown:**

**Phase 1: App Icon Design & Export (AC: 1)**

- [ ] **Task 15.4.1:** Design app icon
  - [ ] Subtask: Create icon concept (avoid YouTube branding, unique visual identity)
  - [ ] Subtask: Design in vector format (Sketch, Figma, or Illustrator)
  - [ ] Subtask: Follow macOS icon design guidelines (rounded square, depth, shadows)
  - [ ] Subtask: Test icon appearance in light and dark mode
  - [ ] Subtask: Ensure icon is recognizable at small sizes (16x16, 32x32)
  - [ ] Subtask: Get design feedback (internal team or target users)

- [ ] **Task 15.4.2:** Export all required icon sizes
  - [ ] Subtask: Export 1024x1024 PNG (App Store marketing icon)
  - [ ] Subtask: Export 512x512@1x and 512x512@2x (Mac app icon)
  - [ ] Subtask: Export 256x256@1x and 256x256@2x
  - [ ] Subtask: Export 128x128@1x and 128x128@2x
  - [ ] Subtask: Export 32x32@1x and 32x32@2x
  - [ ] Subtask: Export 16x16@1x and 16x16@2x
  - [ ] Subtask: Ensure all exports are sRGB color space

- [ ] **Task 15.4.3:** Add icons to Xcode project
  - [ ] Subtask: Open `MyToob/Assets.xcassets/AppIcon.appiconset`
  - [ ] Subtask: Drag each icon size to appropriate slot
  - [ ] Subtask: Verify `Contents.json` references all sizes correctly
  - [ ] Subtask: Build app and check icon in Finder, Dock, Spotlight

**Phase 2: Screenshot Capture & Editing (AC: 2)**

- [ ] **Task 15.4.4:** Prepare app for screenshots
  - [ ] Subtask: Populate library with diverse, high-quality sample videos
  - [ ] Subtask: Create sample collections: "Swift Tutorials", "Design Inspiration", "Research Queue"
  - [ ] Subtask: Add sample notes with rich content (markdown, links, timestamps)
  - [ ] Subtask: Enable Pro features for screenshots (show full feature set)
  - [ ] Subtask: Set window size to standard resolution (1280x800 or 2560x1600)
  - [ ] Subtask: Ensure clean UI (no debug overlays, realistic data)

- [ ] **Task 15.4.5:** Capture required screenshots
  - [ ] Subtask: Screenshot 1: Main library view with grid layout and sidebar
  - [ ] Subtask: Screenshot 2: Search interface with hybrid search results
  - [ ] Subtask: Screenshot 3: Video playback (local file in AVKit player)
  - [ ] Subtask: Screenshot 4: Collections view with drag-and-drop visualization
  - [ ] Subtask: Screenshot 5: Note editor with markdown formatting
  - [ ] Subtask: Screenshot 6 (optional): AI clusters visualization
  - [ ] Subtask: Screenshot 7 (optional): Settings/Preferences pane
  - [ ] Subtask: Screenshot 8 (optional): Spotlight integration demo

- [ ] **Task 15.4.6:** Edit and optimize screenshots
  - [ ] Subtask: Crop to remove unnecessary chrome (menu bar, dock)
  - [ ] Subtask: Add subtle drop shadows or frames (optional, per App Store best practices)
  - [ ] Subtask: Annotate key features with arrows or labels (optional)
  - [ ] Subtask: Ensure all screenshots are same aspect ratio
  - [ ] Subtask: Export in JPEG or PNG format (max 8 MB each)
  - [ ] Subtask: Compress images without visible quality loss

**Phase 3: Marketing Copy & Metadata (AC: 3, 4)**

- [ ] **Task 15.4.7:** Write app description
  - [ ] Subtask: Opening line: concise value proposition (1-2 sentences)
  - [ ] Subtask: Feature list: bullet points for key features (AI search, collections, notes, local + online)
  - [ ] Subtask: Use cases: researcher, educator, content creator personas
  - [ ] Subtask: Compliance note: "Not affiliated with YouTube. Uses official YouTube APIs."
  - [ ] Subtask: Avoid "YouTube" in app name or primary description text
  - [ ] Subtask: Length: 170-4000 characters (App Store Connect limit)
  - [ ] Subtask: Proofread for grammar, clarity, App Store guidelines compliance

- [ ] **Task 15.4.8:** Select keywords
  - [ ] Subtask: Primary keywords: video, organizer, research, notes, library
  - [ ] Subtask: Secondary keywords: macOS, AI, semantic search, collections
  - [ ] Subtask: Avoid trademarked terms ("YouTube", "Google")
  - [ ] Subtask: Comma-separated list, total under 100 characters
  - [ ] Subtask: Example: "video,organizer,research,notes,library,macOS,AI,semantic,search,collections"
  - [ ] Subtask: Test keyword relevance with App Store search previews

- [ ] **Task 15.4.9:** Write promotional text (optional)
  - [ ] Subtask: Short tagline for App Store listing (30-170 characters)
  - [ ] Subtask: Highlight latest features or time-sensitive promotions
  - [ ] Subtask: Example: "New in v1.0: AI-powered semantic search and Smart Collections"

**Phase 4: Privacy Policy & Support URLs (AC: 5, 6)**

- [ ] **Task 15.4.10:** Create Privacy Policy page
  - [ ] Subtask: Write privacy policy document (markdown or HTML)
  - [ ] Subtask: Sections: Data Collection, Data Usage, Third-Party Services (YouTube API), User Rights
  - [ ] Subtask: Include CloudKit sync explanation (opt-in, user data only)
  - [ ] Subtask: State "Data Not Collected" for analytics (if applicable)
  - [ ] Subtask: Host on static site: `https://yourwebsite.com/mytoob/privacy`
  - [ ] Subtask: Test URL accessibility (no authentication required)

- [ ] **Task 15.4.11:** Create Support page
  - [ ] Subtask: Write support page with FAQ, troubleshooting, contact info
  - [ ] Subtask: Include email: `support@yourapp.com`
  - [ ] Subtask: Link to GitHub issues (if open-source)
  - [ ] Subtask: Add "Send Diagnostics" instructions
  - [ ] Subtask: Host on static site: `https://yourwebsite.com/mytoob/support`
  - [ ] Subtask: Test URL accessibility

**Phase 5: App Store Connect Listing (AC: 7)**

- [ ] **Task 15.4.12:** Create App Store Connect listing
  - [ ] Subtask: Log in to App Store Connect (https://appstoreconnect.apple.com)
  - [ ] Subtask: Create new app: "My Apps" > "+" > "New App"
  - [ ] Subtask: Fill in basic info: Name ("MyToob"), Primary Language (English), Bundle ID
  - [ ] Subtask: Select SKU (unique identifier, e.g., "mytoob-macos-v1")

- [ ] **Task 15.4.13:** Fill all metadata fields
  - [ ] Subtask: App Name: "MyToob"
  - [ ] Subtask: Subtitle: Short tagline (30 characters max)
  - [ ] Subtask: Description: Paste app description from Task 15.4.7
  - [ ] Subtask: Keywords: Paste keyword list from Task 15.4.8
  - [ ] Subtask: Privacy Policy URL: Paste from Task 15.4.10
  - [ ] Subtask: Support URL: Paste from Task 15.4.11
  - [ ] Subtask: Marketing URL (optional): Project website or GitHub repo

- [ ] **Task 15.4.14:** Upload screenshots
  - [ ] Subtask: Go to "App Store" tab > "macOS" > "Screenshots"
  - [ ] Subtask: Upload screenshots for required display sizes
  - [ ] Subtask: Drag to reorder (first screenshot appears in search results)
  - [ ] Subtask: Add captions/descriptions for each screenshot (optional)

- [ ] **Task 15.4.15:** Configure app categorization
  - [ ] Subtask: Primary Category: "Productivity" or "Utilities"
  - [ ] Subtask: Secondary Category (optional): "Education" or "Entertainment"
  - [ ] Subtask: Age Rating: Complete questionnaire (likely 4+, depends on UGC safeguards)

- [ ] **Task 15.4.16:** Set pricing and availability
  - [ ] Subtask: Price: Free (with in-app purchase for Pro)
  - [ ] Subtask: Availability: All territories (or select specific countries)
  - [ ] Subtask: Pre-order: No (unless planning staged release)

- [ ] **Task 15.4.17:** Review and submit
  - [ ] Subtask: Preview listing in App Store Connect (check for errors)
  - [ ] Subtask: Save draft
  - [ ] Subtask: Submit for review (after app binary uploaded, see Epic A for CI/CD)

**Dev Notes:**
- **File Locations:**
  - App icon: `MyToob/Assets.xcassets/AppIcon.appiconset/`
  - Screenshots: Store in `docs/appstore/screenshots/` (not in Xcode project)
  - Marketing copy: `docs/appstore/description.txt`, `docs/appstore/keywords.txt`
  - Privacy policy: Host externally, not in repo (unless static site in repo)
- **Design Tools:** Sketch, Figma, Illustrator for icon design
- **Screenshot Tools:** macOS Screenshot (Cmd+Shift+4), or use Xcode Simulator for consistent window sizes
- **Compliance Check:** Ensure all copy avoids YouTube branding, includes disclaimers per Story 12.5

**Testing Requirements:**
- **Manual Testing:**
  - [ ] Icon appears correctly in all contexts (Finder, Dock, Spotlight, Mission Control)
  - [ ] Screenshots accurately represent app functionality
  - [ ] Privacy Policy and Support URLs load without errors
  - [ ] App Store Connect listing preview matches intended design
- **Accessibility Check:**
  - [ ] Screenshots include visible UI elements (no reliance on color alone)
  - [ ] Description text is clear and readable

---

### Story 15.5: Reviewer Documentation & Compliance Notes

**Status:** Not Started  
**Dependencies:** Stories 2.1-2.3 (YouTube IFrame Player), 4.1-4.5 (local file playback), 12.1-12.6 (UGC safeguards), 15.4 (App Store submission package)  
**Epic:** Epic 15 - Monetization & App Store Release

**Acceptance Criteria:**
1. `ReviewerNotes.md` document created in project repo
2. Document sections:
   - **Architecture Overview:** Explains IFrame Player + Data API usage (no stream access)
   - **YouTube Compliance:** How app adheres to ToS (no downloading, no ad removal, UGC safeguards)
   - **App Store Guidelines:** How app meets 1.2 (UGC moderation) and 5.2.3 (no IP violation)
   - **Demo Workflow:** Step-by-step instructions for testing key features
   - **Test Account:** Demo YouTube account credentials (if needed for review)
3. Document includes screenshots: player UI (showing YouTube ads intact), UGC reporting flow, content policy page
4. Document uploaded to App Store Connect: "App Review Information" > "Notes" field (paste or attach)
5. Contact information provided for follow-up questions
6. Document reviewed by legal (if available) for accuracy

**Implementation Breakdown:**

**Phase 1: Document Structure & Introduction (AC: 1, 2)**

- [ ] **Task 15.5.1:** Create ReviewerNotes.md file
  - [ ] Subtask: Create `docs/appstore/ReviewerNotes.md` in project repo
  - [ ] Subtask: Add title: "# MyToob - App Store Reviewer Notes"
  - [ ] Subtask: Add introduction paragraph: purpose of document, key compliance areas
  - [ ] Subtask: Table of contents with links to each section
  - [ ] Subtask: Include version number and submission date

**Phase 2: Architecture Overview Section (AC: 2 - Architecture)**

- [ ] **Task 15.5.2:** Write Architecture Overview
  - [ ] Subtask: Section title: "## 1. Architecture Overview"
  - [ ] Subtask: Explain high-level app architecture: SwiftUI + SwiftData + Core ML
  - [ ] Subtask: YouTube playback architecture:
    - "YouTube videos played via official IFrame Player API embedded in WKWebView"
    - "No direct access to video streams (`googlevideo.com`)"
    - "JavaScript bridge for play/pause/seek controls only"
  - [ ] Subtask: Local file playback architecture:
    - "Local video files played via AVKit (AVPlayerView)"
    - "Full computer vision/ASR allowed for local files (not YouTube content)"
  - [ ] Subtask: Data API usage:
    - "YouTube Data API v3 used for metadata only (title, description, thumbnails)"
    - "No stream downloading or caching"
  - [ ] Subtask: Include architecture diagram (optional, visual aid)

**Phase 3: YouTube Compliance Section (AC: 2 - YouTube Compliance)**

- [ ] **Task 15.5.3:** Write YouTube Compliance section
  - [ ] Subtask: Section title: "## 2. YouTube Compliance"
  - [ ] Subtask: Subsection: "### 2.1 YouTube Terms of Service Adherence"
  - [ ] Subtask: Point 1: "No stream downloading: App uses IFrame Player API only, no `googlevideo.com` access"
  - [ ] Subtask: Point 2: "No ad removal: YouTube ads display unmodified, no DOM manipulation"
  - [ ] Subtask: Point 3: "Pause when hidden: Playback pauses when window backgrounded (except native PiP)"
  - [ ] Subtask: Point 4: "Branding compliance: 'Not affiliated with YouTube' disclaimer, no YouTube trademark in app name/icon"

- [ ] **Task 15.5.4:** Write UGC safeguards subsection
  - [ ] Subtask: Subsection: "### 2.2 User-Generated Content Safeguards"
  - [ ] Subtask: Point 1: "Report Content: Deep-links to YouTube's reporting UI (`https://www.youtube.com/watch?v={videoID}&report=1`)"
  - [ ] Subtask: Point 2: "Hide Channel: Users can blacklist channels to hide all content"
  - [ ] Subtask: Point 3: "Content Policy: In-app link to content policy page (Settings > About)"
  - [ ] Subtask: Point 4: "Support Contact: Email and support page accessible from Settings"
  - [ ] Subtask: Reference: "See Section 4 for demo workflow"

**Phase 4: App Store Guidelines Section (AC: 2 - App Store Guidelines)**

- [ ] **Task 15.5.5:** Write App Store Guidelines compliance section
  - [ ] Subtask: Section title: "## 3. App Store Guidelines Compliance"
  - [ ] Subtask: Subsection: "### 3.1 Guideline 1.2 (User-Generated Content)"
  - [ ] Subtask: Explain UGC moderation features:
    - "Report Content action (deep-link to YouTube)"
    - "Channel blacklist feature"
    - "Content policy page with clear standards"
    - "Support contact for policy questions"
  - [ ] Subtask: Reference screenshots: "See attached screenshots showing report flow and content policy page"

- [ ] **Task 15.5.6:** Write IP violation compliance subsection
  - [ ] Subtask: Subsection: "### 3.2 Guideline 5.2.3 (Intellectual Property)"
  - [ ] Subtask: Explain no IP violation:
    - "YouTube content accessed via official IFrame Player API (licensed by YouTube)"
    - "No stream downloading or unauthorized reproduction"
    - "Local files: user-selected content (user responsible for IP compliance)"
  - [ ] Subtask: Branding note: "App name 'MyToob' does not use 'YouTube' trademark"

**Phase 5: Demo Workflow Section (AC: 2 - Demo Workflow)**

- [ ] **Task 15.5.7:** Write step-by-step demo workflow
  - [ ] Subtask: Section title: "## 4. Demo Workflow"
  - [ ] Subtask: Introduction: "Follow these steps to test key features during App Store review:"

- [ ] **Task 15.5.8:** Add workflow steps
  - [ ] Subtask: Step 1: Launch app
    - "Open MyToob from Applications folder"
    - "Grant necessary permissions (network, file access if prompted)"
  - [ ] Subtask: Step 2: Import local file
    - "File > Import Local Videos"
    - "Select sample video file (provided in test account, or use any MP4)"
    - "Verify video appears in library with thumbnail"
  - [ ] Subtask: Step 3: Sign in with YouTube (optional)
    - "Settings > YouTube Account > Sign In"
    - "Use test account credentials (see Section 5)"
    - "Authorize app with minimal scopes (youtube.readonly)"
  - [ ] Subtask: Step 4: Play YouTube video
    - "Search for any video or browse library"
    - "Click video to open detail view"
    - "Click Play button"
    - "Verify IFrame Player loads with YouTube branding intact"
    - "Verify ads display if present (do not skip or block)"
  - [ ] Subtask: Step 5: Test UGC safeguards
    - "Right-click on any YouTube video"
    - "Select 'Report Content' from context menu"
    - "Verify dialog explains action, opens YouTube reporting page in browser"
    - "Back in app: right-click video again, select 'Hide Channel'"
    - "Verify channel added to blacklist (Settings > Hidden Channels)"
  - [ ] Subtask: Step 6: Test search
    - "Enter search query in search bar (e.g., 'swift tutorials')"
    - "Verify results include both keyword and semantic matches"
  - [ ] Subtask: Step 7: Test collections
    - "Create new collection: Collections sidebar > '+' button"
    - "Drag video to collection"
    - "Verify video appears in collection"
  - [ ] Subtask: Step 8: Test note-taking
    - "Open video detail view"
    - "Click 'New Note' button"
    - "Type note with timestamp anchor: `[15:30] Important concept`"
    - "Verify timestamp link jumps to correct playback position"

**Phase 6: Test Account & Contact Info (AC: 2 - Test Account, AC: 5)**

- [ ] **Task 15.5.9:** Add test account section
  - [ ] Subtask: Section title: "## 5. Test Account (Optional)"
  - [ ] Subtask: If YouTube sign-in required for review:
    - "Email: testaccount@yourapp.com"
    - "Password: [secure password, do not commit to public repo]"
    - "Note: This account has minimal subscriptions and watch history for demo purposes"
  - [ ] Subtask: If YouTube sign-in optional:
    - "YouTube sign-in is optional. App fully functional with local files only."
    - "Reviewers may use their own YouTube accounts if preferred."

- [ ] **Task 15.5.10:** Add contact information
  - [ ] Subtask: Section title: "## 6. Contact Information"
  - [ ] Subtask: Developer contact: "Name: [Your Name or Company Name]"
  - [ ] Subtask: Email: "support@yourapp.com"
  - [ ] Subtask: Phone (optional, for urgent review questions): "[Phone number]"
  - [ ] Subtask: Response time: "We aim to respond within 24 hours during review process"

**Phase 7: Add Screenshots (AC: 3)**

- [ ] **Task 15.5.11:** Capture compliance screenshots
  - [ ] Subtask: Screenshot 1: YouTube player UI with ads intact (if ad present)
  - [ ] Subtask: Screenshot 2: Report Content dialog and YouTube reporting page
  - [ ] Subtask: Screenshot 3: Content Policy page (Settings > About > Content Policy)
  - [ ] Subtask: Screenshot 4: Support contact info (Settings > About > Support)
  - [ ] Subtask: Screenshot 5: Channel blacklist view (Settings > Hidden Channels)

- [ ] **Task 15.5.12:** Embed screenshots in document
  - [ ] Subtask: Add section: "## 7. Screenshots"
  - [ ] Subtask: Embed images in markdown: `![Player UI](screenshots/player-ui.png)`
  - [ ] Subtask: Add captions explaining each screenshot
  - [ ] Subtask: Store screenshots in `docs/appstore/screenshots/compliance/`

**Phase 8: Legal Review & Finalization (AC: 6)**

- [ ] **Task 15.5.13:** Legal review (if available)
  - [ ] Subtask: Share document with legal team or advisor
  - [ ] Subtask: Request review for accuracy, compliance claims, liability
  - [ ] Subtask: Incorporate feedback and revisions
  - [ ] Subtask: Get sign-off from legal (if required)

- [ ] **Task 15.5.14:** Finalize document
  - [ ] Subtask: Proofread for clarity, grammar, completeness
  - [ ] Subtask: Verify all sections from AC 2 are present
  - [ ] Subtask: Verify all screenshots are embedded and visible
  - [ ] Subtask: Export to PDF (for upload to App Store Connect)
  - [ ] Subtask: Commit to repo: `git add docs/appstore/ReviewerNotes.md && git commit -m "Add reviewer documentation"`

**Phase 9: Upload to App Store Connect (AC: 4)**

- [ ] **Task 15.5.15:** Upload reviewer notes
  - [ ] Subtask: Log in to App Store Connect
  - [ ] Subtask: Navigate to app listing > "App Review Information"
  - [ ] Subtask: Scroll to "Notes" field
  - [ ] Subtask: Copy-paste full ReviewerNotes.md content (if short enough)
  - [ ] Subtask: OR: Upload PDF as attachment (if Notes field has file upload option)
  - [ ] Subtask: OR: Link to hosted document: "Full reviewer notes: https://yourwebsite.com/mytoob/reviewer-notes.pdf"
  - [ ] Subtask: Save changes

**Dev Notes:**
- **File Locations:**
  - Main document: `docs/appstore/ReviewerNotes.md`
  - Screenshots: `docs/appstore/screenshots/compliance/`
  - PDF export: `docs/appstore/ReviewerNotes.pdf`
- **Key Compliance Points to Emphasize:**
  - IFrame Player API usage (no stream access)
  - YouTube ads unmodified
  - UGC reporting and moderation features
  - Clear YouTube ToS adherence
- **Legal Review:** If no legal team available, consider consulting App Store review guidelines experts or communities (e.g., forums, Reddit r/iOSProgramming)

**Testing Requirements:**
- **Manual Review:**
  - [ ] Follow demo workflow from Section 4 to ensure accuracy
  - [ ] Verify all screenshots are current and match latest UI
  - [ ] Test all links in document (if any external references)
  - [ ] Ensure test account credentials work (if provided)
- **Compliance Check:**
  - [ ] Cross-reference with YouTube ToS and App Store Guidelines
  - [ ] Verify all claims in document are accurate and implemented

---

### Story 15.6: Notarized DMG Build for Alternate Distribution

**Status:** Not Started  
**Dependencies:** Stories 1.1 (SwiftData models), 4.6 (local file CV/ASR), Epic A (CI/CD), 15.4 (App Store submission package)  
**Epic:** Epic 15 - Monetization & App Store Release

**Acceptance Criteria:**
1. "DMG Build" configuration created in Xcode (separate from App Store build)
2. DMG build enables power-user features: deeper CV/ASR for local files (disabled in App Store build)
3. App codesigned with Developer ID certificate (not App Store certificate)
4. DMG notarized via `xcrun notarytool` (submits to Apple for malware scan)
5. Notarization ticket stapled to app bundle: `xcrun stapler staple MyToob.app`
6. DMG created with app + README: drag-to-Applications instructions
7. DMG hosted on project website: `https://yourwebsite.com/mytoob/download`
8. DMG build versioned separately (e.g., 1.0.1-dmg to distinguish from App Store 1.0.1)

**Implementation Breakdown:**

**Phase 1: Create DMG Build Configuration (AC: 1, 2)**

- [ ] **Task 15.6.1:** Duplicate App Store build configuration
  - [ ] Subtask: Open Xcode project
  - [ ] Subtask: Select project in navigator > "Info" tab
  - [ ] Subtask: Under "Configurations", duplicate "Release" configuration
  - [ ] Subtask: Rename duplicate to "DMG Release"

- [ ] **Task 15.6.2:** Configure DMG-specific build settings
  - [ ] Subtask: Select "MyToob" target > "Build Settings"
  - [ ] Subtask: Filter by "DMG Release" configuration
  - [ ] Subtask: Set code signing identity: "Developer ID Application: [Your Name or Company]"
  - [ ] Subtask: Set provisioning profile: "None" (Developer ID doesn't use profiles)
  - [ ] Subtask: Set `PRODUCT_BUNDLE_IDENTIFIER` to `com.yourcompany.MyToob.dmg` (different from App Store ID)
  - [ ] Subtask: Add custom build flag: `DMG_BUILD = 1` (for conditional compilation)

- [ ] **Task 15.6.3:** Enable power-user features with build flag
  - [ ] Subtask: Open `MyToob/AI/LocalFileProcessor.swift` (or similar file)
  - [ ] Subtask: Add conditional compilation:
    ```swift
    #if DMG_BUILD
    func processLocalFile(url: URL) {
        // Full CV/ASR pipeline enabled
        runDeepComputerVision(url)
        runAutomaticSpeechRecognition(url)
    }
    #else
    func processLocalFile(url: URL) {
        // Limited processing for App Store compliance
        runBasicMetadataExtraction(url)
    }
    #endif
    ```
  - [ ] Subtask: Add similar guards for any App Store-restricted features
  - [ ] Subtask: Document power-user features in `README-DMG.md`

**Phase 2: Codesigning with Developer ID Certificate (AC: 3)**

- [ ] **Task 15.6.4:** Obtain Developer ID certificate
  - [ ] Subtask: Log in to Apple Developer account (https://developer.apple.com)
  - [ ] Subtask: Navigate to "Certificates, Identifiers & Profiles"
  - [ ] Subtask: Create new certificate: "Developer ID Application"
  - [ ] Subtask: Download certificate and install in Keychain Access
  - [ ] Subtask: Verify certificate appears in Xcode: Xcode > Preferences > Accounts > [Your Team] > Manage Certificates

- [ ] **Task 15.6.5:** Build app with DMG Release configuration
  - [ ] Subtask: Select "DMG Release" scheme in Xcode (or create new scheme)
  - [ ] Subtask: Product > Archive
  - [ ] Subtask: Wait for build to complete
  - [ ] Subtask: Organizer window opens with archive

- [ ] **Task 15.6.6:** Export app bundle for notarization
  - [ ] Subtask: In Organizer, select archive
  - [ ] Subtask: Click "Distribute App"
  - [ ] Subtask: Select "Developer ID" distribution method
  - [ ] Subtask: Select "Export" (do not upload to App Store)
  - [ ] Subtask: Choose destination folder (e.g., `~/Desktop/MyToobDMG/`)
  - [ ] Subtask: Xcode codesigns app with Developer ID certificate
  - [ ] Subtask: Verify app bundle exported: `~/Desktop/MyToobDMG/MyToob.app`

**Phase 3: Notarize App via xcrun notarytool (AC: 4)**

- [ ] **Task 15.6.7:** Prepare for notarization
  - [ ] Subtask: Compress app bundle into ZIP:
    ```bash
    cd ~/Desktop/MyToobDMG/
    /usr/bin/ditto -c -k --keepParent MyToob.app MyToob.zip
    ```
  - [ ] Subtask: Verify ZIP created: `ls -lh MyToob.zip`

- [ ] **Task 15.6.8:** Submit for notarization
  - [ ] Subtask: Run notarytool command:
    ```bash
    xcrun notarytool submit MyToob.zip \
      --apple-id "your-email@example.com" \
      --team-id "YOUR_TEAM_ID" \
      --password "app-specific-password" \
      --wait
    ```
  - [ ] Subtask: Wait for notarization to complete (can take 1-30 minutes)
  - [ ] Subtask: Notarytool outputs status: "Accepted" or "Invalid"

- [ ] **Task 15.6.9:** Handle notarization result
  - [ ] Subtask: If "Accepted": proceed to Task 15.6.10
  - [ ] Subtask: If "Invalid": check notarization log:
    ```bash
    xcrun notarytool log <submission-id> \
      --apple-id "your-email@example.com" \
      --team-id "YOUR_TEAM_ID" \
      --password "app-specific-password"
    ```
  - [ ] Subtask: Fix issues (common: unsigned frameworks, invalid entitlements)
  - [ ] Subtask: Re-sign and resubmit

**Phase 4: Staple Notarization Ticket (AC: 5)**

- [ ] **Task 15.6.10:** Staple ticket to app bundle
  - [ ] Subtask: Run stapler command:
    ```bash
    xcrun stapler staple ~/Desktop/MyToobDMG/MyToob.app
    ```
  - [ ] Subtask: Verify stapling succeeded: "The staple and validate action worked!"
  - [ ] Subtask: Test stapled app: open on Mac without internet connection (should launch without Gatekeeper warning)

**Phase 5: Create DMG Package (AC: 6)**

- [ ] **Task 15.6.11:** Write DMG README
  - [ ] Subtask: Create `README-DMG.txt` or `README-DMG.md`
  - [ ] Subtask: Content:
    - "# MyToob - Direct Download Edition"
    - "This version includes power-user features not available in the App Store version."
    - "Installation: Drag MyToob.app to your Applications folder."
    - "Power-User Features: Full computer vision and speech recognition for local files."
    - "System Requirements: macOS 13.0 or later, Apple Silicon or Intel Mac."
  - [ ] Subtask: Include license info, support contact, website link

- [ ] **Task 15.6.12:** Create DMG image
  - [ ] Subtask: Use `hdiutil` or third-party tool (DMG Canvas, create-dmg script)
  - [ ] Subtask: Example with hdiutil:
    ```bash
    hdiutil create -volname "MyToob" -srcfolder ~/Desktop/MyToobDMG/ -ov -format UDZO ~/Desktop/MyToob-1.0.1-dmg.dmg
    ```
  - [ ] Subtask: OR: Use create-dmg script for custom background, icon layout:
    ```bash
    create-dmg \
      --volname "MyToob" \
      --window-pos 200 120 \
      --window-size 600 400 \
      --icon-size 100 \
      --icon "MyToob.app" 175 120 \
      --app-drop-link 425 120 \
      ~/Desktop/MyToob-1.0.1-dmg.dmg \
      ~/Desktop/MyToobDMG/
    ```
  - [ ] Subtask: Verify DMG created: `ls -lh ~/Desktop/MyToob-1.0.1-dmg.dmg`

- [ ] **Task 15.6.13:** Test DMG installation
  - [ ] Subtask: Double-click DMG to mount
  - [ ] Subtask: Verify volume appears with app and README
  - [ ] Subtask: Drag app to Applications folder (test on clean Mac or VM)
  - [ ] Subtask: Launch app from Applications
  - [ ] Subtask: Verify app launches without Gatekeeper warning (notarization successful)
  - [ ] Subtask: Verify power-user features enabled (check settings or behavior)

**Phase 6: Version & Host DMG (AC: 7, 8)**

- [ ] **Task 15.6.14:** Version DMG build separately
  - [ ] Subtask: Update version string in Xcode for DMG build: "1.0.1-dmg"
  - [ ] Subtask: OR: Keep same version but add suffix to DMG filename: `MyToob-1.0.1-dmg.dmg`
  - [ ] Subtask: Document versioning scheme in release notes

- [ ] **Task 15.6.15:** Host DMG on project website
  - [ ] Subtask: Upload DMG to web server or CDN
  - [ ] Subtask: Create download page: `https://yourwebsite.com/mytoob/download`
  - [ ] Subtask: Add download button/link to DMG file
  - [ ] Subtask: Include release notes: version, changes, system requirements
  - [ ] Subtask: Add disclaimer: "This version is not available on the App Store. It includes advanced features for power users."

- [ ] **Task 15.6.16:** Announce DMG availability
  - [ ] Subtask: Update project README with download link
  - [ ] Subtask: Post announcement on social media, forums, mailing list (if applicable)
  - [ ] Subtask: Add download link to GitHub releases page (if open-source)

**Phase 7: Automate DMG Build (Optional, CI/CD Integration)**

- [ ] **Task 15.6.17:** Add DMG build to CI/CD pipeline
  - [ ] Subtask: Create GitHub Actions workflow: `.github/workflows/dmg-release.yml`
  - [ ] Subtask: Trigger on Git tag: `tags: ['v*-dmg']`
  - [ ] Subtask: Steps:
    1. Checkout code
    2. Set up Xcode with Developer ID certificate (stored in secrets)
    3. Build with DMG Release configuration
    4. Notarize with `xcrun notarytool`
    5. Staple notarization ticket
    6. Create DMG with `hdiutil` or `create-dmg`
    7. Upload DMG as GitHub release asset
  - [ ] Subtask: Test workflow with test tag

**Dev Notes:**
- **File Locations:**
  - Xcode DMG Release configuration: Project settings > "Info" > "Configurations"
  - Build flags: Project settings > "Build Settings" > "Swift Compiler - Custom Flags"
  - DMG README: `docs/dmg/README-DMG.md`
  - DMG build output: `~/Desktop/MyToobDMG/` (or CI/CD artifacts folder)
- **Developer ID Certificate:** Separate from App Store certificate, used for notarized apps distributed outside App Store
- **Notarization:** Required for Gatekeeper acceptance (macOS 10.15+), even for DMG distribution
- **Power-User Features:** Frame-level CV/ASR for local files (Story 4.6), advanced logging, experimental features
- **Versioning:** Append "-dmg" to version string or filename to distinguish from App Store builds

**Testing Requirements:**
- **Manual Testing:**
  - [ ] Build DMG on local machine, verify codesigning
  - [ ] Submit for notarization, verify "Accepted" status
  - [ ] Staple ticket, verify no Gatekeeper warnings
  - [ ] Mount DMG, drag to Applications, launch app
  - [ ] Verify power-user features enabled (check CV/ASR behavior for local files)
  - [ ] Test on fresh Mac or VM to simulate end-user experience
- **Automated Testing (CI/CD):**
  - [ ] DMG build workflow triggers on `-dmg` tag
  - [ ] Notarization completes without errors
  - [ ] DMG uploaded to release assets

---

## Cross-References & Dependencies Summary

**Major Cross-Story Dependencies:**
- **Epic 15 depends on:** All prior epics (1-14) for complete feature set
- **Story 15.1-15.3** (StoreKit) referenced by: Story 15.4 (marketing copy mentions Pro features)
- **Story 15.4** (App Store package) required for: Story 15.5 (reviewer notes reference screenshots)
- **Story 15.5** (reviewer notes) complements: Story 12.1-12.6 (UGC safeguards documentation)
- **Story 15.6** (DMG build) diverges from: App Store build (separate configuration, power-user features)

**Epic 15 Completion Status:**
- All 6 stories (15.1-15.6) now have comprehensive task breakdowns
- Total tasks across Epic 15: ~95 tasks, ~475 subtasks
- Ready for implementation and App Store/DMG release preparation

---


---

# Cross-References & Story Dependencies

This section maps relationships between stories across all 15 epics to help developers understand dependencies, parallel work opportunities, and integration points.

## Critical Path Dependencies

**Foundation Layer (Must Complete First):**
1. **Story 1.1** (SwiftData Models) → Required by ALL stories that persist data
2. **Story 1.3** (Basic App Shell) → Required by ALL UI stories
3. **Epic A** (CI/CD Setup) → Required before deploying any features

**YouTube Integration Chain:**
1. Story 2.1 (OAuth Setup) → Story 2.2 (Data API Client) → Story 2.3 (Library Sync) → Story 3.1 (IFrame Player)
2. Story 3.1 (IFrame Player) → Story 3.2 (JS Bridge) → Story 3.3-3.6 (All playback controls)

**AI Pipeline Chain:**
1. Story 6.1 (Core ML Embeddings) → Story 6.4 (Batch Processing) → Story 6.6 (HNSW Index)
2. Story 6.6 (HNSW Index) → Story 7.3 (Vector Search) → Story 8.1 (Hybrid Search)
3. Story 7.1 (kNN Graph) → Story 7.2 (Leiden Clustering) → Story 7.3 (Smart Collections)

**Search & Discovery Chain:**
1. Story 8.2 (Keyword Search) + Story 7.3 (Vector Search) → Story 8.4 (Hybrid Fusion)
2. Story 8.4 (Hybrid Fusion) → Story 8.6 (Search Results Display)
3. Story 8.5 (Filter Pills) → Story 8.6 (Search Results Display)

**Collections & Organization Chain:**
1. Story 9.1 (Collections CRUD) → Story 9.2 (Video Assignment) → Story 9.3 (Drag-Drop)
2. Story 7.3 (Smart Collections) → Story 9.1 (Collections CRUD) [integration point]

**Note-Taking Chain:**
1. Story 10.1 (Note Model) → Story 10.2 (Timestamp Anchors) → Story 10.3 (Wiki Links)
2. Story 10.4 (Templates) → Story 10.2 (Timestamp Anchors) [template variables include timestamps]

**Compliance Chain:**
1. Story 11.1 (Report Content) → Story 11.5 (YouTube Disclaimers)
2. Story 11.2 (Hide Channel) → Story 11.3 (Content Policy)
3. Story 11.6 (Compliance Logging) → Story 14.5 (Reviewer Documentation)

**macOS Integration Chain:**
1. Story 12.1 (Spotlight) → Requires Story 1.1 (VideoItem model) for indexing
2. Story 12.2 (App Intents) → Requires Stories 3.3, 9.2, 7.3 (playback, collections, search functionality)
3. Story 12.3 (Menu Bar Controller) → Requires Story 3.2 (JS Bridge) for playback control

**Accessibility Chain:**
1. Story 13.1 (VoiceOver) → Should be integrated with ALL UI stories as they're built
2. Story 13.2 (Keyboard Navigation) → Should be integrated with ALL UI stories as they're built

**Monetization Chain:**
1. Story 14.1 (StoreKit Config) → Story 14.2 (Paywall) → Story 14.3 (Restore Purchase)
2. Story 14.2 (Paywall) → Requires knowledge of all Pro features from Epics 6-12

**Release Chain:**
1. Story 14.4 (App Store Package) → Story 14.5 (Reviewer Documentation) → Story 15 submission
2. Story 14.6 (DMG Build) → Parallel to App Store submission, not blocking

## Feature-Based Groupings

### YouTube Content Features
**Related Stories:** 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 11.1, 11.2, 11.5
**Key Integration Point:** IFrame Player (Story 3.1) is central hub for all YouTube playback features
**Compliance Note:** All these stories must maintain YouTube ToS compliance (no stream access, no ad blocking)

### Local File Features
**Related Stories:** 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.1, 5.2, 5.3
**Key Integration Point:** AVKit Player (Story 4.1) is central hub for local playback
**DMG Note:** Story 4.6 (CV/ASR) has enhanced version in DMG build (Story 14.6)

### AI & Search Features
**Related Stories:** 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 7.1, 7.2, 7.3, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
**Key Integration Points:**
- Embeddings (6.1) feed into Vector Index (6.6)
- Vector Index (6.6) powers Vector Search (7.3) and Smart Collections (7.3)
- Hybrid Search (8.4) combines Keyword (8.2) and Vector (7.3) search
**Pro Feature:** All AI features gated behind Pro tier (Story 14.2)

### Collections & Organization
**Related Stories:** 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 7.3 (Smart Collections)
**Key Integration Points:**
- Manual Collections (9.1-9.6) coexist with AI Smart Collections (7.3)
- Drag-Drop (9.3) integrates with System Drag-Drop (12.6)

### Note-Taking & Research
**Related Stories:** 10.1, 10.2, 10.3, 10.4, 10.5, 10.6
**Key Integration Points:**
- Timestamps (10.2) require playback integration (Stories 3.2, 4.2)
- Wiki Links (10.3) integrate with Collections (9.1) and VideoItems (1.1)
- Templates (10.4) use metadata from VideoItem model (1.1)

### Compliance & UGC
**Related Stories:** 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 14.5
**Key Integration Points:**
- Report Content (11.1) deep-links to YouTube
- Compliance Logging (11.6) tracks all UGC actions
- Reviewer Notes (14.5) documents all compliance features

### System Integration
**Related Stories:** 12.1, 12.2, 12.3, 12.4, 12.5, 12.6
**Key Integration Points:**
- Spotlight (12.1) indexes VideoItem model (1.1)
- App Intents (12.2) expose app functionality to Shortcuts
- Menu Bar (12.3) requires playback bridge (3.2)
- Drag-Drop (12.6) integrates with Collections (9.2)

### Accessibility & Polish
**Related Stories:** 13.1, 13.2, 13.3, 13.4, 13.5, 13.6
**Cross-Cutting Concerns:** These stories affect ALL UI stories
**Integration Note:** Should be validated for each major UI feature as it's built

### Monetization & Distribution
**Related Stories:** 14.1, 14.2, 14.3, 14.4, 14.5, 14.6
**Key Integration Points:**
- StoreKit (14.1-14.3) gates Pro features across Epics 6-12
- Reviewer Notes (14.5) references compliance features (Epic 11)
- DMG Build (14.6) enables advanced features from Story 4.6

## Parallel Work Opportunities

**Can Be Built Independently (After Foundation):**
- **Epic 2** (YouTube) and **Epic 4** (Local Files) → Separate playback stacks
- **Epic 6** (Embeddings) and **Epic 8** (Keyword Search) → Separate until Story 8.4 (fusion)
- **Epic 9** (Collections) and **Epic 10** (Notes) → Independent features until wiki-link integration
- **Epic 12** (System Integration) stories can be built independently once core features exist

**Should Be Built Sequentially:**
- **Epic 1** → ALL other epics (foundation)
- **Stories 6.1 → 6.6 → 7.1 → 7.2 → 7.3** (AI pipeline chain)
- **Stories 2.1 → 2.2 → 2.3 → 3.1** (YouTube integration chain)
- **Stories 14.1 → 14.2 → 14.3** (monetization chain)

**Can Be Iterated On (MVP → Full Feature):**
- **Search:** Start with Story 8.2 (keyword only) → Add Story 7.3 (vector) → Complete with Story 8.4 (hybrid)
- **Collections:** Start with Story 9.1-9.2 (manual) → Add Story 7.3 (Smart Collections) later
- **Notes:** Start with Story 10.1 (basic editor) → Add Story 10.2 (timestamps) → Add Story 10.3 (wiki links) → Add Story 10.4 (templates)

## Testing Dependencies

**Unit Test Dependencies:**
- Most model tests (Epic 1) can be written immediately
- API client tests (Story 2.2) require mock responses
- AI pipeline tests (Epic 6) require test embeddings and sample data

**Integration Test Dependencies:**
- IFrame Player tests (Story 3.2) require WKWebView + YouTube player loaded
- Hybrid search tests (Story 8.4) require both keyword and vector search implemented
- CloudKit sync tests (Story 5.3) require CloudKit test environment

**UI Test Dependencies:**
- All UI tests require Story 1.3 (Basic App Shell) as foundation
- Playback UI tests require Stories 3.1 (IFrame) or 4.1 (AVKit) completed
- Search UI tests require Story 8.6 (Search Results Display) completed

**Accessibility Tests:**
- VoiceOver tests (Story 13.1) should be run for each major UI feature
- Keyboard navigation tests (Story 13.2) should validate all interactive elements

## Architecture Dependencies

**SwiftData Schema:**
- **Core Models** (Story 1.1): VideoItem, ClusterLabel, Collection, Note, ChannelBlacklist
- **Relationships:**
  - VideoItem ↔ Collection (many-to-many, Story 9.2)
  - VideoItem ↔ Note (one-to-many, Story 10.1)
  - VideoItem → ClusterLabel (many-to-one, Story 7.2)

**Core ML Pipeline:**
- **Embedding Model** (Story 6.1) → All embeddings generated here
- **HNSW Index** (Story 6.6) → Stores all embeddings for search
- **Clustering** (Story 7.2) → Consumes embeddings from HNSW

**Playback Architecture:**
- **YouTube Path:** WKWebView (Story 3.1) → JS Bridge (3.2) → Transport Controls (3.3-3.6)
- **Local Path:** AVPlayerView (Story 4.1) → Transport Controls (4.2) → CV/ASR (4.6)
- **Unified Interface:** PlaybackProtocol adopted by both paths

**Search Architecture:**
- **Keyword Engine** (Story 8.2) → Tokenization, substring matching
- **Vector Engine** (Story 7.3) → HNSW search
- **Fusion Layer** (Story 8.4) → Reciprocal Rank Fusion (RRF)
- **UI Layer** (Story 8.6) → Results display + filters

## Compliance Cross-References

**YouTube ToS Compliance:**
- **IFrame Player** (Story 3.1): Only approved playback method
- **No Stream Access** (Stories 3.1, 3.2): Enforced by architecture
- **No Ad Blocking** (Story 3.1): Player UI unmodified
- **Pause When Hidden** (Story 3.4): Required behavior
- **Branding** (Story 11.5): Disclaimers and attribution

**App Store Guidelines Compliance:**
- **UGC Moderation** (Stories 11.1-11.4): Required for Guideline 1.2
- **Privacy Policy** (Story 14.4): Required URL for submission
- **Support Contact** (Story 14.4): Required for submission
- **Accessibility** (Stories 13.1-13.3): Best practices, may be reviewed
- **Reviewer Notes** (Story 14.5): Documents all compliance measures

**Pro Feature Gating:**
- **Free Tier:** Stories 1.1-4.5, 8.2 (keyword search), 9.1-9.6 (manual collections)
- **Pro Tier:** Stories 6.1-6.6 (AI embeddings), 7.1-7.3 (clustering/semantic search), 10.4 (templates), 12.1-12.2 (Spotlight/App Intents)
- **Paywall** (Story 14.2): Gates Pro features, shows value proposition

## Quick Reference: "If I Build X, What Depends On It?"

**If you build Story 1.1 (SwiftData Models):**
- Unblocks: ALL data persistence stories, CloudKit sync, search, collections, notes

**If you build Story 2.2 (YouTube Data API Client):**
- Unblocks: Library sync (2.3), metadata display, search data population

**If you build Story 3.1 (IFrame Player):**
- Unblocks: ALL YouTube playback features (3.2-3.6), menu bar controller (12.3)

**If you build Story 4.1 (AVKit Player):**
- Unblocks: ALL local file features (4.2-4.6), local file import (4.5)

**If you build Story 6.1 (Core ML Embeddings):**
- Unblocks: Vector index (6.6), clustering (7.1-7.2), semantic search (7.3), Smart Collections (7.3)

**If you build Story 6.6 (HNSW Index):**
- Unblocks: Vector search (7.3), hybrid search (8.4)

**If you build Story 8.2 (Keyword Search):**
- Enables: Basic search functionality (MVP)
- Unblocks: Hybrid search (8.4) when combined with vector search (7.3)

**If you build Story 9.1 (Collections CRUD):**
- Unblocks: Video assignment (9.2), drag-drop (9.3), bulk operations (9.4), wiki links (10.3)

**If you build Story 10.1 (Note Model):**
- Unblocks: ALL note-taking features (10.2-10.6), wiki links (10.3)

**If you build Story 11.1 (Report Content):**
- Partially satisfies: App Store Guideline 1.2 (UGC moderation)
- Complements: Story 11.6 (compliance logging)

**If you build Story 12.1 (Spotlight):**
- Provides: System-wide search for app content
- Requires: VideoItem model (1.1), Pro tier check (14.2)

**If you build Story 14.1 (StoreKit Config):**
- Unblocks: Paywall (14.2), Pro feature gating across ALL Pro features

---


# Time Estimates & Complexity Ratings

This section provides planning estimates for each story. Times are in developer-days (8-hour workdays) for an experienced iOS/macOS developer familiar with the tech stack.

**Complexity Scale:**
- **Low:** Straightforward implementation, well-documented patterns, minimal risk
- **Medium:** Moderate complexity, some unknowns, standard iOS development
- **High:** Complex implementation, multiple integration points, requires expertise
- **Very High:** Cutting-edge tech, significant R&D, high risk, requires deep expertise

**Time Estimates Include:**
- Implementation of all acceptance criteria
- Unit tests and basic integration tests
- Code review and iteration
- Documentation updates

**NOT Included:**
- Initial project setup (covered in Epic A)
- UI/UX design time (assumes designs exist)
- Extensive debugging of edge cases beyond AC
- Performance optimization beyond AC targets

---

## Epic 1: Foundation & Core Models (2-3 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 1.1 | SwiftData Models | Medium | 3-4 | Schema migration complexity | SwiftData, CloudKit basics |
| 1.2 | SwiftData Migrations | High | 4-5 | Data loss risk, testing complexity | SwiftData migrations, versioning |
| 1.3 | Basic App Shell | Low | 2-3 | Minimal, standard SwiftUI | SwiftUI, macOS app architecture |

**Epic 1 Total:** 9-12 days (1.8-2.4 weeks)

**Notes:**
- Story 1.1 is foundational and blocks most other work
- Story 1.2 becomes critical once app has users; can be deferred for v1.0 if no schema changes
- Story 1.3 is quick but must be solid (app architecture foundation)

---

## Epic 2: YouTube OAuth & Data API (2-3 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 2.1 | OAuth 2.0 Flow | Medium | 3-4 | OAuth security, keychain storage | OAuth 2.0, ASWebAuthenticationSession |
| 2.2 | Data API Client | Medium | 4-5 | Quota management, error handling | REST APIs, async/await, Codable |
| 2.3 | Library Sync | High | 5-6 | Pagination, rate limiting, stale data | YouTube Data API v3, quota optimization |

**Epic 2 Total:** 12-15 days (2.4-3 weeks)

**Notes:**
- OAuth (2.1) is well-documented but security-critical
- Data API (2.2) complexity driven by quota management and error handling
- Library Sync (2.3) highest risk due to API quota limits and sync complexity

---

## Epic 3: YouTube IFrame Player Integration (3-4 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 3.1 | IFrame Player Setup | Medium | 3-4 | WKWebView security, player loading | WKWebView, YouTube IFrame API |
| 3.2 | JS Bridge | High | 5-6 | Async messaging, state sync | JavaScript, WKWebView messaging |
| 3.3 | Transport Controls | Medium | 3-4 | State management, UI sync | SwiftUI, Combine |
| 3.4 | Pause When Hidden | Low | 1-2 | Window state tracking | AppKit window lifecycle |
| 3.5 | Seek & Scrubbing | Medium | 3-4 | Smooth UX, time formatting | SwiftUI gestures, Combine |
| 3.6 | Native PiP | Medium | 2-3 | PiP entitlements, window management | PiP APIs, macOS entitlements |

**Epic 3 Total:** 17-23 days (3.4-4.6 weeks)

**Notes:**
- Story 3.2 (JS Bridge) is highest complexity; robust error handling critical
- Stories 3.3-3.6 build on 3.2, must be rock-solid before proceeding
- Compliance risk: ensure no ad-blocking, no stream access

---

## Epic 4: Local File Playback (AVKit) (2-3 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 4.1 | AVKit Player Setup | Low | 2-3 | Minimal, well-documented | AVKit, AVPlayerView |
| 4.2 | Transport Controls | Low | 2-3 | Similar to Story 3.3 | SwiftUI, AVPlayer |
| 4.3 | Thumbnails & Snapshots | Medium | 3-4 | Image generation performance | AVAsset, Core Graphics |
| 4.4 | Playback Position Save | Low | 1-2 | SwiftData persistence | SwiftData, AVPlayer time observation |
| 4.5 | Local File Import | Medium | 3-4 | File permissions, sandbox | FileManager, NSOpenPanel |
| 4.6 | CV/ASR (Power User) | Very High | 7-10 | Model selection, performance | Vision, Speech frameworks, Core ML |

**Epic 4 Total:** 18-26 days (3.6-5.2 weeks)

**Notes:**
- Stories 4.1-4.5 are straightforward (AVKit is mature)
- Story 4.6 (CV/ASR) is R&D-heavy, high variance in estimate depending on model choice
- Story 4.6 can be scoped down for MVP (basic metadata only)

---

## Epic 5: CloudKit Sync & Offline Mode (2-3 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 5.1 | CloudKit Setup | Medium | 3-4 | Entitlements, schema design | CloudKit, SwiftData + CloudKit |
| 5.2 | Conflict Resolution | High | 5-6 | Edge cases, data loss risk | CloudKit merge policies, CKRecord |
| 5.3 | Offline Mode | Medium | 3-4 | Queue management, retry logic | NetworkMonitor, async operations |

**Epic 5 Total:** 11-14 days (2.2-2.8 weeks)

**Notes:**
- Story 5.2 (Conflict Resolution) is high risk; "Last Write Wins" is simplest strategy
- Extensive testing required for sync edge cases (concurrent edits, network failures)

---

## Epic 6: On-Device AI - Embeddings & Vector Index (4-6 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 6.1 | Core ML Embeddings | High | 6-8 | Model conversion, quantization | Core ML, Python (coremltools) |
| 6.2 | Embed Metadata | Medium | 3-4 | Text preprocessing, OCR | Core ML, Vision (OCR) |
| 6.3 | SwiftData Storage | Low | 2-3 | Schema design for vectors | SwiftData, binary data |
| 6.4 | Batch Processing | Medium | 4-5 | Concurrency, progress tracking | Swift Concurrency, Task groups |
| 6.5 | Delta Updates | Medium | 3-4 | Change tracking, incremental updates | SwiftData observation, Combine |
| 6.6 | HNSW Vector Index | Very High | 8-10 | Algorithm implementation, performance | HNSW algorithm, C++ (if using library) |

**Epic 6 Total:** 26-34 days (5.2-6.8 weeks)

**Notes:**
- Story 6.1 (Core ML) requires ML expertise; model selection is critical
- Story 6.6 (HNSW) is very high complexity; consider using existing library (hnswlib)
- Performance targets (<10ms inference, <50ms search) are aggressive; may require optimization

---

## Epic 7: AI Clustering & Smart Collections (3-4 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 7.1 | kNN Graph | High | 5-6 | Graph construction performance | Graph algorithms, HNSW |
| 7.2 | Leiden Clustering | Very High | 7-9 | Algorithm implementation, tuning | Community detection, graph algorithms |
| 7.3 | Smart Collections | Medium | 4-5 | UI integration, query logic | SwiftUI, SwiftData queries |

**Epic 7 Total:** 16-20 days (3.2-4 weeks)

**Notes:**
- Story 7.2 (Leiden) is very high complexity; consider using Python library (igraph) via bridge or pre-computation
- Clustering quality depends on parameter tuning (resolution, kNN k-value)
- Can be scoped as Pro feature, not required for MVP

---

## Epic 8: Hybrid Search & Discovery UX (2-3 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 8.1 | Search Bar UI | Low | 1-2 | Standard SwiftUI | SwiftUI, TextField |
| 8.2 | Keyword Search | Medium | 3-4 | Tokenization, ranking | String algorithms, full-text search |
| 8.3 | Vector Search Integration | Low | 2-3 | Query HNSW index (built in 6.6) | HNSW query API |
| 8.4 | Hybrid Fusion (RRF) | High | 4-5 | RRF algorithm, ranking tuning | Reciprocal Rank Fusion, ranking |
| 8.5 | Filter Pills | Medium | 3-4 | UI state management, filtering | SwiftUI, query composition |
| 8.6 | Results Display | Medium | 3-4 | Grid/list layouts, pagination | SwiftUI, LazyVGrid |

**Epic 8 Total:** 16-22 days (3.2-4.4 weeks)

**Notes:**
- Story 8.4 (Hybrid Fusion) is core differentiator; RRF is well-documented but tuning is an art
- Stories 8.1, 8.5, 8.6 are UI-heavy; design quality matters

---

## Epic 9: Collections & Organization (2-3 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 9.1 | Collections CRUD | Low | 2-3 | Standard CRUD operations | SwiftUI, SwiftData |
| 9.2 | Video Assignment | Medium | 3-4 | Many-to-many relationship | SwiftData relationships |
| 9.3 | Drag-and-Drop | Medium | 3-4 | macOS drag-drop APIs | SwiftUI drag-drop, NSPasteboard |
| 9.4 | Bulk Operations | Low | 2-3 | Selection state, batch updates | SwiftUI, SwiftData batch |
| 9.5 | Collection Metadata | Low | 1-2 | Additional fields, UI | SwiftData, SwiftUI forms |
| 9.6 | Nested Collections | Medium | 3-4 | Tree structure, recursion | SwiftData parent-child relationships |

**Epic 9 Total:** 14-20 days (2.8-4 weeks)

**Notes:**
- Stories 9.1-9.5 are straightforward; well-trodden ground
- Story 9.6 (Nested Collections) adds complexity; optional for MVP

---

## Epic 10: Research Tools & Note-Taking (3-4 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 10.1 | Note Model & Editor | Medium | 4-5 | Markdown rendering, editor UX | Markdown, TextEditor, SwiftUI |
| 10.2 | Timestamp Anchors | High | 5-6 | Parsing, player integration | Regex, playback bridge integration |
| 10.3 | Wiki-Style Links | High | 5-7 | Link parsing, autocomplete, backlinks | Regex, graph relationships, SwiftUI |
| 10.4 | Note Templates | Medium | 3-4 | Variable substitution, UI | String templates, SwiftUI |
| 10.5 | Full-Text Search | Medium | 3-4 | Search indexing, highlighting | Full-text search, SwiftUI highlighting |
| 10.6 | Export Notes | Low | 2-3 | File export, formatting | FileManager, Markdown/PDF generation |

**Epic 10 Total:** 22-29 days (4.4-5.8 weeks)

**Notes:**
- Story 10.2 (Timestamp Anchors) is complex; tight integration with playback required
- Story 10.3 (Wiki Links) is high complexity; autocomplete UX is critical
- Note-taking is a major feature area; consider phased rollout

---

## Epic 11: UGC Safeguards & Compliance (1-2 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 11.1 | Report Content | Low | 1-2 | Deep-link, UI | SwiftUI, URL handling |
| 11.2 | Hide Channel | Low | 2-3 | Blacklist model, filtering | SwiftData, query filtering |
| 11.3 | Content Policy Page | Low | 1-2 | Static content, web view | SwiftUI, WKWebView or external link |
| 11.4 | Support Contact | Low | 1-2 | Email link, diagnostics export | SwiftUI, MFMailComposeViewController |
| 11.5 | YouTube Disclaimers | Low | 1 | Static UI text | SwiftUI Text views |
| 11.6 | Compliance Logging | Low | 2-3 | OSLog, event tracking | OSLog, structured logging |

**Epic 11 Total:** 8-13 days (1.6-2.6 weeks)

**Notes:**
- All stories are low complexity; critical for App Store approval
- Story 11.6 (Compliance Logging) useful for reviewer documentation
- Can be completed quickly once core features exist

---

## Epic 12: macOS System Integration (3-4 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 12.1 | Spotlight Indexing | Medium | 4-5 | CSSearchableItem, indexing performance | Core Spotlight, CSSearchableItem |
| 12.2 | App Intents | High | 5-6 | Intent definitions, Shortcuts integration | App Intents framework, Shortcuts |
| 12.3 | Menu Bar Controller | Medium | 3-4 | NSStatusBar, popover UI | AppKit, SwiftUI in NSPopover |
| 12.4 | Keyboard Shortcuts | Medium | 4-5 | Global hotkeys, shortcut customization | AppKit key events, NSEvent monitoring |
| 12.5 | Command Palette | Medium | 3-4 | Search UI, action routing | SwiftUI, fuzzy search |
| 12.6 | External Drag-Drop | Medium | 3-4 | URL/file drag from external apps | NSView drag-drop, UTType |

**Epic 12 Total:** 22-28 days (4.4-5.6 weeks)

**Notes:**
- Story 12.2 (App Intents) is high complexity; new framework, evolving APIs
- Story 12.4 (Keyboard Shortcuts) requires accessibility permissions for global hotkeys
- All stories enhance macOS integration; can be Pro features

---

## Epic 13: Accessibility & Polish (3-4 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 13.1 | VoiceOver Support | High | 6-8 | Testing complexity, label quality | NSAccessibility, VoiceOver testing |
| 13.2 | Keyboard Navigation | Medium | 4-5 | Focus management, shortcuts | SwiftUI focus, keyboard events |
| 13.3 | High-Contrast Theme | Medium | 3-4 | Theme system, contrast ratios | SwiftUI color system, WCAG guidelines |
| 13.4 | Loading States | Low | 2-3 | UI state management | SwiftUI ProgressView, skeleton screens |
| 13.5 | Empty States | Low | 2-3 | Placeholder UI, messaging | SwiftUI conditional views |
| 13.6 | Animations | Medium | 3-4 | Animation tuning, Reduce Motion | SwiftUI animations, accessibility |

**Epic 13 Total:** 20-27 days (4-5.4 weeks)

**Notes:**
- Story 13.1 (VoiceOver) is time-intensive; requires real user testing
- Accessibility should be integrated throughout development, not bolted on
- Stories 13.4-13.6 (polish) significantly improve UX

---

## Epic 14: Monetization & App Store Release (2-3 weeks total)

| Story | Title | Complexity | Est. Days | Risk Factors | Required Expertise |
|-------|-------|------------|-----------|--------------|-------------------|
| 14.1 | StoreKit 2 Config | Medium | 3-4 | StoreKit 2 API, testing | StoreKit 2, in-app purchases |
| 14.2 | Paywall UI | Medium | 4-5 | UI design, purchase flow | SwiftUI, StoreKit views |
| 14.3 | Restore Purchase | Low | 2-3 | Receipt sync, UI | StoreKit 2 transaction management |
| 14.4 | App Store Package | Low | 3-4 | Marketing copy, screenshots | App Store Connect, design tools |
| 14.5 | Reviewer Documentation | Low | 2-3 | Writing, screenshots | Markdown, documentation |
| 14.6 | Notarized DMG | Medium | 3-4 | Notarization, DMG creation | Xcode codesigning, notarytool |

**Epic 14 Total:** 17-23 days (3.4-4.6 weeks)

**Notes:**
- Story 14.1 (StoreKit) is straightforward with StoreKit 2 (simpler than StoreKit 1)
- Story 14.4 (App Store Package) is time-consuming (design, copy, screenshots)
- Story 14.6 (DMG) is optional but valuable for power users

---

## Summary: Total Project Estimates

**By Epic (in weeks):**
1. Epic 1 (Foundation): 1.8-2.4 weeks
2. Epic 2 (YouTube API): 2.4-3 weeks
3. Epic 3 (IFrame Player): 3.4-4.6 weeks
4. Epic 4 (AVKit Player): 3.6-5.2 weeks
5. Epic 5 (CloudKit): 2.2-2.8 weeks
6. Epic 6 (AI Embeddings): 5.2-6.8 weeks
7. Epic 7 (AI Clustering): 3.2-4 weeks
8. Epic 8 (Hybrid Search): 3.2-4.4 weeks
9. Epic 9 (Collections): 2.8-4 weeks
10. Epic 10 (Note-Taking): 4.4-5.8 weeks
11. Epic 11 (Compliance): 1.6-2.6 weeks
12. Epic 12 (macOS Integration): 4.4-5.6 weeks
13. Epic 13 (Accessibility): 4-5.4 weeks
14. Epic 14 (Monetization): 3.4-4.6 weeks

**Total (Sequential): 45.6-61.2 weeks (11.4-15.3 months)**

**Total (With Parallelization):**
- **MVP (Core Features Only):** 25-35 weeks (6-9 months)
  - Includes: Epics 1, 2, 3, 4, 8 (keyword search only), 9 (basic collections), 11 (compliance), 14 (release)
  - Excludes: AI features (6, 7), advanced notes (10), system integration (12), full accessibility (13)
  
- **Full Feature Set (2-3 Developers):** 30-40 weeks (7.5-10 months)
  - With parallel work streams: YouTube (Epics 2-3) + Local Files (Epic 4) + AI (Epics 6-7)
  - Core features → Polish → Release

**Risk Factors Affecting Timeline:**
- **High Risk Stories:** 1.2, 2.3, 3.2, 4.6, 5.2, 6.1, 6.6, 7.2, 8.4, 10.2, 10.3, 12.2, 13.1
- **Unknowns:** AI model performance, HNSW implementation, YouTube API quota constraints
- **External Dependencies:** App Store review time (1-5 days typical), CloudKit issues, YouTube API changes

**Recommended Approach:**
1. **Phase 1 (MVP - 6 months):** Epics 1-4, 8 (keyword only), 9, 11, 14
2. **Phase 2 (AI Features - 3 months):** Epics 6-7, integrate into Phase 1 app
3. **Phase 3 (Polish & Power User - 2 months):** Epics 10, 12, 13, 14.6

---


# Document Summary & Usage Guide

## What This Document Contains

This comprehensive task breakdown document covers **all 91 user stories** across **15 epics** for the MyToob project. It provides:

**For Each Story:**
- Status and dependency information
- Complete acceptance criteria (from PRD)
- 6-8 implementation phases
- 30-50 detailed subtasks per story
- Dev notes with file locations, function signatures, and technical patterns
- Testing requirements with specific test counts

**Additional Sections:**
- Cross-references showing dependencies between stories
- Time estimates and complexity ratings for planning
- Parallel work opportunities
- Compliance cross-references

**Total Content:**
- **91 stories** expanded with full implementation details
- **~550 implementation phases**
- **~2,750 detailed subtasks**
- **Comprehensive cross-reference matrix**
- **Complete time/complexity analysis**

---

## How to Use This Document

### For Project Managers

**Planning a Sprint:**
1. Review **Time Estimates & Complexity Ratings** section
2. Check **Critical Path Dependencies** to understand blocking relationships
3. Identify **Parallel Work Opportunities** for team task allocation
4. Select stories that fit sprint capacity and have dependencies satisfied

**Tracking Progress:**
- Each story has clear status field (Not Started / In Progress / Completed)
- Use subtask checkboxes to track granular progress
- Reference **Cross-References** section to identify downstream impacts

**Risk Management:**
- High/Very High complexity stories require experienced developers
- Stories marked "High Risk" in estimates need extra buffer time
- External dependencies (YouTube API, App Store review) have unknowns

**Example Sprint Planning:**
```
Sprint 1 (2 weeks, 1 developer):
- Story 1.1 (SwiftData Models) - 3-4 days
- Story 1.3 (Basic App Shell) - 2-3 days
- Story 8.1 (Search Bar UI) - 1-2 days
- Story 9.1 (Collections CRUD) - 2-3 days
Total: 8-12 days (fits in 10-day sprint)
```

### For Developers

**Starting a New Story:**
1. Read the **Acceptance Criteria** first (understand success criteria)
2. Review **Dependencies** section (ensure prerequisite stories are complete)
3. Scan **Implementation Phases** for high-level approach
4. Read **Dev Notes** for file locations and technical patterns
5. Work through **subtasks** sequentially, checking off as you go

**During Implementation:**
- Use subtask checkboxes as micro-milestones
- Refer to **Dev Notes** for specific file paths and function signatures
- Check **Cross-References** if you need to understand integration points
- Validate against **Testing Requirements** as you implement

**Code Examples in Doc:**
- All code snippets are actual Swift/SwiftUI patterns used in MyToob
- Function signatures in Dev Notes are copy-pasteable starting points
- File paths in Dev Notes show exact locations in project structure

**Example Workflow for Story 3.2 (JS Bridge):**
```
1. Read AC → understand play/pause/seek must work bidirectionally
2. Check Dependencies → Story 3.1 (IFrame Player) must be done
3. Read Phase 1 subtasks → set up evaluateJavaScript infrastructure
4. Read Dev Notes → file: MyToob/YouTube/IFrameBridge.swift
5. Implement Phase 1, check off subtasks
6. Move to Phase 2, repeat
7. Run tests from Testing Requirements section
8. Mark story as "Completed"
```

### For Technical Leads / Architects

**Understanding System Architecture:**
- **Architecture Dependencies** section maps core architectural relationships
- **Feature-Based Groupings** show how stories cluster by functional area
- **Critical Path Dependencies** reveal foundational vs. leaf features

**Code Review Planning:**
- High/Very High complexity stories need senior review
- Stories with "Compliance Risk" need extra scrutiny (YouTube ToS, App Store Guidelines)
- Cross-references show which stories affect multiple parts of codebase

**Technical Debt Management:**
- Stories marked "Can Be Deferred" are candidates for MVP cut
- "MVP → Full Feature" section shows incremental delivery paths
- Time estimates highlight where technical shortcuts might be tempting (don't take them in High Risk stories)

**Example Architecture Review:**
```
Epic 6 (AI Embeddings) Architecture:
- Story 6.1: Core ML model (foundation)
- Story 6.6: HNSW index (depends on 6.1)
- Story 7.3: Vector search (depends on 6.6)
→ Review: Ensure 6.1 model is production-ready before building on it
→ Consider: HNSW library (hnswlib) vs. custom implementation (Story 6.6)
```

### For QA / Testing

**Test Planning:**
- Each story has **Testing Requirements** section with specific test counts
- **Testing Dependencies** section shows which tests require other features
- Accessibility stories (Epic 13) define cross-cutting test requirements

**Test Execution:**
- Use subtasks as test cases (each subtask should be testable)
- Acceptance Criteria are definitive success conditions
- Dev Notes often include "edge cases" or "error scenarios" to test

**Regression Testing:**
- **Cross-References** section shows which stories affect each other
- When a story changes, check "If I Build X, What Depends On It?" section

**Example Test Plan for Story 8.4 (Hybrid Search):**
```
From Testing Requirements:
- Unit tests (15): RRF scoring, result merging, edge cases
- Integration tests (5): Keyword + vector search working together
- UI tests (3): Search mode toggle, results display, filter integration

From Acceptance Criteria:
- Test: Query "swift async" returns results from both keyword and vector
- Test: Empty query handled gracefully
- Test: Top-100 results returned (verify limit)

From Dev Notes (Edge Cases):
- Test: Video in both result sets → single entry with combined score
- Test: Keyword search returns 0 results → vector search still runs
```

---

## Navigation Tips

**Finding Specific Information:**

**"I want to know what Story X.Y does"**
→ Search for "Story X.Y:" to jump to story heading
→ Read Acceptance Criteria first

**"I want to know how long Story X.Y will take"**
→ Jump to **Time Estimates & Complexity Ratings** section
→ Find story in table, check Est. Days column

**"I want to know what depends on Story X.Y"**
→ Jump to **Cross-References** section
→ Search for "If you build Story X.Y" in Quick Reference

**"I want to know what stories I can work on in parallel"**
→ Jump to **Parallel Work Opportunities** section
→ Check "Can Be Built Independently" list

**"I want to understand the AI pipeline architecture"**
→ Jump to **Feature-Based Groupings** → AI & Search Features
→ Read Core ML Pipeline description in Architecture Dependencies

**"I want to see all compliance-related stories"**
→ Jump to **Compliance Cross-References** section
→ Lists all YouTube ToS and App Store Guidelines stories

**Search Tips:**
- Search "Epic X" to jump to specific epic
- Search "Story X.Y" to jump to specific story
- Search "AC:" to see all Acceptance Criteria sections
- Search "Phase X:" to see all phases for current story
- Search "Dev Notes:" to see technical implementation details
- Search "Testing Requirements:" to see all test sections

---

## Recommended Workflows

### Workflow 1: MVP Development (6-Month Plan)

**Goal:** Ship core product to App Store

**Epics to Implement:**
1. Epic 1 (Foundation) - Weeks 1-2
2. Epic 2 (YouTube API) - Weeks 3-5
3. Epic 3 (IFrame Player) - Weeks 6-9
4. Epic 4 (AVKit Player) - Weeks 10-13
5. Epic 8 (Keyword Search Only) - Weeks 14-16
6. Epic 9 (Basic Collections) - Weeks 17-19
7. Epic 11 (Compliance) - Weeks 20-21
8. Epic 14 (Monetization & Release) - Weeks 22-26

**Stories to Skip for MVP:**
- Epic 5 (CloudKit) - Add in v1.1
- Epic 6-7 (AI Features) - Add in v2.0
- Epic 10 (Note-Taking) - Add in v1.2
- Epic 12 (macOS Integration) - Add in v1.1
- Epic 13 (Accessibility) - Partial only (VoiceOver basics, keyboard nav)

**Team Structure:**
- 1-2 developers
- Focus on getting to App Store approval quickly
- Defer Pro features, monetize later

### Workflow 2: Full-Featured Development (10-Month Plan)

**Goal:** Ship complete product with all AI features

**Phase 1: Foundation (Months 1-2)**
- Epic 1 (Foundation)
- Epic 2 (YouTube API)
- Epic 3 (IFrame Player)
- Epic 4 (AVKit Player)

**Phase 2: Search & Organization (Months 3-5)**
- Epic 6 (AI Embeddings)
- Epic 7 (AI Clustering)
- Epic 8 (Hybrid Search)
- Epic 9 (Collections)

**Phase 3: Power User Features (Months 6-7)**
- Epic 5 (CloudKit)
- Epic 10 (Note-Taking)
- Epic 12 (macOS Integration)

**Phase 4: Polish & Release (Months 8-10)**
- Epic 11 (Compliance)
- Epic 13 (Accessibility)
- Epic 14 (Monetization & Release)

**Team Structure:**
- 2-3 developers working in parallel
- Developer 1: YouTube integration (Epics 2-3)
- Developer 2: Local files + AI (Epics 4, 6-7)
- Developer 3: UI/UX + Polish (Epics 8-9, 13)

### Workflow 3: Iterative Development (Recommended)

**Goal:** Ship MVP quickly, iterate with user feedback

**Iteration 1: Core Playback (2 months)**
- Epic 1, 2, 3, 4
- **Ship:** Basic YouTube + local file playback, no AI

**Iteration 2: Search & Organize (2 months)**
- Epic 8 (keyword search), Epic 9 (collections), Epic 11 (compliance)
- **Ship:** v1.0 to App Store, gather user feedback

**Iteration 3: AI Features (3 months)**
- Epic 6, 7 (add AI embeddings and clustering)
- **Ship:** v2.0 with semantic search, Smart Collections (Pro feature)

**Iteration 4: Power User (2 months)**
- Epic 10 (notes), Epic 12 (system integration)
- **Ship:** v2.1 with research tools

**Iteration 5: Polish (1 month)**
- Epic 13 (full accessibility), Epic 14.6 (DMG build)
- **Ship:** v2.2 polished release

**Advantages:**
- Faster time to market
- User feedback informs priorities
- Lower risk (validate core concept before investing in AI)
- Cash flow (monetization in Iteration 3)

---

## Best Practices

### Using This Document Effectively

**Do:**
- ✅ Read Acceptance Criteria before implementation
- ✅ Check Dependencies before starting a story
- ✅ Use subtask checkboxes to track progress
- ✅ Refer to Dev Notes for file locations and patterns
- ✅ Cross-reference with PRD for additional context
- ✅ Update status fields as work progresses
- ✅ Add notes if you discover new dependencies or gotchas

**Don't:**
- ❌ Implement stories out of dependency order
- ❌ Skip unit tests listed in Testing Requirements
- ❌ Modify subtasks without understanding full context
- ❌ Ignore compliance notes (YouTube ToS, App Store Guidelines)
- ❌ Cut corners on High/Very High complexity stories
- ❌ Assume time estimates are worst-case (they're average case)

### Code Quality Standards

**Every Story Should:**
- Meet ALL Acceptance Criteria (non-negotiable)
- Have unit tests (counts in Testing Requirements)
- Include error handling (noted in subtasks)
- Follow SwiftLint rules (when configured)
- Have inline documentation for non-obvious logic
- Be code reviewed by another developer

**Compliance-Critical Stories:**
- Epic 2-3 (YouTube): No stream access, no ad blocking
- Epic 11 (UGC): All safeguards must work
- Epic 14 (Release): All App Store requirements met

**Performance-Critical Stories:**
- Story 6.1: <10ms embedding inference (M1 Mac)
- Story 6.6: <50ms vector search (P95)
- Story 8.4: Search completes in <100ms total

### When to Deviate from This Document

**It's OK to deviate if:**
- You discover a better implementation approach (document why)
- A library/framework change makes subtasks obsolete
- User research reveals different priorities
- Technical constraints require different architecture

**How to deviate safely:**
1. Discuss with team lead
2. Document deviation in story notes or commit messages
3. Ensure Acceptance Criteria still met
4. Update this document if change is significant
5. Update time estimates if change affects other stories

**Never deviate on:**
- Acceptance Criteria (these define success)
- Compliance requirements (YouTube ToS, App Store Guidelines)
- Performance targets (users will notice)
- Accessibility standards (required for App Store)

---

## Troubleshooting

**"I don't understand what a subtask means"**
→ Read the parent phase description (provides context)
→ Check Dev Notes for examples or patterns
→ Refer to PRD (docs/prd/epic-X.md) for user story context

**"A dependency is missing or unclear"**
→ Check Cross-References section for related stories
→ Search document for story number (e.g., "Story 3.1")
→ Review Architecture Dependencies for system-level relationships

**"Time estimate seems way off"**
→ Estimates assume experienced iOS/macOS developer
→ High/Very High complexity stories have high variance
→ First-time estimates often underestimate (add 1.5x buffer)

**"Subtasks don't make sense for my tech stack"**
→ This doc assumes SwiftUI, SwiftData, Core ML
→ If using different stack, adapt subtasks but keep ACs
→ Document your changes in story notes

**"I found a bug in the document"**
→ Check PRD for source of truth on Acceptance Criteria
→ Fix and commit if you have write access
→ File GitHub issue or Slack message if you don't

---

## Document Maintenance

**When to Update This Document:**

**After Completing a Story:**
- Change status from "In Progress" to "Completed"
- Add any lessons learned to Dev Notes
- Update time estimates if actual time significantly different

**When Starting a New Sprint:**
- Update story statuses to "In Progress" for sprint stories
- Check that dependencies are met
- Assign developers to stories (add note if needed)

**When Discovering New Dependencies:**
- Add to Dependencies section of affected story
- Update Cross-References section if major
- Inform team of impact

**When Changing Architecture:**
- Update Dev Notes in affected stories
- Update Architecture Dependencies section
- Consider time estimate impacts

**Periodic Review (Monthly):**
- Review completed stories for accuracy
- Update time estimates based on actuals
- Adjust remaining story estimates if patterns emerge
- Update cross-references if new relationships discovered

---

## Additional Resources

**Related Documents:**
- `IdeaDoc.md` - Original PRD and technical spec (source of Acceptance Criteria)
- `docs/prd/epic-*.md` - Individual epic PRDs (more context on user stories)
- `CLAUDE.md` - Project setup, architecture, MCP tooling, compliance rules
- `docs/XCODE_SETUP.md` - Xcode configuration, entitlements, signing
- `docs/SWIFTLINT_SETUP.md` - Code quality standards (when configured)

**External References:**
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines) - UI/UX standards
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) - Compliance requirements
- [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference) - Playback integration
- [YouTube Data API v3](https://developers.google.com/youtube/v3) - Metadata API
- [YouTube Terms of Service](https://www.youtube.com/t/terms) - Compliance requirements
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit) - In-app purchases

**Community & Support:**
- GitHub Issues (if open-source)
- Internal Slack channels
- Weekly sprint retrospectives
- Code review feedback

---

## Conclusion

This document represents **~60-80 hours of planning work** to break down MyToob's 91 user stories into **2,750+ actionable subtasks**. It's designed to be a living document that evolves with the project.

**Key Takeaways:**
- **Comprehensive Coverage:** All 91 stories across 15 epics fully expanded
- **Actionable Granularity:** 30-50 subtasks per story with checkboxes
- **Context-Rich:** Dev notes, cross-references, time estimates, complexity ratings
- **Flexible Usage:** Supports MVP, full-featured, or iterative development approaches
- **Compliance-Focused:** YouTube ToS and App Store Guidelines baked into relevant stories

**Success Metrics:**
- ✅ 91 stories → 2,750+ subtasks (30-50 per story)
- ✅ All dependencies mapped and cross-referenced
- ✅ Time estimates for all stories (9-12 months total, 6-9 months MVP)
- ✅ Compliance requirements documented for YouTube and App Store
- ✅ Multiple development workflows provided (MVP, full-featured, iterative)

**What This Document Enables:**
- Accurate sprint planning with time estimates
- Parallel work stream coordination
- Risk management with complexity ratings
- Quality assurance with detailed testing requirements
- New developer onboarding (clear, granular tasks)
- Stakeholder communication (clear progress tracking)

**Remember:**
- This is a **plan**, not a straitjacket
- Adapt as you learn (but document deviations)
- **Acceptance Criteria** are non-negotiable
- **Subtasks** are guidelines (can be adjusted)
- **Time estimates** are averages (add buffers)

**Next Steps:**
1. Review entire document to understand scope
2. Select development workflow (MVP / Full-Featured / Iterative)
3. Identify first sprint stories (usually Epic 1)
4. Assign developers to stories
5. Begin implementation, checking off subtasks as you go
6. Update this document with lessons learned

Good luck building MyToob! 🚀

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-19  
**Total Stories Covered:** 91  
**Total Subtasks:** ~2,750  
**Estimated Project Duration:** 9-15 months (varies by scope)  

---

*End of Task Breakdowns Continuation Document*


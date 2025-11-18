# Epic 3: Compliant YouTube Playback

**Goal:** Integrate the YouTube IFrame Player API within a WKWebView to provide compliant, ToS-adhering video playback. This epic implements the JavaScript bridge for playback control (play/pause/seek), state synchronization (time updates, player events), and enforces policy boundaries (no ad removal, no stream access, pause when hidden). Successful completion enables users to watch YouTube videos within the app without violating YouTube's Developer Policies.

## Story 3.1: WKWebView YouTube IFrame Player Setup

As a **developer**,
I want **a WKWebView that loads the YouTube IFrame Player API**,
so that **YouTube videos can be played within the app using official APIs**.

**Acceptance Criteria:**
1. `YouTubePlayerView` SwiftUI view created wrapping `WKWebView` (via `NSViewRepresentable`)
2. HTML page embedded in app resources that loads YouTube IFrame Player API: `https://www.youtube.com/iframe_api`
3. IFrame Player initialized with video ID parameter passed from SwiftUI
4. Player configured with parameters: `controls=1` (show controls), `modestbranding=1`, `rel=0` (no related videos from other channels)
5. Player loads and displays video correctly when `YouTubePlayerView` shown with valid video ID
6. No DOM manipulation of player element or ads (player rendered as-is)
7. UI test verifies player loads and video starts playing

## Story 3.2: JavaScript Bridge for Playback Control

As a **developer**,
I want **a Swift ↔ JavaScript bridge to control playback (play/pause/seek) programmatically**,
so that **the app can provide native playback controls alongside the IFrame player**.

**Acceptance Criteria:**
1. `WKScriptMessageHandler` implemented to receive messages from JavaScript
2. JavaScript functions defined: `playVideo()`, `pauseVideo()`, `seekTo(seconds)`, `setVolume(level)`
3. Swift methods call JavaScript functions via `webView.evaluateJavaScript()`
4. SwiftUI controls (play/pause button, seek slider) trigger JavaScript commands
5. Playback state updates reflected in UI (play button becomes pause button when playing)
6. Seek slider updates in real-time during playback (synced with video time)
7. UI test verifies play/pause/seek commands work correctly

## Story 3.3: Player State & Time Event Handling

As a **developer**,
I want **to receive player state changes and time updates from the IFrame Player**,
so that **the app can track playback progress and respond to player events**.

**Acceptance Criteria:**
1. JavaScript event listeners registered for: `onStateChange`, `onReady`, `onError`
2. State changes posted to Swift via `window.webkit.messageHandlers.playerState.postMessage(state)`
3. Player states handled: `-1` (unstarted), `0` (ended), `1` (playing), `2` (paused), `3` (buffering), `5` (cued)
4. Time updates posted every second during playback: `currentTime`, `duration`
5. Swift updates `VideoItem.watchProgress` in SwiftData when time updates received
6. Player ready state enables playback controls (disabled until ready)
7. Player errors logged and displayed to user (e.g., "Video unavailable", "Playback error")

## Story 3.4: Picture-in-Picture Support (Native Only)

As a **user**,
I want **to use Picture-in-Picture mode when available**,
so that **I can continue watching while using other apps**.

**Acceptance Criteria:**
1. PiP enabled if supported by YouTube IFrame Player and macOS (HTML5 video element native PiP)
2. PiP button appears in macOS window controls when video is playing
3. Clicking PiP button activates native macOS PiP (floats video above other windows)
4. Playback continues in PiP mode (does NOT pause when app window hidden while in PiP)
5. Exiting PiP returns video to main window
6. No custom PiP implementation (uses native OS capability only)—compliance requirement
7. PiP availability logged (may not be available for all videos due to YouTube restrictions)

## Story 3.5: Player Visibility Enforcement (Compliance)

As a **developer**,
I want **playback to pause when the player window is hidden or minimized (unless PiP is active)**,
so that **the app complies with YouTube's Required Minimum Functionality policy**.

**Acceptance Criteria:**
1. Window visibility tracked using `NSWindow.isVisible` and app lifecycle events (`scenePhase`)
2. When app window hidden, minimized, or occluded: call `pauseVideo()` via JavaScript bridge
3. Exception: If PiP is active, do NOT pause (PiP is visible playback surface)
4. When app returns to foreground, playback remains paused (user can manually resume)
5. Visibility state changes logged for compliance audit trail
6. UI test verifies pause behavior when app backgrounded
7. No background audio playback when player not visible (enforced by YouTube IFrame Player)

## Story 3.6: Error Handling & Unsupported Videos

As a **user**,
I want **clear error messages when a video cannot be played**,
so that **I understand why playback failed and what to do next**.

**Acceptance Criteria:**
1. Player `onError` events handled for codes: `2` (invalid video ID), `5` (HTML5 player error), `100` (video not found), `101`/`150` (embedding disabled)
2. User-friendly error messages displayed: "This video is unavailable", "This video cannot be embedded", "An error occurred during playback"
3. "Open in YouTube" button shown in error state (deep-links to `youtube.com/watch?v={videoID}`)
4. Errors logged to OSLog for debugging (include video ID and error code)
5. Error state dismissible (user can try another video)
6. Retry button shown for transient errors (network issues, buffering failures)
7. No crashes or infinite retry loops on persistent errors

---

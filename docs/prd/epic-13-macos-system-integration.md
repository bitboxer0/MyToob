# Epic 13: macOS System Integration

**Goal:** Deeply integrate with macOS platform features: Spotlight search indexing, App Intents for Shortcuts automation, menu bar controls for playback, and comprehensive keyboard shortcuts. This epic makes the app feel like a native macOS citizen, accessible system-wide and efficient for power users.

## Story 13.1: Spotlight Indexing for Videos

As a **user**,
I want **saved videos and collections indexed in Spotlight**,
so that **I can find content using macOS system search**.

**Acceptance Criteria:**
1. `CSSearchableItem` created for each `VideoItem` with metadata: title, description, tags, thumbnail
2. Items indexed on import and updated when metadata changes
3. Spotlight results show video thumbnails and descriptions
4. Clicking Spotlight result launches app and opens video detail view
5. "Index in Spotlight" toggle in Settings (enabled by default, Pro feature)
6. Deleting video removes from Spotlight index
7. Search query in Spotlight: "mytoob swift tutorials" finds relevant videos

## Story 13.2: App Intents for Shortcuts

As a **user**,
I want **to automate video actions using Shortcuts**,
so that **I can integrate the app into my workflows**.

**Acceptance Criteria:**
1. App Intents defined: "Play Video", "Add to Collection", "Search Videos", "Get Random Video from Cluster"
2. Intents support parameters: video ID, collection name, search query, cluster ID
3. Intents exposed in Shortcuts app (appear when adding MyToob actions)
4. Example Shortcut: "Morning Briefing" plays unwatched videos from "Learning" collection
5. Intents return results (e.g., "Search Videos" returns list of matching videos for further Shortcuts processing)
6. Intents work when app is backgrounded (use background execution entitlement if needed)
7. UI test verifies intents are discoverable in Shortcuts app

## Story 13.3: Menu Bar Mini-Controller

As a **user**,
I want **playback controls in the macOS menu bar**,
so that **I can control playback without switching to the app window**.

**Acceptance Criteria:**
1. Menu bar icon added (custom icon, unobtrusive)
2. Clicking icon shows popover with: current video title, play/pause button, skip forward/back buttons, volume slider
3. Now-playing info updated in real-time (title changes when new video starts)
4. Menu bar controller works for both YouTube and local playback
5. "Hide Menu Bar Controller" toggle in Settings (for users who prefer minimal menu bar)
6. Menu bar icon badge shows play/pause state (optional: animated when playing)
7. Global hotkeys work even when menu bar controller hidden (see Story 12.4)

## Story 13.4: Comprehensive Keyboard Shortcuts

As a **power user**,
I want **keyboard shortcuts for all primary actions**,
so that **I can navigate and control the app without using the mouse**.

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

## Story 13.5: Command Palette (⌘K)

As a **user**,
I want **a command palette for quick access to any action**,
so that **I can navigate the app efficiently without memorizing menus**.

**Acceptance Criteria:**
1. Command palette opened with ⌘K (customizable shortcut)
2. Palette shows searchable list of all actions: "New Collection", "Import Files", "Search Videos", "Settings", etc.
3. Fuzzy search: typing "adcol" matches "Add to Collection"
4. Recent actions shown at top (MRU - most recently used)
5. Actions categorized: Playback, Collections, Search, Settings (filterable by category)
6. Selecting action executes it immediately (e.g., "New Collection" opens dialog)
7. Palette dismissible with Escape or clicking outside
8. UI test verifies palette opens and actions execute correctly

## Story 13.6: Drag-and-Drop from External Sources

As a **user**,
I want **to drag YouTube URLs from Safari or videos from Finder into the app**,
so that **I can quickly add content from anywhere**.

**Acceptance Criteria:**
1. Dragging YouTube URL from browser into app window adds video to library (fetches metadata via API)
2. Dragging video file from Finder into app imports as local file (same as Story 4.5)
3. Drop zones: main content area, collection sidebar items (drops into specific collection)
4. Visual feedback: drop zone highlights, "+" icon on hover
5. Invalid drops handled: non-video URLs or unsupported files show error toast
6. Batch drops supported: drag 10 YouTube links, all imported in sequence
7. UI test verifies drag-and-drop from Finder and browser

---

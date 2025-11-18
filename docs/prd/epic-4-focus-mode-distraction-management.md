# Epic 4: Focus Mode & Distraction Management

**Goal:** Empower users to create distraction-free viewing experiences by selectively hiding YouTube UI elements that compete for attention (sidebar recommendations, related videos, comments, homepage feed). This epic implements customizable distraction controls inspired by browser extensions like Unhook and YouFocus, with time-based scheduling for automatic focus mode activation during work hours. By the end of this epic, users can configure granular distraction hiding preferences that sync across devices and optionally activate on a schedule.

## Story 4.1: Focus Mode Global Toggle

As a **user**,
I want **a global Focus Mode toggle that instantly hides distracting YouTube elements**,
so that **I can quickly enter a focused viewing state without manually configuring individual settings**.

**Acceptance Criteria:**
1. "Focus Mode" toggle button added to toolbar (icon: eye.slash or similar SF Symbol)
2. Clicking toggle activates/deactivates Focus Mode with visual feedback (button highlighted when active)
3. When Focus Mode ON, applies currently configured distraction hiding settings (default: hide all distractors)
4. When Focus Mode OFF, restores YouTube UI to default state (all elements visible)
5. Keyboard shortcut: ⌘⇧F toggles Focus Mode globally
6. Focus Mode state persists across app restarts (stored in UserDefaults)
7. Toast notification on toggle: "Focus Mode Enabled" or "Focus Mode Disabled"
8. Focus Mode status shown in Settings > Focus Mode section

## Story 4.2: Hide YouTube Sidebar

As a **user**,
I want **to hide YouTube's sidebar containing trending and recommended sections**,
so that **I'm not distracted by algorithm-driven suggestions while browsing my library**.

**Acceptance Criteria:**
1. Settings > Focus Mode > "Hide YouTube Sidebar" toggle
2. When enabled, YouTube sidebar (trending, recommended) hidden from main content area (CSS injection or DOM manipulation if accessing YouTube web views)
3. Note: This applies to YouTube web content if displayed within the app (not applicable to IFrame Player which doesn't show sidebar)
4. Setting applies immediately without app restart
5. Setting syncs via CloudKit if sync enabled
6. "Granular Control" button allows showing/hiding specific sidebar sections (Advanced: Trending ON, Recommended OFF)
7. UI test verifies sidebar visibility changes based on toggle state

## Story 4.3: Hide Related Videos Panel

As a **user**,
I want **to hide the "Up Next" and related videos panel during playback**,
so that **I can focus on the current video without being tempted by recommendations**.

**Acceptance Criteria:**
1. Settings > Focus Mode > "Hide Related Videos" toggle
2. When enabled, related videos panel removed from player view (right-side panel or below-player section)
3. "Up Next" autoplay queue hidden (user can manually navigate to next video from library)
4. Option to "Show Related from Same Creator Only" (middle ground: hide algorithm suggestions but keep creator's content)
5. Setting applies to both YouTube IFrame Player context and any YouTube web content
6. If hiding is not possible due to IFrame Player limitations, show explanation: "This YouTube video requires related videos to be shown (creator setting)"
7. UI test verifies related videos panel hidden when toggle enabled

## Story 4.4: Hide Comments Section

As a **user**,
I want **to hide the comments section below YouTube videos**,
so that **I avoid spoilers, toxic comments, and distraction from the video content**.

**Acceptance Criteria:**
1. Settings > Focus Mode > "Hide Comments" toggle
2. When enabled, comments section removed from video detail view
3. "Show Comments" button available to temporarily reveal comments (for videos where user wants community discussion)
4. Setting persists per-session (temporary show resets on new video or app restart)
5. Privacy benefit communicated: "Hiding comments also prevents tracking via comment interactions"
6. Setting syncs via CloudKit
7. UI test verifies comments section visibility based on toggle

## Story 4.5: Hide Homepage Feed

As a **user**,
I want **to hide YouTube's algorithm-driven homepage feed**,
so that **I see only my subscriptions, playlists, and saved content without algorithmic recommendations**.

**Acceptance Criteria:**
1. Settings > Focus Mode > "Hide Homepage Feed" toggle
2. When enabled, YouTube homepage feed (Recommended, Trending) hidden in YouTube section of sidebar
3. Subscriptions, Playlists, Watch History remain visible (user-controlled content only)
4. Empty state in YouTube section: "Focus Mode active. Browse your subscriptions or use search."
5. "Browse YouTube Homepage" button available to temporarily disable (opens YouTube web in browser if needed)
6. Setting applies to in-app YouTube browsing (if applicable)
7. UI test verifies homepage feed hidden, subscriptions visible

## Story 4.6: Focus Mode Scheduling (Pro Feature)

As a **Pro user**,
I want **to schedule Focus Mode to activate automatically during specific times**,
so that **I maintain focused viewing habits during work hours without manual toggling**.

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

## Story 4.7: Distraction Hiding Presets

As a **user**,
I want **predefined presets for common distraction hiding configurations**,
so that **I can quickly switch between different focus levels without configuring each setting**.

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

---

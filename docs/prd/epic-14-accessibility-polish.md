# Epic 14: Accessibility & Polish

**Goal:** Ensure the app is fully accessible to users with disabilities (VoiceOver support, keyboard-only operation, high-contrast themes) and polished with smooth animations, loading states, empty states, and error handling. This epic elevates the app from functional to delightful, meeting Apple's accessibility standards and user experience expectations.

## Story 14.1: VoiceOver Support for All UI Elements

As a **user relying on VoiceOver**,
I want **all UI elements properly labeled and navigable**,
so that **I can use the app independently**.

**Acceptance Criteria:**
1. All buttons, links, and interactive elements have descriptive accessibility labels (e.g., "Play video", not "Button")
2. Video thumbnails include labels: "Video: {title}, {duration}, {channel}"
3. Custom controls (e.g., seek slider) implement accessibility protocols (`NSAccessibility` for macOS)
4. Focus order logical: top-to-bottom, left-to-right within sections
5. Modal dialogs trap focus (Tab cycles within dialog, Escape dismisses)
6. Dynamic content changes announced: "Search returned 12 results", "Video added to collection"
7. VoiceOver testing conducted with real screen reader users (recruit from accessibility community)

## Story 14.2: Keyboard-Only Navigation

As a **power user or accessibility user**,
I want **complete keyboard-only operation**,
so that **I can use the app without a mouse**.

**Acceptance Criteria:**
1. Tab key navigates through all interactive elements in logical order
2. Shift+Tab navigates backwards
3. Enter/Space activates buttons and links
4. Arrow keys navigate lists and grids
5. Escape dismisses modals, popovers, and cancels actions
6. Focus indicators visible: selected item highlighted with system accent color
7. "Keyboard-only mode" tested: unplug mouse, complete all user workflows

## Story 14.3: High-Contrast Theme

As a **user with visual impairments**,
I want **a high-contrast theme option**,
so that **I can read text and see controls clearly**.

**Acceptance Criteria:**
1. "High Contrast" toggle in Settings > Accessibility
2. High-contrast theme increases contrast ratios: 4.5:1 for body text, 3:1 for large text (WCAG AA)
3. Colors adjusted: darker text on lighter backgrounds, thicker borders, larger focus indicators
4. System high-contrast preference respected: if macOS "Increase Contrast" enabled, app follows automatically
5. High-contrast theme tested with contrast checker tool (e.g., Stark, Color Oracle)
6. All UI elements remain functional and readable in high-contrast mode
7. Theme persists across app restarts (stored in UserDefaults)

## Story 14.4: Loading States & Progress Indicators

As a **user**,
I want **clear feedback when the app is loading data**,
so that **I know the app is working and not frozen**.

**Acceptance Criteria:**
1. Loading spinners shown during: API calls, embedding generation, search queries, video loading
2. Progress bars shown for long operations: importing 100+ videos, generating embeddings for library, exporting notes
3. Skeleton screens used while content loads (e.g., placeholder thumbnails in grid)
4. "Cancel" button available for cancelable operations (e.g., import, export)
5. Loading states don't block entire UI: show partial results while background tasks run
6. Error states handled: if loading fails, show "Retry" button and error message
7. No blank screens: always show loading indicator or empty state

## Story 14.5: Empty States with Helpful Messaging

As a **user**,
I want **helpful messages when sections are empty**,
so that **I understand what to do next**.

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

## Story 14.6: Smooth Animations & Transitions

As a **user**,
I want **smooth animations and transitions**,
so that **the app feels polished and responsive**.

**Acceptance Criteria:**
1. View transitions animated: fade or slide when switching between library/search/collections
2. Hover effects on interactive elements: thumbnails scale slightly on hover, buttons lighten on hover
3. List/grid insertions animated: new videos fade in when added
4. Modal dialogs animate in/out (scale + fade)
5. Reduced motion respected: if macOS "Reduce Motion" enabled, use simple fades instead of complex animations
6. Animations fast enough to feel responsive (100-300ms duration, not too slow)
7. No janky animations: maintain 60 FPS during transitions (tested with Instruments)

---

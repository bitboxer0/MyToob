# Epic 10: Collections & Organization

**Goal:** Enable users to create custom collections (folders) for manual video organization, with drag-and-drop support, bulk actions, and AI-suggested tags. This epic provides the manual curation tools that complement AI auto-collections, giving users full control over their library structure.

## Story 10.1: Create & Manage Collections

As a **user**,
I want **to create named collections to organize my videos**,
so that **I can group related content for easy access**.

**Acceptance Criteria:**
1. "New Collection" button in sidebar under "Collections" section
2. Clicking button shows dialog: "Collection Name" text field + Create/Cancel buttons
3. Collection created in SwiftData with: `name`, `createdAt`, `updatedAt`, `itemCount`, `isAutomatic = false`
4. New collection appears in sidebar under "Collections" section
5. Collection names must be unique (validation error if duplicate)
6. "Rename Collection" context menu action (shows same dialog, updates name)
7. "Delete Collection" context menu action (confirmation dialog: "Delete collection 'Name'? Videos will not be deleted.")
8. Deleted collections removed from sidebar, videos remain in library

## Story 10.2: Add Videos to Collections

As a **user**,
I want **to add videos to collections via drag-and-drop or context menu**,
so that **I can organize content efficiently**.

**Acceptance Criteria:**
1. **Drag-and-drop:** Drag video thumbnail from content area to collection in sidebar, video added to collection
2. **Context menu:** Right-click video → "Add to Collection" → select collection from submenu
3. **Multi-select:** Select multiple videos (Shift+click or Cmd+click), add all to collection in one action
4. Video can belong to multiple collections (many-to-many relationship)
5. Visual feedback: collection highlights on drag-over, shows "+" icon on drop
6. "Already in collection" handled gracefully: no error, video not duplicated
7. Collections show updated video count immediately after add

## Story 10.3: Collection Detail View

As a **user**,
I want **to view all videos in a collection**,
so that **I can browse and manage collection contents**.

**Acceptance Criteria:**
1. Clicking collection in sidebar loads collection detail view in main content area
2. Detail view shows: collection name (editable), description (optional text field), video count, creation date
3. Videos displayed in grid/list (same layout as library view)
4. Videos reorderable via drag-and-drop within collection (custom sort order)
5. "Remove from Collection" action on individual videos (right-click menu or delete key)
6. "Play All" button starts playback queue of all videos in collection
7. Empty collection shows: "This collection is empty. Drag videos here to add them."

## Story 10.4: Collection Export to Markdown

As a **user**,
I want **to export a collection as a Markdown file with video links and notes**,
so that **I can share or archive my research collections**.

**Acceptance Criteria:**
1. "Export Collection..." button in collection detail view
2. Clicking button shows save dialog (file picker, default filename: "CollectionName.md")
3. Exported Markdown includes: collection name as H1, description (if present), video list with YouTube links or local file paths, timestamps, notes (if any)
4. Format example:
   ```
   # Swift Concurrency Tutorials

   Collection of resources for learning Swift concurrency.

   ## Videos

   1. **Understanding async/await** ([Watch on YouTube](https://youtube.com/watch?v=abc123))
      - Duration: 15:30
      - Added: 2024-01-15
      - Notes: Great explanation of task cancellation

   2. **Local Tutorial.mp4** (file:///Users/...)
      - Duration: 22:10
   ```
5. Export succeeds with confirmation: "Collection exported to [path]"
6. Exported file opens in default Markdown viewer (optional)

## Story 10.5: AI-Suggested Tags

As a **user**,
I want **AI-suggested tags for videos based on content**,
so that **I can quickly apply relevant labels without manual typing**.

**Acceptance Criteria:**
1. "Suggested Tags" shown in video detail view (below title/description)
2. Tags generated from: cluster membership (cluster label keywords), frequent keywords in similar videos, metadata analysis
3. Tags displayed as chips/pills (clickable)
4. Clicking suggested tag applies it to video (adds to `VideoItem.aiTopicTags`)
5. Applied tags shown separately from suggestions (visual distinction)
6. "Dismiss" button on suggested tags (removes suggestion, doesn't apply tag)
7. Suggestions refreshed when AI model or clustering updates

## Story 10.6: Bulk Operations on Multiple Videos

As a **user**,
I want **to perform actions on multiple selected videos at once**,
so that **I can manage large collections efficiently**.

**Acceptance Criteria:**
1. Multi-select supported: Shift+click (range select), Cmd+click (individual select)
2. Selection shown visually (checkmarks or highlighted borders on thumbnails)
3. Bulk actions available: "Add to Collection", "Remove from Collection", "Add Tag", "Mark as Watched", "Delete"
4. Bulk action confirmation dialog: "Add 15 videos to 'Swift Tutorials'?"
5. Bulk operations atomic: all succeed or all fail (rollback on error)
6. Progress indicator for slow bulk operations (e.g., deleting 1000 videos)
7. "Select All" / "Deselect All" actions (keyboard shortcuts: Cmd+A, Escape)

---

# Epic 11: Research Tools & Note-Taking

**Goal:** Provide integrated note-taking capabilities with timestamp anchors, Markdown support, bidirectional links, and export functionality. This epic transforms the app from a video player into a research tool, enabling knowledge workers to annotate, cite, and build knowledge bases from video content.

## Story 11.1: Inline Note Editor for Videos

As a **user**,
I want **to take notes directly within the video detail view**,
so that **I can capture insights while watching**.

**Acceptance Criteria:**
1. Video detail view shows note editor panel (below or beside video player)
2. Note editor supports Markdown formatting: headings, bold, italic, lists, code blocks
3. Markdown preview toggle (show formatted output vs. raw Markdown)
4. Note autosaved every 5 seconds or on focus loss
5. Notes stored in `Note` model with relationship to `VideoItem`
6. Multiple notes per video supported (user can create "New Note" button)
7. Note editor accessible via keyboard shortcut: ⌘N (while viewing video)

## Story 11.2: Timestamp-Anchored Notes

As a **user**,
I want **to link notes to specific video timestamps**,
so that **I can jump to relevant moments when reviewing notes**.

**Acceptance Criteria:**
1. "Insert Timestamp" button in note editor (or keyboard shortcut: ⌘T)
2. Clicking button inserts current video playback time into note: `[15:30]` (MM:SS format)
3. Timestamp rendered as clickable link in Markdown preview
4. Clicking timestamp seeks video to that time and starts playback
5. Timestamps shown in sidebar "Notes" list with preview text
6. Notes automatically sorted by first timestamp (chronological order within video)
7. Timestamp format respects video length (HH:MM:SS for videos >1 hour)

## Story 11.3: Bidirectional Links Between Notes

As a **user**,
I want **to link notes to each other using wiki-style links**,
so that **I can build a connected knowledge graph**.

**Acceptance Criteria:**
1. Wiki-link syntax supported: `[[Note Title]]` or `[[Video Title > Note]]`
2. Typing `[[` shows autocomplete dropdown with matching note/video titles
3. Links rendered as clickable in Markdown preview
4. Clicking link navigates to linked note/video
5. "Backlinks" section in note editor shows notes that link to current note
6. Orphaned links (linking to non-existent notes) shown in different color (red or gray)
7. "Create Note from Link" action on orphaned links (creates new note with that title)

## Story 11.4: Note Search & Filtering

As a **user**,
I want **to search across all notes to find specific content**,
so that **I can quickly locate information from past research**.

**Acceptance Criteria:**
1. "Search Notes" tab or filter in main search bar
2. Query matches note content (full-text search on Markdown text)
3. Search highlights matching terms in note previews
4. Filter by: note creation date, associated video, tags
5. Results show note preview with context (2 lines before/after match)
6. Clicking result opens video detail view with note visible
7. "Recent Notes" view shows last 20 edited notes for quick access

## Story 11.5: Note Export & Citation

As a **user**,
I want **to export notes in Markdown format with video citations**,
so that **I can use my research in other tools or publications**.

**Acceptance Criteria:**
1. "Export Notes..." button in video detail view or Settings
2. Export single video's notes or all notes (global export)
3. Exported Markdown includes: note content, video title/link, timestamps, creation date
4. Citation format configurable: YouTube format (APA/MLA/Chicago), local file path, or custom
5. Example exported note:
   ```
   # Understanding async/await (Video Notes)

   **Source:** [Watch on YouTube](https://youtube.com/watch?v=abc123)
   **Date Watched:** 2024-01-15

   ## Key Concepts

   - Task cancellation explained at [15:30]
   - Error handling patterns at [22:45]
   ```
6. Export format options: Markdown (.md), Plain Text (.txt), PDF (optional)
7. Export success notification: "Notes exported to [path]"

## Story 11.6: Note Templates (Pro Feature)

As a **Pro user**,
I want **predefined note templates for common research patterns**,
so that **I can take structured notes efficiently**.

**Acceptance Criteria:**
1. "Templates" dropdown in note editor (Pro users only)
2. Built-in templates: "Video Summary", "Key Takeaways", "Quote + Reflection", "Meeting Notes"
3. Template inserts structured Markdown into note editor:
   ```
   ## Video Summary

   **Main Topic:**

   **Key Points:**
   -

   **Action Items:**
   -
   ```
4. User can create custom templates (saved in Settings)
5. Templates support variables: `{video_title}`, `{current_time}`, `{today_date}`
6. Template selection dialog shows preview of template structure
7. Free users see "Unlock templates with Pro" message in dropdown

---

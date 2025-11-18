# Epic 9: Hybrid Search & Discovery UX

**Goal:** Create a unified search interface that combines keyword matching (traditional search) with vector similarity (semantic search), providing filter pills for faceted search and ranked results optimized for relevance. This epic delivers the primary content discovery mechanism, enabling users to find videos quickly and accurately regardless of search style.

## Story 9.1: Search Bar & Query Input

As a **user**,
I want **a prominent search bar at the top of the window**,
so that **I can quickly search my video library**.

**Acceptance Criteria:**
1. Search bar positioned in toolbar (top of window, always visible)
2. Search bar placeholder text: "Search videos..." or "Search by title, topic, or description..."
3. Search activates on Return key press or after 500ms debounce (user stops typing)
4. Search input cleared with "X" button when text present
5. Search history (recent queries) shown in dropdown below search bar (optional, Pro feature)
6. Keyboard shortcut: ⌘F focuses search bar
7. Search works in all views (YouTube library, local files, collections)

## Story 9.2: Keyword Search Implementation

As a **developer**,
I want **keyword search that matches titles, descriptions, and tags**,
so that **users can find videos using traditional exact-match search**.

**Acceptance Criteria:**
1. Query tokenized into keywords (split by whitespace, remove stop words)
2. Each keyword matched against `VideoItem.title`, `.description`, `.aiTopicTags` using case-insensitive substring match
3. Results ranked by number of keyword matches (more matches = higher rank)
4. Exact phrase matching supported: query in quotes "swift concurrency" matches exact phrase
5. Boolean operators supported (optional, advanced): "swift AND concurrency", "tutorial OR guide"
6. Search completes in <100ms for 10,000-video library
7. Unit tests verify keyword matching with various query patterns

## Story 9.3: Vector Similarity Search Integration

As a **developer**,
I want **vector similarity search for natural language queries**,
so that **users can search by concept even if exact keywords don't match**.

**Acceptance Criteria:**
1. Query converted to embedding using Core ML model (same as Story 6.1)
2. Query embedding used to search HNSW index for top-20 nearest neighbors (same as Story 6.6)
3. Vector search results include similarity scores (cosine similarity, 0-1 range)
4. Vector search completes in <50ms (same latency target as keyword search)
5. Empty query handled: don't run vector search (fall back to showing all videos or recents)
6. Unit tests verify vector search returns semantically similar results (e.g., "async programming" matches "concurrency tutorials")

## Story 9.4: Hybrid Search Result Fusion

As a **developer**,
I want **keyword and vector search results combined intelligently**,
so that **users get best-of-both-worlds: exact matches and semantic relevance**.

**Acceptance Criteria:**
1. Hybrid search runs both keyword and vector search in parallel
2. Results merged using reciprocal rank fusion (RRF): score = 1/(k + keyword_rank) + 1/(k + vector_rank), k=60
3. Final results sorted by fused score (higher = better)
4. De-duplication: if same video in both result sets, use single entry with combined score
5. Top-100 results returned (reasonable limit for UI display)
6. "Search Mode" toggle in UI: "Smart" (hybrid, default), "Keyword" (exact match), "Semantic" (vector only)
7. Unit tests verify RRF scoring with sample result sets

## Story 9.5: Filter Pills for Faceted Search

As a **user**,
I want **filter pills to narrow search results by duration, date, source, and topic**,
so that **I can refine searches without complex query syntax**.

**Acceptance Criteria:**
1. Filter pills shown below search bar when search active: "Duration", "Date", "Source", "Topic"
2. **Duration filter:** Short (<5min), Medium (5-20min), Long (>20min)
3. **Date filter:** Today, This Week, This Month, This Year, Custom Range
4. **Source filter:** YouTube, Local Files, Specific Channel (dropdown)
5. **Topic filter:** Select from cluster labels (multi-select)
6. Filters applied cumulatively (AND logic): "Long + This Month + Swift Concurrency"
7. Active filters shown as dismissible pills (click X to remove)
8. Filter state persists during session (cleared on new query or app restart)
9. Filters applied after search fusion (filter final result set, not individual search results)

## Story 9.6: Search Results Display & Ranking

As a **user**,
I want **search results displayed in a clear, scannable layout with relevance indicators**,
so that **I can quickly identify the best matches**.

**Acceptance Criteria:**
1. Search results shown in main content area as grid or list (user preference in Settings)
2. Each result shows: thumbnail, title, channel/source, duration, relevance score (optional: show % match)
3. Query terms highlighted in title and description (bold or background color)
4. Results sorted by fused score (highest relevance first)
5. Pagination or infinite scroll if >100 results (load more on scroll)
6. Empty results state: "No videos found for 'query'. Try a different search or remove filters."
7. Result click opens video detail view or starts playback
8. "Related Videos" section below each result (optional, shows vector-similar videos)

---

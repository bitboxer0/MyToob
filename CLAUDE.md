# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyToob is a native macOS video client that organizes and discovers YouTube videos (via official IFrame Player) and local video files using on-device AI. The app is privacy-first, App Store-compliant, and operates with YouTube's IFrame Player API rather than downloading streams.

**Key Compliance Boundaries:**
- YouTube playback uses IFrame Player in WKWebView only (no stream extraction/caching)
- No ad-blocking, ad-skipping, or DOM manipulation of YouTube player UI
- AI analysis limited to metadata, thumbnails, and user interactions for YouTube content
- Full computer vision/ASR allowed only for local files
- Two distributions: App Store SKU (strict compliance) and notarized DMG (power-user features)

## Build & Development Commands

> **📘 Complete Xcode Setup:** See [docs/XCODE_SETUP.md](docs/XCODE_SETUP.md) for comprehensive Xcode configuration, entitlements, signing, and troubleshooting.

### Building the App
```bash
# Open in Xcode
open MyToob.xcodeproj

# Build from command line (via xcodebuild MCP or direct)
xcodebuild -project MyToob.xcodeproj -scheme MyToob -destination 'platform=macOS' build

# Clean build
xcodebuild -project MyToob.xcodeproj -scheme MyToob clean
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project MyToob.xcodeproj -scheme MyToob -destination 'platform=macOS'

# Run specific test target
xcodebuild test -project MyToob.xcodeproj -scheme MyToob -only-testing:MyToobTests

# Run UI tests only
xcodebuild test -project MyToob.xcodeproj -scheme MyToob -only-testing:MyToobUITests
```

### Code Quality
When lint/format tools are added:
```bash
# SwiftLint (when configured)
swiftlint lint
swiftlint --fix

# swift-format (when configured)
swift-format lint --recursive MyToob/
swift-format format --in-place --recursive MyToob/
```

## Architecture

### Data Layer (SwiftData + CloudKit)

The app uses SwiftData for local persistence with CloudKit sync for user data. Core models from IdeaDoc.md:

**VideoItem** - Represents both YouTube and local videos
- `videoID: String?` - YouTube video ID (nil for local files)
- `localURL: URL?` - File URL for local videos
- `title, channelID, duration, watchProgress`
- `embedding: [Float]?` - 384-dimensional vector for semantic search
- `aiTopicTags: [String]` - AI-generated topic labels
- `isLocal: Bool` - Distinguishes YouTube vs local content

**ClusterLabel** - AI-generated topic clusters
- Groups semantically similar videos
- Generated via kNN graph + Leiden/Louvain community detection

**ChannelBlacklist** - User content moderation
- Hide/block specific YouTube channels

### Playback Architecture

**YouTube Playback (IFrame Player + WKWebView)**
- Load YouTube IFrame Player inside WKWebView
- JavaScript bridge for play/pause/seek controls
- State/time event handling via JS↔Swift messaging
- **Critical:** No overlays that obscure player UI or ads
- Picture-in-Picture via player/OS support (no DOM hacks)

**Local File Playback (AVKit)**
- AVPlayerView for local video files
- Standard transport controls, scrubbing, snapshots
- Full CV/ASR pipeline allowed (YouTube: metadata only)

### AI Pipeline (On-Device Only)

**Embeddings Generation**
- Core ML sentence embedding model (~384-dim, 8-bit quantized)
- Sources for YouTube: title + description + thumbnail OCR text (no video frames)
- Sources for local: full frame-level CV/ASR allowed

**Vector Search & Retrieval**
- HNSW index persisted in SwiftData
- Hybrid search: keyword + vector similarity
- Delta updates for new content

**Clustering & Organization**
- Build kNN graph from embeddings
- Leiden/Louvain community detection for topic clusters
- Auto-generate cluster labels via keyword extraction

**Ranking**
- Gradient-boosted tree model (Core ML)
- Features: recency, similarity, dwell time, completion %, diversity

### YouTube Data API Integration

**Quota Management**
- Default quota: 10,000 units/day
- search.list = 100 units, videos.list = 1 unit
- Use ETags + If-None-Match for cache validation
- Field filtering to minimize payload size
- Circuit breaker on 429 errors with exponential backoff

**OAuth Flow**
- Minimal scopes (e.g., youtube.readonly)
- Keychain storage for refresh tokens
- Token rotation for security

### Compliance Guardrails

**Policy Enforcement**
- Lint rules to block direct `googlevideo.com` access
- Playback pauses when window is hidden (PiP exception)
- No caching of YouTube video/audio streams (metadata/thumbnails only)

**UGC Safeguards (App Store Guideline 1.2)**
- Report content link (deep-link to YouTube's reporting UI)
- Channel hide/blacklist functionality
- Visible content policy and support contact

**Branding (YouTube Guidelines)**
- No "YouTube" in app name or icon
- "Not affiliated with YouTube" disclaimer
- Attribution per YouTube branding requirements

## Directory Structure

```
MyToob/
├── MyToob/                    # Main app target
│   ├── MyToobApp.swift       # App entry point with SwiftData container
│   ├── ContentView.swift     # Placeholder UI (to be replaced)
│   ├── Item.swift            # Placeholder model (to be replaced with VideoItem)
│   └── Assets.xcassets/      # App icons and assets
├── MyToobTests/              # Unit tests
├── MyToobUITests/            # UI tests
└── IdeaDoc.md               # Comprehensive PRD and technical spec
```

## Implementation Phases

Work is organized into epics (see IdeaDoc.md for complete details):

1. **Epic A** - Repo setup, CI/CD, MCP workflows
2. **Epic B** - OAuth & YouTube Data API (metadata only)
3. **Epic C** - Playback layer (IFrame + AVKit)
4. **Epic D** - Storage & caching (metadata/embeddings only)
5. **Epic E** - On-device AI (embeddings, search, clustering, ranking)
6. **Epic F** - Search, discovery & organization UX
7. **Epic G** - macOS integrations (Spotlight, App Intents, keyboard shortcuts)
8. **Epic H** - Privacy, security, UGC safeguards
9. **Epic I** - Network resilience & quota management
10. **Epic J** - Observability & QA
11. **Epic K** - Accessibility & internationalization
12. **Epic L** - App Store readiness & DMG distribution
13. **Epic M** - Monetization (freemium with Pro unlock)
14. **Epic N** - Documentation & support

## Critical Development Rules

### YouTube Content Handling
- **Never** download, cache, or prefetch YouTube video/audio bytes
- **Never** manipulate the IFrame Player DOM to remove ads or branding
- **Always** use IFrame Player API for playback controls
- **Only** run AI analysis on metadata, thumbnails, and user interactions

### Local File Handling
- Full frame-level analysis (CV/ASR) permitted
- AVKit for playback
- File access via user-selected bookmarks (sandbox compliance)

### Data Privacy
- All AI processing on-device via Core ML
- CloudKit sync for user data only (opt-in)
- No external analytics without explicit user consent
- "Data Not Collected" privacy label where applicable

### Testing Requirements
- Unit tests for models, stores, API client, ranker features
- UI tests for IFrame bridge (play/pause/seek state changes)
- Migration tests for SwiftData schema changes
- Network failure handling (429/5xx backoff)
- Quota budget simulation tests

### Performance Targets
- Cold start to first render: < 2 seconds
- Warm start: < 500ms
- Vector search top-k retrieval: < 50ms P95 (M-series Mac)
- UI frame budget: < 16ms during background indexing
- Index build (1k items): < 5 seconds on M1

## MCP Server Tooling Guide

This project has extensive MCP server integration. Use these tools strategically for maximum efficiency.

### Build & Test Automation

#### XcodeMCP (`mcp__xcodemcp__*`)
**Primary tool for all Xcode operations.** Prefer this over raw xcodebuild commands.

**Essential Operations:**
```swift
// Open project
xcode_open_project(xcodeproj: "/path/to/MyToob.xcodeproj")

// Build
xcode_build(xcodeproj: "...", scheme: "MyToob", destination: "platform=macOS")

// Run tests (can take minutes - don't timeout)
xcode_test(xcodeproj: "...", destination: "iPhone 15 Pro Simulator")

// Run specific tests
xcode_test(
  xcodeproj: "...",
  selected_tests: ["MyToobTests/VideoItemTests"],
  test_plan_path: "path/to/plan.xctestplan"
)

// Get test results
find_xcresults(xcodeproj: "...")
xcresult_browse(xcresult_path: "...", test_id: "1")
xcresult_get_screenshot(xcresult_path: "...", test_id: "1", timestamp: 30.69)
```

**When to Use:**
- Building the app before running or testing
- Running unit/UI tests with detailed failure analysis
- Extracting screenshots/logs from test failures
- Getting available schemes and destinations

**Pro Tips:**
- Always specify `destination` for predictable test environments
- Use `xcresult_browse` to analyze test failures (includes console output, screenshots, UI hierarchy)
- For UI test failures, use `xcresult_get_screenshot` with timestamp BEFORE the failure
- Check available schemes with `xcode_get_schemes` before building

#### IDE Integration (`mcp__ide__*`)
**VS Code language diagnostics and Jupyter execution.**

```swift
// Get Swift/Xcode diagnostics
getDiagnostics(uri: "file:///path/to/MyToob/ContentView.swift")

// Execute code in Jupyter (for notebooks)
executeCode(code: "print('test')")
```

**When to Use:**
- Checking for compiler errors/warnings without full build
- Running quick code validation
- Notebook-based experimentation (if using Jupyter for prototyping)

### Code Intelligence & Navigation

#### Serena (`mcp__serena__*`)
**Primary tool for semantic code navigation and refactoring.** Most powerful for understanding Swift code structure.

**Core Workflow:**
```swift
// 1. Get file overview first (always start here for new files)
get_symbols_overview(relative_path: "MyToob/VideoItem.swift")

// 2. Find specific symbols
find_symbol(
  name_path: "VideoItem/embedding",  // class/property
  relative_path: "MyToob",           // scope to directory
  include_body: true,                // get implementation
  depth: 1                          // include nested symbols
)

// 3. Find references
find_referencing_symbols(
  name_path: "VideoItem",
  relative_path: "MyToob/VideoItem.swift"
)

// 4. Search for patterns
search_for_pattern(
  substring_pattern: "IFrame.*Player",
  restrict_search_to_code_files: true,
  paths_include_glob: "**/*.swift"
)

// 5. Edit symbols
replace_symbol_body(
  name_path: "VideoItem/__init__",
  relative_path: "MyToob/VideoItem.swift",
  body: "init() { ... }"
)

insert_after_symbol(
  name_path: "VideoItem",  // insert after this class
  relative_path: "MyToob/VideoItem.swift",
  body: "\n\nclass ClusterLabel { ... }"
)

rename_symbol(
  name_path: "Item",
  relative_path: "MyToob/Item.swift",
  new_name: "VideoItem"
)
```

**Critical Rules:**
- **ALWAYS** use `get_symbols_overview` before reading full files
- **NEVER** read entire files when symbolic tools can find what you need
- **NEVER** read the same content twice (overview then full file)
- Use `find_symbol` with `include_body: false` first, then selectively fetch bodies
- For edits, prefer symbol-based tools over regex when possible

**Name Path Matching:**
- Simple name: `"VideoItem"` - matches anywhere in any file
- Relative path: `"VideoItem/embedding"` - matches property in VideoItem class
- Absolute path: `"/VideoItem"` - matches only top-level VideoItem
- Substring matching: Set `substring_matching: true` for fuzzy name matching

**When to Use:**
- Understanding code architecture (start with overview)
- Finding class/method definitions
- Locating all references to a symbol
- Refactoring (rename, move, extract)
- Adding new methods/properties to existing classes

#### RepoPrompt (`mcp__RepoPrompt__*`)
**Workspace-level code selection and context management.** Complements Serena for multi-file work.

**Selection Management:**
```swift
// View current selection
manage_selection(op: "get", view: "files")

// Add files to selection (auto-adds related codemaps)
manage_selection(
  op: "add",
  paths: ["MyToob/VideoItem.swift", "MyToob/ClusterLabel.swift"],
  mode: "full"
)

// Add only codemaps (signatures, no bodies)
manage_selection(
  op: "add",
  paths: ["MyToob/YouTubeAPI/"],
  mode: "codemap_only"
)

// Add specific line ranges
manage_selection(
  op: "add",
  mode: "slices",
  slices: [{
    path: "MyToob/ContentView.swift",
    ranges: [{
      start_line: 45,
      end_line: 120,
      description: "IFrame Player setup"
    }]
  }]
)

// Preview before committing
manage_selection(op: "preview", view: "files")

// Clear selection
manage_selection(op: "clear")
```

**Code Structure:**
```swift
// Get codemaps (fast alternative to reading files)
get_code_structure(
  scope: "paths",
  paths: ["MyToob/Models/"],
  max_results: 25
)

// Get structure of current selection
get_code_structure(scope: "selected")
```

**Search & Navigation:**
```swift
// File tree
get_file_tree(type: "files", mode: "auto")  // Smart depth limiting
get_file_tree(type: "files", mode: "folders")  // Directories only
get_file_tree(type: "roots")  // List workspace roots

// Search
file_search(
  pattern: "YouTubeAPI.*Client",
  mode: "path",
  regex: true
)

file_search(
  pattern: "IFrame Player",
  mode: "content",
  regex: false,
  context_lines: 3
)
```

**File Operations:**
```swift
// Create/edit files
file_actions(action: "create", path: "MyToob/New.swift", content: "...")
apply_edits(path: "MyToob/File.swift", search: "old", replace: "new")

// Rewrite entire file
apply_edits(path: "MyToob/File.swift", rewrite: "...", on_missing: "create")
```

**Chat Integration:**
```swift
// Start planning chat
chat_send(
  message: "How should we structure the WKWebView bridge?",
  mode: "plan",
  new_chat: true,
  chat_name: "IFrame Player Architecture"
)

// Continue with implementation
chat_send(
  message: "Implement the JS bridge",
  mode: "edit",
  new_chat: false
)

// List available model presets
list_models()
```

**When to Use:**
- Managing context across multiple files (avoid loading unnecessary files)
- Working with related files (selection auto-adds dependencies)
- Getting high-level code structure without reading bodies
- Planning multi-file changes with chat mode
- Searching across the codebase (faster than Grep for large codebases)

**Pro Tips:**
- Use `mode: "codemap_only"` for context without full file content (saves tokens)
- Always `preview` selection before large operations
- Use `slices` for focused context on specific functionality
- Chat `mode: "plan"` before `mode: "edit"` for complex tasks

#### Filesystem (`mcp__filesystem__*`)
**Low-level file operations.** Use when Serena/RepoPrompt aren't sufficient.

```swift
// Read files
read_text_file(path: "MyToob/Config.json")
read_multiple_files(paths: ["File1.swift", "File2.swift"])

// Directory operations
list_directory(path: "MyToob/Models")
directory_tree(path: "MyToob")

// File management
write_file(path: "MyToob/New.swift", content: "...")
edit_file(path: "MyToob/File.swift", edits: [{oldText: "...", newText: "..."}])
move_file(source: "old.swift", destination: "new.swift")

// Search
search_files(path: "MyToob", pattern: "*.swift", excludePatterns: ["*Test*"])
```

**When to Use:**
- Reading non-code files (JSON, plist, markdown)
- Bulk file operations
- Directory structure exploration
- When you need explicit file system control

### Research & Documentation

#### Apple Docs MCP (`mcp__apple-docs-mcp__*`)
**Essential for iOS/macOS development.** Comprehensive Apple documentation access.

**Documentation Search:**
```swift
// Search for APIs
search_apple_docs(
  query: "WKWebView JavaScript",
  type: "documentation"  // or "sample" for code examples
)

// Get full documentation
get_apple_doc_content(
  url: "https://developer.apple.com/documentation/webkit/wkwebview",
  includeRelatedApis: true,
  includePlatformAnalysis: true
)
```

**Framework Discovery:**
```swift
// Browse all frameworks
list_technologies(category: "App frameworks")

// Explore framework APIs
search_framework_symbols(
  framework: "webkit",
  symbolType: "class",
  namePattern: "WK*"
)
```

**WWDC Content:**
```swift
// Find WWDC sessions
list_wwdc_videos(
  year: "2025",
  topic: "swiftui-ui-frameworks",
  hasCode: true
)

// Search transcripts
search_wwdc_content(
  query: "WKWebView security",
  searchIn: "both"
)

// Get full session
get_wwdc_video(
  year: "2024",
  videoId: "10101",
  includeTranscript: true,
  includeCode: true
)
```

**When to Use:**
- Learning new APIs (WKWebView, AVKit, Core ML)
- Finding implementation examples
- Understanding platform compatibility
- Discovering related APIs
- Researching WWDC best practices

**Pro Tips for This Project:**
- Search "WKWebView JavaScript bridge" for IFrame Player integration
- Look up "AVPlayerView" for local file playback
- Research "Core ML embeddings" for AI pipeline
- Find "SwiftData CloudKit sync" examples
- Check "App Store submission guidelines" for compliance

#### Context7 (`mcp__context7__*` / `mcp__context7-mcp__*`)
**Third-party library documentation.** Use for dependencies.

```swift
// Find library
resolve-library-id(libraryName: "Alamofire")

// Get documentation
get-library-docs(
  context7CompatibleLibraryID: "/alamofire/alamofire",
  topic: "authentication",
  page: 1
)
```

**When to Use:**
- Integrating third-party Swift packages
- Understanding dependency APIs
- Finding usage examples for libraries

#### OctoCode MCP (`mcp__octocode-mcp__*`)
**GitHub code research.** Search public repositories for implementation patterns.

**Progressive Research Workflow:**
```swift
// 1. Discover repositories
githubSearchRepositories(queries: [{
  topicsToSearch: ["wkwebview", "youtube-player"],
  stars: ">500"
}])

// 2. Explore structure
githubViewRepoStructure(queries: [{
  owner: "owner",
  repo: "repo",
  branch: "main",
  path: "",
  depth: 1
}])

// 3. Search code
githubSearchCode(queries: [{
  owner: "owner",
  repo: "repo",
  keywordsToSearch: ["WKWebView", "evaluateJavaScript"],
  match: "file",
  limit: 5
}])

// 4. Read implementation
githubGetFileContent(queries: [{
  owner: "owner",
  repo: "repo",
  path: "Sources/Player.swift",
  matchString: "evaluateJavaScript"
}])
```

**When to Use:**
- Finding reference implementations (WKWebView YouTube players)
- Learning patterns from successful apps
- Discovering edge cases and solutions
- Research before implementing novel features

**Pro Tips:**
- Search for "swift youtube iframe player" repos
- Look for "swiftui avkit" examples
- Find "core ml embeddings swift" implementations
- Research "swiftdata cloudkit sync" patterns

### Knowledge & Memory

#### Memory MCP (`mcp__memory-mcp__*`)
**Persistent knowledge graph.** Store insights across sessions.

```swift
// Create entities
create_entities(entities: [{
  name: "YouTubeIFramePlayer",
  entityType: "Component",
  observations: [
    "Uses WKWebView with JavaScript bridge",
    "Must not obscure ads or player UI",
    "Supports play/pause/seek via evaluateJavaScript"
  ]
}])

// Create relationships
create_relations(relations: [{
  from: "ContentView",
  to: "YouTubeIFramePlayer",
  relationType: "contains"
}])

// Search knowledge
search_nodes(query: "WKWebView compliance")

// Read specific nodes
open_nodes(names: ["YouTubeIFramePlayer"])
```

**When to Use:**
- Storing architectural decisions
- Recording compliance boundaries
- Documenting API quota strategies
- Tracking implementation patterns
- Building project knowledge base

**Recommended Entities for This Project:**
- `YouTubeComplianceRules` - App Store & YouTube ToS requirements
- `VideoItemModel` - SwiftData schema and relationships
- `IFramePlayerBridge` - JavaScript bridge implementation
- `QuotaManagement` - API quota budgeting strategy
- `AIProcessingPipeline` - Core ML embedding pipeline

#### Sequential Thinking (`mcp__sequential-thinking__*`)
**Structured problem-solving.** Use for complex architectural decisions.

```swift
sequentialthinking(
  thought: "Need to decide WKWebView vs UIWebView for YouTube player",
  thoughtNumber: 1,
  totalThoughts: 5,
  nextThoughtNeeded: true
)
```

**When to Use:**
- Planning complex features (IFrame bridge, AI pipeline)
- Debugging multi-step issues
- Architectural decision-making
- Breaking down epics into tasks

### Strategic Tool Selection

**For Code Understanding:**
1. **Start:** `serena.get_symbols_overview` (fastest)
2. **Navigate:** `serena.find_symbol` with `include_body: false`
3. **Read:** Selectively fetch bodies or use `RepoPrompt.manage_selection`
4. **Never:** Read full files without checking overview first

**For Implementation:**
1. **Research:** `apple-docs-mcp` or `octocode-mcp` for patterns
2. **Plan:** `RepoPrompt.chat_send` with `mode: "plan"`
3. **Code:** `serena` symbol edits or `RepoPrompt.apply_edits`
4. **Test:** `xcodemcp.xcode_test` with result analysis
5. **Document:** `memory-mcp` to record decisions

**For Building/Testing:**
1. **Always:** Use `xcodemcp` instead of raw xcodebuild
2. **Test failures:** Use `xcresult_browse` and `xcresult_get_screenshot`
3. **Diagnostics:** Use `ide.getDiagnostics` for quick checks

**For Documentation Research:**
1. **Apple APIs:** `apple-docs-mcp` (first choice for iOS/macOS)
2. **WWDC:** `apple-docs-mcp.search_wwdc_content` for best practices
3. **Third-party:** `context7` for library docs
4. **Examples:** `octocode-mcp` for real-world code

**Token Optimization:**
- Use `RepoPrompt.manage_selection` with `mode: "codemap_only"` for API signatures
- Use `serena.get_symbols_overview` instead of reading full files
- Use `get_code_structure` for high-level understanding
- Use slices for focused context on specific functionality

## MCP Workflows

The `.mcp.json` configuration wires up:
- **workflows-mcp-server** - Task automation (bootstrap, build, test, release)
- **xcodebuild-mcp** - Xcode build/test operations
- **repoprompt-mcp** - Repository context and code search
- **memory-mcp** - Knowledge persistence across sessions

Suggested workflows (defined in `.workflows/` when implemented):
- `bootstrap_repo` - Initialize project structure, entitlements, CI
- `add_youtube_oauth` - OAuth flow with Keychain storage
- `iframe_player_bridge` - WKWebView + JS bridge setup
- `swiftdata_schema_v1` - Implement VideoItem, ClusterLabel models
- `embeddings_coreml_setup` - Core ML model integration
- `vector_index_hnsw` - HNSW index implementation
- `clustering_graph` - kNN + Leiden/Louvain clustering
- `hybrid_search` - Keyword + vector search UI
- `ugc_safeguards` - Report/hide/contact UGC controls

## References

All critical compliance documentation is linked in IdeaDoc.md:
- [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference)
- [YouTube API Services Terms & Developer Policies](https://developers.google.com/youtube/terms/developer-policies)
- [YouTube Data API Quota Costs](https://developers.google.com/youtube/v3/determine_quota_cost)
- [YouTube Branding Guidelines](https://developers.google.com/youtube/terms/branding-guidelines)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Core ML Documentation (for on-device ML implementation)

## Current State

The project is in initial scaffolding phase:
- Xcode project created with SwiftData integration
- Placeholder models (`Item`) to be replaced with production models (`VideoItem`, etc.)
- Basic ContentView to be replaced with full YouTube + local file UI
- Test targets configured but empty

**Next Steps:** Implement Epic A (repo setup, CI/CD, coding standards) before beginning feature work.

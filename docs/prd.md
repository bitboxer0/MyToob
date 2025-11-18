# MyToob Product Requirements Document (PRD)

## Goals and Background Context

### Goals

- Deliver a **native macOS video organization application** that combines YouTube integration and local file management with on-device AI capabilities
- Achieve **100% compliance** with YouTube Terms of Service and App Store Guidelines to enable successful App Store distribution
- Provide **tangible independent value** beyond a simple wrapper through AI-powered search, clustering, and research tools
- Ensure **privacy-first architecture** where all AI processing happens on-device using Core ML
- Create a **freemium monetization model** with basic features free and Pro tier for advanced AI/research capabilities
- Establish **dual distribution channels**: App Store build (strict compliance) and notarized DMG (power-user features for local files)
- Achieve **performance targets**: P95 search latency <50ms, cold start <2s, smooth playback
- Build **foundation for long-term product evolution** with modular architecture supporting future enhancements

### Background Context

Video content has become a primary medium for learning, research, and knowledge work, yet existing tools fail to provide adequate organization and discovery capabilities. YouTube's web interface offers minimal organizational features beyond basic playlists, while traditional media players lack intelligence and cloud integration. Knowledge workers—researchers, students, content creators—find themselves juggling disconnected tools for viewing, organizing, and annotating video content.

MyToob addresses this gap by providing a native macOS application that unifies YouTube content (accessed via official, compliant APIs) with local video files in a single, intelligently organized interface. By leveraging on-device AI through Core ML, the app offers semantic search, automatic topic clustering, and personalized recommendations while maintaining complete user privacy—no data leaves the device except through user-controlled CloudKit sync.

The compliance-first architecture distinguishes MyToob from "YouTube downloader" apps that violate ToS. By using only the official YouTube IFrame Player for playback and the Data API for metadata, MyToob provides a sustainable, App Store-approved path forward while delivering genuine value through AI organization features that work equally well for YouTube and local content.

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-17 | 1.0 | Initial PRD created from Project Brief and IdeaDoc | BMad Master |
| 2025-11-17 | 1.1 | Added Epic 4: Focus Mode & Distraction Management (7 stories, FR75-FR82) | BMad Master |

---

## Requirements

### Functional Requirements

**Authentication & Account Management:**
- FR1: The system shall support Google OAuth authentication with minimal scopes (youtube.readonly) for YouTube API access
- FR2: The system shall securely store OAuth refresh tokens in macOS Keychain
- FR3: The system shall handle token expiration and automatic refresh without user intervention
- FR4: The system shall allow users to sign out and clear all authentication credentials

**YouTube Integration (Compliance-First):**
- FR5: The system shall use YouTube IFrame Player API exclusively for YouTube video playback
- FR6: The system shall NOT download, cache, or prefetch YouTube video or audio streams
- FR7: The system shall NOT modify, overlay, or obscure the YouTube player UI, ads, or branding
- FR8: The system shall pause YouTube playback when the player window is hidden or minimized (unless Picture-in-Picture is active)
- FR9: The system shall support Picture-in-Picture only through native player/OS capabilities (no DOM hacking)
- FR10: The system shall use YouTube Data API v3 for metadata retrieval only (title, description, thumbnails, channel info, etc.)
- FR11: The system shall implement ETag-based caching with If-None-Match headers to minimize API quota usage
- FR12: The system shall implement field filtering (part= and fields= parameters) to reduce API payload sizes
- FR13: The system shall enforce daily API quota budgets per endpoint with circuit-breaker pattern on 429 responses
- FR14: The system shall import user's YouTube subscriptions, playlists, and watch history (with appropriate OAuth scopes)

**Local Video File Management:**
- FR15: The system shall support playback of local video files (MP4, MOV, MKV, and other AVFoundation-supported formats)
- FR16: The system shall use AVKit/AVPlayerView for local file playback with full transport controls
- FR17: The system shall implement security-scoped bookmarks for persistent access to user-selected local files
- FR18: The system shall support drag-and-drop import of local video files
- FR19: The system shall persist watch progress for local files

**On-Device AI & Intelligence:**
- FR20: The system shall generate text embeddings from video metadata (title, description) using Core ML (384-dimensional vectors)
- FR21: The system shall extract text from video thumbnails using Vision framework OCR for enhanced semantic understanding
- FR22: The system shall build and maintain an HNSW (Hierarchical Navigable Small World) vector index for fast similarity search
- FR23: The system shall perform automatic topic clustering using kNN graph construction and Leiden/Louvain community detection algorithms
- FR24: The system shall auto-generate cluster labels using keyword extraction from metadata and centroid analysis
- FR25: The system shall implement a gradient-boosted tree ranking model (Core ML) with features including: recency, similarity to session intent, dwell time, completion percentage, novelty/diversity
- FR26: For YouTube videos, AI processing shall use ONLY metadata, thumbnails, and user interaction data (no frame-level stream analysis)
- FR27: For local files, the system MAY enable optional frame-level computer vision and speech recognition (explicitly marked "Local only")

**Search & Discovery:**
- FR28: The system shall provide hybrid search combining keyword matching and vector similarity
- FR29: The system shall support natural language queries for semantic search
- FR30: The system shall provide filter pills for duration, recency, channel, and cluster
- FR31: The system shall return search results ranked by the AI ranking model
- FR32: The system shall highlight query-relevant terms in search results
- FR33: The system shall provide "related videos" recommendations based on vector similarity

**Organization & Collections:**
- FR34: The system shall allow users to create custom collections/folders for organizing videos
- FR35: The system shall support drag-and-drop between collections
- FR36: The system shall provide auto-collections generated from AI clustering results
- FR37: The system shall allow users to add AI-suggested topic tags and create custom tags
- FR38: The system shall support multi-select operations (add to collection, tag, delete)

**Notes & Research Tools:**
- FR39: The system shall provide inline note-taking capabilities for each video
- FR40: The system shall support timestamp-based notes linked to specific video moments
- FR41: The system shall support Markdown formatting in notes
- FR42: The system shall provide bidirectional linking between notes
- FR43: The system shall support export of notes and collections to Markdown format
- FR44: The system shall provide citation formatting for academic use

**Data Persistence & Sync:**
- FR45: The system shall use SwiftData for local persistence of all user data (VideoItem, ClusterLabel, Note, ChannelBlacklist models)
- FR46: The system shall support versioned SwiftData schema migrations
- FR47: The system shall provide optional CloudKit sync for user data using private database
- FR48: The system shall handle CloudKit sync conflicts deterministically
- FR49: The system shall allow users to toggle CloudKit sync on/off
- FR50: The system shall cache YouTube metadata with ETag-based validation
- FR51: The system shall cache thumbnails respecting HTTP cache headers
- FR52: The system shall NOT cache YouTube video/audio streams

**UGC Safeguards (App Store Compliance):**
- FR53: The system shall provide a "Report Content" action that deep-links to YouTube's official reporting flow
- FR54: The system shall allow users to hide/blacklist channels
- FR55: The system shall provide an easily accessible Content Policy page
- FR56: The system shall provide contact/support information for user reports
- FR57: The system shall display a "Not affiliated with YouTube" disclaimer

**macOS Integration:**
- FR58: The system shall integrate with Spotlight for indexing saved videos, tags, and clusters
- FR59: The system shall provide App Intents for Shortcuts integration ("play next," "add to collection," "search cluster")
- FR60: The system shall provide a menu bar mini-controller for playback control and now-playing info
- FR61: The system shall support keyboard shortcuts for all primary actions
- FR62: The system shall provide a command palette for quick access to features
- FR63: The system shall support drag-and-drop from Finder (local files) and web browsers (YouTube URLs)

**Accessibility & Internationalization:**
- FR64: The system shall provide VoiceOver labels for all UI controls
- FR65: The system shall ensure logical focus order for keyboard navigation
- FR66: The system shall support keyboard-only operation for all core workflows
- FR67: The system shall support Dynamic Type for text scaling
- FR68: The system shall provide high-contrast theme support
- FR69: The system shall use localizable strings framework for future internationalization

**Focus Mode & Distraction Management:**
- FR75: The system shall provide a global Focus Mode toggle that hides distracting YouTube UI elements
- FR76: The system shall allow hiding of YouTube's sidebar (trending, recommended sections) with granular section control
- FR77: The system shall allow hiding of related videos panel ("Up Next" and recommendations during playback)
- FR78: The system shall allow hiding of the comments section below YouTube videos
- FR79: The system shall allow hiding of YouTube's algorithm-driven homepage feed while preserving subscriptions/playlists
- FR80: The system shall provide Focus Mode scheduling (Pro feature) with time-based auto-enable (e.g., "Weekdays 9am-5pm")
- FR81: The system shall provide distraction hiding presets: "Minimal" (hide all), "Moderate" (hide some), "Maximum Focus" (hide everything except player)
- FR82: The system shall persist Focus Mode preferences across app restarts and sync via CloudKit if enabled

**Monetization:**
- FR83: The system shall provide a free tier with basic viewing and simple organization features
- FR84: The system shall provide a Pro tier (via in-app purchase) unlocking: advanced AI (embeddings index, clustering, ranker), research notes, vector search, Spotlight/App Intents integration, Focus Mode scheduling
- FR85: The system shall implement StoreKit 2 for purchase flow and receipt validation
- FR86: The system shall provide "Restore Purchase" functionality
- FR87: The system shall NEVER claim to remove YouTube ads or provide YouTube Premium-like features

### Non-Functional Requirements

**Performance:**
- NFR1: P95 query latency for vector search shall be <50ms on Apple Silicon Macs (M1/M2/M3)
- NFR2: Cold start (app launch to first render) shall be <2 seconds
- NFR3: Warm start shall be <500 milliseconds
- NFR4: UI shall remain responsive with <16ms frame budget (60 FPS) during background indexing
- NFR5: Embedding generation shall average <10ms per video on Apple Silicon
- NFR6: App shall maintain "Low" Energy Impact rating in Activity Monitor during normal use

**Scalability:**
- NFR7: System shall handle user libraries of 10,000+ videos without performance degradation
- NFR8: Vector index rebuild for 1,000 videos shall complete in <5 seconds on M1 Mac
- NFR9: Cluster computation shall handle up to 50,000 edges in kNN graph

**Reliability:**
- NFR10: App crash-free rate shall be >99.5%
- NFR11: YouTube API calls shall implement exponential backoff on 429/5xx errors
- NFR12: System shall gracefully degrade when API quota is exceeded (use cached data, inform user)
- NFR13: CloudKit sync shall handle network failures and resume gracefully
- NFR14: Video playback shall handle network interruptions without crashing

**Security:**
- NFR15: All OAuth tokens shall be stored in macOS Keychain with appropriate access controls
- NFR16: The app shall run in App Sandbox with minimal entitlements (network.client, user-selected file R/W)
- NFR17: No secrets, API keys, or credentials shall be committed to version control
- NFR18: Crash logs and diagnostics shall not contain sensitive user data (tokens, video titles, etc.)
- NFR19: Security-scoped bookmarks shall be used for all local file access

**Privacy:**
- NFR20: All AI processing (embeddings, clustering, ranking) shall execute on-device
- NFR21: No user data shall be sent to external servers without explicit user consent
- NFR22: CloudKit sync shall use only the user's private iCloud database
- NFR23: App Store privacy labels shall accurately reflect "Data Not Collected" where applicable
- NFR24: Telemetry, if implemented, shall be on-device aggregated and user-initiated export only

**Compliance:**
- NFR25: YouTube integration shall comply with YouTube Terms of Service and Developer Policies
- NFR26: App shall comply with App Store Review Guidelines (specifically 1.2 UGC moderation, 5.2.3 IP/downloading)
- NFR27: Compile-time lint rules shall block usage of googlevideo.com or non-official YouTube endpoints
- NFR28: Branding shall follow YouTube Branding Guidelines (no "YouTube" in app name/icon, proper attribution)

**Maintainability:**
- NFR29: Code shall follow Swift best practices with SwiftLint enforcement
- NFR30: All public APIs and complex logic shall have comprehensive inline documentation
- NFR31: SwiftData model changes shall use versioned migrations with rollback capability
- NFR32: AI models shall be versioned to support background re-indexing on model updates
- NFR33: System architecture shall support feature flagging for gradual rollout

**Testability:**
- NFR34: Unit test coverage shall exceed 85% for core business logic (models, stores, ranker, API clients)
- NFR35: UI tests shall cover critical user workflows (YouTube playback, search, collection creation, UGC reporting)
- NFR36: Migration tests shall verify SwiftData schema changes don't corrupt data
- NFR37: Soak tests shall simulate API quota burn and network failures

**Usability:**
- NFR38: New users shall be able to complete core workflow (sign in, search, play video) within 2 minutes
- NFR39: System shall provide contextual help and onboarding for AI features
- NFR40: Error messages shall be user-friendly and actionable (not raw technical errors)
- NFR41: All modal dialogs shall be dismissible and non-blocking where possible

---

## User Interface Design Goals

### Overall UX Vision

MyToob provides a **clean, native macOS experience** that feels instantly familiar to Mac users while introducing intelligent, AI-powered organization that "just works." The interface prioritizes **content over chrome**—video and collections are the focus, with controls and features accessible but unobtrusive. The app embraces **progressive disclosure**: basic features (playback, browsing) are immediately obvious, while advanced capabilities (vector search, clustering, research tools) reveal themselves naturally as users explore.

The experience should feel **fast, fluid, and intelligent**. Search results appear instantly, AI-suggested clusters help users discover content they didn't know they had, and the interface adapts to user behavior. Privacy and compliance are communicated **transparently** without being heavy-handed—users understand what the app can and cannot do with YouTube content.

### Key Interaction Paradigms

**Unified Content View:**
- YouTube and local videos are **presented uniformly** in the main content grid/list
- Visual badges distinguish source (YouTube icon vs. local file icon)
- Seamless switching between YouTube IFrame Player and AVKit playback based on source

**AI-Powered Discovery:**
- **Natural language search bar** as primary entry point: "Show me Swift tutorials from last month"
- **Auto-generated topic clusters** appear as smart collections in sidebar
- **Recommendations surface organically** based on current viewing and research topics

**Research-Oriented Workflow:**
- **Side-by-side viewing**: Video player + notes panel (resizable split view)
- **Timestamp-based note taking**: Click video moment to anchor note
- **Collections as knowledge bases**: Organize research topics with nested structure

**Keyboard-First Power User Mode:**
- **Command palette** (⌘K) for quick access to all actions
- **Vim-style navigation** optional for search results and collections
- **Global hotkeys** for playback control even when app is backgrounded

**Contextual Actions:**
- **Right-click context menus** for video items with relevant actions (add to collection, create note, hide channel, report)
- **Drag-and-drop everywhere**: URLs from browser, files from Finder, videos between collections

### Core Screens and Views

**Main Window (Primary Interface):**
- **Sidebar:** Collections, auto-clusters, subscriptions (YouTube), playlists
- **Content Grid/List:** Video thumbnails with metadata (title, channel, duration, watch progress)
- **Player View:** Embedded YouTube IFrame Player or AVKit player (full-screen capable)
- **Search Bar:** Prominent at top with filter pills (duration, date, channel, cluster)
- **Toolbar:** Primary actions (search mode toggle, view options, sync status, Pro upgrade)

**Search & Discovery View:**
- **Search results grid** with relevance scores and highlighted terms
- **Filter sidebar:** Faceted search (duration ranges, date ranges, channels, clusters)
- **Related videos panel:** AI-suggested similar content based on vector similarity

**Collection Detail View:**
- **Collection metadata:** Title, description, auto/manual tag, video count
- **Video list:** Videos in collection with reorder capability (drag-and-drop)
- **Quick actions:** Play all, shuffle, export to Markdown

**Video Detail / Player View:**
- **Primary player area:** YouTube IFrame Player or AVKit player (16:9 or content aspect ratio)
- **Video metadata panel:** Title, channel, description, tags, watch progress
- **Notes panel:** Timestamp-based notes with Markdown editor
- **Related videos:** AI-suggested similar content from user's library

**Settings / Preferences:**
- **General:** App appearance, default player behavior, keyboard shortcuts
- **YouTube Account:** OAuth status, disconnect account, API quota dashboard (dev mode)
- **AI & Privacy:** CloudKit sync toggle, AI feature controls (Pro), local file analysis options (DMG build)
- **Advanced:** Performance settings, cache management, diagnostics export

**Onboarding Flow:**
- **Welcome screen:** Value proposition, compliance transparency ("Uses official YouTube APIs")
- **OAuth authentication:** Google sign-in flow with scope explanation
- **Permission requests:** Local file access (if user imports local videos)
- **Feature tour:** Quick interactive tutorial highlighting search, collections, clustering

**UGC & Compliance Screens:**
- **Content Policy Page:** Easy-to-understand explanation of what content is allowed
- **Report Content Flow:** Deep-link to YouTube reporting + channel hide/blacklist option
- **About / Legal:** Disclaimers, attributions, contact, terms of service, privacy policy

**Pro Upgrade / Paywall:**
- **Feature comparison:** Free vs. Pro features (AI organization, research tools, Spotlight)
- **Purchase flow:** StoreKit 2 in-app purchase with restore option
- **Success confirmation:** Welcome to Pro, feature unlocks

### Accessibility

**Target: WCAG AA compliance** for macOS native apps with the following specific requirements:

- **VoiceOver:** Full support with descriptive labels for all interactive elements, custom actions for video controls
- **Keyboard Navigation:** Complete keyboard-only operation with visible focus indicators, logical tab order
- **Dynamic Type:** Support for macOS text size preferences, layout adapts without content truncation
- **High Contrast:** Dedicated high-contrast theme with sufficient contrast ratios (4.5:1 for body text, 3:1 for large text)
- **Reduced Motion:** Respect macOS reduced motion setting, disable non-essential animations
- **Color:** Never rely on color alone to convey information (use icons, labels, patterns)

### Branding

**Visual Identity:**
- **App Name:** "MyToob" (avoids "YouTube" per branding guidelines)
- **App Icon:** Custom design suggesting video organization/discovery (NOT YouTube logo or derivative)
- **Color Palette:** Modern, Mac-native colors (SF Symbols-compatible), avoid YouTube red as primary color
- **Typography:** SF Pro (system font) for native feel, SF Mono for technical details (quota dashboard, diagnostics)

**Compliance Branding:**
- **YouTube Attribution:** Show "Powered by YouTube" badge near player per branding guidelines
- **Disclaimer:** "Not affiliated with YouTube" in About screen
- **Player Integrity:** Display YouTube logo/branding as provided by IFrame Player (no removal/overlay)

**Tone:**
- **Professional yet approachable:** This is a productivity tool, not a consumer entertainment app
- **Transparent about capabilities:** Clear communication about what is/isn't possible with YouTube integration
- **Privacy-forward:** Emphasize on-device processing and user data ownership

### Target Device and Platforms

**Primary Target: macOS 14.0 (Sonoma) or later**
- **Hardware Focus:** Apple Silicon Macs (M1/M2/M3) as primary target for AI performance
- **Intel Support:** Best-effort compatibility (Core ML may be slower, user-facing performance warnings)
- **Screen Sizes:** Optimized for 13" to 27"+ displays, minimum window size 1024x768
- **Input Methods:** Keyboard + mouse/trackpad (no touch screen assumptions)

**NOT Supported in MVP:**
- iOS/iPadOS (future consideration for view-only companion apps)
- Apple TV (future consideration for collection playback)
- Apple Watch (future consideration for remote control)
- Web browser version

---

## Technical Assumptions

### Repository Structure: Monorepo

**Decision:** Single Xcode project with SwiftPM dependencies

**Rationale:**
- Single-app project (native macOS only in MVP)
- SwiftUI + SwiftData + Core ML are all first-party Apple frameworks
- No need for polyrepo complexity until potential future iOS/web expansion
- All code lives in one Xcode project for simplicity
- Separate targets for main app, tests, and optional helper tools

**Structure:**
```
MyToob/
├── MyToob/                    # Main app target
│   ├── App/                   # App entry point, main views
│   ├── Features/              # Feature modules (YouTube, LocalFiles, AI, Search, etc.)
│   ├── Core/                  # Shared utilities, extensions
│   └── Resources/             # Assets, localization
├── MyToobTests/               # Unit tests
├── MyToobUITests/             # UI tests
└── Package.swift              # SwiftPM dependencies (if any external)
```

### Service Architecture

**Decision:** Monolithic single-process native app (no backend services)

**Rationale:**
- All functionality runs on-device (AI, storage, networking)
- No need for custom backend—YouTube Data API provides metadata, CloudKit handles sync
- Simpler deployment and maintenance (no server infrastructure)
- Better privacy story (no data leaves device except via user-controlled CloudKit)
- Lower operating costs (no server hosting fees)

**Component Structure:**
- **YouTubeService:** OAuth, Data API client, quota management
- **LocalFileService:** File import, security-scoped bookmarks, AVKit playback
- **AIService:** Core ML embeddings, vector index, clustering, ranking
- **StorageService:** SwiftData models, CloudKit sync, caching
- **PlayerService:** Unified player abstraction (YouTube IFrame vs. AVKit)
- **SearchService:** Hybrid search coordinator (keyword + vector)

### Testing Requirements

**Decision:** Full testing pyramid (unit + integration + UI + manual testing conveniences)**

**Rationale:**
- Core ML models need integration testing (real model inference, not mocked)
- YouTube IFrame Player bridge needs UI testing (JavaScript interop)
- SwiftData migrations need dedicated migration tests
- API quota management needs soak testing
- Compliance features (UGC reporting, player visibility) need manual testing checklists

**Testing Breakdown:**
- **Unit Tests (85%+ coverage target):** Models, business logic, AI algorithms, API clients, ranking features
- **Integration Tests:** Core ML model inference, SwiftData persistence, CloudKit sync, YouTube Data API (with mock server)
- **UI Tests:** Critical user workflows (sign in, search, playback, collection creation, UGC reporting)
- **Migration Tests:** SwiftData schema versioning, data integrity across versions
- **Soak Tests:** API quota burn simulation, network failure scenarios (429/5xx responses)
- **Manual Testing:** App Store submission checklist (documented test cases for reviewers)

**Testing Conveniences:**
- Mock mode for YouTube Data API (no real quota consumption during dev)
- Seed data generator for testing large libraries (10k+ videos)
- Performance profiling helpers (measure search latency, frame times, energy impact)
- Diagnostics export for user bug reports (sanitized logs, telemetry)

### Additional Technical Assumptions and Requests

**Language & Frameworks:**
- **Language:** Swift 5.10+ with modern concurrency (async/await, actors for thread-safe state)
- **UI Framework:** SwiftUI exclusively (no UIKit/AppKit except where required for AVKit/WKWebView interop)
- **Data Persistence:** SwiftData (not Core Data—use modern Apple framework)
- **Networking:** URLSession with async/await, Combine for reactive streams where needed
- **AI/ML:** Core ML exclusively (no TensorFlow, PyTorch, or external inference engines)

**Third-Party Dependencies:**
- **Minimize external dependencies** to reduce supply chain risk and App Store review complexity
- **Acceptable exceptions:**
  - HNSW index implementation (if performant Swift library exists; otherwise implement custom)
  - Graph clustering (Leiden/Louvain algorithm—port or use existing Swift/C++ library)
  - OAuth helpers (if they simplify implementation significantly; otherwise use raw URLSession)
- **Prohibited dependencies:**
  - Any YouTube stream extraction libraries (yt-dlp wrappers, etc.)—ToS violation risk
  - Analytics SDKs (Firebase, Mixpanel, etc.)—conflicts with privacy-first goal
  - Ad-blocking or DOM manipulation libraries—ToS violation

**Development Tools:**
- **Xcode 15+** as primary IDE
- **SwiftLint + swift-format** for code quality and consistency
- **GitHub Actions** for CI/CD (lint, test, build, notarize)
- **XcodeBuildMCP** for automation via Claude Code
- **danger** for PR checks (prevent API key commits, enforce policy keywords like "googlevideo.com")

**Deployment & Distribution:**
- **App Store Build:** Strict compliance, sandboxed, minimal entitlements
- **Notarized DMG Build:** Power-user features for local files only (deeper CV/ASR), requires explicit user opt-in
- **CI/CD Pipeline:** Automate build, test, codesign, notarize, staple, upload to App Store Connect
- **TestFlight:** Beta testing distribution for pre-release feedback

**AI Models:**
- **Embedding Model:** Port a small sentence-transformer model (e.g., all-MiniLM-L6-v2, 384-dim) to Core ML, 8-bit quantization for performance
- **Ranking Model:** Train gradient-boosted tree (XGBoost/LightGBM) offline, export to Core ML
- **OCR:** Use Vision framework's built-in text recognition (no custom model needed)
- **Model Versioning:** Embed model version in metadata, trigger background re-index when model updates

**Logging & Observability:**
- **On-device logging** using OSLog with appropriate privacy levels (public, private, sensitive)
- **User-initiated diagnostics export:** Collect logs, telemetry, system info into sanitized archive
- **No external crash reporting** without explicit user opt-in (privacy-first)
- **Dev-only quota dashboard:** Real-time API unit consumption display (removed in App Store build or hidden behind secret menu)

**Localization:**
- **English (US) only in MVP** with localizable strings framework in place
- **Post-MVP:** Add major languages (Spanish, French, German, Japanese, Chinese) based on user demand

**Accessibility:**
- **WCAG AA compliance** as baseline
- **VoiceOver testing** with real screen reader users (recruit from accessibility community for beta)
- **Keyboard-only operation testing:** Ensure 100% feature coverage without mouse

**Performance Profiling:**
- **Instruments:** Regular profiling for Time Profiler, Allocations, Leaks, Energy Log
- **MetricKit:** Collect on-device performance metrics (launch time, hang rate, memory usage) with user consent
- **Benchmarking:** Establish performance baselines for search latency, index rebuild time, playback smoothness

**Security Audits:**
- **Pre-launch security review:** Check for hardcoded secrets, proper Keychain usage, sandbox compliance
- **Dependency audit:** Verify all external libraries are from trusted sources with recent updates
- **Crash log sanitization:** Ensure no sensitive data (tokens, video titles, user notes) in crash reports

**Compliance Validation:**
- **YouTube ToS compliance checklist:** Document how each requirement is met (no stream caching, no ad removal, etc.)
- **App Store guidelines checklist:** Document how UGC safeguards, IP protection, and privacy labels are addressed
- **Reviewer documentation package:** Screen-by-screen compliance notes, architecture explainer, demo workflow

---

## Epic List

1. **Epic 1: Foundation & Project Infrastructure** - Establish Xcode project, CI/CD pipeline, SwiftData models, and compliance tooling to enable rapid development with built-in quality gates.

2. **Epic 2: YouTube OAuth & Data API Integration** - Implement Google OAuth authentication and YouTube Data API client with quota management, enabling compliant metadata retrieval without ToS violations.

3. **Epic 3: Compliant YouTube Playback** - Integrate YouTube IFrame Player in WKWebView with JavaScript bridge for playback control, ensuring full compliance with YouTube policies (no stream access, no ad manipulation).

4. **Epic 4: Focus Mode & Distraction Management** - Implement customizable distraction hiding for YouTube UI elements (sidebar, related videos, comments, homepage feed) with time-based scheduling, enabling focused, distraction-free viewing experiences.

5. **Epic 5: Local File Playback & Management** - Enable local video file import and playback via AVKit, providing full-featured media player capabilities for user-owned content.

6. **Epic 6: Data Persistence & CloudKit Sync** - Implement SwiftData models with versioned migrations and optional CloudKit sync, providing reliable local storage and cross-device synchronization.

7. **Epic 7: On-Device AI Embeddings & Vector Index** - Build Core ML-powered text embeddings pipeline and HNSW vector index for fast semantic search, enabling intelligent content discovery.

8. **Epic 8: AI Clustering & Auto-Collections** - Implement graph-based clustering (kNN + Leiden/Louvain) with automatic labeling, enabling AI-powered topic grouping of video content.

9. **Epic 9: Hybrid Search & Discovery UX** - Create unified search interface combining keyword and vector similarity with filter pills and ranked results, enabling fast and relevant content discovery.

10. **Epic 10: Collections & Organization** - Build user-created collections, drag-and-drop organization, and AI-suggested tags, enabling manual and automated content curation.

11. **Epic 11: Research Tools & Note-Taking** - Implement inline notes with timestamp anchors, Markdown support, and export capabilities, enabling video-based research workflows.

12. **Epic 12: UGC Safeguards & Compliance Features** - Implement content reporting, channel blocking, policy pages, and compliance UI, ensuring App Store approval and user safety.

13. **Epic 13: macOS System Integration** - Add Spotlight indexing, App Intents (Shortcuts), menu bar controls, and keyboard shortcuts, providing deep macOS platform integration.

14. **Epic 14: Accessibility & Polish** - Ensure VoiceOver support, keyboard-only operation, high-contrast themes, and comprehensive accessibility features for inclusive user experience.

15. **Epic 15: Monetization & App Store Release** - Implement StoreKit 2 paywall, Pro tier features, App Store submission package with reviewer documentation, and notarized DMG build for alternate distribution.

---

## Epic 1: Foundation & Project Infrastructure

**Goal:** Establish the foundational project structure, development tooling, and core data models that will support all subsequent development. This epic delivers the basic application shell with working CI/CD pipeline, SwiftData persistence layer, and compliance enforcement tooling. By the end of this epic, we have a functioning (though minimal) macOS app that can be built, tested, and deployed via automated pipeline.

### Story 1.1: Xcode Project Setup & Configuration

As a **developer**,
I want **a properly configured Xcode project with target settings, entitlements, and build configurations**,
so that **I can develop a sandboxed macOS app with correct signing and capabilities**.

**Acceptance Criteria:**
1. Xcode project created for macOS target with minimum deployment target macOS 14.0 (Sonoma)
2. App sandbox enabled with entitlements: `com.apple.security.network.client`, `com.apple.security.files.user-selected.read-write`
3. Signing configured for development and distribution (code signing identity, provisioning profiles)
4. Build configurations created: Debug, Release, TestFlight
5. App group configured for shared data access (if needed for extensions in future)
6. Info.plist includes required keys: LSMinimumSystemVersion, NSHumanReadableCopyright, etc.
7. Core ML embedding model (`sentence-transformer-384.mlpackage`) added to `MyToob/Resources/CoreML Models/` directory
8. Project builds successfully and launches with empty window

### Story 1.2: SwiftLint & Code Quality Tooling

As a **developer**,
I want **automated code quality checks enforced via SwiftLint and swift-format**,
so that **code style is consistent and policy violations (e.g., banned API usage) are caught at compile time**.

**Acceptance Criteria:**
1. SwiftLint installed and integrated as Xcode build phase
2. `.swiftlint.yml` configuration file created with project-specific rules
3. Custom lint rule blocks usage of `googlevideo.com` in string literals (compliance enforcement)
4. Custom lint rule warns on hardcoded secrets/API keys patterns
5. swift-format installed for automated code formatting
6. Danger rules configured to check PRs for policy keywords and file changes
7. Build fails if critical lint violations found (errors, not warnings)

### Story 1.3: GitHub CI/CD Pipeline

As a **developer**,
I want **automated CI/CD via GitHub Actions that runs tests, linting, and builds on every commit**,
so that **code quality is enforced and broken builds are caught immediately**.

**Acceptance Criteria:**
1. `.github/workflows/ci.yml` created with jobs: lint, test, build
2. Lint job runs SwiftLint and fails on errors
3. Test job runs `xcodebuild test` and reports coverage
4. Build job produces signed `.app` artifact
5. Workflow triggers on: push to main, pull requests
6. Workflow uses macOS runner (macos-latest or macos-14)
7. Build artifacts uploaded to GitHub Actions for debugging
8. All jobs pass on initial empty project

### Story 1.4: SwiftData Core Models

As a **developer**,
I want **SwiftData models defined for VideoItem, ClusterLabel, Note, and ChannelBlacklist**,
so that **the app can persist video metadata, AI results, user notes, and moderation preferences**.

**Acceptance Criteria:**
1. `VideoItem` model created with properties: `videoID` (YouTube ID or nil for local), `localURL`, `title`, `channelID`, `duration`, `watchProgress`, `isLocal`, `aiTopicTags`, `embedding` (transformable [Float] array), `addedAt`, `lastWatchedAt`
2. `ClusterLabel` model created with properties: `clusterID`, `label`, `centroid` (transformable [Float] array), `itemCount`
3. `Note` model created with properties: `noteID`, `content` (Markdown string), `timestamp` (optional video position), `createdAt`, `updatedAt`, relationship to `VideoItem`
4. `ChannelBlacklist` model created with properties: `channelID` (unique), `reason` (optional), `blockedAt`
5. Models use `@Attribute(.unique)` for identity fields where appropriate
6. SwiftData model container configured in app entry point
7. Unit tests created for model creation, fetching, and deletion

### Story 1.5: Basic App Shell & Navigation

As a **user**,
I want **a minimal but functional macOS app window with sidebar and main content area**,
so that **I have a foundation UI to build features upon**.

**Acceptance Criteria:**
1. SwiftUI `App` struct created with `@main` entry point
2. Main window created with `WindowGroup` and minimum size (1024x768)
3. Sidebar + content split view layout implemented
4. Sidebar shows placeholder sections: "Collections", "YouTube", "Local Files"
5. Main content area shows placeholder message: "Select an item from the sidebar"
6. App launches without crashes and displays window correctly
7. Window state (size, position) persists across app launches (using AppStorage or SceneStorage)

### Story 1.6: Logging & Diagnostics Framework

As a **developer**,
I want **structured logging using OSLog with privacy controls**,
so that **I can debug issues while respecting user privacy**.

**Acceptance Criteria:**
1. Logging utility created wrapping `OSLog` with predefined subsystems/categories
2. Log levels defined: debug, info, notice, error, fault
3. Privacy levels used: public (non-sensitive), private (sensitive), sensitive (redacted in logs)
4. Example log statements added to app launch flow demonstrating usage
5. Diagnostics export function created (collects logs, system info, sanitizes sensitive data)
6. User-initiated diagnostics export accessible via Settings (returns `.zip` file)
7. No logs written to files by default (uses OS logging system)

---

## Epic 2: YouTube OAuth & Data API Integration

**Goal:** Enable users to authenticate with their YouTube account and retrieve metadata (subscriptions, playlists, video details) via the official YouTube Data API v3. This epic establishes the compliant integration pattern with OAuth, token management, quota budgeting, and efficient caching—all foundational to YouTube features without violating ToS.

### Story 2.1: Google OAuth Authentication Flow

As a **user**,
I want **to sign in with my Google account to access YouTube data**,
so that **the app can retrieve my subscriptions, playlists, and viewing history**.

**Acceptance Criteria:**
1. OAuth 2.0 flow implemented using `ASWebAuthenticationSession` (native macOS authentication UI)
2. OAuth scopes requested: `https://www.googleapis.com/auth/youtube.readonly` (minimal scope)
3. OAuth credentials (client ID, client secret) stored securely (not hardcoded, loaded from config file excluded from repo)
4. Authorization code exchange implemented to obtain access token and refresh token
5. Tokens stored securely in macOS Keychain with appropriate access controls
6. User shown clear explanation of what data the app will access before OAuth redirect
7. OAuth flow cancellable by user without app crash
8. Success/failure states handled gracefully with user-friendly error messages

### Story 2.2: Token Storage & Automatic Refresh

As a **developer**,
I want **OAuth tokens securely stored in Keychain with automatic refresh when expired**,
so that **users remain authenticated without repeated sign-ins**.

**Acceptance Criteria:**
1. Keychain wrapper created for storing/retrieving access token and refresh token
2. Token expiry time tracked (typically 3600 seconds for access token)
3. Before each API call, check if access token is expired (within 5-minute buffer)
4. If expired, automatically refresh using refresh token via OAuth token endpoint
5. If refresh fails (invalid refresh token), prompt user to re-authenticate
6. "Sign Out" action in Settings clears all tokens from Keychain
7. Unit tests verify token refresh logic with mocked OAuth endpoints

### Story 2.3: YouTube Data API Client Foundation

As a **developer**,
I want **a strongly-typed API client for YouTube Data API v3 endpoints**,
so that **I can reliably fetch metadata with proper error handling**.

**Acceptance Criteria:**
1. API client created using `URLSession` with async/await
2. Base URL configured: `https://www.googleapis.com/youtube/v3/`
3. API client automatically injects OAuth access token in `Authorization: Bearer` header
4. Typed request/response models created for key endpoints: `search.list`, `videos.list`, `channels.list`, `playlists.list`, `playlistItems.list`
5. Error handling for HTTP status codes: 401 (unauthorized, trigger token refresh), 403 (quota exceeded), 429 (rate limit), 5xx (server error)
6. API responses parsed into Swift structs (Codable)
7. Unit tests with mocked HTTP responses verify parsing and error handling

### Story 2.4: ETag-Based Caching for Metadata

As a **developer**,
I want **ETag-based caching with If-None-Match headers to minimize API quota usage**,
so that **repeated requests for the same data don't consume quota unnecessarily**.

**Acceptance Criteria:**
1. Caching layer stores API responses keyed by request URL + parameters
2. When response includes `ETag` header, cache stores both ETag and response body
3. On subsequent requests, include `If-None-Match: <cached-ETag>` header
4. If server returns `304 Not Modified`, use cached response body (no quota charge)
5. If server returns `200 OK` with new data, update cache with new ETag and body
6. Cache eviction policy: LRU with 1000-item limit or 7-day TTL, whichever comes first
7. Cache hit rate logged for performance monitoring (goal: >90% hit rate on repeated refreshes)

### Story 2.5: API Quota Budgeting & Circuit Breaker

As a **developer**,
I want **per-endpoint quota budgeting with circuit breaker pattern on 429 errors**,
so that **the app doesn't exhaust the user's daily API quota**.

**Acceptance Criteria:**
1. Quota cost table defined for each endpoint: `search.list` = 100 units, `videos.list` = 1 unit, etc. (per YouTube docs)
2. Quota budget tracker increments consumed units per request (reset daily at midnight PT)
3. Before each request, check if budget would exceed daily limit (10,000 units default)
4. If quota would be exceeded, return cached data or show user warning ("Daily API limit reached, showing cached data")
5. On 429 response, implement exponential backoff: retry after 1s, 2s, 4s, 8s (max 3 retries)
6. Circuit breaker opens after 5 consecutive 429s (blocks further requests for 1 hour)
7. Dev-only quota dashboard shows real-time unit consumption per endpoint (removed in release builds)

### Story 2.6: Import User Subscriptions

As a **user**,
I want **to import my YouTube subscriptions into the app**,
so that **I can organize and search videos from channels I follow**.

**Acceptance Criteria:**
1. "Import Subscriptions" button in YouTube section of sidebar
2. Calls `subscriptions.list` API with pagination (50 results per page)
3. For each subscription, fetches channel metadata: `channelID`, `title`, `thumbnailURL`
4. Creates `VideoItem` entries for recent uploads from each channel (optional: calls `channels.list` to get `uploads` playlist ID, then `playlistItems.list`)
5. Progress indicator shows import status ("Importing subscriptions: 45/120 channels...")
6. Handles API errors gracefully (quota exceeded, network failure)—user can retry
7. Import can be paused/resumed (stores state in SwiftData)
8. After import, subscriptions appear in sidebar under "YouTube > Subscriptions"

---

## Epic 3: Compliant YouTube Playback

**Goal:** Integrate the YouTube IFrame Player API within a WKWebView to provide compliant, ToS-adhering video playback. This epic implements the JavaScript bridge for playback control (play/pause/seek), state synchronization (time updates, player events), and enforces policy boundaries (no ad removal, no stream access, pause when hidden). Successful completion enables users to watch YouTube videos within the app without violating YouTube's Developer Policies.

### Story 3.1: WKWebView YouTube IFrame Player Setup

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

### Story 3.2: JavaScript Bridge for Playback Control

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

### Story 3.3: Player State & Time Event Handling

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

### Story 3.4: Picture-in-Picture Support (Native Only)

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

### Story 3.5: Player Visibility Enforcement (Compliance)

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

### Story 3.6: Error Handling & Unsupported Videos

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

## Epic 4: Focus Mode & Distraction Management

**Goal:** Empower users to create distraction-free viewing experiences by selectively hiding YouTube UI elements that compete for attention (sidebar recommendations, related videos, comments, homepage feed). This epic implements customizable distraction controls inspired by browser extensions like Unhook and YouFocus, with time-based scheduling for automatic focus mode activation during work hours. By the end of this epic, users can configure granular distraction hiding preferences that sync across devices and optionally activate on a schedule.

### Story 4.1: Focus Mode Global Toggle

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

### Story 4.2: Hide YouTube Sidebar

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

### Story 4.3: Hide Related Videos Panel

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

### Story 4.4: Hide Comments Section

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

### Story 4.5: Hide Homepage Feed

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

### Story 4.6: Focus Mode Scheduling (Pro Feature)

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

### Story 4.7: Distraction Hiding Presets

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

## Epic 5: Local File Playback & Management

**Goal:** Enable users to import and play local video files (MP4, MOV, MKV, etc.) using AVKit, providing a full-featured media player experience for user-owned content. This epic handles file selection, security-scoped bookmarks for persistent access, AVPlayerView integration, and playback state tracking—establishing the local video management capabilities that complement YouTube integration.

### Story 5.1: Local File Import via File Picker

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

### Story 5.2: Security-Scoped Bookmarks for Persistent Access

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

### Story 5.3: AVPlayerView Integration for Local Playback

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

### Story 5.4: Playback State Persistence for Local Files

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

### Story 5.5: Drag-and-Drop File Import

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

### Story 5.6: Local File Metadata Extraction

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

## Epic 6: Data Persistence & CloudKit Sync

**Goal:** Establish robust data persistence using SwiftData with versioned schema migrations, and provide optional CloudKit synchronization for cross-device access to user data (collections, notes, watch progress, embeddings). This epic ensures data integrity, conflict resolution, and user control over syncing—foundational to a reliable multi-device experience.

### Story 6.1: SwiftData Model Container & Configuration

As a **developer**,
I want **SwiftData model container configured with proper migration strategy**,
so that **schema changes don't corrupt user data**.

**Acceptance Criteria:**
1. `ModelContainer` initialized in app entry point with all models: `VideoItem`, `ClusterLabel`, `Note`, `ChannelBlacklist`
2. Model configuration specifies versioned schema: `ModelConfiguration(schema: .version1, isStoredInMemoryOnly: false)`
3. Default storage location: `~/Library/Application Support/MyToob/default.store`
4. Container injected into SwiftUI environment: `.modelContainer(for: [VideoItem.self, ...])`
5. Cold start creates initial schema without migrations
6. Unit tests verify container initialization succeeds and models are queryable
7. No data loss on app restart (persistent storage confirmed)

### Story 6.2: Versioned Schema Migrations

As a **developer**,
I want **versioned schema migrations that safely evolve the data model**,
so that **users can upgrade the app without losing data**.

**Acceptance Criteria:**
1. Schema versioning implemented: `SchemaV1`, `SchemaV2`, etc.
2. Migration plan defined: `SchemaMigrationPlan` with `stages` mapping old→new versions
3. Example migration created for testing: add new property to `VideoItem` (e.g., `lastAccessedAt: Date?`)
4. Lightweight migrations handled automatically (adding optional properties)
5. Custom migrations implemented for complex changes (e.g., splitting properties, data transformations)
6. Migration rollback strategy: backup database before migration, restore on failure
7. Migration tests verify data integrity across version upgrades (seed v1 data, migrate to v2, verify no loss)

### Story 6.3: CloudKit Container & Private Database Setup

As a **developer**,
I want **CloudKit container configured for private database sync**,
so that **user data can sync across devices via iCloud**.

**Acceptance Criteria:**
1. CloudKit container identifier registered in Apple Developer portal: `iCloud.com.yourdomain.mytoob`
2. CloudKit capability enabled in Xcode: `iCloud > CloudKit`, container selected
3. Private database used (not public—user data only)
4. Record types created in CloudKit Dashboard matching SwiftData models: `VideoItem`, `ClusterLabel`, `Note`, `ChannelBlacklist`
5. SwiftData models annotated with `@CloudKitSync` (if using SwiftData+CloudKit integration, or custom sync implementation)
6. CloudKit sync enabled by default (can be toggled off in Settings)
7. Unit tests verify CloudKit container accessible and records can be created/fetched

### Story 6.4: CloudKit Sync Conflict Resolution

As a **developer**,
I want **deterministic conflict resolution when sync conflicts occur**,
so that **users don't lose data when the same record is modified on multiple devices**.

**Acceptance Criteria:**
1. Conflict resolution strategy: "Last Write Wins" (based on `modifiedAt` timestamp)
2. If conflict detected (same record modified on two devices before sync), keep newer version based on timestamp
3. For `Note` conflicts, create conflict copy with suffix " (Conflict Copy)" rather than discarding
4. Conflict resolution logged for debugging: "Resolved conflict for VideoItem {id}: kept device A version (newer)"
5. User notified if conflicts occurred: "Sync completed with 3 conflicts resolved" (non-blocking notification)
6. Manual conflict review UI (optional for Pro tier): show conflicts, let user choose which version to keep
7. Integration tests simulate conflicts by modifying same record on two "devices" (separate CloudKit clients)

### Story 6.5: Sync Status UI & User Controls

As a **user**,
I want **to see sync status and control whether CloudKit sync is enabled**,
so that **I understand what data is syncing and can opt out if desired**.

**Acceptance Criteria:**
1. Sync status indicator in toolbar: "Synced" (green checkmark), "Syncing..." (spinner), "Sync Failed" (red X)
2. Clicking sync status opens sync details popover: "Last synced: 2 minutes ago | 1,234 items | Next sync: automatic"
3. Settings > iCloud Sync toggle: enable/disable CloudKit sync
4. When sync disabled, all data remains local-only (no CloudKit pushes)
5. "Sync Now" button in Settings forces immediate sync (useful for troubleshooting)
6. Sync error details shown to user: "Sync failed: Not signed into iCloud" or "Sync failed: Network unavailable"
7. No automatic sync when user explicitly disabled it (respects user choice)

### Story 6.6: Caching Strategy for Metadata & Thumbnails

As a **developer**,
I want **efficient caching of YouTube metadata and thumbnails with proper eviction**,
so that **the app is fast and doesn't re-download data unnecessarily**.

**Acceptance Criteria:**
1. Metadata cache: key = `videoID`, value = YouTube API response JSON, TTL = 7 days
2. Thumbnail cache: key = `thumbnailURL`, value = image data, respects HTTP `Cache-Control` headers
3. ETag-based revalidation for metadata (implemented in Epic 2)—cache uses ETags
4. Cache stored on disk: `~/Library/Caches/MyToob/metadata/` and `.../thumbnails/`
5. Cache eviction: LRU policy, max 1000 metadata entries, max 500 MB thumbnails
6. "Clear Cache" button in Settings removes all cached data (forces re-download on next access)
7. Cache hit rate monitored: goal >90% for repeated views of same videos
8. No caching of YouTube video/audio streams (policy violation check—ensure no stream URLs cached)

---

## Epic 7: On-Device AI Embeddings & Vector Index

**Goal:** Implement Core ML-powered text embeddings generation from video metadata (titles, descriptions, thumbnail OCR text) and build an HNSW vector index for fast semantic similarity search. This epic establishes the AI foundation that enables intelligent content discovery without cloud dependencies, keeping all processing on-device for privacy.

### Story 7.1: Core ML Embedding Model Integration

As a **developer**,
I want **a Core ML model that generates 384-dimensional embeddings from text**,
so that **video metadata can be converted to vectors for semantic search**.

**Acceptance Criteria:**
1. Small sentence-transformer model (e.g., all-MiniLM-L6-v2) converted to Core ML format (`.mlmodel` or `.mlpackage`)
2. Model quantized to 8-bit for performance (reduces model size, speeds up inference)
3. Model added to Xcode project as resource, loaded at app startup
4. Swift wrapper created: `EmbeddingService.generateEmbedding(text: String) async -> [Float]`
5. Input text preprocessed: lowercased, truncated to model's max length (typically 256 tokens)
6. Output: 384-element Float array (embedding vector)
7. Inference latency measured: <10ms average on M1 Mac (target met)
8. Unit tests verify embeddings are consistent (same input → same output)

### Story 7.2: Metadata Text Preparation for Embeddings

As a **developer**,
I want **to combine video title, description, and tags into a single text representation**,
so that **embeddings capture the semantic meaning of the video content**.

**Acceptance Criteria:**
1. For each `VideoItem`, concatenate: `title + " " + description + " " + tags.joined(separator: " ")`
2. Text cleaned: remove URLs, HTML tags, excessive whitespace, non-ASCII characters (optional, if they hurt model performance)
3. Text truncated to model's max input length (typically 256 tokens ≈ 1000 characters)
4. Title weighted more heavily (optional: repeat title 2-3 times in concatenated text for emphasis)
5. If metadata is minimal (e.g., local file with only filename), fall back to filename only
6. Empty or very short text (<10 characters) handled gracefully: generate default embedding or skip
7. Unit tests verify text preparation with various input scenarios (long description, missing title, etc.)

### Story 7.3: Thumbnail OCR Text Extraction

As a **developer**,
I want **to extract text from video thumbnails using Vision framework**,
so that **text visible in thumbnails (e.g., video titles, labels) enhances semantic embeddings**.

**Acceptance Criteria:**
1. `VNRecognizeTextRequest` used to extract text from thumbnail images
2. Thumbnail downloaded (or loaded from cache) as `NSImage`/`CGImage`
3. OCR runs asynchronously (doesn't block main thread)
4. Extracted text combined with metadata text before embedding generation
5. OCR failures handled gracefully (if no text found, continue without OCR text)
6. OCR text cleaned: remove low-confidence results (<0.5 confidence threshold)
7. Performance acceptable: OCR adds <100ms to embedding pipeline (measured)
8. Unit tests verify OCR extraction with sample thumbnails (text-heavy vs. text-free)

### Story 7.4: Batch Embedding Generation Pipeline

As a **user**,
I want **embeddings generated automatically for all imported videos**,
so that **semantic search works without manual intervention**.

**Acceptance Criteria:**
1. On video import (YouTube or local), trigger embedding generation in background queue
2. Batch processing: process up to 10 videos at a time (parallel inference using Core ML)
3. Progress indicator shown: "Generating embeddings: 45/120 videos..."
4. Embedding stored in `VideoItem.embedding` (transformable [Float] array in SwiftData)
5. If embedding generation fails (e.g., Core ML error), log error and retry later
6. "Re-generate Embeddings" action in Settings forces regeneration for all videos (useful after model update)
7. App usable while embeddings generate (non-blocking background task)
8. Embeddings persist across app restarts (stored in SwiftData)

### Story 7.5: HNSW Vector Index Construction

As a **developer**,
I want **an HNSW index built from all video embeddings**,
so that **vector similarity queries return results in <50ms**.

**Acceptance Criteria:**
1. HNSW index implementation integrated (use existing Swift/C++ library or implement custom)
2. Index built from all `VideoItem.embedding` vectors on app launch (if embeddings exist)
3. Index parameters tuned: M=16 (connections per layer), ef_construction=200 (construction search depth)
4. Index stored on disk for persistence: `~/Library/Application Support/MyToob/vector-index.bin`
5. Index incrementally updated when new videos added (no full rebuild required)
6. Index rebuild time measured: <5 seconds for 1,000 videos on M1 Mac (target met)
7. Query interface: `VectorIndex.search(query: [Float], k: Int) async -> [VideoItem]` returns top-k nearest neighbors
8. Unit tests verify index returns correct neighbors (known similar vectors)

### Story 7.6: Vector Similarity Search API

As a **user**,
I want **to search videos using natural language queries**,
so that **I can find relevant content even if I don't remember exact titles**.

**Acceptance Criteria:**
1. User types query in search bar: "swift concurrency tutorials"
2. Query text converted to embedding using same Core ML model
3. Query embedding used to search HNSW index for top-20 nearest neighbors
4. Results sorted by cosine similarity score (higher = more similar)
5. Search completes in <50ms (P95 latency target met)
6. Results displayed in main content area with similarity scores (optional: show % match)
7. Empty results handled: "No similar videos found. Try a different query."
8. UI test verifies search returns expected results for sample queries

---

## Epic 8: AI Clustering & Auto-Collections

**Goal:** Implement graph-based clustering using kNN graph construction and Leiden/Louvain community detection algorithms to automatically group related videos by topic. Generate human-readable labels for each cluster using keyword extraction. This epic enables the "smart collections" feature that helps users discover thematic connections in their video library.

### Story 8.1: kNN Graph Construction from Embeddings

As a **developer**,
I want **a k-nearest-neighbors graph built from all video embeddings**,
so that **similar videos are connected and can be clustered**.

**Acceptance Criteria:**
1. For each video embedding, find k=10 nearest neighbors using HNSW index
2. Construct undirected graph: nodes = videos, edges = k-nearest-neighbor connections
3. Edge weights = cosine similarity between embeddings (higher weight = more similar)
4. Graph stored in memory (adjacency list representation)
5. Graph construction time measured: <2 seconds for 1,000 videos on M1 Mac
6. Graph updated incrementally when new videos added (add new node + edges, no full rebuild)
7. Unit tests verify graph structure (degree distribution, connectivity)

### Story 8.2: Leiden Community Detection Algorithm

As a **developer**,
I want **Leiden algorithm applied to kNN graph to detect topic clusters**,
so that **videos are grouped by semantic similarity**.

**Acceptance Criteria:**
1. Leiden algorithm implemented (or integrated from existing Swift/C++ library)
2. Algorithm runs on kNN graph to detect communities (clusters)
3. Leiden parameters tuned: resolution=1.0 (controls cluster granularity)
4. Output: assignment of each video to a cluster ID (e.g., video A → cluster 3)
5. Cluster count reasonable: typically 5-20 clusters for 1,000 videos (not too many, not too few)
6. Clustering time measured: <3 seconds for 1,000-video graph on M1 Mac
7. Re-clustering triggered when library grows significantly (e.g., +100 videos)
8. Unit tests verify algorithm produces non-trivial clustering (not all videos in one cluster)

### Story 8.3: Cluster Centroid Computation & Label Generation

As a **developer**,
I want **each cluster to have a human-readable label generated from member video titles**,
so that **users understand what each auto-collection represents**.

**Acceptance Criteria:**
1. For each cluster, compute centroid: average of all member video embeddings
2. Extract keywords from member video titles using TF-IDF or frequency analysis
3. Select top 3-5 keywords as cluster label (e.g., "Swift, Concurrency, Async")
4. Label formatted: "Swift Concurrency" (title case, comma-separated keywords)
5. Labels stored in `ClusterLabel` model with `clusterID`, `label`, `centroid`, `itemCount`
6. Labels unique (no duplicate labels across clusters—append disambiguation if needed)
7. "Rename Cluster" action allows user to override auto-generated label
8. UI test verifies cluster labels are generated correctly for sample data

### Story 8.4: Auto-Collections UI in Sidebar

As a **user**,
I want **to see auto-generated topic collections in the sidebar**,
so that **I can browse videos grouped by AI-detected themes**.

**Acceptance Criteria:**
1. Sidebar section added: "Smart Collections" (above or below manual collections)
2. Each `ClusterLabel` displayed as a sidebar item: label + count (e.g., "Swift Concurrency (24)")
3. Clicking cluster loads videos in that cluster in main content area
4. Cluster icon: system icon indicating AI-generated (e.g., sparkles icon)
5. Clusters sorted by size (largest first) or alphabetically (user preference in Settings)
6. Empty clusters (0 videos) not shown in sidebar
7. "Hide Smart Collections" toggle in Settings for users who prefer manual organization only

### Story 8.5: Cluster Stability & Re-Clustering Trigger

As a **developer**,
I want **clustering to remain stable across app restarts and only re-cluster when necessary**,
so that **users don't see collections constantly changing**.

**Acceptance Criteria:**
1. Cluster assignments persisted in SwiftData (add `clusterID` property to `VideoItem`)
2. On app launch, load existing clusters from SwiftData (no re-clustering unless needed)
3. Re-clustering triggered when: user manually requests, library grows by >10% since last clustering, AI model updated
4. Re-clustering runs in background (doesn't block UI)
5. After re-clustering, old cluster IDs mapped to new clusters to preserve user edits (e.g., renamed labels)
6. "Re-cluster Now" action in Settings forces full re-clustering
7. Cluster stability measured: >90% of videos remain in same cluster after re-clustering (goal: minimize churn)

### Story 8.6: Cluster Detail View & Refinement

As a **user**,
I want **to view all videos in a cluster and refine the cluster**,
so that **I can understand and improve auto-generated collections**.

**Acceptance Criteria:**
1. Clicking cluster in sidebar loads cluster detail view
2. Detail view shows: cluster label, video count, member videos in grid/list
3. "Rename Cluster" button allows custom label (overrides auto-generated)
4. "Merge with..." action combines two clusters into one (user selects second cluster)
5. "Remove from Cluster" action on individual videos (moves video out of cluster)
6. "Convert to Manual Collection" creates a user collection from cluster (preserves videos, removes from smart collections)
7. Changes to clusters persist across app restarts

---

## Epic 9: Hybrid Search & Discovery UX

**Goal:** Create a unified search interface that combines keyword matching (traditional search) with vector similarity (semantic search), providing filter pills for faceted search and ranked results optimized for relevance. This epic delivers the primary content discovery mechanism, enabling users to find videos quickly and accurately regardless of search style.

### Story 9.1: Search Bar & Query Input

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

### Story 9.2: Keyword Search Implementation

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

### Story 9.3: Vector Similarity Search Integration

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

### Story 9.4: Hybrid Search Result Fusion

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

### Story 9.5: Filter Pills for Faceted Search

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

### Story 9.6: Search Results Display & Ranking

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

## Epic 10: Collections & Organization

**Goal:** Enable users to create custom collections (folders) for manual video organization, with drag-and-drop support, bulk actions, and AI-suggested tags. This epic provides the manual curation tools that complement AI auto-collections, giving users full control over their library structure.

### Story 10.1: Create & Manage Collections

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

### Story 10.2: Add Videos to Collections

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

### Story 10.3: Collection Detail View

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

### Story 10.4: Collection Export to Markdown

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

### Story 10.5: AI-Suggested Tags

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

### Story 10.6: Bulk Operations on Multiple Videos

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

## Epic 11: Research Tools & Note-Taking

**Goal:** Provide integrated note-taking capabilities with timestamp anchors, Markdown support, bidirectional links, and export functionality. This epic transforms the app from a video player into a research tool, enabling knowledge workers to annotate, cite, and build knowledge bases from video content.

### Story 11.1: Inline Note Editor for Videos

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

### Story 11.2: Timestamp-Anchored Notes

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

### Story 11.3: Bidirectional Links Between Notes

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

### Story 11.4: Note Search & Filtering

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

### Story 11.5: Note Export & Citation

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

### Story 11.6: Note Templates (Pro Feature)

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

## Epic 12: UGC Safeguards & Compliance Features

**Goal:** Implement user-generated content (UGC) moderation tools and compliance features required for App Store approval: content reporting (deep-link to YouTube), channel blocking, content policy page, and support contact. This epic ensures the app meets Apple's Guideline 1.2 (UGC) requirements and demonstrates responsible platform behavior.

### Story 12.1: Report Content Action

As a **user**,
I want **to report inappropriate YouTube content**,
so that **YouTube can review and take action according to their policies**.

**Acceptance Criteria:**
1. "Report Content" action in video context menu (right-click on YouTube video)
2. Clicking action shows dialog: "Report this video for violating YouTube's Community Guidelines?"
3. Dialog includes "Report on YouTube" button (primary) and "Cancel" button
4. "Report on YouTube" opens YouTube's reporting page in default web browser: `https://www.youtube.com/watch?v={videoID}&report=1`
5. Action only available for YouTube videos (hidden for local files)
6. "Report" action logged for compliance audit: "User reported video {videoID} at {timestamp}"
7. UI test verifies report action opens correct URL

### Story 12.2: Hide & Blacklist Channels

As a **user**,
I want **to hide content from specific YouTube channels**,
so that **I can avoid creators whose content I find inappropriate or unwanted**.

**Acceptance Criteria:**
1. "Hide Channel" action in video context menu for YouTube videos
2. Clicking action shows confirmation: "Hide all videos from [Channel Name]? You can unhide channels in Settings."
3. Channel added to `ChannelBlacklist` model with `channelID`, `reason = "User hidden"`, `blockedAt`
4. All videos from blacklisted channel hidden from library and search results
5. "Hidden Channels" list in Settings shows all blacklisted channels
6. "Unhide" button in Settings removes channel from blacklist (videos reappear)
7. Blacklist syncs via CloudKit (if sync enabled) so channel is hidden across devices

### Story 12.3: Content Policy Page

As a **user**,
I want **to view the app's content policy**,
so that **I understand what content is acceptable and how to report violations**.

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

### Story 12.4: Support & Contact Information

As a **user**,
I want **easily accessible support contact information**,
so that **I can report issues or ask questions**.

**Acceptance Criteria:**
1. "Support" or "Contact" link in Settings > About section
2. Contact options provided: email (support@yourapp.com), support page URL, GitHub issues (for open-source projects)
3. "Send Diagnostics" button creates sanitized log archive and opens email client with pre-filled support request
4. Support email response time commitment stated (e.g., "We aim to respond within 48 hours")
5. FAQ or Help Center link provided (if available)
6. Support information shown in App Store listing (consistent with in-app info)
7. UI test verifies support links are accessible from Settings

### Story 12.5: YouTube Disclaimers & Attributions

As a **user**,
I want **clear disclaimers that this app is not affiliated with YouTube**,
so that **I understand the relationship between the app and YouTube**.

**Acceptance Criteria:**
1. "Not affiliated with YouTube" disclaimer shown in About screen (Settings > About)
2. YouTube branding attribution: "Powered by YouTube" badge shown near IFrame Player (per YouTube Branding Guidelines)
3. YouTube logo displayed in sidebar "YouTube" section (using official logo, not modified)
4. App name "MyToob" avoids using "YouTube" trademark
5. App icon custom-designed, does not resemble YouTube logo
6. Terms of Service link includes statement: "This app uses YouTube services via official APIs and is subject to YouTube's Terms of Service"
7. Reviewer Notes document includes section explaining compliance with YouTube branding guidelines

### Story 12.6: Compliance Audit Logging

As a **developer**,
I want **audit logs for compliance-related actions (reports, channel hides)**,
so that **I can demonstrate responsible platform operation if questioned by reviewers**.

**Acceptance Criteria:**
1. Compliance events logged using OSLog with dedicated subsystem: `com.mytoob.compliance`
2. Events logged: "User reported video {videoID}", "User hid channel {channelID}", "User accessed Content Policy", "User contacted support"
3. Logs include: timestamp, user action, video/channel ID, no PII (no video titles, usernames)
4. Logs stored securely, not accessible to users (only via diagnostics export with user consent)
5. Log retention: 90 days, then auto-deleted
6. "Export Compliance Logs" action (hidden, developer-only) for App Store review submission
7. Logs formatted as JSON for machine-readability

---

## Epic 13: macOS System Integration

**Goal:** Deeply integrate with macOS platform features: Spotlight search indexing, App Intents for Shortcuts automation, menu bar controls for playback, and comprehensive keyboard shortcuts. This epic makes the app feel like a native macOS citizen, accessible system-wide and efficient for power users.

### Story 13.1: Spotlight Indexing for Videos

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

### Story 13.2: App Intents for Shortcuts

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

### Story 13.3: Menu Bar Mini-Controller

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

### Story 13.4: Comprehensive Keyboard Shortcuts

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

### Story 13.5: Command Palette (⌘K)

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

### Story 13.6: Drag-and-Drop from External Sources

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

## Epic 14: Accessibility & Polish

**Goal:** Ensure the app is fully accessible to users with disabilities (VoiceOver support, keyboard-only operation, high-contrast themes) and polished with smooth animations, loading states, empty states, and error handling. This epic elevates the app from functional to delightful, meeting Apple's accessibility standards and user experience expectations.

### Story 14.1: VoiceOver Support for All UI Elements

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

### Story 14.2: Keyboard-Only Navigation

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

### Story 14.3: High-Contrast Theme

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

### Story 14.4: Loading States & Progress Indicators

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

### Story 14.5: Empty States with Helpful Messaging

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

### Story 14.6: Smooth Animations & Transitions

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

## Epic 15: Monetization & App Store Release

**Goal:** Implement StoreKit 2 in-app purchase paywall for Pro tier, configure App Store submission package with reviewer documentation, and create notarized DMG for alternate distribution. This epic completes the product with monetization and distribution strategy, enabling both App Store approval and power-user alternate distribution.

### Story 15.1: StoreKit 2 Configuration

As a **developer**,
I want **StoreKit 2 configured with Pro tier in-app purchase**,
so that **users can unlock premium features**.

**Acceptance Criteria:**
1. App Store Connect: in-app purchase created (non-consumable, product ID: `com.mytoob.pro`)
2. StoreKit configuration file created for local testing (`.storekit`)
3. Purchase flow tested in Xcode with StoreKit testing environment (no real money)
4. Pro tier price set: $9.99 USD (adjust for other regions)
5. Product description written: "Unlock advanced AI organization, vector search, research tools, Spotlight integration, and more."
6. Purchase UI shown to free users: "Upgrade to Pro" button in toolbar or feature-gated screens
7. Receipt validation implemented: verify purchase on app launch, cache result

### Story 15.2: Paywall & Feature Gating

As a **free user**,
I want **to see which features require Pro and easily upgrade**,
so that **I understand the value proposition and can unlock features when ready**.

**Acceptance Criteria:**
1. Feature comparison sheet shown when clicking "Upgrade to Pro": Free vs. Pro columns
2. Free tier features: basic playback (YouTube + local), simple search, manual collections
3. Pro tier features: AI embeddings/clustering/search, research notes, Spotlight/App Intents, note templates, advanced filters
4. Gated features show lock icon + "Pro" badge in UI
5. Clicking gated feature shows paywall: "Unlock with Pro" + "Upgrade Now" button
6. Purchase flow: click "Upgrade Now" → StoreKit 2 sheet → authenticate with Apple ID → purchase confirmed → features unlocked
7. No dark patterns: clear value proposition, easy to dismiss paywall, "Restore Purchase" option prominently displayed

### Story 15.3: Restore Purchase & Subscription Management

As a **user**,
I want **to restore my Pro purchase on new devices or after reinstall**,
so that **I don't have to pay again**.

**Acceptance Criteria:**
1. "Restore Purchase" button in Settings > Pro tier section
2. Clicking button calls `AppStore.sync()` (StoreKit 2 receipt sync)
3. If valid purchase found, unlock Pro features immediately
4. If no purchase found, show message: "No Pro purchase found for this Apple ID"
5. "Manage Subscription" link opens App Store subscriptions page (if using subscription model)
6. Purchase status shown in Settings: "Pro (Purchased)" or "Free (Upgrade to Pro)"
7. UI test verifies restore purchase flow in StoreKit testing environment

### Story 15.4: App Store Submission Package

As a **developer**,
I want **all App Store submission materials prepared**,
so that **the app can be uploaded and approved**.

**Acceptance Criteria:**
1. App icon created in all required sizes (1024x1024 for App Store, 512x512, 256x256, etc.)
2. Screenshots created (1280x800, 2560x1600): library view, search, playback, collections, notes (5-10 screenshots)
3. App description written (concise, highlights key features, avoids "YouTube" in name)
4. Keywords selected: video, organizer, research, notes, library, macOS, AI, semantic search (under 100 characters)
5. Privacy Policy URL hosted: `https://yourwebsite.com/mytoob/privacy`
6. Support URL: `https://yourwebsite.com/mytoob/support`
7. App Store Connect listing completed: all metadata fields filled, screenshots uploaded

### Story 15.5: Reviewer Documentation & Compliance Notes

As a **developer**,
I want **comprehensive reviewer notes explaining compliance strategy**,
so that **App Store reviewers understand the architecture and approve the app**.

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

### Story 15.6: Notarized DMG Build for Alternate Distribution

As a **developer**,
I want **a notarized DMG build with power-user features enabled**,
so that **users who prefer direct downloads can access advanced local file features**.

**Acceptance Criteria:**
1. "DMG Build" configuration created in Xcode (separate from App Store build)
2. DMG build enables power-user features: deeper CV/ASR for local files (disabled in App Store build)
3. App codesigned with Developer ID certificate (not App Store certificate)
4. DMG notarized via `xcrun notarytool` (submits to Apple for malware scan)
5. Notarization ticket stapled to app bundle: `xcrun stapler staple MyToob.app`
6. DMG created with app + README: drag-to-Applications instructions
7. DMG hosted on project website: `https://yourwebsite.com/mytoob/download`
8. DMG build versioned separately (e.g., 1.0.1-dmg to distinguish from App Store 1.0.1)

---

## Checklist Results Report

*This section will be populated after running the pm-checklist validation. The checklist will verify:*

- [ ] All epics follow logical sequential order (foundational epics first)
- [ ] All stories are self-contained "vertical slices" delivering value
- [ ] No story depends on work from a later story/epic
- [ ] Story sizes are appropriate for AI agent execution (2-4 hour tasks)
- [ ] Acceptance criteria are clear, testable, and unambiguous
- [ ] Functional requirements (FR) and non-functional requirements (NFR) are comprehensive
- [ ] Technical assumptions are documented and rational
- [ ] UI/UX design goals align with product vision
- [ ] Compliance requirements (YouTube ToS, App Store Guidelines) are addressed in stories
- [ ] MVP scope is clearly defined (in-scope vs. out-of-scope features)

*Checklist execution pending—will be run after user confirmation.*

---

## Next Steps

### UX Expert Prompt

Now that the PRD is complete, please transition to **UX Expert mode** using the `front-end-spec-tmpl` template. Create a comprehensive front-end specification document for MyToob that details:

- macOS-native SwiftUI component hierarchy
- Screen-by-screen layouts (sidebar, content grid, player view, search, settings)
- Interaction patterns (drag-and-drop, context menus, keyboard shortcuts)
- Visual design system (color palette, typography, iconography)
- Accessibility requirements (VoiceOver labels, focus order, high-contrast)
- YouTube IFrame Player integration details
- AVKit player integration details

Reference this PRD for feature requirements and ensure the front-end spec covers all user-facing interactions described in the epics. Focus on creating a design that feels **native, fast, and intelligent** while maintaining compliance with YouTube policies (no UI overlay of player).

### Architect Prompt

After the front-end specification is complete, transition to **Architect mode** using the `fullstack-architecture-tmpl` template. Create a technical architecture document that defines:

- System architecture diagram (services, data flow, external APIs)
- SwiftData models with relationships and migration strategy
- YouTube integration architecture (OAuth, Data API client, IFrame Player bridge, quota management)
- Core ML pipeline (embedding generation, vector index, clustering, ranking)
- CloudKit sync architecture (conflict resolution, schema mapping)
- Security architecture (Keychain, sandboxing, security-scoped bookmarks)
- Performance optimization strategies (caching, background processing, lazy loading)
- Testing strategy (unit, integration, UI, migration, soak tests)

Reference both the PRD and front-end spec to ensure the architecture supports all features and UI requirements. Highlight compliance enforcement mechanisms (lint rules, policy boundaries) and provide clear implementation guidance for each epic.

---

*This PRD represents the complete product vision for MyToob v1.0. All subsequent development should reference this document to ensure feature completeness and alignment with project goals.*

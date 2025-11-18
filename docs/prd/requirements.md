# Requirements

## Functional Requirements

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

## Non-Functional Requirements

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

# Project Brief: MyToob - AI-Powered Video Organization for macOS

## Executive Summary

MyToob is a native macOS application that revolutionizes video organization and discovery by combining YouTube integration (via official IFrame Player) with local video library management, powered entirely by on-device AI. The app addresses the growing need for intelligent content organization, research capabilities, and privacy-first video management that neither YouTube's web interface nor existing media players currently provide. By leveraging Core ML for embeddings, vector search, and intelligent clustering, MyToob offers tangible value beyond a simple wrapper—providing researchers, content curators, and knowledge workers with a powerful tool for managing their video consumption and research workflows.

**Key Value Proposition:** Privacy-first, AI-powered video organization that works seamlessly with both YouTube content and local files, offering advanced search, automatic topic clustering, and research note-taking capabilities—all processed on-device without external data collection.

## Problem Statement

### Current State and Pain Points

**YouTube's Organizational Limitations:**
- YouTube's web interface provides minimal organizational tools beyond basic playlists
- No semantic search or topic-based discovery across subscriptions
- Limited note-taking and research capabilities
- No integration with local video libraries
- Privacy concerns with all processing happening on Google's servers

**Local Video Management Challenges:**
- Existing media players lack intelligent organization features
- No unified interface for managing both online and local content
- Difficult to discover related videos across disparate sources
- No AI-powered tagging or clustering capabilities

**Research and Knowledge Work Gaps:**
- Content creators, researchers, and students need better tools for organizing video research
- No way to semantically search across watched content
- Limited ability to create collections with notes and citations
- Lack of privacy-respecting solutions for sensitive research topics

### Impact and Urgency

The explosion of video content has created an organizational crisis for knowledge workers. Users spend significant time manually organizing content, re-searching for videos they've already watched, and managing disconnected tools for YouTube and local files. This represents both a productivity loss and a missed opportunity for AI-enhanced discovery and learning.

With increasing privacy awareness, users are seeking alternatives that keep their data on-device rather than sending viewing habits and organizational preferences to cloud services. The timing is ideal as Apple Silicon's machine learning capabilities make sophisticated on-device AI practical and performant.

### Why Existing Solutions Fall Short

- **YouTube's web interface:** Limited organization, no privacy, no local file support
- **Traditional media players (VLC, IINA):** No YouTube integration, no AI features
- **YouTube downloaders/wrappers:** Violate ToS, risk account bans, no official API support
- **Cloud-based video organizers:** Privacy concerns, subscription costs, limited AI
- **Browser extensions:** Limited functionality, inconsistent experience, no local files

## Proposed Solution

### Core Concept

MyToob is a native macOS application that provides a unified, AI-powered interface for organizing and discovering video content from multiple sources:

1. **YouTube Integration (Compliant):** Uses the official YouTube IFrame Player API for playback and YouTube Data API for metadata—fully compliant with YouTube's Terms of Service and App Store guidelines
2. **Local Video Support:** Full-featured local file playback via AVKit with advanced features (chapters, waveforms, snapshots)
3. **On-Device AI:** Core ML-powered embeddings, vector search, and clustering that runs entirely on the user's Mac
4. **Research Tools:** Note-taking, collections, bidirectional links, and Markdown export
5. **Privacy-First:** All AI processing happens on-device; optional CloudKit sync uses only user's private iCloud storage

### Key Differentiators

**Compliance-First Architecture:**
- Uses YouTube's official APIs exclusively (IFrame Player, Data API)
- No stream downloading, caching, or ad-blocking
- Comprehensive UGC safeguards (reporting, channel blocking, content policy)
- Clear path to App Store approval with detailed reviewer documentation

**Tangible Independent Value:**
- Semantic search across all video content using natural language queries
- Automatic topic clustering that groups related videos across channels
- Smart recommendations based on viewing patterns and research topics
- Integrated note-taking and citation management
- Spotlight and Shortcuts integration for system-wide access

**Privacy & Performance:**
- All AI processing on-device via Core ML (embeddings, clustering, ranking)
- No external analytics or data collection without explicit opt-in
- Fast and responsive: P95 query latency < 50ms, cold start < 2s
- Works offline for cached metadata and local files

**Dual Distribution Strategy:**
- App Store build with strict YouTube compliance
- Notarized DMG with power-user features for local files only

### Why This Will Succeed

1. **Technical Feasibility:** Built on proven Apple technologies (SwiftUI, Core ML, SwiftData, CloudKit)
2. **Compliance Strategy:** Clear separation of YouTube and local capabilities, with comprehensive ToS adherence
3. **Real Value:** Solves actual organizational pain points with meaningful AI features
4. **Market Timing:** Apple Silicon makes on-device AI practical; privacy concerns drive demand
5. **Monetization:** Clear freemium model (basic features free, AI/research tools in Pro tier)

## Target Users

### Primary User Segment: Researchers & Knowledge Workers

**Profile:**
- Graduate students, academics, content creators, professional learners
- Age 25-45, tech-savvy, Mac users
- Consume 10+ hours of video content weekly for work/learning
- Currently juggle multiple tools (YouTube, note apps, reference managers)

**Current Behaviors:**
- Watch educational content, tutorials, conference talks, interviews
- Take notes in separate apps (Notion, Obsidian, Apple Notes)
- Manually organize playlists and bookmarks
- Struggle to relocate videos they've watched previously

**Needs & Pain Points:**
- Need to organize research materials across YouTube and local files
- Want semantic search to find videos by topic/concept, not just title keywords
- Require integrated note-taking with timestamps and citations
- Value privacy for sensitive research topics
- Need to export/share research collections with colleagues

**Goals:**
- Efficiently manage video-based research and learning
- Quickly relocate and reference previously watched content
- Build organized knowledge bases from video content
- Maintain privacy and data ownership

### Secondary User Segment: YouTube Power Users

**Profile:**
- Active YouTube subscribers who follow 50+ channels
- Create extensive playlists and use Watch Later heavily
- Frustrated with YouTube's limited organizational tools
- Want better discovery across their subscriptions

**Needs & Pain Points:**
- Current YouTube interface makes it hard to find older videos from subscriptions
- Playlists are manual and time-consuming to maintain
- Want automatic grouping by topic across channels
- Desire better offline/download management for travel

**Goals:**
- Better organize subscription content
- Discover connections between videos across channels
- Manage watch progress and viewing history more effectively

### Tertiary User Segment: Local Media Library Enthusiasts

**Profile:**
- Users with extensive local video collections (courses, screencasts, personal videos)
- Currently use basic media players (VLC, IINA, QuickTime)
- Want advanced organization without cloud upload

**Needs & Pain Points:**
- Existing players lack organizational features
- No way to tag, search, or cluster local videos intelligently
- Want to combine local and YouTube content in unified interface

**Goals:**
- Organize large local video libraries efficiently
- Apply AI tagging and clustering to personal collections
- Unified interface for all video consumption

## Goals & Success Metrics

### Business Objectives

- **Launch:** Ship App Store-approved v1.0 within 6 months of development start
- **User Acquisition:** Achieve 1,000 active users within first 3 months post-launch
- **Conversion:** Convert 15% of active users to Pro tier within first year
- **Retention:** Maintain 60% monthly active user retention rate
- **Compliance:** Zero YouTube ToS violations or App Store rejections

### User Success Metrics

- **Engagement:** 60%+ of weekly users actively use AI organization features (search, collections, clustering)
- **Search Efficacy:** 80%+ of search queries return relevant results in top-5
- **Performance:** Users report app is fast and responsive (validated by telemetry: <50ms search, <2s cold start)
- **Feature Adoption:** Users create average of 5+ collections with 20+ videos each within first month
- **Satisfaction:** Net Promoter Score (NPS) of 40+ from user surveys

### Key Performance Indicators (KPIs)

- **Technical Performance:**
  - P95 search query latency < 50ms on M1/M2 Macs
  - Cold start to first render < 2 seconds
  - Warm start < 500ms
  - App remains responsive (<16ms frame budget) during background indexing

- **AI Effectiveness:**
  - Embedding generation < 10ms average per video
  - Cluster stability across reboots (>90% consistency)
  - Query relevance: >80% relevant results in top-5

- **API Efficiency:**
  - YouTube API quota usage: <10,000 units/day per user
  - Cache hit rate: >90% on repeated metadata requests
  - ETag-based request reduction: >95% cached responses on refresh

- **User Growth:**
  - Weekly Active Users (WAU) growth rate: 10%+ month-over-month
  - Pro tier conversion rate: 15%+ of active users
  - Churn rate: <10% monthly

## MVP Scope

### Core Features (Must Have)

- **YouTube Integration (Compliant):**
  - OAuth authentication with minimal scopes (youtube.readonly)
  - YouTube IFrame Player in WKWebView for compliant playback
  - YouTube Data API client with quota management (ETags, field filtering, unit budgeting)
  - Import subscriptions, playlists, and watch history
  - No stream downloading, caching, or ad manipulation

- **Local Video Playback:**
  - AVKit-based playback for local files (MP4, MOV, MKV, etc.)
  - Transport controls, scrubbing, and playback state persistence
  - User-selected file access with security-scoped bookmarks

- **On-Device AI Organization:**
  - Core ML-based text embeddings (384-dim, 8-bit quantized)
  - Thumbnail OCR for extracting text from video thumbnails
  - HNSW vector index for fast similarity search
  - Automatic topic clustering (kNN graph + Leiden/Louvain algorithm)
  - Auto-generated cluster labels from metadata keywords

- **Search & Discovery:**
  - Hybrid search (keyword + vector similarity)
  - Natural language queries
  - Filter by duration, recency, channel, cluster
  - Search results ranked by gradient-boosted model (recency, similarity, engagement)

- **Collections & Organization:**
  - User-created collections/folders
  - Drag-and-drop organization
  - Auto-collections based on clusters
  - AI-suggested topic tags

- **Storage & Sync:**
  - SwiftData for local persistence
  - Optional CloudKit sync for user data (embeddings, tags, notes, progress)
  - Metadata and thumbnail caching (no YouTube video caching)

- **UGC Safeguards (App Store Compliance):**
  - Report content (deep-link to YouTube's reporting flow)
  - Hide/blacklist channels
  - Visible content policy page
  - Easy-to-find contact/support

- **macOS Integration:**
  - Native SwiftUI interface
  - Keyboard shortcuts and command palette
  - Dark mode support
  - Window management and Picture-in-Picture

### Out of Scope for MVP

- **Downloading/saving YouTube videos for offline viewing**
- **Ad-blocking, ad-skipping, or SponsorBlock integration**
- **YouTube video/audio caching or prefetching**
- **Alternative YouTube frontends (Invidious, Piped) in App Store build**
- **Frame-level computer vision analysis of YouTube streams** (policy boundary: YouTube analysis limited to metadata/thumbnails only)
- **Multi-user collaboration features**
- **Mobile apps (iOS/iPadOS)**
- **Video editing or annotation tools**
- **Live streaming support**
- **Advanced local file features** (waveforms, deep CV/ASR—saved for DMG build)
- **Playlist sharing/social features**
- **Browser extension**

### MVP Success Criteria

MVP is successful when:
1. App Store approval achieved with no compliance rejections
2. YouTube playback works reliably via IFrame Player (no ToS violations)
3. Users can search 100+ saved videos and get relevant results in <50ms
4. Collections and clustering provide clear organizational value
5. App is stable (crash-free rate >99.5%)
6. Positive user feedback on performance and usefulness (early beta NPS >30)
7. Zero API quota violations or account bans

## Post-MVP Vision

### Phase 2 Features

**Enhanced AI Capabilities:**
- Downloadable larger/better embedding models for Pro users
- Multi-modal embeddings (combining text, thumbnails, and audio transcripts for local files)
- Personalized ranking models that learn from individual viewing patterns
- Smart recommendations for "videos related to your research topics"

**Advanced Research Tools:**
- Full-featured note editor with rich text, images, and video embeds
- Bidirectional links between notes and videos
- Timeline/chronological view of research evolution
- Export to academic citation formats (BibTeX, APA, MLA)
- Integration with reference managers (Zotero, Mendeley)

**Collaboration & Sharing:**
- Shareable collection links (view-only)
- Collaborative collections with team members
- Export collections as websites or PDF reports

**Enhanced Local File Features (DMG Build):**
- Frame-level computer vision analysis for local files
- Automatic speech recognition and transcription
- Waveform visualization
- Chapter detection and editing
- Advanced metadata editing

### Long-term Vision (1-2 Years)

**Cross-Platform Expansion:**
- iOS/iPadOS companion apps (view-only, sync with Mac)
- Apple TV app for collections playback
- Apple Watch remote control

**AI Research Assistant:**
- Natural language queries: "Show me videos about transformer architecture from last month"
- Automatic summarization of video content (metadata-based for YouTube)
- Knowledge graph connecting concepts across videos
- "Smart briefings" that surface relevant unwatched content

**Enhanced Discovery:**
- Cross-user recommendations (privacy-preserving federated learning)
- Trending topics within user's interest areas
- Integration with other research tools (Notion, Obsidian, DEVONthink)

**Power User Features:**
- AppleScript/Shortcuts automation
- Custom AI model plugins
- Advanced import/export (JSON, CSV, XML)
- Keyboard maestro integration

### Expansion Opportunities

- **Education Market:** Tailored features for educators and students (course organization, assignment tracking)
- **Content Creator Tools:** Competitor analysis, trend tracking, inspiration boards
- **Enterprise:** Corporate training video management, compliance tracking
- **Academic Research:** Integration with institutional repositories, peer review tools
- **Media Production:** Pre-production research, stock footage management

## Technical Considerations

### Platform Requirements

- **Target Platform:** macOS 14.0 (Sonoma) or later
- **Hardware:** Apple Silicon (M1/M2/M3) or Intel with minimum 8GB RAM
- **Performance Requirements:**
  - P95 search latency < 50ms (in-memory index)
  - Cold start < 2 seconds
  - Smooth playback and UI (<16ms frame times)
  - Efficient battery usage (Energy Impact: Low)

### Technology Preferences

**Frontend:**
- SwiftUI for native macOS interface
- WKWebView for YouTube IFrame Player integration
- AVKit/AVFoundation for local video playback
- Swift 5.10+ with modern concurrency (async/await, actors)

**Data Layer:**
- SwiftData for local persistence (VideoItem, ClusterLabel, Note, ChannelBlacklist models)
- CloudKit for optional sync (private database)
- Keychain for OAuth tokens and sensitive data

**AI/ML Stack:**
- Core ML for embeddings (sentence-transformer model, 384-dim, 8-bit quantized)
- HNSW index for vector similarity search (in-memory with persistence)
- Gradient-boosted trees (Core ML) for ranking
- Vision framework for thumbnail OCR
- Community detection algorithms (Leiden/Louvain) for clustering

**Networking:**
- URLSession for YouTube Data API
- OAuth 2.0 with minimal scopes (youtube.readonly)
- ETag/If-None-Match for caching
- Circuit breaker pattern for quota management

**Development Tools:**
- Xcode 15+
- SwiftLint + swift-format for code quality
- GitHub Actions for CI/CD
- XcodeBuildMCP for automation

### Architecture Considerations

**Repository Structure:**
- Single Xcode project with SwiftPM dependencies only
- App group for shared data access
- Modular architecture: separate targets for networking, AI, storage, UI

**Service Architecture:**
- Single-process native app (no backend services)
- All processing on-device
- Optional CloudKit sync (user-controlled)

**Integration Requirements:**
- YouTube IFrame Player API (playback control, state events)
- YouTube Data API v3 (metadata only, quota: 10k units/day)
- Spotlight indexing for system-wide search
- App Intents for Shortcuts integration
- Menu bar controls for now playing

**Security/Compliance:**
- App Sandbox enabled
- Network client entitlement (YouTube API, CloudKit)
- User-selected file read/write (local videos)
- No hardcoded secrets (all OAuth-based)
- Security-scoped bookmarks for local file access
- Keychain storage for OAuth refresh tokens

**Policy Enforcement:**
- Compile-time lint rules blocking googlevideo.com access
- No URLSession calls to non-official YouTube domains
- Player visibility enforcement (pause when hidden, allow native PiP only)
- UGC controls always accessible

## Constraints & Assumptions

### Constraints

**Budget:**
- Self-funded indie development
- Minimal external costs (Apple Developer Program: $99/year, potential Core ML model hosting)
- Cannot afford dedicated designers or extensive user testing initially

**Timeline:**
- **Aggressive target:** 6 months from start to App Store launch (15 epics with 100+ stories)
- **Realistic target:** 9 months with 3-month buffer for YouTube API testing, App Store review iterations, and AI model tuning
- Solo developer or small team (1-2 developers)
- Part-time development alongside other commitments
- **Note:** Timeline assumes AI-assisted development (Claude Code + MCP) for velocity gains

**Resources:**
- Development by AI-assisted coding (Claude Code + MCP)
- Bootstrap design (system components, minimal custom UI initially)
- Community-driven testing and feedback (beta via TestFlight)

**Technical:**
- Must comply with YouTube Terms of Service and Developer Policies
- Must pass App Store review (Guidelines 1.2 UGC, 5.2.3 IP/downloading)
- Limited by YouTube Data API quota (10k units/day default, can request increase)
- macOS-only initially (requires platform-specific features: SwiftUI, Core ML, CloudKit)
- Apple Silicon optimization priority (Intel support secondary)

**Legal/Compliance:**
- Cannot use "YouTube" in app name or icon
- Must include "not affiliated with YouTube" disclaimer
- Must follow YouTube branding guidelines for attribution
- Must implement UGC moderation controls
- Must provide privacy policy and terms of service

### Key Assumptions

- Users have YouTube accounts and are willing to authenticate with OAuth
- Users understand the distinction between compliant YouTube integration and "downloader" apps
- Sufficient demand exists for privacy-focused, AI-powered video organization
- App Store reviewers will approve compliant YouTube integration with proper documentation
- Users will accept freemium model (basic free, AI features paid)
- YouTube API quotas are sufficient for typical user behavior (can request increase if needed)
- On-device AI quality is sufficient for valuable organization (no cloud LLMs required)
- CloudKit sync is acceptable alternative to custom backend (no server infrastructure needed)
- Users will find value in unified YouTube + local file management

## Risks & Open Questions

### Key Risks

- **App Store Review Variance:** macOS App Store reviewers may interpret guidelines differently; risk of rejection despite compliance efforts.
  - *Mitigation:* Comprehensive reviewer documentation, clear architecture explainer, pre-submission consultation with Apple, maintain DMG distribution path

- **YouTube Policy Changes:** YouTube could change ToS, API quotas, or IFrame Player capabilities.
  - *Mitigation:* Design architecture to adapt (e.g., degrade gracefully if quotas reduced), monitor policy updates, maintain local file features as independent value

- **Quota Limitations:** Heavy users might exceed 10k units/day quota.
  - *Mitigation:* Aggressive caching (ETags, field filtering), quota budgeting dashboard, user education, quota increase requests for Pro users

- **AI Quality Expectations:** On-device models may not match cloud LLM quality; users may expect ChatGPT-level features.
  - *Mitigation:* Clear marketing about on-device privacy trade-offs, focus on features that work well with smaller models (embeddings, clustering), future option for downloadable better models

- **Performance on Intel Macs:** Core ML may be slower on Intel, impacting user experience.
  - *Mitigation:* Apple Silicon as primary target, Intel as "best effort" with performance warnings, eventual Intel deprecation

- **Competition:** Established players (Playlists.ai, similar tools) may add competing features.
  - *Mitigation:* Focus on unique combination: privacy + local files + research tools + compliance

- **Monetization:** Users may resist paying for organization features they expect to be free.
  - *Mitigation:* Generous free tier, clear Pro value proposition (advanced AI, research tools), avoid any appearance of "paying to remove ads"

### Open Questions

- Should we ship with optional downloadable larger embedding models behind Pro toggle? (Trade-off: quality vs. complexity/download size)
- Which OCR strategy for thumbnails performs best offline: Vision framework vs. Tesseract? (Need benchmarking)
- What level of chapter/summary extraction is permissible from YouTube metadata alone without analyzing streams? (Need legal review)
- How to handle YouTube Premium members who want background playback? (IFrame Player limitations)
- Should DMG build allow all local features by default, or require explicit user opt-in? (UX/compliance trade-off)
- Can we pre-generate embeddings for popular YouTube videos to speed up first-time indexing? (Infrastructure/cost question)
- Should we build custom MCP servers for this project's unique workflows? (Development efficiency question)

### Areas Needing Further Research

- **Legal Review:** Formal legal opinion on compliance strategy, especially boundary between metadata-based AI and stream analysis
- **UX Research:** User testing on AI feature discoverability and value perception
- **Performance Benchmarking:** Real-world testing of Core ML models on various Mac hardware
- **Competitive Analysis:** Deep dive into existing tools (Playlists.ai, Raindrop.io, etc.) to identify gaps
- **Quota Modeling:** Analyze typical user behavior to project API quota usage patterns
- **App Store Precedents:** Research similar apps that successfully passed review (or were rejected) to learn patterns
- **Accessibility:** Ensure VoiceOver and keyboard-only operation work seamlessly (testing with accessibility users)
- **Monetization Validation:** Survey potential users about willingness to pay and acceptable pricing

## Appendices

### A. Research Summary

**Market Research:**
- Video content consumption continues to grow (YouTube: 1B+ hours watched daily)
- Privacy-focused software seeing increased demand post-GDPR/CCPA
- Apple Silicon adoption accelerating (60%+ of Mac sales in 2023)
- Knowledge workers increasingly use video for professional learning

**Competitive Analysis:**
- **Playlists.ai:** Web-based, cloud-only, limited local file support, subscription-based
- **YouTube Premium:** Better mobile experience but no organizational features
- **Raindrop.io / Pocket:** Bookmarking tools with limited video-specific features
- **Notion / Obsidian:** Note-taking tools without integrated video playback
- **Traditional downloaders (yt-dlp, etc.):** Violate ToS, command-line only, no organization

**Gap Identification:**
MyToob uniquely combines: YouTube compliance + local files + on-device AI + research tools + native macOS experience

**Technical Feasibility:**
- Core ML embeddings proven performant on Apple Silicon (sentence-transformers: <10ms)
- HNSW index implementations available (can port or use existing libraries)
- IFrame Player API well-documented with active community
- SwiftData + CloudKit mature technologies with good tooling

### B. Stakeholder Input

**Developer Perspective (Self):**
- Excited about building something I want to use personally
- Confidence in AI/ML implementation skills
- Some concern about App Store review unpredictability
- Committed to doing this right (compliance-first approach)

**Potential Early Users (Informal Conversations):**
- Researchers expressed strong interest in unified video research tool
- Privacy concerns with existing cloud-based solutions
- Willingness to pay for quality Mac-native experience ($5-15/month range mentioned)
- Skepticism about App Store approval, but excited if achievable

### C. References

**YouTube Documentation:**
- [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference)
- [YouTube Data API v3](https://developers.google.com/youtube/v3)
- [YouTube Terms of Service](https://www.youtube.com/t/terms)
- [YouTube Developer Policies](https://developers.google.com/youtube/terms/developer-policies)
- [YouTube API Quota Costs](https://developers.google.com/youtube/v3/determine_quota_cost)
- [YouTube Branding Guidelines](https://developers.google.com/youtube/terms/branding-guidelines)

**Apple Documentation:**
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)

**Technical Resources:**
- [HNSW Algorithm Paper](https://arxiv.org/abs/1603.09320)
- [Leiden Algorithm Paper](https://www.nature.com/articles/s41598-019-41695-z)
- [Sentence Transformers](https://www.sbert.net/)

## Next Steps

### Immediate Actions

1. **Validate compliance strategy** with App Store pre-submission consultation (if available) or thorough policy review
2. **Set up development environment:** Xcode project, GitHub repo, CI/CD pipeline, MCP servers
3. **Create detailed PRD** from this project brief with PM agent (@pm)
4. **Prototype IFrame Player integration** to validate YouTube playback approach works as expected
5. **Test Core ML embedding models** to confirm performance targets achievable on target hardware
6. **Begin architecture document** with detailed technical decisions (@architect)

### PM Handoff

This Project Brief provides the full context for **MyToob** - an AI-powered video organization app for macOS. The project emphasizes:

1. **Compliance-first approach** to YouTube integration (official APIs only)
2. **Privacy-first architecture** (on-device AI, no external data collection)
3. **Tangible independent value** beyond simple YouTube wrapper (AI organization, research tools)
4. **Dual distribution** strategy (App Store + DMG for power users)

Please start in **PRD Generation Mode**. Review this brief thoroughly and work with the user to create the PRD section by section, asking for any necessary clarification or suggesting improvements. Pay special attention to:

- Maintaining clear separation between YouTube and local file capabilities (compliance boundary)
- Defining specific acceptance criteria for ToS compliance features
- Breaking down the 14 epics from the original IdeaDoc into actionable stories
- Ensuring architecture decisions support the compliance strategy

The original IdeaDoc (IdeaDoc.md) contains extensive technical details including epics A-N, data models, and task definitions that should inform the PRD structure.

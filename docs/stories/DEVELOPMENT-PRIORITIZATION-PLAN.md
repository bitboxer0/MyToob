# MyToob Development Prioritization & Parallelization Plan

**Created:** 2025-11-17
**Created By:** Bob (Scrum Master)
**Strategy:** Maximum Parallelization with Dependency Awareness

---

## Executive Summary

This plan organizes all 91 stories into **5 development phases** with **4 parallel work streams** to maximize velocity while respecting technical dependencies.

**Key Metrics:**
- **Total Stories:** 91
- **Phases:** 5 (Foundation → Core Features → AI/Search → Polish → Release)
- **Parallel Streams:** Up to 4 teams working simultaneously
- **Critical Path:** ~23 stories (sequential dependencies)
- **Parallelizable:** ~68 stories (75% can run in parallel)

---

## Dependency Analysis

### Critical Path (Must Be Sequential)
1. 1.1 Xcode Project Setup *(blocks everything)*
2. 1.4 SwiftData Core Models *(blocks data features)*
3. 1.5 Basic App Shell *(blocks UI features)*
4. 2.1-2.3 OAuth & YouTube API *(blocks YouTube playback)*
5. 3.1-3.3 YouTube Player *(blocks Focus Mode)*
6. 7.1-7.5 AI Embeddings *(blocks clustering & search)*
7. 8.1-8.3 Clustering *(blocks smart collections)*
8. 15.4 App Store Submission *(final gate)*

### Independent Work Streams
- **Local Files (Epic 5):** No YouTube dependencies, can start early
- **macOS Integration (Epic 13):** Platform features, mostly independent
- **Infrastructure (Epic 1 remaining):** CI/CD, linting, logging
- **Compliance (Epic 12):** Can define policies early, implement later

---

## Phase 1: Foundation (Week 1)
**Goal:** Establish project infrastructure and core data layer

### 🔴 Critical Path (Sequential - Team Alpha)
**Blocking:** Everything depends on these
```
Day 1-2: 1.1 Xcode Project Setup & Configuration
Day 3-4: 1.4 SwiftData Core Models
Day 4-5: 1.5 Basic App Shell & Navigation
```

### 🟢 Parallel Stream 1 (Team Bravo - Infrastructure)
**Independent:** Can start after 1.1 completes
```
Day 2-3: 1.2 SwiftLint & Code Quality Tooling
Day 3-5: 1.3 GitHub CI/CD Pipeline
Day 4-5: 1.6 Logging & Diagnostics Framework
```

### 🟡 Parallel Stream 2 (Team Charlie - Docs & Specs)
**Independent:** No code dependencies
```
Day 1-5: 12.5 Privacy Policy & Data Disclosure (draft)
Day 1-5: 12.4 ToS Compliance Enforcement (spec)
Day 1-5: 15.6 Marketing Assets & App Store Page (prep)
```

**Phase 1 Output:**
- ✅ Working macOS app with data persistence
- ✅ CI/CD pipeline operational
- ✅ Code quality gates enforced
- ✅ Compliance documentation started

**Stories Completed:** 9/91 (10%)

---

## Phase 2: Core Features (Weeks 2-4)
**Goal:** Implement YouTube integration, local playback, and data sync

### 🔴 Critical Path (Team Alpha - YouTube)
**Blocking:** Focus Mode, Compliance features
```
Week 2:
  2.1 Google OAuth Authentication Flow
  2.2 Token Storage & Automatic Refresh
  2.3 YouTube Data API Client Foundation

Week 3:
  3.1 WKWebView YouTube IFrame Player Setup
  3.2 JavaScript Bridge for Playback Control
  3.3 Player State & Time Event Handling

Week 4:
  2.6 Import User Subscriptions (uses 2.1-2.3)
  3.6 Error Handling & Unsupported Videos
```

### 🟢 Parallel Stream 1 (Team Bravo - YouTube Infrastructure)
**Depends on:** 2.3 API Client
```
Week 2-3:
  2.4 ETag-Based Caching for Metadata
  2.5 API Quota Budgeting & Circuit Breaker

Week 3-4:
  3.4 Picture-in-Picture Support
  3.5 Player Visibility Enforcement (Compliance)
```

### 🟡 Parallel Stream 2 (Team Charlie - Local Files)
**Independent:** No YouTube dependencies
```
Week 2:
  5.1 Local File Import via File Picker
  5.2 Security-Scoped Bookmarks for Persistent Access

Week 3:
  5.3 AVPlayerView Integration for Local Playback
  5.4 Playback State Persistence for Local Files

Week 4:
  5.5 Drag-and-Drop File Import
  5.6 Local File Metadata Extraction
```

### 🔵 Parallel Stream 3 (Team Delta - Data Layer)
**Depends on:** 1.4 SwiftData Models
```
Week 2-3:
  6.1 SwiftData Model Container & Configuration
  6.2 Versioned Schema Migrations
  6.3 CloudKit Container & Private Database Setup

Week 3-4:
  6.4 CloudKit Sync Conflict Resolution
  6.5 Sync Status UI & User Controls
  6.6 Caching Strategy for Metadata & Thumbnails
```

**Phase 2 Output:**
- ✅ YouTube OAuth + API integration working
- ✅ YouTube video playback functional
- ✅ Local file playback functional
- ✅ CloudKit sync operational
- ✅ Both player types with state persistence

**Stories Completed:** 30/91 (33%)

---

## Phase 3: AI & Search (Weeks 5-7)
**Goal:** Implement AI embeddings, clustering, search, and collections

### 🔴 Critical Path (Team Alpha - AI Core)
**Blocking:** Search, Smart Collections
```
Week 5:
  7.1 Core ML Embedding Model Integration
  7.2 Metadata Text Preparation for Embeddings
  7.3 Thumbnail OCR Text Extraction

Week 6:
  7.4 Batch Embedding Generation Pipeline
  7.5 HNSW Vector Index Construction
  7.6 Vector Search Query Engine (depends on 7.5)

Week 7:
  8.1 kNN Graph Construction from Embeddings
  8.2 Leiden Community Detection Algorithm
  8.3 Cluster Centroid Computation & Label Generation
```

### 🟢 Parallel Stream 1 (Team Bravo - Search UI)
**Depends on:** 7.6 Vector Search
```
Week 6-7:
  9.1 Keyword Search Implementation
  9.2 Vector Similarity Search (needs 7.6)
  9.3 Hybrid Ranking Fusion
  9.4 Search UI & Real-Time Results
  9.5 Search Filters & Refinement
  9.6 Search History & Suggestions
```

### 🟡 Parallel Stream 2 (Team Charlie - Collections)
**Depends on:** 1.4 SwiftData Models
```
Week 5-6:
  10.1 Create & Manage Collections
  10.2 Add/Remove Videos from Collections
  10.3 Collection Sorting & Filtering
  10.4 Collection Export to Markdown

Week 7:
  10.5 Smart Collections from Clusters (needs 8.3)
  10.6 Collection Sharing & Import
```

### 🔵 Parallel Stream 3 (Team Delta - Smart Collections UI)
**Depends on:** 8.2 Clustering
```
Week 7:
  8.4 Auto-Collections UI in Sidebar
  8.5 Cluster Stability & Re-Clustering Trigger
  8.6 User Cluster Customization
```

**Phase 3 Output:**
- ✅ AI embeddings generated for all videos
- ✅ Semantic search fully functional
- ✅ Smart collections auto-generated
- ✅ Manual collections management
- ✅ Hybrid search (keyword + vector)

**Stories Completed:** 54/91 (59%)

---

## Phase 4: Focus Mode, Notes & Integration (Weeks 8-10)
**Goal:** User experience polish, productivity features, system integration

### 🟢 Parallel Stream 1 (Team Alpha - Focus Mode)
**Depends on:** 3.3 YouTube Player
```
Week 8:
  4.1 Focus Mode Global Toggle
  4.2 Hide YouTube Sidebar
  4.3 Hide Related Videos Panel

Week 9:
  4.4 Hide Comments Section
  4.5 Hide Homepage Feed
  4.7 Distraction Hiding Presets

Week 10:
  4.6 Focus Mode Scheduling (Pro Feature)
```

### 🟡 Parallel Stream 2 (Team Bravo - Research Tools)
**Depends on:** 3.3 YouTube Player, 5.3 Local Player
```
Week 8:
  11.1 Timestamped Note Creation
  11.2 Markdown Editor Integration
  11.3 Note-to-Video Timestamp Linking

Week 9:
  11.4 Note Search & Organization
  11.5 Note Export (Markdown, PDF)
  11.6 Research Dashboard View
```

### 🔵 Parallel Stream 3 (Team Charlie - macOS Integration)
**Independent:** Platform features
```
Week 8:
  13.1 Core Spotlight Indexing
  13.2 App Intents for Shortcuts

Week 9:
  13.3 Menu Bar Quick Actions
  13.4 Quick Look Preview Extension

Week 10:
  13.5 Share Extension Support
  13.6 Touch Bar Support (optional)
```

### 🟠 Parallel Stream 4 (Team Delta - Compliance)
**Depends on:** 2.6 Subscriptions, 3.6 Player Errors
```
Week 8-9:
  12.1 Report Content Functionality
  12.2 Block/Hide Channels
  12.3 Content Warnings & Age Gates

Week 10:
  12.6 Parental Controls (Optional)
```

**Phase 4 Output:**
- ✅ Focus Mode fully functional
- ✅ Research tools with notes & export
- ✅ Deep macOS system integration
- ✅ UGC safeguards implemented

**Stories Completed:** 73/91 (80%)

---

## Phase 5: Polish & Release (Weeks 11-12)
**Goal:** Accessibility, monetization, App Store submission

### 🟢 Parallel Stream 1 (Team Alpha - Accessibility)
**Depends on:** All UI features
```
Week 11:
  14.1 VoiceOver Support
  14.2 Keyboard Navigation
  14.3 High Contrast & Dark Mode

Week 12:
  14.4 Reduced Motion Support
  14.5 Dynamic Type Support
  14.6 Accessibility Audit & Testing
```

### 🟡 Parallel Stream 2 (Team Bravo - Monetization)
**Independent:** StoreKit implementation
```
Week 11:
  15.1 StoreKit 2 Integration
  15.2 Pro Tier IAP Implementation
  15.3 Subscription Management UI

Week 12:
  15.5 DMG Notarization & Distribution (parallel to submission)
```

### 🔴 Critical Path (Team Charlie - Release)
**Blocking:** Final launch
```
Week 12:
  15.4 App Store Submission Prep
  → Submit to App Store
  → Submit DMG for notarization
  → Final QA and release
```

**Phase 5 Output:**
- ✅ Full accessibility compliance
- ✅ Pro tier monetization live
- ✅ App Store submitted
- ✅ DMG build available

**Stories Completed:** 91/91 (100%) 🎉

---

## Team Structure & Recommended Composition

### Team Alpha (Critical Path Owners)
**Focus:** Core features that block other work
- **Skills:** Swift, SwiftUI, Core ML, YouTube API
- **Phase 1:** Foundation (Xcode, Models, Shell)
- **Phase 2:** YouTube OAuth & Playback
- **Phase 3:** AI Embeddings & Clustering
- **Phase 4:** Focus Mode
- **Phase 5:** Release coordination

### Team Bravo (Infrastructure & Search)
**Focus:** Infrastructure, search, monetization
- **Skills:** DevOps, Swift, Search algorithms, StoreKit
- **Phase 1:** CI/CD, Linting, Logging
- **Phase 2:** Caching, Quota, YouTube infrastructure
- **Phase 3:** Search UI & Hybrid ranking
- **Phase 4:** Research tools
- **Phase 5:** Monetization & IAP

### Team Charlie (Independent Features)
**Focus:** Local files, collections, macOS integration
- **Skills:** AVFoundation, SwiftUI, macOS frameworks
- **Phase 1:** Documentation & specs
- **Phase 2:** Local file playback
- **Phase 3:** Collections management
- **Phase 4:** macOS system integration
- **Phase 5:** App Store submission

### Team Delta (Data & Sync)
**Focus:** Data persistence, CloudKit, AI features
- **Skills:** SwiftData, CloudKit, Graph algorithms
- **Phase 2:** CloudKit sync
- **Phase 3:** Smart collections UI
- **Phase 4:** Compliance features
- **Phase 5:** Final QA

---

## Risk Mitigation

### High-Risk Dependencies
1. **Core ML Model Performance** (7.1)
   - **Mitigation:** Test early in Phase 3, have fallback model ready
   - **Impact:** Blocks search (9.2) and clustering (8.1)

2. **YouTube API Quota Limits** (2.5)
   - **Mitigation:** Implement caching (2.4) first, conservative defaults
   - **Impact:** Could limit subscriptions import (2.6)

3. **CloudKit Sync Conflicts** (6.4)
   - **Mitigation:** Test with simulated multi-device scenarios early
   - **Impact:** User data loss if wrong strategy

4. **App Store Review** (15.4)
   - **Mitigation:** YouTube ToS compliance review in Phase 4
   - **Impact:** Delays launch if rejected

### Recommended De-Risking
- **Week 3:** Core ML model smoke test (load + inference)
- **Week 5:** YouTube quota monitoring in production-like scenario
- **Week 7:** CloudKit conflict resolution integration tests
- **Week 10:** Pre-submission compliance audit

---

## Sprint Planning Template

### Sprint Structure (2-week sprints)

**Sprint 1 (Phase 1):** Foundation
- Alpha: 1.1, 1.4, 1.5
- Bravo: 1.2, 1.3, 1.6
- Charlie: 12.5, 12.4 (docs)

**Sprint 2-3 (Phase 2):** YouTube & Local Files
- Alpha: Epic 2 + Epic 3 (critical path)
- Bravo: 2.4, 2.5, 3.4, 3.5
- Charlie: Epic 5 (all stories)
- Delta: Epic 6 (all stories)

**Sprint 4-5 (Phase 3):** AI & Search
- Alpha: Epic 7 → Epic 8
- Bravo: Epic 9 (after 7.6)
- Charlie: Epic 10
- Delta: 8.4, 8.5, 8.6

**Sprint 6-7 (Phase 4):** UX Polish
- Alpha: Epic 4
- Bravo: Epic 11
- Charlie: Epic 13
- Delta: Epic 12

**Sprint 8 (Phase 5):** Release
- Alpha: Epic 14
- Bravo: Epic 15 (IAP)
- Charlie: 15.4 submission
- All: Final QA

---

## Velocity Assumptions

**Per Team Per Week:**
- Foundation work: 1-2 stories/week (complex, blocking)
- Feature work: 2-3 stories/week (parallel, moderate complexity)
- Polish work: 3-4 stories/week (independent, lower complexity)

**Total Timeline:** 12 weeks (3 months) with 4 parallel teams

**Single Team:** ~24-30 weeks (6-7 months) sequential

**Parallelization Speedup:** ~2.5x faster than single team

---

## Success Metrics

### Phase Gates
- **Phase 1:** App launches, builds in CI, models persist
- **Phase 2:** Can watch YouTube + local videos, data syncs
- **Phase 3:** Semantic search returns relevant results
- **Phase 4:** Focus Mode hides distractions, notes exportable
- **Phase 5:** Passes accessibility audit, App Store approved

### Quality Checkpoints
- **Code Coverage:** 80% unit tests (per phase)
- **Performance:** <2s cold start, <50ms search (Phase 3)
- **Compliance:** No YouTube ToS violations (Phase 4 audit)
- **Accessibility:** VoiceOver navigable (Phase 5)

---

## Next Steps

1. **Week 0 (Pre-Development):**
   - Finalize team assignments
   - Set up dev environments
   - Create Slack/communication channels per team
   - Schedule daily standups + weekly cross-team sync

2. **Sprint 1 Kickoff:**
   - Review Phase 1 stories with all teams
   - Establish definition of done
   - Set up story tracking (Jira/Linear/GitHub Projects)

3. **Continuous:**
   - Daily standups within teams
   - Weekly cross-team dependency sync (Scrum of Scrums)
   - Bi-weekly sprint planning & retrospectives

---

**Ready to start Sprint 1?** Let's build MyToob! 🚀

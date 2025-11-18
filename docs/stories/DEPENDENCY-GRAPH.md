# MyToob Story Dependency Graph

**Visual representation of story dependencies and parallelization opportunities**

---

## Critical Path (Red Line - Sequential Dependencies)

```
START
  ↓
1.1 Xcode Project Setup [BLOCKS EVERYTHING]
  ↓
1.4 SwiftData Core Models
  ↓
1.5 Basic App Shell
  ↓
2.1 OAuth Authentication ──→ 2.2 Token Storage ──→ 2.3 YouTube API Client
  ↓                                                      ↓
3.1 YouTube IFrame Player ──→ 3.2 JavaScript Bridge ──→ 3.3 Player State Events
  ↓                                                      ↓
7.1 Core ML Model ──→ 7.4 Batch Embeddings ──→ 7.5 HNSW Index ──→ 7.6 Vector Search
  ↓                                                                  ↓
8.1 kNN Graph ──→ 8.2 Leiden Clustering ──→ 8.3 Cluster Labels
  ↓
15.4 App Store Submission
  ↓
LAUNCH
```

**Critical Path Length:** ~23 stories (must be sequential)

---

## Parallel Work Stream 1: Infrastructure (Can Start After 1.1)

```
1.1 Xcode Project Setup ✓
  ↓
  ├─→ 1.2 SwiftLint (parallel)
  ├─→ 1.3 CI/CD Pipeline (parallel)
  └─→ 1.6 Logging Framework (parallel)
```

---

## Parallel Work Stream 2: Local Files (Independent - No YouTube Deps)

```
1.4 SwiftData Models ✓
  ↓
5.1 File Import ──→ 5.2 Security Bookmarks
  ↓                    ↓
5.3 AVPlayer Integration
  ↓
5.4 Playback Persistence
  ↓
5.5 Drag-Drop Import (parallel with 5.6)
5.6 Metadata Extraction (parallel with 5.5)
```

**Can start Week 2, complete by Week 4**

---

## Parallel Work Stream 3: Data Sync (Depends on 1.4 Models)

```
1.4 SwiftData Models ✓
  ↓
6.1 Model Container Config ──→ 6.2 Schema Migrations
  ↓                                ↓
6.3 CloudKit Setup ──→ 6.4 Conflict Resolution ──→ 6.5 Sync UI
                                                      ↓
                                                   6.6 Caching
```

**Can start Week 2, complete by Week 4**

---

## Parallel Work Stream 4: YouTube Infrastructure (Depends on 2.3 API)

```
2.3 YouTube API Client ✓
  ↓
  ├─→ 2.4 ETag Caching (parallel)
  ├─→ 2.5 Quota Budgeting (parallel)
  └─→ 2.6 Import Subscriptions (can start after 2.3)
```

---

## Parallel Work Stream 5: YouTube Player Features (Depends on 3.3)

```
3.3 Player State Events ✓
  ↓
  ├─→ 3.4 Picture-in-Picture (parallel)
  ├─→ 3.5 Visibility Enforcement (parallel)
  └─→ 3.6 Error Handling (parallel)
```

---

## Parallel Work Stream 6: Search (Depends on 7.6 Vector Search)

```
7.6 Vector Search Engine ✓
  ↓
9.1 Keyword Search ──→ 9.3 Hybrid Ranking
  ↓                      ↓
9.2 Vector Similarity ─┘  └─→ 9.4 Search UI ──→ 9.5 Filters ──→ 9.6 History
```

**Can start Week 6, complete by Week 7**

---

## Parallel Work Stream 7: Collections (Depends on 1.4 Models)

```
1.4 SwiftData Models ✓
  ↓
10.1 Create Collections ──→ 10.2 Add/Remove Videos
  ↓                            ↓
10.3 Sorting/Filtering      10.4 Export Markdown
  ↓
10.5 Smart Collections (WAITS FOR 8.3 Cluster Labels)
  ↓
10.6 Collection Sharing
```

**Can start Week 5, block at 10.5 until Week 7, complete Week 7**

---

## Parallel Work Stream 8: Smart Collections UI (Depends on 8.2)

```
8.2 Leiden Clustering ✓
  ↓
8.4 Auto-Collections UI (parallel with 8.5, 8.6)
8.5 Cluster Stability (parallel with 8.4, 8.6)
8.6 User Customization (parallel with 8.4, 8.5)
```

**Can start Week 7**

---

## Parallel Work Stream 9: Focus Mode (Depends on 3.3 Player)

```
3.3 Player State Events ✓
  ↓
4.1 Focus Toggle ──→ 4.7 Presets
  ↓
  ├─→ 4.2 Hide Sidebar (parallel)
  ├─→ 4.3 Hide Related (parallel)
  ├─→ 4.4 Hide Comments (parallel)
  └─→ 4.5 Hide Homepage (parallel)
  ↓
4.6 Focus Scheduling (Pro - after 15.2 IAP)
```

**Can start Week 8, complete Week 10**

---

## Parallel Work Stream 10: Research Tools (Depends on Players)

```
3.3 YouTube Player ✓ + 5.3 Local Player ✓
  ↓
11.1 Timestamped Notes ──→ 11.2 Markdown Editor ──→ 11.3 Timestamp Linking
  ↓                                                     ↓
11.4 Note Search ──────────────────────────────────→ 11.6 Research Dashboard
  ↓
11.5 Note Export
```

**Can start Week 8, complete Week 9**

---

## Parallel Work Stream 11: macOS Integration (Mostly Independent)

```
1.5 Basic App Shell ✓
  ↓
  ├─→ 13.1 Spotlight Indexing (parallel)
  ├─→ 13.2 App Intents (parallel)
  ├─→ 13.3 Menu Bar (parallel)
  ├─→ 13.4 Quick Look (parallel)
  ├─→ 13.5 Share Extension (parallel)
  └─→ 13.6 Touch Bar (parallel)
```

**Can start Week 8, complete Week 10 (all parallel)**

---

## Parallel Work Stream 12: Compliance (Depends on YouTube Features)

```
2.6 Subscriptions ✓ + 3.6 Player Errors ✓
  ↓
  ├─→ 12.1 Report Content (parallel)
  ├─→ 12.2 Block Channels (parallel)
  ├─→ 12.3 Content Warnings (parallel)
  └─→ 12.6 Parental Controls (parallel)

12.4 ToS Enforcement (can start early - spec only)
12.5 Privacy Policy (can start early - docs only)
```

**Can start Week 8 for implementation, complete Week 10**

---

## Parallel Work Stream 13: Accessibility (Depends on All UI)

```
All UI Features Complete (Week 11)
  ↓
  ├─→ 14.1 VoiceOver (parallel)
  ├─→ 14.2 Keyboard Nav (parallel)
  ├─→ 14.3 High Contrast (parallel)
  ├─→ 14.4 Reduced Motion (parallel)
  ├─→ 14.5 Dynamic Type (parallel)
  └─→ 14.6 Accessibility Audit (after all above)
```

**Week 11-12 (mostly parallel)**

---

## Parallel Work Stream 14: Monetization (Independent)

```
START (Week 11)
  ↓
15.1 StoreKit Integration ──→ 15.2 Pro IAP ──→ 15.3 Subscription UI
  ↓                                              ↓
15.5 DMG Notarization ────────────────────────→ 15.4 App Store Submission
  ↓
15.6 Marketing Assets (can start early)
```

**Week 11-12**

---

## Parallelization Matrix

| Week | Team Alpha (Critical) | Team Bravo | Team Charlie | Team Delta |
|------|----------------------|------------|--------------|------------|
| **1** | 1.1, 1.4, 1.5 | 1.2, 1.3, 1.6 | 12.4, 12.5 docs | - |
| **2** | 2.1, 2.2, 2.3 | 2.4, 2.5 | 5.1, 5.2 | 6.1, 6.2 |
| **3** | 3.1, 3.2, 3.3 | 2.6 | 5.3, 5.4 | 6.3, 6.4 |
| **4** | 3.4, 3.5, 3.6 | - | 5.5, 5.6 | 6.5, 6.6 |
| **5** | 7.1, 7.2, 7.3 | - | 10.1, 10.2 | - |
| **6** | 7.4, 7.5, 7.6 | 9.1, 9.2 | 10.3, 10.4 | - |
| **7** | 8.1, 8.2, 8.3 | 9.3, 9.4, 9.5, 9.6 | 10.5, 10.6 | 8.4, 8.5, 8.6 |
| **8** | 4.1, 4.2, 4.3 | 11.1, 11.2, 11.3 | 13.1, 13.2 | 12.1, 12.2 |
| **9** | 4.4, 4.5, 4.7 | 11.4, 11.5, 11.6 | 13.3, 13.4 | 12.3, 12.6 |
| **10** | 4.6 | - | 13.5, 13.6 | - |
| **11** | 14.1, 14.2, 14.3 | 15.1, 15.2, 15.3 | 15.6 | QA Support |
| **12** | 14.4, 14.5, 14.6 | 15.5 | 15.4 SUBMIT | QA Final |

**Peak Parallelization:** Week 7 (all 4 teams fully loaded, 10 stories in parallel)

---

## Dependency Summary

### Stories With No Dependencies (Can Start Anytime)
- 1.2, 1.3, 1.6 (after 1.1)
- 12.4, 12.5, 15.6 (documentation/specs)
- Epic 13 (macOS integration - mostly independent)

### Stories Blocking Multiple Others (High Priority)
- **1.1** - Blocks everything (91 stories)
- **1.4** - Blocks all data features (25+ stories)
- **1.5** - Blocks all UI features (30+ stories)
- **2.3** - Blocks YouTube features (15+ stories)
- **7.5** - Blocks search and clustering (12+ stories)
- **7.6** - Blocks search UI (6 stories)
- **8.2** - Blocks smart collections (4 stories)

### Independent Feature Clusters (Low Risk)
- Epic 5 (Local Files) - 6 stories
- Epic 13 (macOS Integration) - 6 stories
- Epic 14 (Accessibility) - 6 stories
- Epic 15 (Monetization) - 6 stories

---

## Recommended Start Order (Day 1)

1. **Team Alpha:** 1.1 Xcode Project Setup (CRITICAL - START IMMEDIATELY)
2. **Team Charlie:** 12.5 Privacy Policy draft (documentation, no blockers)
3. **Team Charlie:** 15.6 Marketing Assets prep (can start early)
4. **Team Bravo:** Wait for 1.1 to complete (~2 days)

**Day 3:** All teams can be productive in parallel!

---

**Use this graph to:**
- Visualize dependencies when planning sprints
- Identify bottlenecks (red critical path)
- Maximize team utilization (parallel streams)
- Coordinate cross-team handoffs

**Next:** See `DEVELOPMENT-PRIORITIZATION-PLAN.md` for detailed phase breakdown

# Security and Performance

## Security Requirements

**Application Security:**
- **Sandboxing:** App runs in macOS sandbox with minimal entitlements (network.client, user-selected files R/W)
- **Code Signing:** All builds signed with Developer ID or App Store certificate
- **Hardened Runtime:** Enabled for notarization (no JIT, no unsigned code execution)
- **Entitlements:** Only request necessary permissions (no camera, mic, location)

**Data Security:**
- **OAuth Tokens:** Stored in Keychain with `kSecAttrAccessibleWhenUnlocked` attribute
- **Security-Scoped Bookmarks:** Encrypted by macOS, stored in SwiftData
- **User Data:** Encrypted at rest via SwiftData (FileVault if enabled), CloudKit sync uses encryption in transit (TLS)
- **Secrets:** No hardcoded API keys—loaded from environment or secure config
- **Crash Logs:** Sanitized (no tokens, no user content)

**Network Security:**
- **TLS 1.3:** All network calls via URLSession with App Transport Security (ATS) enforced
- **Certificate Pinning:** Not required (YouTube API uses public CAs)
- **Input Validation:** All API responses validated against expected schemas (Codable)
- **Rate Limiting:** Quota budget enforcement prevents excessive API calls
- **CORS:** Not applicable (native app, no web content except IFrame Player)

**Compliance:**
- **YouTube ToS:** No stream downloading/caching, no ad removal, IFrame Player only
- **App Store Guidelines:** UGC moderation (report/hide/contact), no IP violation, privacy labels accurate
- **Privacy Policy:** Transparent about on-device processing, CloudKit sync opt-in
- **GDPR/CCPA:** User data stays on-device (CloudKit is user's own iCloud), no third-party analytics

## Performance Optimization

**App Performance:**
- **Cold Start Target:** <2 seconds from click to first render
  - Strategy: Lazy load AI models, defer CloudKit sync, preload UI only
- **Warm Start Target:** <500ms from reactivation
  - Strategy: SwiftData in-memory cache, no network calls on resume
- **Memory Usage:** <500MB for 10,000-video library
  - Strategy: Lazy loading, thumbnail LRU cache (max 500MB), unload embeddings when not searching
- **Energy Impact:** "Low" rating in Activity Monitor
  - Strategy: Batch background tasks, coalesce timers, avoid polling

**Search Performance:**
- **P95 Query Latency:** <50ms for vector search
  - Strategy: HNSW index in memory (memory-mapped file for persistence), M=16, ef_search=100
- **Index Build Time:** <5 seconds for 1,000 videos on M1
  - Strategy: Parallel embedding generation (10 concurrent tasks), incremental index updates

**UI Performance:**
- **Frame Rate:** 60 FPS (16ms frame budget) during scrolling
  - Strategy: LazyVGrid for thumbnails, async image loading, prefetch visible+1 row
- **Scroll Performance:** No dropped frames with 100+ thumbnails
  - Strategy: Thumbnail downsampling (320x180 for grid, 640x360 for detail), HEIC compression

**Network Performance:**
- **API Response Time:** <500ms P95 for YouTube Data API calls
  - Strategy: Regional CDN (Google's infrastructure), ETag caching (95%+ hit rate), field filtering
- **Thumbnail Loading:** <200ms P95
  - Strategy: CloudFront CDN (YouTube), local cache with LRU eviction

**AI Performance:**
- **Embedding Generation:** <10ms average per video on M1
  - Strategy: 8-bit quantized model, batch inference (10 videos at once)
- **Clustering:** <3 seconds for 1,000-video graph on M1
  - Strategy: Approximate kNN (HNSW), Leiden fast-unfolding variant

---

# Epic 6: Data Persistence & CloudKit Sync

**Goal:** Establish robust data persistence using SwiftData with versioned schema migrations, and provide optional CloudKit synchronization for cross-device access to user data (collections, notes, watch progress, embeddings). This epic ensures data integrity, conflict resolution, and user control over syncing—foundational to a reliable multi-device experience.

## Story 6.1: SwiftData Model Container & Configuration

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

## Story 6.2: Versioned Schema Migrations

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

## Story 6.3: CloudKit Container & Private Database Setup

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

## Story 6.4: CloudKit Sync Conflict Resolution

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

## Story 6.5: Sync Status UI & User Controls

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

## Story 6.6: Caching Strategy for Metadata & Thumbnails

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

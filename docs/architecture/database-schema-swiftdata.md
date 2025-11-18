# Database Schema (SwiftData)

**Schema Version:** 1.0

**Models:** VideoItem, ClusterLabel, Note, Collection, ChannelBlacklist, FocusModeSettings

**SwiftData Configuration:**
```swift
let modelContainer = try ModelContainer(
    for: VideoItem.self, ClusterLabel.self, Note.self,
        Collection.self, ChannelBlacklist.self, FocusModeSettings.self,
    configurations: ModelConfiguration(
        schema: Schema([...]),
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .private // CloudKit sync enabled
    )
)
```

**Indexes:**
- `VideoItem.videoID` (unique, for YouTube videos)
- `VideoItem.addedAt` (for sorting by date)
- `VideoItem.clusterID` (for filtering by cluster)
- `Collection.name` (for search/sort)
- `ChannelBlacklist.channelID` (unique, for fast lookups)

**Migrations:**
- Schema versioning via `VersionedSchema` protocol
- Lightweight migrations for additive changes (new properties)
- Custom migration plans for breaking changes (rename, split, merge properties)
- Backup database before migration, rollback on failure

**CloudKit Sync:**
- Automatic sync of all SwiftData models marked for CloudKit
- Private database only (user's iCloud account)
- Conflict resolution: Last Write Wins (based on `modifiedAt` timestamp)
- Sync conflicts for Notes create conflict copies (" (Conflict Copy)" suffix)
- User can toggle sync on/off in Settings

---

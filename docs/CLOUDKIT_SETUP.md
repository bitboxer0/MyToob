# CloudKit Setup Guide

This document explains how to enable CloudKit private database synchronization for MyToob.

## Overview

MyToob uses SwiftData with CloudKit integration to sync user data (VideoItem, ClusterLabel, Note, ChannelBlacklist) across devices via iCloud. CloudKit sync is **disabled by default** and requires a paid Apple Developer Program enrollment.

## Prerequisites

1. **Paid Apple Developer Program** ($99/year)
   - Personal development teams (free tier) do NOT support iCloud capabilities
   - Enrollment: https://developer.apple.com/programs/

2. **iCloud Account**
   - Sign in to iCloud on your Mac (System Settings > Apple ID)
   - Same Apple ID used for development signing

## Setup Steps

### 1. Register CloudKit Container

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** > **App IDs**
4. Find or create the App ID for `finley.MyToob`
5. Enable **iCloud** capability
6. Click **Edit** for iCloud
7. Add CloudKit container: `iCloud.finley.MyToob`
8. Save changes

### 2. Update Xcode Entitlements

#### Debug Entitlements (`MyToob/MyToobDebug.entitlements`)

Uncomment the CloudKit keys:

```xml
<!-- BEFORE (commented) -->
<!--
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
	<string>iCloud.finley.MyToob</string>
</array>

<key>com.apple.developer.icloud-services</key>
<array>
	<string>CloudKit</string>
</array>
-->

<!-- AFTER (uncommented) -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
	<string>iCloud.finley.MyToob</string>
</array>

<key>com.apple.developer.icloud-services</key>
<array>
	<string>CloudKit</string>
</array>
```

#### Release Entitlements (`MyToob/MyToobRelease.entitlements`)

Make the same changes in the Release entitlements file.

### 3. Enable CloudKit Sync in Configuration

CloudKit sync is controlled by `Configuration.cloudKitSyncEnabled`:

**Option A: Environment Variable (Recommended for Development)**

Add to your `.env` file (or Xcode scheme environment variables):

```bash
CLOUDKIT_SYNC_ENABLED=true
```

**Option B: Change Default (Production)**

Edit `MyToob/Core/Utilities/Configuration.swift`:

```swift
static var cloudKitSyncEnabled: Bool {
  if let value = getValue(for: "CLOUDKIT_SYNC_ENABLED") {
    return value.lowercased() == "true"
  }
  return true  // Changed from false to true
}
```

### 4. Verify Setup

1. **Build the app**
   ```bash
   xcodebuild -project MyToob.xcodeproj -scheme MyToob -destination 'My Mac' build
   ```
   - Should complete without provisioning errors
   - CloudKit entitlements should be included in the build

2. **Check logs**
   - Run the app from Xcode
   - Open Console.app
   - Filter by process "MyToob"
   - Look for: `"CloudKit sync enabled with container: iCloud.finley.MyToob"`

3. **Run health check** (optional verification)
   
   Add temporary code to `ContentView.swift` `onAppear`:
   
   ```swift
   .onAppear {
     Task {
       do {
         let health = try await CloudKitService.shared.verifyHealth()
         print("CloudKit Health: \(health.summary)")
       } catch {
         print("CloudKit health check failed: \(error)")
       }
     }
   }
   ```
   
   Expected output:
   ```
   CloudKit Health: CloudKit healthy - latency: 245.67ms
   ```

4. **Verify in CloudKit Dashboard**
   - Navigate to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
   - Select your team and `iCloud.finley.MyToob` container
   - Switch to **Development** environment
   - Under **Schema**, verify SwiftData model record types appear after first sync:
     - `CD_VideoItemV2`
     - `CD_ClusterLabelV2`
     - `CD_NoteV2`
     - `CD_ChannelBlacklistV2`

## Testing

### Run CloudKit Tests

```bash
xcodebuild test -project MyToob.xcodeproj -scheme MyToob \
  -destination 'My Mac' \
  -only-testing:MyToobTests/CloudKitContainerTests
```

**Expected behavior:**
- With CloudKit enabled and iCloud signed in: Tests pass
- With CloudKit disabled: Tests skip with known issue
- Without iCloud account: Tests skip with known issue

### Test Isolation

All CloudKit tests use a dedicated test zone (`MyToobTestsZone`) to avoid polluting user data. Test records are cleaned up after each test.

## Disabling CloudKit Sync

To temporarily disable CloudKit sync (useful for local-only development):

**Option 1: Environment Variable**
```bash
CLOUDKIT_SYNC_ENABLED=false
```

**Option 2: Comment Entitlements**

Re-comment the CloudKit keys in both entitlements files. This also avoids provisioning errors when using a personal (free) development team.

## Troubleshooting

### Provisioning Profile Errors

**Error:**
```
Provisioning profile doesn't support the iCloud capability
```

**Cause:** Personal development team or missing entitlements

**Solution:**
- Verify you have a **paid** Apple Developer Program enrollment
- Check that entitlements are uncommented
- Clean build folder: Product > Clean Build Folder in Xcode

### Account Status Not Available

**Error:**
```
CloudKit account status: No iCloud Account
```

**Cause:** Not signed into iCloud

**Solution:**
1. Open System Settings > Apple ID
2. Sign in with your Apple ID
3. Enable iCloud Drive
4. Restart the app

### Container Not Found

**Error:**
```
CKError: Container not found
```

**Cause:** Container not registered in App Store Connect

**Solution:**
- Follow Step 1 above to register `iCloud.finley.MyToob`
- Ensure container identifier exactly matches `iCloud.finley.MyToob`
- Allow 10-15 minutes for container registration to propagate

### Health Check Fails

**Error:**
```
CloudKit health check failed: Operation not permitted
```

**Cause:** Entitlements not properly configured or iCloud account restricted

**Solution:**
1. Verify entitlements are uncommented and saved
2. Clean and rebuild the app
3. Check iCloud account is not restricted (Settings > Screen Time)
4. Ensure iCloud Drive is enabled

## Architecture Notes

### SwiftData + CloudKit Integration

MyToob uses SwiftData's first-party CloudKit integration:

- **ModelContainer** configured with `cloudKitDatabase: .private(containerIdentifier)`
- No manual sync code required; SwiftData handles sync automatically
- Models are automatically mapped to CloudKit record types
- Conflict resolution uses SwiftData's default policy (configurable in future stories)

### CloudKitService

`CloudKitService` provides operational utilities **separate** from SwiftData sync:

- **Health checks** - `verifyHealth()` measures round-trip latency
- **Account status** - `checkAccountStatus()` validates iCloud availability
- **Manual operations** - Future stories may use for custom sync verbs

**Important:** Do not use CloudKitService for model CRUD; SwiftData handles that automatically.

### Local-Only Fallback

When `Configuration.cloudKitSyncEnabled = false`:
- App uses `ModelConfiguration` without CloudKit
- All data stays local (no iCloud sync)
- No network calls or quota consumption
- Suitable for users without paid accounts or offline use

## References

- [SwiftData CloudKit Integration (WWDC 2023)](https://developer.apple.com/videos/play/wwdc2023/10154/)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [Configuring iCloud Capabilities](https://developer.apple.com/documentation/xcode/configuring-icloud-capability)
- [Story 6.3 Implementation](../STORY_6.3_COMPLETION_SUMMARY.md)

## Next Steps

After enabling CloudKit sync, see:
- **Story 6.4** - Conflict resolution policies
- **Story 6.5** - Settings UI with sync on/off toggle
- **Story 6.6** - Sync status indicators and error handling

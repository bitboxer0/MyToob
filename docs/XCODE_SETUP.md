# Xcode Setup Guide for MyToob

This guide covers the complete Xcode configuration for the MyToob project, including required settings for App Store compliance and YouTube API integration.

## Prerequisites

### Required Software
- **Xcode 16.1+** (Currently using Xcode 26.1.1 - likely a beta version)
- **macOS Sequoia (15.0+)** for development
- **Apple Developer Account** (for code signing and entitlements)

### Development Team
- **Team ID:** `L75FTB3G3C`
- Configured for automatic signing in project settings

## Project Overview

**Project File:** `MyToob.xcodeproj`

**Targets:**
- **MyToob** - Main application target
- **MyToobTests** - Unit tests
- **MyToobUITests** - UI/integration tests

**Schemes:**
- **MyToob** - Default scheme for building and running

**Bundle Identifier:** `finley.MyToob`

## Initial Configuration Steps

### 1. Open Project in Xcode

```bash
cd "/Users/danielfinley/projects/App Projects/MyToob/MyToob"
open MyToob.xcodeproj
```

Or use XcodeMCP:
```bash
# Via MCP tool
xcode_open_project(xcodeproj: "/path/to/MyToob.xcodeproj")
```

### 2. Update Deployment Target

⚠️ **CRITICAL:** Current deployment target is set to macOS 26.1 (beta). Per IdeaDoc.md requirements, this should be **macOS 14.0+**.

**Steps to fix:**
1. Select the **MyToob** project in the navigator
2. Select the **MyToob** target
3. Go to **General** tab
4. Set **Minimum Deployments** → **macOS** to **14.0**
5. Repeat for **MyToobTests** and **MyToobUITests** targets

**Via project.pbxproj:**
```
MACOSX_DEPLOYMENT_TARGET = 14.0;
```

### 3. Configure Signing & Capabilities

#### General Tab
- **Team:** L75FTB3G3C (already configured)
- **Bundle Identifier:** `finley.MyToob`
- **Version:** 1.0
- **Build:** 1
- **Signing:** Automatic (CODE_SIGN_STYLE = Automatic)

#### Signing & Capabilities Tab

**Currently Enabled (Good!):**
- ✅ App Sandbox
- ✅ Hardened Runtime
- ✅ User Selected Files (Read Only)

**Required Additional Capabilities:**

1. **Network Client** (for YouTube Data API)
   - Click **+ Capability**
   - Add **App Sandbox** → Check **Outgoing Connections (Client)**

2. **Network Server** (for WKWebView local resource serving)
   - Under **App Sandbox** → Check **Incoming Connections (Server)** if needed

3. **Keychain Sharing** (for OAuth token storage)
   - Click **+ Capability**
   - Add **Keychain Sharing**
   - Add keychain group: `$(AppIdentifierPrefix)finley.MyToob`

4. **CloudKit** (for optional user data sync)
   - Click **+ Capability**
   - Add **CloudKit**
   - Configure container: `iCloud.finley.MyToob`
   - Add **Background Modes** → **Remote notifications** (for CloudKit sync)

5. **App Groups** (for extension support in future)
   - Click **+ Capability**
   - Add **App Groups**
   - Add group: `group.finley.MyToob`

### 4. Configure Entitlements

Xcode will create `MyToob.entitlements` automatically when adding capabilities. Ensure it contains:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- Hardened Runtime -->
    <key>com.apple.security.hardened-runtime</key>
    <true/>

    <!-- Network Access (for YouTube API) -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- User Selected Files (for local video import) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>

    <!-- Keychain Access Groups (for OAuth tokens) -->
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)finley.MyToob</string>
    </array>

    <!-- CloudKit Containers -->
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.finley.MyToob</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>

    <!-- App Groups -->
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.finley.MyToob</string>
    </array>
</dict>
</plist>
```

### 5. Build Settings Configuration

#### Swift Settings (Already Configured ✅)
- **Swift Language Version:** 5.0
- **Swift Compilation Mode:**
  - Debug: Incremental
  - Release: Whole Module
- **Swift Optimization Level:**
  - Debug: No Optimization (-Onone)
  - Release: Optimize for Speed (-O)

#### Additional Required Settings

Navigate to **Build Settings** → **All** → **Combined**:

**Code Generation:**
```
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG $(inherited)  # Debug only
SWIFT_OPTIMIZATION_LEVEL = -Onone  # Debug
SWIFT_OPTIMIZATION_LEVEL = -O      # Release
```

**Linking:**
```
LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/../Frameworks
```

**Asset Catalog:**
```
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor
ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES
```

**Localization:**
```
LOCALIZATION_PREFERS_STRING_CATALOGS = YES
```

**Concurrency (Already Configured ✅):**
```
SWIFT_APPROACHABLE_CONCURRENCY = YES
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
```

### 6. Info.plist Configuration

Since `GENERATE_INFOPLIST_FILE = YES`, Xcode auto-generates Info.plist. Configure via **Target → Info** tab:

**Required Keys:**

1. **App Information**
   - **Bundle name:** MyToob
   - **Bundle display name:** MyToob (or your marketing name)
   - **Bundle version:** 1.0
   - **Bundle version string (short):** 1

2. **Privacy Descriptions** (Add via Info → Custom macOS Target Properties)
   ```
   NSHumanReadableCopyright = "Copyright © 2025 Your Name. All rights reserved."
   ```

3. **URL Schemes** (for OAuth callback)
   - Add **URL Types** → **URL Schemes** → Add: `mytoob`
   - **Identifier:** `finley.MyToob.oauth`
   - **Role:** Editor

4. **Network Usage Description** (if explicitly prompting for network)
   ```
   NSLocalNetworkUsageDescription = "MyToob needs network access to connect to YouTube's API for browsing and playback."
   ```

### 7. Scheme Configuration

#### Edit Scheme (Product → Scheme → Edit Scheme)

**Build Configuration:**
- **Run:** Debug
- **Test:** Debug
- **Profile:** Release
- **Analyze:** Debug
- **Archive:** Release

**Run Settings:**
- **Build Configuration:** Debug
- **Executable:** MyToob.app
- **Launch:** Automatically
- **Debug executable:** ✅ Checked

**Test Settings:**
- **Build Configuration:** Debug
- **Code Coverage:** ✅ Gather coverage data
- **Test Language:** English
- **Test Region:** United States

**Arguments & Environment Variables (Optional):**

Add environment variables for debugging:
```
YOUTUBE_API_QUOTA_LIMIT = 10000
LOG_LEVEL = debug
FORCE_OFFLINE_MODE = false
```

## Swift Package Manager Setup

### Adding Dependencies

When ready to add Swift Package dependencies (e.g., for networking, OAuth):

1. **File → Add Package Dependencies...**
2. Add URLs for required packages:

**Suggested Packages:**
```
# OAuth & Networking
- https://github.com/Alamofire/Alamofire.git (if not using URLSession)
- https://github.com/OAuthSwift/OAuthSwift.git

# YouTube API Client (if using third-party)
- https://github.com/googleapis/google-api-objectivec-client-for-rest.git

# Vector Search (for HNSW index)
- Custom implementation or research Swift packages

# Core ML Utilities
- Custom implementation recommended
```

3. Select **MyToob** target for each package
4. Choose version rules (recommend "Up to Next Major Version")

### Package.swift Alternative

For managing dependencies via Package.swift (if converting to SPM project):

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MyToob",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MyToob", targets: ["MyToob"])
    ],
    dependencies: [
        // Add dependencies here
    ],
    targets: [
        .executableTarget(
            name: "MyToob",
            dependencies: []
        ),
        .testTarget(
            name: "MyToobTests",
            dependencies: ["MyToob"]
        )
    ]
)
```

## Build Configurations

### Debug Configuration (Current: ✅ Correct)
- **Optimization:** None (-Onone)
- **Debug Information:** DWARF
- **Assertions:** Enabled
- **Testability:** Enabled
- **Active Compilation Conditions:** DEBUG
- **Preprocessor Macros:** DEBUG=1

### Release Configuration (Current: ✅ Correct)
- **Optimization:** Whole Module
- **Debug Information:** DWARF with dSYM
- **Assertions:** Disabled
- **Testability:** Disabled
- **Strip Debug Symbols:** Yes
- **Dead Code Stripping:** Yes

### Distribution Configuration (Create New)

For App Store distribution, create a **Distribution** configuration:

1. **Project → Info → Configurations**
2. Duplicate **Release** → Rename to **Distribution**
3. Add specific settings:
   ```
   CODE_SIGN_STYLE = Manual
   CODE_SIGN_IDENTITY = "Apple Distribution"
   PROVISIONING_PROFILE_SPECIFIER = "MyToob Distribution Profile"
   ```

## Testing Configuration

### Unit Tests (MyToobTests)
- **Bundle Loader:** Points to MyToob.app
- **Host Application:** MyToob
- **Test without Building:** Disabled

### UI Tests (MyToobUITests)
- **Test Target:** MyToob
- **Target Application:** MyToob.app
- **Code Coverage:** Enabled

### Test Plans (Future Enhancement)

Create `.xctestplan` files for different test configurations:

1. **File → New → Test Plan**
2. Create plans:
   - `UnitTests.xctestplan` - Fast unit tests only
   - `IntegrationTests.xctestplan` - API integration tests
   - `UITests.xctestplan` - Full UI test suite
   - `CITests.xctestplan` - Quick tests for CI/CD

## Build & Run

### Building the App

**Via Xcode:**
- **⌘B** - Build
- **⌘R** - Build and Run
- **⌘U** - Build and Test
- **⌘⇧K** - Clean Build Folder

**Via Command Line:**
```bash
# Build
xcodebuild -project MyToob.xcodeproj -scheme MyToob -destination 'platform=macOS' build

# Test
xcodebuild test -project MyToob.xcodeproj -scheme MyToob -destination 'platform=macOS'

# Clean
xcodebuild clean -project MyToob.xcodeproj -scheme MyToob
```

**Via XcodeMCP:**
```bash
# Build
xcode_build(xcodeproj: "/path/to/MyToob.xcodeproj", scheme: "MyToob", destination: "platform=macOS")

# Test
xcode_test(xcodeproj: "/path/to/MyToob.xcodeproj", destination: "platform=macOS")

# Clean
xcode_clean(xcodeproj: "/path/to/MyToob.xcodeproj")
```

### Build Locations

- **Products:** `~/Library/Developer/Xcode/DerivedData/MyToob-*/Build/Products/`
- **Intermediates:** `~/Library/Developer/Xcode/DerivedData/MyToob-*/Build/Intermediates.noindex/`
- **Archives:** `~/Library/Developer/Xcode/Archives/`

### Custom DerivedData Location (Optional)

To use project-relative DerivedData:

**Xcode → Settings → Locations → DerivedData → Advanced**
- Select **Custom → Relative to Workspace**
- Path: `DerivedData`

Or add to `.mcp.json`:
```json
{
  "xcodebuild": {
    "env": {
      "DERIVED_DATA_PATH": "DerivedData"
    }
  }
}
```

## Troubleshooting

### Common Issues

**1. Code Signing Errors**
```
Error: "MyToob" requires a provisioning profile
```
**Fix:**
- Xcode → Settings → Accounts → Download Manual Profiles
- Or switch to Automatic signing

**2. Deployment Target Mismatch**
```
Error: The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET' is set to 26.1
```
**Fix:** Change to 14.0 in Build Settings (see Step 2 above)

**3. SwiftData Not Available**
```
Error: Cannot find 'SwiftData' in scope
```
**Fix:** Ensure deployment target is macOS 14.0+ (SwiftData requires macOS 14+)

**4. Sandbox Violations**
```
Error: Sandbox violation: Network connection denied
```
**Fix:** Add Network Client capability (see Step 3 above)

**5. Entitlements Error**
```
Error: The executable was signed with invalid entitlements
```
**Fix:** Check that all entitlements in .entitlements file match capabilities

### Build Performance

**Speed up builds:**
- Enable **Build Settings → COMPILER_INDEX_STORE_ENABLE = NO** (only if not using Xcode indexing)
- Use **Whole Module Optimization** for Release only
- Clear DerivedData periodically: `rm -rf ~/Library/Developer/Xcode/DerivedData/MyToob-*`

## Next Steps

After completing Xcode setup:

1. ✅ **Verify Build:** Ensure project builds successfully with ⌘B
2. ✅ **Run App:** Test basic app launch with ⌘R
3. ✅ **Run Tests:** Verify test targets build and run with ⌘U
4. 📋 **Configure CI/CD:** Set up GitHub Actions (see Epic A in IdeaDoc.md)
5. 📋 **Add Dependencies:** Install required Swift packages
6. 📋 **Implement Models:** Replace placeholder Item.swift with VideoItem (see Epic D)
7. 📋 **Configure Code Quality:** Add SwiftLint and swift-format

## Reference Links

- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [App Sandbox Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [App Store Distribution](https://developer.apple.com/distribute/)
- [CloudKit Setup](https://developer.apple.com/documentation/cloudkit/setting_up_cloudkit)

## Compliance Checklist

Before App Store submission:

- [ ] Deployment target is macOS 14.0 or later
- [ ] App Sandbox enabled with minimal required entitlements
- [ ] Hardened Runtime enabled
- [ ] Code signing configured (automatic for development, manual for distribution)
- [ ] CloudKit container configured (if using sync)
- [ ] Privacy descriptions added to Info.plist
- [ ] URL schemes configured for OAuth (mytoob://)
- [ ] App Groups configured for future extension support
- [ ] No references to "YouTube" in app name, bundle name, or display name
- [ ] Build warnings resolved
- [ ] All tests passing

---

**Last Updated:** 2025-11-17
**Xcode Version:** 26.1.1 (update to 16.1+ for production)
**macOS Version:** 15.0+

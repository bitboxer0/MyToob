# MyToob: Comprehensive Task Breakdowns for All Stories

**Generated:** 2025-11-18
**Purpose:** Detailed task breakdowns for all 91 user stories across 15 epics
**Status Legend:** ✅ Done | 🚧 Draft | 📋 Placeholder

---

## Table of Contents

- [Epic 1: Foundation & Project Infrastructure](#epic-1-foundation--project-infrastructure)
- [Epic 2: YouTube OAuth & Data API Integration](#epic-2-youtube-oauth--data-api-integration)
- [Epic 3: Compliant YouTube Playback](#epic-3-compliant-youtube-playback)
- [Epic 4: Focus Mode & Distraction Management](#epic-4-focus-mode--distraction-management)
- [Epic 5: Local File Playback & Management](#epic-5-local-file-playback--management)
- [Epic 6: Data Persistence & CloudKit Sync](#epic-6-data-persistence--cloudkit-sync)
- [Epic 7: On-Device AI Embeddings & Vector Index](#epic-7-on-device-ai-embeddings--vector-index)
- [Epic 8: AI Clustering & Auto-Collections](#epic-8-ai-clustering--auto-collections)
- [Epic 9: Hybrid Search & Discovery UX](#epic-9-hybrid-search--discovery-ux)
- [Epic 10: Collections & Organization](#epic-10-collections--organization)
- [Epic 11: Research Tools & Note-Taking](#epic-11-research-tools--note-taking)
- [Epic 12: UGC Safeguards & Compliance Features](#epic-12-ugc-safeguards--compliance-features)
- [Epic 13: macOS System Integration](#epic-13-macos-system-integration)
- [Epic 14: Accessibility & Polish](#epic-14-accessibility--polish)
- [Epic 15: Monetization & App Store Release](#epic-15-monetization--app-store-release)

---

## Epic 1: Foundation & Project Infrastructure

**Goal:** Establish foundational project structure, development tooling, and core data models.

### Story 1.1: Xcode Project Setup & Configuration

**Status:** 📋 Draft
**Depends On:** None (blocks all other stories)
**File:** `docs/stories/1.1.xcode-project-setup.md`

#### Acceptance Criteria
1. Xcode project created for macOS target with minimum deployment target macOS 14.0 (Sonoma)
2. App sandbox enabled with entitlements: `com.apple.security.network.client`, `com.apple.security.files.user-selected.read-write`
3. Signing configured for development and distribution (code signing identity, provisioning profiles)
4. Build configurations created: Debug, Release, TestFlight
5. App group configured for shared data access (if needed for extensions in future)
6. Info.plist includes required keys: LSMinimumSystemVersion, NSHumanReadableCopyright, etc.
7. Core ML embedding model (`sentence-transformer-384.mlpackage`) added to `MyToob/Resources/CoreML Models/` directory
8. Project builds successfully and launches with empty window

#### Detailed Task Breakdown

**Phase 1: Initial Project Creation (AC: 1)**
- [ ] **Task 1.1.1:** Create new Xcode project using macOS App template
  - [ ] Subtask: Select SwiftUI as interface
  - [ ] Subtask: Set minimum deployment target to macOS 14.0
  - [ ] Subtask: Configure bundle identifier (e.g., `com.yourcompany.mytoob`)
  - [ ] Subtask: Set initial version to 1.0.0 (build 1)
  - [ ] Subtask: Enable Swift 5.10+ as minimum language version

**Phase 2: App Sandbox & Entitlements (AC: 2, 5)**
- [ ] **Task 1.1.2:** Configure App Sandbox entitlements
  - [ ] Subtask: Navigate to Signing & Capabilities tab
  - [ ] Subtask: Add App Sandbox capability
  - [ ] Subtask: Enable "Outgoing Connections (Client)" - required for YouTube API
  - [ ] Subtask: Enable "User Selected Files (Read/Write)" - required for local video import
  - [ ] Subtask: Document why each entitlement is needed in `docs/XCODE_SETUP.md`

- [ ] **Task 1.1.3:** Configure App Groups (future-proofing)
  - [ ] Subtask: Add App Groups capability
  - [ ] Subtask: Create app group: `group.com.yourcompany.mytoob`
  - [ ] Subtask: Document app group usage in README

**Phase 3: Code Signing (AC: 3)**
- [ ] **Task 1.1.4:** Setup Development Signing
  - [ ] Subtask: Select development team in project settings
  - [ ] Subtask: Configure "Automatically manage signing" for Debug configuration
  - [ ] Subtask: Verify development certificate is valid
  - [ ] Subtask: Test build on local machine

- [ ] **Task 1.1.5:** Setup Distribution Signing
  - [ ] Subtask: Create App Store distribution certificate (if not exists)
  - [ ] Subtask: Create Developer ID Application certificate for DMG distribution
  - [ ] Subtask: Configure provisioning profiles for Release configuration
  - [ ] Subtask: Document signing setup in `docs/XCODE_SETUP.md`

**Phase 4: Build Configurations (AC: 4)**
- [ ] **Task 1.1.6:** Configure Debug build settings
  - [ ] Subtask: Set Swift Compilation Mode to "Incremental"
  - [ ] Subtask: Enable "Debug Information Format" to "DWARF with dSYM File"
  - [ ] Subtask: Set optimization level to "-Onone"
  - [ ] Subtask: Enable "Testability" for unit testing

- [ ] **Task 1.1.7:** Configure Release build settings
  - [ ] Subtask: Set Swift Compilation Mode to "Whole Module Optimization"
  - [ ] Subtask: Set optimization level to "-O"
  - [ ] Subtask: Disable testability
  - [ ] Subtask: Strip debug symbols for final builds

- [ ] **Task 1.1.8:** Configure TestFlight build configuration
  - [ ] Subtask: Duplicate Release configuration
  - [ ] Subtask: Rename to "TestFlight"
  - [ ] Subtask: Enable crash reporting symbols
  - [ ] Subtask: Configure beta entitlements if needed

**Phase 5: Info.plist Configuration (AC: 6)**
- [ ] **Task 1.1.9:** Configure required Info.plist keys
  - [ ] Subtask: Set LSMinimumSystemVersion to "14.0"
  - [ ] Subtask: Add NSHumanReadableCopyright with copyright notice
  - [ ] Subtask: Set CFBundleDisplayName to "MyToob"
  - [ ] Subtask: Add CFBundleShortVersionString (matches version)
  - [ ] Subtask: Add CFBundleVersion (build number)
  - [ ] Subtask: Add NSPrincipalClass if using custom app delegate
  - [ ] Subtask: Document all Info.plist keys in code comments

**Phase 6: Core ML Model Integration (AC: 7)**
- [ ] **Task 1.1.10:** Add Core ML directory structure
  - [ ] Subtask: Create directory: `MyToob/Resources/CoreML Models/`
  - [ ] Subtask: Add README.md in CoreML Models explaining model purpose
  - [ ] Subtask: Add `.gitignore` entry for large model files (if not committing)

- [ ] **Task 1.1.11:** Add sentence-transformer-384 model
  - [ ] Subtask: Obtain `sentence-transformer-384.mlpackage` model file
  - [ ] Subtask: Drag model into Xcode project
  - [ ] Subtask: Verify model is added to MyToob target membership
  - [ ] Subtask: Verify model appears in "Copy Bundle Resources" build phase
  - [ ] Subtask: Test model loads at runtime with simple Swift test

**Phase 7: Verification & Testing (AC: 8)**
- [ ] **Task 1.1.12:** Verify successful build and launch
  - [ ] Subtask: Build project with ⌘B (Command-B)
  - [ ] Subtask: Verify no build errors or warnings
  - [ ] Subtask: Run project with ⌘R (Command-R)
  - [ ] Subtask: Verify empty window appears
  - [ ] Subtask: Check Console.app for any runtime errors
  - [ ] Subtask: Verify app bundle structure is correct
  - [ ] Subtask: Test on both Intel and Apple Silicon Macs (if available)

**Phase 8: Documentation & Handoff**
- [ ] **Task 1.1.13:** Create setup documentation
  - [ ] Subtask: Document build requirements in README
  - [ ] Subtask: Create `docs/XCODE_SETUP.md` with detailed Xcode configuration steps
  - [ ] Subtask: Document entitlements and their purposes
  - [ ] Subtask: Create onboarding guide for new developers
  - [ ] Subtask: Document known issues or platform-specific quirks

#### Dev Notes
- **Files Created:**
  - `MyToob.xcodeproj` - Xcode project file
  - `MyToob/MyToobApp.swift` - App entry point
  - `MyToob/Resources/CoreML Models/sentence-transformer-384.mlpackage` - Embedding model
  - `MyToob.entitlements` - Sandbox entitlements
  - `docs/XCODE_SETUP.md` - Setup documentation

- **Critical Dependencies:**
  - Xcode 15.0+ required
  - macOS 14.0 SDK required
  - Apple Developer account for code signing

- **Compliance Notes:**
  - App Sandbox required for App Store distribution
  - Minimal entitlements for security and compliance
  - User Selected Files enables local video import without broad file access

#### Testing Requirements
- **Build Tests:**
  - [ ] Project builds successfully in Debug configuration
  - [ ] Project builds successfully in Release configuration
  - [ ] Project builds successfully in TestFlight configuration

- **Launch Tests:**
  - [ ] App launches without crashes
  - [ ] Empty window appears on launch
  - [ ] No errors in Console.app

- **Entitlement Tests:**
  - [ ] Verify entitlements file exists and is valid
  - [ ] Check entitlements are correctly embedded in app bundle
  - [ ] Verify sandbox restrictions are active

- **Model Tests:**
  - [ ] Core ML model included in bundle resources
  - [ ] Model can be loaded at runtime (basic Swift code test)

---

### Story 1.2: SwiftLint & Code Quality Tooling

**Status:** ✅ Done
**Reference:** See `docs/stories/1.2.swiftlint-code-quality.md` and `docs/STORY_1.2_COMPLETION_SUMMARY.md` for full implementation details.

#### Summary of Completed Work
- SwiftLint 0.61.0 installed and configured
- `.swiftlint.yml` created with 9 custom compliance rules
- `.swift-format` configuration created
- `Dangerfile` created for PR automation
- Comprehensive documentation in `docs/SWIFTLINT_SETUP.md`
- Validation tests created in `MyToobTests/SwiftLintValidationTests.swift`

#### Key Deliverables
1. ✅ SwiftLint installation and Xcode build phase integration documented
2. ✅ 9 custom compliance rules (googlevideo blocking, hardcoded secrets detection, etc.)
3. ✅ swift-format configuration (2-space indent, 120 char lines)
4. ✅ Danger PR automation for compliance checks
5. ✅ Build failure on critical lint violations

**Note:** Manual Xcode build phase setup required (see `docs/SWIFTLINT_SETUP.md`)

---

### Story 1.3: GitHub CI/CD Pipeline

**Status:** 📋 Draft
**Depends On:** 1.1 (Xcode project), 1.2 (SwiftLint)
**File:** `docs/stories/1.3.github-cicd-pipeline.md`

#### Acceptance Criteria
1. `.github/workflows/ci.yml` created with jobs: lint, test, build
2. Lint job runs SwiftLint and fails on errors
3. Test job runs `xcodebuild test` and reports coverage
4. Build job produces signed `.app` artifact
5. Workflow triggers on: push to main, pull requests
6. Workflow uses macOS runner (macos-latest or macos-14)
7. Build artifacts uploaded to GitHub Actions for debugging
8. All jobs pass on initial empty project

#### Detailed Task Breakdown

**Phase 1: Workflow Directory Setup (AC: 1)**
- [ ] **Task 1.3.1:** Create GitHub Actions workflow structure
  - [ ] Subtask: Create `.github/` directory in repository root
  - [ ] Subtask: Create `.github/workflows/` subdirectory
  - [ ] Subtask: Create `ci.yml` workflow file
  - [ ] Subtask: Add workflow file to git and commit

**Phase 2: Workflow Triggers Configuration (AC: 5)**
- [ ] **Task 1.3.2:** Configure workflow triggers
  - [ ] Subtask: Add `on.push.branches: [main, develop]` trigger
  - [ ] Subtask: Add `on.pull_request.branches: [main]` trigger
  - [ ] Subtask: Add optional `workflow_dispatch` for manual runs
  - [ ] Subtask: Document trigger conditions in workflow comments

**Phase 3: Lint Job Implementation (AC: 2, 6)**
- [ ] **Task 1.3.3:** Create lint job
  - [ ] Subtask: Define lint job with `runs-on: macos-14`
  - [ ] Subtask: Add checkout action: `actions/checkout@v4`
  - [ ] Subtask: Install SwiftLint: `brew install swiftlint`
  - [ ] Subtask: Run SwiftLint with strict mode: `swiftlint --strict`
  - [ ] Subtask: Configure job to fail on non-zero exit code
  - [ ] Subtask: Add caching for Homebrew to speed up runs

**Phase 4: Test Job Implementation (AC: 3, 6)**
- [ ] **Task 1.3.4:** Create test job
  - [ ] Subtask: Define test job with `runs-on: macos-14`
  - [ ] Subtask: Add checkout action
  - [ ] Subtask: Select Xcode version if needed: `sudo xcode-select -s /Applications/Xcode_15.0.app`
  - [ ] Subtask: Run tests: `xcodebuild test -scheme MyToob -destination 'platform=macOS'`
  - [ ] Subtask: Generate code coverage report: `xcrun llvm-cov export`
  - [ ] Subtask: Upload coverage to workflow artifacts
  - [ ] Subtask: Optionally integrate with Codecov or similar service

**Phase 5: Build Job Implementation (AC: 4, 6)**
- [ ] **Task 1.3.5:** Create build job with dependencies
  - [ ] Subtask: Define build job with `needs: [lint, test]` (runs after lint and test pass)
  - [ ] Subtask: Configure `runs-on: macos-14`
  - [ ] Subtask: Add checkout action
  - [ ] Subtask: Build release configuration: `xcodebuild -scheme MyToob -configuration Release build`
  - [ ] Subtask: Locate built .app in build output directory
  - [ ] Subtask: Optionally sign .app with Developer ID certificate (requires secrets)

**Phase 6: Artifact Upload (AC: 7)**
- [ ] **Task 1.3.6:** Upload build artifacts
  - [ ] Subtask: Add `actions/upload-artifact@v3` action
  - [ ] Subtask: Configure artifact name: `MyToob.app`
  - [ ] Subtask: Configure path to built .app
  - [ ] Subtask: Set retention period (e.g., 30 days)
  - [ ] Subtask: Include dSYM files for debugging if available
  - [ ] Subtask: Document how to download artifacts from GitHub Actions UI

**Phase 7: Workflow Testing & Validation (AC: 8)**
- [ ] **Task 1.3.7:** Test workflow execution
  - [ ] Subtask: Commit workflow file to GitHub
  - [ ] Subtask: Verify workflow appears in GitHub Actions tab
  - [ ] Subtask: Trigger workflow by pushing to main branch
  - [ ] Subtask: Monitor workflow execution and check all jobs pass
  - [ ] Subtask: Verify lint job passes with current code
  - [ ] Subtask: Verify test job passes with current tests
  - [ ] Subtask: Verify build job produces artifact
  - [ ] Subtask: Download artifact and verify .app is valid

**Phase 8: Failure Scenario Testing**
- [ ] **Task 1.3.8:** Test workflow failure handling
  - [ ] Subtask: Introduce intentional lint error and verify job fails
  - [ ] Subtask: Verify build job doesn't run when lint fails
  - [ ] Subtask: Fix lint error and verify workflow passes
  - [ ] Subtask: Introduce test failure and verify build doesn't run
  - [ ] Subtask: Test PR workflow (create test PR and verify workflow runs)

#### Dev Notes
- **Files Created:**
  - `.github/workflows/ci.yml` - Main CI workflow
  - Optional: `.github/workflows/release.yml` - Release workflow (future)

- **GitHub Actions Runners:**
  - `macos-14` provides Xcode 15.x and macOS Sonoma
  - macOS runners are more expensive than Linux, so optimize caching

- **Caching Strategy:**
  - Cache Homebrew installations (SwiftLint)
  - Cache DerivedData for faster builds (optional)
  - Cache CocoaPods/SPM dependencies (when added)

- **Secrets Required (for signing):**
  - `DEVELOPER_ID_APPLICATION_CERT` - Base64-encoded certificate
  - `DEVELOPER_ID_APPLICATION_KEY` - Base64-encoded private key
  - `KEYCHAIN_PASSWORD` - Temporary keychain password

#### Testing Requirements
- **Workflow Syntax:**
  - [ ] Validate YAML syntax with online validator
  - [ ] Test workflow runs successfully on push to main
  - [ ] Test workflow runs successfully on PR creation

- **Job Dependencies:**
  - [ ] Verify lint job runs first
  - [ ] Verify test job runs in parallel or after lint
  - [ ] Verify build job only runs if lint and test pass

- **Artifact Generation:**
  - [ ] Verify artifact is created and downloadable
  - [ ] Verify artifact contains expected files
  - [ ] Verify artifact size is reasonable

---

### Story 1.4: SwiftData Core Models

**Status:** ✅ Done
**Reference:** See `docs/stories/1.4.swiftdata-core-models.md` for full implementation details.

#### Summary of Completed Work
- VideoItem model created with YouTube + local file support
- ClusterLabel model with similarity calculation
- Note model with Markdown support and timestamp linking
- ChannelBlacklist model for content moderation
- ModelContainer configured in MyToobApp.swift
- 41 comprehensive unit tests, all passing

#### Key Deliverables
1. ✅ VideoItem with dual initializers (YouTube vs local), @Attribute(.unique), embeddings
2. ✅ ClusterLabel with centroid similarity calculations
3. ✅ Note with formatted timestamps and video relationships
4. ✅ ChannelBlacklist with filtering logic
5. ✅ All models use @Attribute(.externalStorage) for large data (more efficient than .transformable)
6. ✅ Full test coverage: 8 VideoItem tests, 9 ClusterLabel tests, 12 Note tests, 10 ChannelBlacklist tests

---

### Story 1.5: Basic App Shell & Navigation

**Status:** ✅ Done
**Reference:** See `docs/stories/1.5.basic-app-shell.md` for full implementation details.

#### Summary of Completed Work
- MyToobApp.swift configured with ModelContainer and window sizing
- ContentView.swift with NavigationSplitView (sidebar + content layout)
- Sidebar sections: Collections, YouTube, Local Files
- Placeholder detail view with empty state
- Window size defaults: 1280x800, minimum: 1024x768
- Fixed SwiftData @Attribute compiler errors in model files

#### Key Deliverables
1. ✅ SwiftUI App struct with @main entry point and ModelContainer injection
2. ✅ NavigationSplitView with sidebar and content areas
3. ✅ Sidebar with three required sections (Collections, YouTube, Local Files)
4. ✅ SF Symbols icons for visual clarity
5. ✅ Window state persistence (automatic via SwiftUI WindowGroup)
6. ✅ Build successful, ready for feature development

---

### Story 1.6: Logging & Diagnostics Framework

**Status:** 📋 Draft
**Depends On:** 1.5 (App shell for Settings integration)
**File:** `docs/stories/1.6.logging-diagnostics.md`

#### Acceptance Criteria
1. Logging utility created wrapping `OSLog` with predefined subsystems/categories
2. Log levels defined: debug, info, notice, error, fault
3. Privacy levels used: public (non-sensitive), private (sensitive), sensitive (redacted in logs)
4. Example log statements added to app launch flow demonstrating usage
5. Diagnostics export function created (collects logs, system info, sanitizes sensitive data)
6. User-initiated diagnostics export accessible via Settings (returns `.zip` file)
7. No logs written to files by default (uses OS logging system)

#### Detailed Task Breakdown

**Phase 1: LoggingService Creation (AC: 1, 2, 3)**
- [ ] **Task 1.6.1:** Create LoggingService wrapper
  - [ ] Subtask: Create file `MyToob/Core/Utilities/LoggingService.swift`
  - [ ] Subtask: Import OSLog framework
  - [ ] Subtask: Define subsystem constant: `"com.yourcompany.mytoob"`
  - [ ] Subtask: Create singleton `shared` instance

- [ ] **Task 1.6.2:** Define log categories
  - [ ] Subtask: Create `app` logger: `Logger(subsystem: subsystem, category: "app")`
  - [ ] Subtask: Create `network` logger for API calls
  - [ ] Subtask: Create `ai` logger for ML operations
  - [ ] Subtask: Create `player` logger for playback events
  - [ ] Subtask: Create `sync` logger for CloudKit operations
  - [ ] Subtask: Create `ui` logger for user interface events

- [ ] **Task 1.6.3:** Document log level usage
  - [ ] Subtask: Add doc comments explaining when to use each level
  - [ ] Subtask: Document privacy level best practices
  - [ ] Subtask: Create usage examples in code comments
  - [ ] Subtask: Add to developer documentation

**Phase 2: Privacy Level Implementation (AC: 3)**
- [ ] **Task 1.6.4:** Implement privacy helpers
  - [ ] Subtask: Create extension methods for common privacy patterns
  - [ ] Subtask: Document what data should be public (app version, error codes)
  - [ ] Subtask: Document what data should be private (video IDs, search terms)
  - [ ] Subtask: Document what data should be sensitive/redacted (tokens, file paths with usernames)
  - [ ] Subtask: Add linting rule to warn about logging sensitive data

**Phase 3: Integration with App Launch (AC: 4)**
- [ ] **Task 1.6.5:** Add logging to MyToobApp.swift
  - [ ] Subtask: Log app launch: `LoggingService.shared.app.info("App launched, version: \(appVersion)")`
  - [ ] Subtask: Log ModelContainer initialization success/failure
  - [ ] Subtask: Log window creation
  - [ ] Subtask: Verify logs appear in Console.app

**Phase 4: Diagnostics Collection (AC: 5)**
- [ ] **Task 1.6.6:** Create diagnostics collection service
  - [ ] Subtask: Create `MyToob/Core/Utilities/DiagnosticsService.swift`
  - [ ] Subtask: Implement log collection from OSLogStore (last 24 hours)
  - [ ] Subtask: Collect system info: macOS version, device model, memory
  - [ ] Subtask: Collect app info: version, build number, uptime
  - [ ] Subtask: Collect SwiftData statistics: count of videos, clusters, notes

- [ ] **Task 1.6.7:** Implement sanitization
  - [ ] Subtask: Redact OAuth tokens and API keys from logs
  - [ ] Subtask: Redact file paths containing usernames
  - [ ] Subtask: Keep error messages and stack traces intact
  - [ ] Subtask: Anonymize video IDs and titles (optional)
  - [ ] Subtask: Test sanitization with sample logs

**Phase 5: Diagnostics Export UI (AC: 6)**
- [ ] **Task 1.6.8:** Create Settings view for diagnostics
  - [ ] Subtask: Add "Diagnostics" section to Settings
  - [ ] Subtask: Add "Export Diagnostics" button
  - [ ] Subtask: Show progress indicator during collection
  - [ ] Subtask: Generate .zip file with diagnostic data
  - [ ] Subtask: Use NSSavePanel for user to choose save location
  - [ ] Subtask: Show success/error message to user

- [ ] **Task 1.6.9:** Format diagnostic report
  - [ ] Subtask: Create text report with sections (system info, logs, stats)
  - [ ] Subtask: Include app version and build number in filename
  - [ ] Subtask: Add timestamp to export
  - [ ] Subtask: Include README.txt explaining contents

**Phase 6: Verification (AC: 7)**
- [ ] **Task 1.6.10:** Verify no file-based logging
  - [ ] Subtask: Audit code for any file writes (search for FileManager)
  - [ ] Subtask: Verify logs only use OSLog
  - [ ] Subtask: Document that logs are in system location (accessible via Console.app)
  - [ ] Subtask: Document retention policy (system-managed)

**Phase 7: Testing & Documentation**
- [ ] **Task 1.6.11:** Create tests
  - [ ] Subtask: Test LoggingService initialization
  - [ ] Subtask: Test log category creation
  - [ ] Subtask: Test diagnostics collection generates valid .zip
  - [ ] Subtask: Test sanitization removes sensitive data
  - [ ] Subtask: Verify exported logs are readable

- [ ] **Task 1.6.12:** Update documentation
  - [ ] Subtask: Add logging guide to developer docs
  - [ ] Subtask: Document how to view logs in Console.app
  - [ ] Subtask: Document diagnostics export for user support
  - [ ] Subtask: Add troubleshooting section

#### Dev Notes
- **Files Created:**
  - `MyToob/Core/Utilities/LoggingService.swift` - OSLog wrapper
  - `MyToob/Core/Utilities/DiagnosticsService.swift` - Export functionality
  - Settings view modifications for diagnostics UI

- **OSLog Best Practices:**
  - Use appropriate log levels (debug for development only, not production)
  - Always annotate privacy levels explicitly
  - Use structured logging for easier filtering
  - Never log full API responses or tokens

- **Diagnostics Export Format:**
  ```
  MyToob_Diagnostics_2025-11-18_14-30-25.zip
  ├── README.txt (explanation of contents)
  ├── system_info.txt (macOS version, device, memory)
  ├── app_info.txt (version, build, uptime)
  ├── logs.txt (sanitized logs from last 24 hours)
  └── swiftdata_stats.txt (counts, index sizes)
  ```

#### Testing Requirements
- **Unit Tests:**
  - [ ] LoggingService initialization
  - [ ] Log category creation
  - [ ] Privacy level helpers work correctly

- **Integration Tests:**
  - [ ] Diagnostics collection generates valid .zip
  - [ ] Sanitization removes sensitive data
  - [ ] Export UI flow works end-to-end

- **Manual Tests:**
  - [ ] Run app and check Console.app for logs
  - [ ] Filter by subsystem "com.yourcompany.mytoob"
  - [ ] Verify log levels appear correctly
  - [ ] Export diagnostics and verify .zip contents
  - [ ] Verify no sensitive data in export

---

## Epic 2: YouTube OAuth & Data API Integration

**Goal:** Enable users to authenticate with their YouTube account and retrieve metadata via official YouTube Data API v3.

### Story 2.1: Google OAuth Authentication Flow

**Status:** 📋 Draft
**Depends On:** 1.5 (App shell), 1.6 (Logging for auth events)
**Blocks:** All YouTube API features (2.2-2.6, 3.x)
**File:** `docs/stories/2.1.google-oauth-authentication.md`

#### Acceptance Criteria
1. OAuth 2.0 flow implemented using `ASWebAuthenticationSession` (native macOS authentication UI)
2. OAuth scopes requested: `https://www.googleapis.com/auth/youtube.readonly` (minimal scope)
3. OAuth credentials (client ID, client secret) stored securely (not hardcoded, loaded from config file excluded from repo)
4. Authorization code exchange implemented to obtain access token and refresh token
5. Tokens stored securely in macOS Keychain with appropriate access controls
6. User shown clear explanation of what data the app will access before OAuth redirect
7. OAuth flow cancellable by user without app crash
8. Success/failure states handled gracefully with user-friendly error messages

#### Detailed Task Breakdown

**Phase 1: OAuth Handler Service Creation (AC: 1, 2)**
- [ ] **Task 2.1.1:** Create OAuth2Handler service
  - [ ] Subtask: Create file `MyToob/Features/YouTube/OAuth2Handler.swift`
  - [ ] Subtask: Import AuthenticationServices framework
  - [ ] Subtask: Define OAuth constants (authorization URL, token URL)
  - [ ] Subtask: Set scope: `https://www.googleapis.com/auth/youtube.readonly`

- [ ] **Task 2.1.2:** Configure OAuth endpoints
  - [ ] Subtask: Set authorization URL: `https://accounts.google.com/o/oauth2/v2/auth`
  - [ ] Subtask: Set token URL: `https://oauth2.googleapis.com/token`
  - [ ] Subtask: Configure redirect URI for macOS app (custom scheme or Universal Link)
  - [ ] Subtask: Add redirect URI to Info.plist URL schemes

**Phase 2: Secure Credential Management (AC: 3)**
- [ ] **Task 2.1.3:** Create Configuration enum for credentials
  - [ ] Subtask: Create `MyToob/Core/Utilities/Configuration.swift`
  - [ ] Subtask: Load OAuth client ID from environment variable or .env file
  - [ ] Subtask: Load OAuth client secret from environment variable or .env file
  - [ ] Subtask: Add error handling if credentials missing

- [ ] **Task 2.1.4:** Setup .env file management
  - [ ] Subtask: Create `.env.example` with placeholder values
  - [ ] Subtask: Add `.env` to `.gitignore` (prevent accidental commits)
  - [ ] Subtask: Document how to obtain Google OAuth credentials in README
  - [ ] Subtask: Document .env setup process for new developers

**Phase 3: Authorization Request Implementation (AC: 1, 7)**
- [ ] **Task 2.1.5:** Implement ASWebAuthenticationSession flow
  - [ ] Subtask: Create `authenticate()` async method
  - [ ] Subtask: Build authorization URL with parameters (client_id, redirect_uri, scope, response_type=code)
  - [ ] Subtask: Initialize ASWebAuthenticationSession with authorization URL
  - [ ] Subtask: Set presentation context provider
  - [ ] Subtask: Start authentication session
  - [ ] Subtask: Handle callback URL with authorization code
  - [ ] Subtask: Handle user cancellation (catch ASWebAuthenticationSessionError.canceledLogin)
  - [ ] Subtask: Return to previous state on cancellation without crash

**Phase 4: Token Exchange Implementation (AC: 4)**
- [ ] **Task 2.1.6:** Implement authorization code exchange
  - [ ] Subtask: Create `exchangeCodeForTokens(code:)` async method
  - [ ] Subtask: Build token request with authorization code, client ID, client secret
  - [ ] Subtask: Set grant_type to "authorization_code"
  - [ ] Subtask: Send POST request to token URL
  - [ ] Subtask: Parse JSON response for access_token, refresh_token, expires_in
  - [ ] Subtask: Handle token exchange errors (invalid_grant, invalid_client)
  - [ ] Subtask: Return tokens or throw descriptive error

**Phase 5: Keychain Storage Integration (AC: 5)**
- [ ] **Task 2.1.7:** Use KeychainService for token storage
  - [ ] Subtask: Store access token with key "youtube_access_token"
  - [ ] Subtask: Store refresh token with key "youtube_refresh_token"
  - [ ] Subtask: Store token expiry timestamp (Date())
  - [ ] Subtask: Use `kSecAttrAccessibleWhenUnlocked` attribute
  - [ ] Subtask: Handle Keychain save errors gracefully

**Phase 6: Pre-Authorization Consent UI (AC: 6)**
- [ ] **Task 2.1.8:** Create consent view
  - [ ] Subtask: Create `OAuthConsentView.swift` SwiftUI view
  - [ ] Subtask: Show app name and purpose
  - [ ] Subtask: List permissions being requested: "YouTube Data (Read-Only)"
  - [ ] Subtask: Explain what data will be accessed: subscriptions, playlists, viewing history
  - [ ] Subtask: Provide "Cancel" and "Continue" buttons
  - [ ] Subtask: Only call OAuth2Handler.authenticate() when user clicks "Continue"

**Phase 7: Error Handling (AC: 8)**
- [ ] **Task 2.1.9:** Implement comprehensive error handling
  - [ ] Subtask: Create OAuth2Error enum with cases for all failure types
  - [ ] Subtask: Handle network errors (URLError)
  - [ ] Subtask: Handle invalid credentials (401 Unauthorized)
  - [ ] Subtask: Handle user denial at Google consent screen
  - [ ] Subtask: Handle malformed responses
  - [ ] Subtask: Show user-friendly alerts with error messages
  - [ ] Subtask: Log all errors to OSLog for debugging

**Phase 8: Testing & Integration**
- [ ] **Task 2.1.10:** Create unit tests
  - [ ] Subtask: Test OAuth URL construction
  - [ ] Subtask: Test token exchange with mocked responses
  - [ ] Subtask: Test error handling scenarios
  - [ ] Subtask: Test Keychain storage and retrieval
  - [ ] Subtask: Test user cancellation handling

- [ ] **Task 2.1.11:** Manual end-to-end testing
  - [ ] Subtask: Run full OAuth flow with real Google account
  - [ ] Subtask: Verify ASWebAuthenticationSession presents correctly
  - [ ] Subtask: Grant permission at Google and verify callback
  - [ ] Subtask: Verify tokens stored in Keychain
  - [ ] Subtask: Test cancellation doesn't crash app
  - [ ] Subtask: Test with invalid credentials
  - [ ] Subtask: Test with network disconnected

#### Dev Notes
- **Files Created:**
  - `MyToob/Features/YouTube/OAuth2Handler.swift` - OAuth flow logic
  - `MyToob/Core/Utilities/Configuration.swift` - Credential loading
  - `MyToob/Views/OAuthConsentView.swift` - Pre-auth consent UI
  - `.env.example` - Template for OAuth credentials

- **Google Cloud Console Setup:**
  1. Create new project in Google Cloud Console
  2. Enable YouTube Data API v3
  3. Create OAuth 2.0 Client ID (macOS app type)
  4. Add redirect URI (custom scheme: `mytoob://oauth-callback`)
  5. Download credentials and add to .env file

- **Security Considerations:**
  - Never commit client secret to repository
  - Use custom URL scheme for redirect (not localhost)
  - Validate callback URL to prevent hijacking
  - Keychain access restricted to unlocked state only

#### Testing Requirements
- **Unit Tests (`MyToobTests/Services/OAuth2HandlerTests.swift`):**
  - [ ] OAuth URL construction with correct parameters
  - [ ] Token exchange with mocked successful response
  - [ ] Token exchange with mocked error responses
  - [ ] Keychain storage and retrieval
  - [ ] User cancellation handling

- **Integration Tests:**
  - [ ] Full OAuth flow with mocked ASWebAuthenticationSession
  - [ ] Keychain persistence across app restarts

- **Manual Tests:**
  - [ ] Run app and initiate OAuth flow
  - [ ] Verify consent screen explains permissions clearly
  - [ ] Complete OAuth flow with real Google account
  - [ ] Verify tokens stored and retrievable
  - [ ] Cancel flow and verify no crash
  - [ ] Test with invalid credentials
  - [ ] Test with network offline

---

### Story 2.2: Token Storage & Automatic Refresh

**Status:** 📋 Draft
**Depends On:** 2.1 (OAuth flow)
**File:** `docs/stories/2.2.token-storage-refresh.md`

#### Acceptance Criteria
1. Keychain wrapper created for storing/retrieving access token and refresh token
2. Token expiry time tracked (typically 3600 seconds for access token)
3. Before each API call, check if access token is expired (within 5-minute buffer)
4. If expired, automatically refresh using refresh token via OAuth token endpoint
5. If refresh fails (invalid refresh token), prompt user to re-authenticate
6. "Sign Out" action in Settings clears all tokens from Keychain
7. Unit tests verify token refresh logic with mocked OAuth endpoints

#### Detailed Task Breakdown

**Phase 1: KeychainService Creation (AC: 1)**
- [ ] **Task 2.2.1:** Create KeychainService wrapper
  - [ ] Subtask: Create `MyToob/Core/Security/KeychainService.swift`
  - [ ] Subtask: Import Security framework
  - [ ] Subtask: Create `save(key:value:)` method using SecItemAdd
  - [ ] Subtask: Create `retrieve(key:)` method using SecItemCopyMatching
  - [ ] Subtask: Create `delete(key:)` method using SecItemDelete
  - [ ] Subtask: Create `update(key:value:)` method using SecItemUpdate
  - [ ] Subtask: Use `kSecAttrAccessibleWhenUnlocked` for all items
  - [ ] Subtask: Handle Keychain errors and return Result types

**Phase 2: Token Expiry Tracking (AC: 2, 3)**
- [ ] **Task 2.2.2:** Implement expiry timestamp management
  - [ ] Subtask: Store token expiry Date in UserDefaults key "youtube_token_expiry"
  - [ ] Subtask: Calculate expiry: `Date().addingTimeInterval(TimeInterval(expiresIn))`
  - [ ] Subtask: Create `isTokenExpired()` method with 5-minute buffer
  - [ ] Subtask: Return true if current time + 300 seconds >= expiry time

- [ ] **Task 2.2.3:** Create token validation check
  - [ ] Subtask: Create `ensureValidToken()` async method
  - [ ] Subtask: Check if token exists in Keychain
  - [ ] Subtask: Check if token is expired
  - [ ] Subtask: If expired, call refresh flow automatically
  - [ ] Subtask: If not expired, return existing token

**Phase 3: Automatic Token Refresh (AC: 4)**
- [ ] **Task 2.2.4:** Implement refresh token flow
  - [ ] Subtask: Create `refreshAccessToken()` async method in OAuth2Handler
  - [ ] Subtask: Retrieve refresh token from Keychain
  - [ ] Subtask: Build refresh request with grant_type="refresh_token"
  - [ ] Subtask: Include client ID, client secret, and refresh token in request
  - [ ] Subtask: Send POST to token URL
  - [ ] Subtask: Parse response for new access_token and expires_in
  - [ ] Subtask: Update Keychain with new access token
  - [ ] Subtask: Update expiry timestamp in UserDefaults
  - [ ] Subtask: Log refresh success/failure

**Phase 4: Refresh Failure Handling (AC: 5)**
- [ ] **Task 2.2.5:** Handle invalid refresh token
  - [ ] Subtask: Catch HTTP 400 with error "invalid_grant"
  - [ ] Subtask: Clear all tokens from Keychain
  - [ ] Subtask: Clear expiry timestamp
  - [ ] Subtask: Set authentication state to "unauthenticated"
  - [ ] Subtask: Show user notification: "Session expired. Please sign in again."
  - [ ] Subtask: Navigate user to OAuth consent screen

**Phase 5: Sign Out Functionality (AC: 6)**
- [ ] **Task 2.2.6:** Implement sign out action
  - [ ] Subtask: Add "Sign Out" button in Settings > YouTube Account section
  - [ ] Subtask: Show confirmation alert: "Are you sure you want to sign out?"
  - [ ] Subtask: On confirmation, delete access token from Keychain
  - [ ] Subtask: Delete refresh token from Keychain
  - [ ] Subtask: Clear expiry timestamp from UserDefaults
  - [ ] Subtask: Reset authentication state
  - [ ] Subtask: Navigate to signed-out state in UI

**Phase 6: Integration with API Client**
- [ ] **Task 2.2.7:** Integrate token refresh into API calls
  - [ ] Subtask: In YouTubeService, call `ensureValidToken()` before each request
  - [ ] Subtask: If refresh triggered, retry original API request with new token
  - [ ] Subtask: Handle 401 responses by triggering refresh once, then re-authenticating if refresh fails
  - [ ] Subtask: Prevent infinite retry loops (max 1 refresh attempt per request)

**Phase 7: Testing**
- [ ] **Task 2.2.8:** Create comprehensive tests
  - [ ] Subtask: Test Keychain save/retrieve/delete operations
  - [ ] Subtask: Test expiry calculation logic
  - [ ] Subtask: Test `isTokenExpired()` with various dates
  - [ ] Subtask: Test refresh flow with mocked token endpoint (200 OK response)
  - [ ] Subtask: Test refresh failure with mocked 400 invalid_grant response
  - [ ] Subtask: Test sign out clears all data
  - [ ] Subtask: Test `ensureValidToken()` refreshes when needed

#### Dev Notes
- **Files Created:**
  - `MyToob/Core/Security/KeychainService.swift` - Keychain wrapper
  - Modifications to `OAuth2Handler.swift` - Add refresh methods
  - Settings view modifications - Add sign out button

- **Token Lifecycle:**
  ```
  1. User authenticates → Access token (3600s) + Refresh token (long-lived) stored
  2. Before API call → Check expiry
  3. If expired → Use refresh token to get new access token
  4. If refresh fails → Clear tokens, prompt re-authentication
  5. User signs out → Clear all tokens
  ```

- **Keychain Keys:**
  - `youtube_access_token` - Current access token
  - `youtube_refresh_token` - Long-lived refresh token
  - UserDefaults key: `youtube_token_expiry` - Expiry timestamp

- **Security Notes:**
  - Keychain items use `kSecAttrAccessibleWhenUnlocked` (not accessible when device locked)
  - Refresh token is long-lived but can be revoked by user at accounts.google.com
  - Never log tokens in production builds

#### Testing Requirements
- **Unit Tests (`MyToobTests/Services/KeychainServiceTests.swift`):**
  - [ ] Save token to Keychain
  - [ ] Retrieve token from Keychain
  - [ ] Delete token from Keychain
  - [ ] Update existing token
  - [ ] Handle save errors (duplicate item)
  - [ ] Handle retrieve errors (item not found)

- **Unit Tests (`MyToobTests/Services/OAuth2HandlerTests.swift`):**
  - [ ] Token expiry detection (expired vs not expired)
  - [ ] Refresh flow with mocked 200 OK response
  - [ ] Refresh flow with mocked 400 invalid_grant
  - [ ] Ensure valid token returns cached token when not expired
  - [ ] Ensure valid token refreshes when expired

- **Integration Tests:**
  - [ ] Full token lifecycle: authenticate → expire → refresh → sign out
  - [ ] Token persistence across app restarts

---

### Story 2.3: YouTube Data API Client Foundation

**Status:** 📋 Draft
**Depends On:** 2.2 (Token management)
**Blocks:** 2.4-2.6 (API features)
**File:** `docs/stories/2.3.youtube-api-client.md`

#### Acceptance Criteria
1. API client created using `URLSession` with async/await
2. Base URL configured: `https://www.googleapis.com/youtube/v3/`
3. API client automatically injects OAuth access token in `Authorization: Bearer` header
4. Typed request/response models created for key endpoints: `search.list`, `videos.list`, `channels.list`, `playlists.list`, `playlistItems.list`
5. Error handling for HTTP status codes: 401 (unauthorized, trigger token refresh), 403 (quota exceeded), 429 (rate limit), 5xx (server error)
6. API responses parsed into Swift structs (Codable)
7. Unit tests with mocked HTTP responses verify parsing and error handling

#### Detailed Task Breakdown

**Phase 1: YouTubeService Creation (AC: 1, 2, 3)**
- [ ] **Task 2.3.1:** Create YouTube API service
  - [ ] Subtask: Create `MyToob/Features/YouTube/YouTubeService.swift`
  - [ ] Subtask: Define base URL constant: `https://www.googleapis.com/youtube/v3/`
  - [ ] Subtask: Initialize shared URLSession instance
  - [ ] Subtask: Create singleton pattern: `shared` instance

- [ ] **Task 2.3.2:** Implement token injection
  - [ ] Subtask: Create `buildRequest(endpoint:parameters:)` method
  - [ ] Subtask: Call `OAuth2Handler.shared.ensureValidToken()` to get current token
  - [ ] Subtask: Add "Authorization: Bearer {token}" header to all requests
  - [ ] Subtask: Add "Accept: application/json" header
  - [ ] Subtask: Build URLRequest with method, headers, and URL

**Phase 2: Codable Models Creation (AC: 4, 6)**
- [ ] **Task 2.3.3:** Create models directory and base structures
  - [ ] Subtask: Create `MyToob/Features/YouTube/Models/` directory
  - [ ] Subtask: Create `YouTubeAPIResponse.swift` for common response structure
  - [ ] Subtask: Define generic PageInfo and pagination structures

- [ ] **Task 2.3.4:** Create search.list models
  - [ ] Subtask: Create `SearchListResponse.swift`
  - [ ] Subtask: Define SearchResult struct (kind, id: videoId/channelId, snippet)
  - [ ] Subtask: Define SearchSnippet struct (title, description, thumbnails, channelId)

- [ ] **Task 2.3.5:** Create videos.list models
  - [ ] Subtask: Create `VideoListResponse.swift`
  - [ ] Subtask: Define Video struct (id, snippet, contentDetails, statistics)
  - [ ] Subtask: Define VideoSnippet, ContentDetails, Statistics structs

- [ ] **Task 2.3.6:** Create channels.list models
  - [ ] Subtask: Create `ChannelListResponse.swift`
  - [ ] Subtask: Define Channel struct (id, snippet, contentDetails)
  - [ ] Subtask: Define ChannelSnippet and related items

- [ ] **Task 2.3.7:** Create playlists.list models
  - [ ] Subtask: Create `PlaylistListResponse.swift`
  - [ ] Subtask: Define Playlist struct (id, snippet, contentDetails)

- [ ] **Task 2.3.8:** Create playlistItems.list models
  - [ ] Subtask: Create `PlaylistItemsResponse.swift`
  - [ ] Subtask: Define PlaylistItem struct (id, snippet, contentDetails)

**Phase 3: API Request Methods (AC: 1)**
- [ ] **Task 2.3.9:** Implement endpoint methods
  - [ ] Subtask: Create `search(query:maxResults:)` async method
  - [ ] Subtask: Create `getVideos(ids:)` async method
  - [ ] Subtask: Create `getChannels(ids:)` async method
  - [ ] Subtask: Create `getPlaylists(channelId:)` async method
  - [ ] Subtask: Create `getPlaylistItems(playlistId:)` async method
  - [ ] Subtask: Each method builds request, sends, parses response

**Phase 4: Error Handling (AC: 5)**
- [ ] **Task 2.3.10:** Create error types
  - [ ] Subtask: Define `YouTubeAPIError` enum
  - [ ] Subtask: Add case for `.unauthorized` (401 - trigger token refresh)
  - [ ] Subtask: Add case for `.quotaExceeded` (403)
  - [ ] Subtask: Add case for `.rateLimited` (429)
  - [ ] Subtask: Add case for `.serverError` (5xx)
  - [ ] Subtask: Add case for `.invalidResponse`
  - [ ] Subtask: Add case for `.networkError(Error)`

- [ ] **Task 2.3.11:** Implement error handling logic
  - [ ] Subtask: Check HTTP status code in response
  - [ ] Subtask: On 401: trigger token refresh, retry request once
  - [ ] Subtask: On 403: throw quotaExceeded error
  - [ ] Subtask: On 429: throw rateLimited error (circuit breaker will handle)
  - [ ] Subtask: On 5xx: throw serverError with status code
  - [ ] Subtask: Log all API errors to OSLog

**Phase 5: Response Parsing**
- [ ] **Task 2.3.12:** Implement response parsing
  - [ ] Subtask: Decode JSON using JSONDecoder
  - [ ] Subtask: Handle decoding errors gracefully
  - [ ] Subtask: Extract items array from response
  - [ ] Subtask: Return typed models to caller

**Phase 6: Testing (AC: 7)**
- [ ] **Task 2.3.13:** Create mock responses
  - [ ] Subtask: Create mock JSON files for each endpoint
  - [ ] Subtask: Load mock files in test resources

- [ ] **Task 2.3.14:** Create unit tests
  - [ ] Subtask: Test request construction (URL, headers, parameters)
  - [ ] Subtask: Test successful response parsing (200 OK)
  - [ ] Subtask: Test 401 handling (should trigger token refresh)
  - [ ] Subtask: Test 403 handling (quota exceeded)
  - [ ] Subtask: Test 429 handling (rate limit)
  - [ ] Subtask: Test 5xx handling (server error)
  - [ ] Subtask: Test malformed JSON handling
  - [ ] Subtask: Mock URLSession for all tests

#### Dev Notes
- **Files Created:**
  - `MyToob/Features/YouTube/YouTubeService.swift` - Main API client
  - `MyToob/Features/YouTube/Models/SearchListResponse.swift`
  - `MyToob/Features/YouTube/Models/VideoListResponse.swift`
  - `MyToob/Features/YouTube/Models/ChannelListResponse.swift`
  - `MyToob/Features/YouTube/Models/PlaylistListResponse.swift`
  - `MyToob/Features/YouTube/Models/PlaylistItemsResponse.swift`
  - `MyToob/Features/YouTube/Models/YouTubeAPIResponse.swift` - Shared structures

- **YouTube Data API v3 Endpoints:**
  - `GET /search` - Search for videos, channels, playlists
  - `GET /videos` - Get video details by IDs
  - `GET /channels` - Get channel details by IDs
  - `GET /playlists` - Get playlists for a channel
  - `GET /playlistItems` - Get videos in a playlist

- **Key Request Parameters:**
  - `part` - Which resource parts to return (snippet, contentDetails, statistics)
  - `id` - Comma-separated list of IDs
  - `maxResults` - Number of results (default 25, max 50)
  - `pageToken` - For pagination

- **CRITICAL Coding Standards:**
  - Never make direct URLSession calls for YouTube API (use YouTubeService wrapper)
  - Always check token expiry before requests
  - Always handle all error cases
  - Log all API calls for debugging

#### Testing Requirements
- **Unit Tests (`MyToobTests/Services/YouTubeServiceTests.swift`):**
  - [ ] Request URL construction with parameters
  - [ ] Authorization header injection
  - [ ] search.list parsing with mock JSON
  - [ ] videos.list parsing with mock JSON
  - [ ] channels.list parsing with mock JSON
  - [ ] playlists.list parsing with mock JSON
  - [ ] playlistItems.list parsing with mock JSON
  - [ ] 401 error triggers token refresh
  - [ ] 403 error throws quotaExceeded
  - [ ] 429 error throws rateLimited
  - [ ] 5xx error throws serverError
  - [ ] Network error handling
  - [ ] Invalid JSON handling

---

**[Continuing with Stories 2.4-2.6 and all remaining epics...]**

---

## Document Structure Summary

This comprehensive task breakdown document provides:

1. **Complete Coverage:** All 91 stories across 15 epics
2. **Detailed Task Breakdowns:** Multi-phase implementation plans with specific subtasks
3. **Acceptance Criteria:** Full AC from epic documents
4. **Dev Notes:** File locations, architecture patterns, critical standards
5. **Testing Requirements:** Unit tests, integration tests, manual verification steps
6. **Dependencies:** Clear blocking/blocked relationships between stories
7. **Status Tracking:** ✅ Done, 🚧 Draft, 📋 Placeholder indicators

### Usage Guide

**For Developers:**
- Use this document as implementation guide for each story
- Follow task breakdowns sequentially within each phase
- Reference dev notes for architecture patterns and file locations
- Ensure all testing requirements are met before marking story complete

**For Project Managers:**
- Track progress using status indicators
- Identify dependencies and plan parallel work streams
- Estimate effort based on task complexity
- Monitor critical path stories (blocks other work)

**For QA:**
- Use acceptance criteria as test cases
- Follow testing requirements for each story
- Verify all subtasks completed before sign-off

---

## Next Steps

1. **Epic 2-15 Task Breakdowns:** Continue generating detailed breakdowns for remaining 70+ stories
2. **Cross-References:** Add links between related stories and shared components
3. **Estimation:** Add time estimates for each task/phase
4. **Resource Assignment:** Map tasks to development team members based on expertise

---

**Document Status:** In Progress (Epic 1-2 detailed, Epic 3-15 to be expanded)
**Last Updated:** 2025-11-18
**Maintained By:** Development Team / Scrum Master


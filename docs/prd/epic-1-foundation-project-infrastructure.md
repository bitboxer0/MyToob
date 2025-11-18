# Epic 1: Foundation & Project Infrastructure

**Goal:** Establish the foundational project structure, development tooling, and core data models that will support all subsequent development. This epic delivers the basic application shell with working CI/CD pipeline, SwiftData persistence layer, and compliance enforcement tooling. By the end of this epic, we have a functioning (though minimal) macOS app that can be built, tested, and deployed via automated pipeline.

## Story 1.1: Xcode Project Setup & Configuration

As a **developer**,
I want **a properly configured Xcode project with target settings, entitlements, and build configurations**,
so that **I can develop a sandboxed macOS app with correct signing and capabilities**.

**Acceptance Criteria:**
1. Xcode project created for macOS target with minimum deployment target macOS 14.0 (Sonoma)
2. App sandbox enabled with entitlements: `com.apple.security.network.client`, `com.apple.security.files.user-selected.read-write`
3. Signing configured for development and distribution (code signing identity, provisioning profiles)
4. Build configurations created: Debug, Release, TestFlight
5. App group configured for shared data access (if needed for extensions in future)
6. Info.plist includes required keys: LSMinimumSystemVersion, NSHumanReadableCopyright, etc.
7. Core ML embedding model (`sentence-transformer-384.mlpackage`) added to `MyToob/Resources/CoreML Models/` directory
8. Project builds successfully and launches with empty window

## Story 1.2: SwiftLint & Code Quality Tooling

As a **developer**,
I want **automated code quality checks enforced via SwiftLint and swift-format**,
so that **code style is consistent and policy violations (e.g., banned API usage) are caught at compile time**.

**Acceptance Criteria:**
1. SwiftLint installed and integrated as Xcode build phase
2. `.swiftlint.yml` configuration file created with project-specific rules
3. Custom lint rule blocks usage of `googlevideo.com` in string literals (compliance enforcement)
4. Custom lint rule warns on hardcoded secrets/API keys patterns
5. swift-format installed for automated code formatting
6. Danger rules configured to check PRs for policy keywords and file changes
7. Build fails if critical lint violations found (errors, not warnings)

## Story 1.3: GitHub CI/CD Pipeline

As a **developer**,
I want **automated CI/CD via GitHub Actions that runs tests, linting, and builds on every commit**,
so that **code quality is enforced and broken builds are caught immediately**.

**Acceptance Criteria:**
1. `.github/workflows/ci.yml` created with jobs: lint, test, build
2. Lint job runs SwiftLint and fails on errors
3. Test job runs `xcodebuild test` and reports coverage
4. Build job produces signed `.app` artifact
5. Workflow triggers on: push to main, pull requests
6. Workflow uses macOS runner (macos-latest or macos-14)
7. Build artifacts uploaded to GitHub Actions for debugging
8. All jobs pass on initial empty project

## Story 1.4: SwiftData Core Models

As a **developer**,
I want **SwiftData models defined for VideoItem, ClusterLabel, Note, and ChannelBlacklist**,
so that **the app can persist video metadata, AI results, user notes, and moderation preferences**.

**Acceptance Criteria:**
1. `VideoItem` model created with properties: `videoID` (YouTube ID or nil for local), `localURL`, `title`, `channelID`, `duration`, `watchProgress`, `isLocal`, `aiTopicTags`, `embedding` (transformable [Float] array), `addedAt`, `lastWatchedAt`
2. `ClusterLabel` model created with properties: `clusterID`, `label`, `centroid` (transformable [Float] array), `itemCount`
3. `Note` model created with properties: `noteID`, `content` (Markdown string), `timestamp` (optional video position), `createdAt`, `updatedAt`, relationship to `VideoItem`
4. `ChannelBlacklist` model created with properties: `channelID` (unique), `reason` (optional), `blockedAt`
5. Models use `@Attribute(.unique)` for identity fields where appropriate
6. SwiftData model container configured in app entry point
7. Unit tests created for model creation, fetching, and deletion

## Story 1.5: Basic App Shell & Navigation

As a **user**,
I want **a minimal but functional macOS app window with sidebar and main content area**,
so that **I have a foundation UI to build features upon**.

**Acceptance Criteria:**
1. SwiftUI `App` struct created with `@main` entry point
2. Main window created with `WindowGroup` and minimum size (1024x768)
3. Sidebar + content split view layout implemented
4. Sidebar shows placeholder sections: "Collections", "YouTube", "Local Files"
5. Main content area shows placeholder message: "Select an item from the sidebar"
6. App launches without crashes and displays window correctly
7. Window state (size, position) persists across app launches (using AppStorage or SceneStorage)

## Story 1.6: Logging & Diagnostics Framework

As a **developer**,
I want **structured logging using OSLog with privacy controls**,
so that **I can debug issues while respecting user privacy**.

**Acceptance Criteria:**
1. Logging utility created wrapping `OSLog` with predefined subsystems/categories
2. Log levels defined: debug, info, notice, error, fault
3. Privacy levels used: public (non-sensitive), private (sensitive), sensitive (redacted in logs)
4. Example log statements added to app launch flow demonstrating usage
5. Diagnostics export function created (collects logs, system info, sanitizes sensitive data)
6. User-initiated diagnostics export accessible via Settings (returns `.zip` file)
7. No logs written to files by default (uses OS logging system)

---

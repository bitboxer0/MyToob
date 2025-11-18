# Technical Assumptions

## Repository Structure: Monorepo

**Decision:** Single Xcode project with SwiftPM dependencies

**Rationale:**
- Single-app project (native macOS only in MVP)
- SwiftUI + SwiftData + Core ML are all first-party Apple frameworks
- No need for polyrepo complexity until potential future iOS/web expansion
- All code lives in one Xcode project for simplicity
- Separate targets for main app, tests, and optional helper tools

**Structure:**
```
MyToob/
├── MyToob/                    # Main app target
│   ├── App/                   # App entry point, main views
│   ├── Features/              # Feature modules (YouTube, LocalFiles, AI, Search, etc.)
│   ├── Core/                  # Shared utilities, extensions
│   └── Resources/             # Assets, localization
├── MyToobTests/               # Unit tests
├── MyToobUITests/             # UI tests
└── Package.swift              # SwiftPM dependencies (if any external)
```

## Service Architecture

**Decision:** Monolithic single-process native app (no backend services)

**Rationale:**
- All functionality runs on-device (AI, storage, networking)
- No need for custom backend—YouTube Data API provides metadata, CloudKit handles sync
- Simpler deployment and maintenance (no server infrastructure)
- Better privacy story (no data leaves device except via user-controlled CloudKit)
- Lower operating costs (no server hosting fees)

**Component Structure:**
- **YouTubeService:** OAuth, Data API client, quota management
- **LocalFileService:** File import, security-scoped bookmarks, AVKit playback
- **AIService:** Core ML embeddings, vector index, clustering, ranking
- **StorageService:** SwiftData models, CloudKit sync, caching
- **PlayerService:** Unified player abstraction (YouTube IFrame vs. AVKit)
- **SearchService:** Hybrid search coordinator (keyword + vector)

## Testing Requirements

**Decision:** Full testing pyramid (unit + integration + UI + manual testing conveniences)**

**Rationale:**
- Core ML models need integration testing (real model inference, not mocked)
- YouTube IFrame Player bridge needs UI testing (JavaScript interop)
- SwiftData migrations need dedicated migration tests
- API quota management needs soak testing
- Compliance features (UGC reporting, player visibility) need manual testing checklists

**Testing Breakdown:**
- **Unit Tests (85%+ coverage target):** Models, business logic, AI algorithms, API clients, ranking features
- **Integration Tests:** Core ML model inference, SwiftData persistence, CloudKit sync, YouTube Data API (with mock server)
- **UI Tests:** Critical user workflows (sign in, search, playback, collection creation, UGC reporting)
- **Migration Tests:** SwiftData schema versioning, data integrity across versions
- **Soak Tests:** API quota burn simulation, network failure scenarios (429/5xx responses)
- **Manual Testing:** App Store submission checklist (documented test cases for reviewers)

**Testing Conveniences:**
- Mock mode for YouTube Data API (no real quota consumption during dev)
- Seed data generator for testing large libraries (10k+ videos)
- Performance profiling helpers (measure search latency, frame times, energy impact)
- Diagnostics export for user bug reports (sanitized logs, telemetry)

## Additional Technical Assumptions and Requests

**Language & Frameworks:**
- **Language:** Swift 5.10+ with modern concurrency (async/await, actors for thread-safe state)
- **UI Framework:** SwiftUI exclusively (no UIKit/AppKit except where required for AVKit/WKWebView interop)
- **Data Persistence:** SwiftData (not Core Data—use modern Apple framework)
- **Networking:** URLSession with async/await, Combine for reactive streams where needed
- **AI/ML:** Core ML exclusively (no TensorFlow, PyTorch, or external inference engines)

**Apple Ecosystem Compliance:**
- **CRITICAL:** All code, design, and implementation must strictly adhere to:
  - [Apple Human Interface Guidelines (HIG)](https://developer.apple.com/design/human-interface-guidelines) - mandatory for all UI/UX decisions
  - [App Store Review Guidelines](https://developer.apple.com/app-store/guidelines/) - compliance required for App Store submission
  - [macOS Design Themes](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos) - platform-specific patterns
- **Human Interface Guidelines Requirements:**
  - Use native macOS UI patterns and controls (NSToolbar-style toolbars, NSSplitView layouts, native context menus)
  - Follow macOS keyboard shortcuts and menu bar conventions (⌘K for search, ⌘W to close, standard Edit menu)
  - Respect system preferences (Dark Mode, accent colors, reduced motion, increase contrast)
  - Use SF Symbols for icons where appropriate (system-provided icons preferred over custom)
  - Implement proper window management (state restoration, full-screen support, split view)
  - Support macOS-native drag & drop behaviors
- **App Store Guidelines Requirements:**
  - Section 4.2 Minimum Functionality: App must provide substantial, sustained value
  - Section 5.1.1 Data Collection: Privacy labels accurate, user consent for data collection
  - Section 5.2.3 User-Generated Content (UGC): Reporting mechanism, moderation tools, blocking features
  - YouTube ToS compliance: No stream downloading, no ad blocking, use approved YouTube IFrame Player API
  - Sandbox entitlements minimal and justified (network, user-selected files, keychain only)
- **Design Philosophy:**
  - Native macOS look and feel over cross-platform abstractions
  - Leverage system frameworks (SwiftUI, AppKit where needed) rather than custom reimplementations
  - Accessibility baked in from day one (VoiceOver, keyboard navigation, Dynamic Type)
  - Platform integration (Spotlight, Handoff, Continuity Camera if applicable)

**Third-Party Dependencies:**
- **Minimize external dependencies** to reduce supply chain risk and App Store review complexity
- **Acceptable exceptions:**
  - HNSW index implementation (if performant Swift library exists; otherwise implement custom)
  - Graph clustering (Leiden/Louvain algorithm—port or use existing Swift/C++ library)
  - OAuth helpers (if they simplify implementation significantly; otherwise use raw URLSession)
- **Prohibited dependencies:**
  - Any YouTube stream extraction libraries (yt-dlp wrappers, etc.)—ToS violation risk
  - Analytics SDKs (Firebase, Mixpanel, etc.)—conflicts with privacy-first goal
  - Ad-blocking or DOM manipulation libraries—ToS violation

**Development Tools:**
- **Xcode 15+** as primary IDE
- **SwiftLint + swift-format** for code quality and consistency
- **GitHub Actions** for CI/CD (lint, test, build, notarize)
- **XcodeBuildMCP** for automation via Claude Code
- **danger** for PR checks (prevent API key commits, enforce policy keywords like "googlevideo.com")

**Deployment & Distribution:**
- **App Store Build:** Strict compliance, sandboxed, minimal entitlements
- **Notarized DMG Build:** Power-user features for local files only (deeper CV/ASR), requires explicit user opt-in
- **CI/CD Pipeline:** Automate build, test, codesign, notarize, staple, upload to App Store Connect
- **TestFlight:** Beta testing distribution for pre-release feedback

**AI Models:**
- **Embedding Model:** Port a small sentence-transformer model (e.g., all-MiniLM-L6-v2, 384-dim) to Core ML, 8-bit quantization for performance
- **Ranking Model:** Train gradient-boosted tree (XGBoost/LightGBM) offline, export to Core ML
- **OCR:** Use Vision framework's built-in text recognition (no custom model needed)
- **Model Versioning:** Embed model version in metadata, trigger background re-index when model updates

**Logging & Observability:**
- **On-device logging** using OSLog with appropriate privacy levels (public, private, sensitive)
- **User-initiated diagnostics export:** Collect logs, telemetry, system info into sanitized archive
- **No external crash reporting** without explicit user opt-in (privacy-first)
- **Dev-only quota dashboard:** Real-time API unit consumption display (removed in App Store build or hidden behind secret menu)

**Localization:**
- **English (US) only in MVP** with localizable strings framework in place
- **Post-MVP:** Add major languages (Spanish, French, German, Japanese, Chinese) based on user demand

**Accessibility:**
- **WCAG AA compliance** as baseline
- **VoiceOver testing** with real screen reader users (recruit from accessibility community for beta)
- **Keyboard-only operation testing:** Ensure 100% feature coverage without mouse

**Performance Profiling:**
- **Instruments:** Regular profiling for Time Profiler, Allocations, Leaks, Energy Log
- **MetricKit:** Collect on-device performance metrics (launch time, hang rate, memory usage) with user consent
- **Benchmarking:** Establish performance baselines for search latency, index rebuild time, playback smoothness

**Security Audits:**
- **Pre-launch security review:** Check for hardcoded secrets, proper Keychain usage, sandbox compliance
- **Dependency audit:** Verify all external libraries are from trusted sources with recent updates
- **Crash log sanitization:** Ensure no sensitive data (tokens, video titles, user notes) in crash reports

**Compliance Validation:**
- **YouTube ToS compliance checklist:** Document how each requirement is met (no stream caching, no ad removal, etc.)
- **App Store guidelines checklist:** Document how UGC safeguards, IP protection, and privacy labels are addressed
- **Reviewer documentation package:** Screen-by-screen compliance notes, architecture explainer, demo workflow

---

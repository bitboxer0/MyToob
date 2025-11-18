# Tech Stack

| Category | Technology | Version | Purpose | Rationale |
|----------|------------|---------|---------|-----------|
| **Language** | Swift | 5.10+ | Primary development language | Native to Apple platforms, modern concurrency (async/await), strong type safety |
| **UI Framework** | SwiftUI | macOS 14+ | Declarative UI | Apple's recommended framework, reactive, excellent performance, native look-and-feel |
| **Data Persistence** | SwiftData | macOS 14+ | Local database ORM | Modern replacement for Core Data, simpler API, automatic CloudKit sync support |
| **Cloud Sync** | CloudKit | - | Cross-device synchronization | First-party Apple service, private database for user data, no server infrastructure needed |
| **AI/ML Framework** | Core ML | - | On-device machine learning | Optimized for Apple Silicon, supports quantized models, privacy-preserving |
| **Vector Search** | Custom HNSW | - | Approximate nearest neighbor search | High-performance vector similarity, in-memory with disk persistence |
| **Clustering** | Leiden/Louvain (custom) | - | Graph-based community detection | State-of-art clustering for topic grouping, modularity optimization |
| **OCR** | Vision framework | - | Thumbnail text extraction | Built-in to macOS, excellent accuracy, GPU-accelerated |
| **Video Playback (YouTube)** | WKWebView + IFrame Player | - | YouTube video rendering | Official YouTube API, compliant with ToS, no stream access |
| **Video Playback (Local)** | AVKit / AVFoundation | - | Local file playback | Native macOS framework, full codec support, PiP, scrubbing |
| **Networking** | URLSession | - | HTTP client (YouTube API) | Native to Apple platforms, async/await support, caching, authentication |
| **OAuth** | ASWebAuthenticationSession | - | Google OAuth flow | Native macOS authentication UI, secure token exchange |
| **Security** | Keychain Services | - | Secure credential storage | Hardware-backed encryption, sandbox-compliant |
| **Search Integration** | Core Spotlight | - | System-wide search indexing | Native macOS search, zero-config integration |
| **Automation** | App Intents | - | Shortcuts support | Native macOS automation, Siri integration potential |
| **Testing (Unit)** | XCTest | - | Unit and integration tests | Native Xcode framework, async testing support |
| **Testing (UI)** | XCUITest | - | UI automation tests | Native Xcode framework, accessibility integration |
| **Linting** | SwiftLint | Latest | Code quality enforcement | Industry standard, customizable rules, CI integration |
| **Formatting** | swift-format | Latest | Code formatting | Apple's official formatter, consistent style |
| **CI/CD** | GitHub Actions | - | Automated builds and tests | Free for public repos, macOS runners available |
| **Crash Reporting** | OSLog | - | On-device logging | Privacy-preserving, user-controlled export |
| **Monitoring** | MetricKit | - | Performance metrics | On-device telemetry, user consent required |
| **In-App Purchase** | StoreKit 2 | - | Pro tier monetization | Modern async APIs, receipt validation |
| **Notarization** | xcrun notarytool | - | DMG code signing | Required for non-App Store distribution |

---

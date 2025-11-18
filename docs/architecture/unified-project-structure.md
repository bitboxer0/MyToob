# Unified Project Structure

```
MyToob/
├── .github/
│   └── workflows/
│       ├── ci.yml              # Build, test, lint on PR
│       └── release.yml         # Notarize and upload DMG
├── MyToob/                     # Main app target
│   ├── MyToobApp.swift         # @main app entry point
│   ├── Info.plist              # App metadata, entitlements
│   ├── App/
│   │   ├── ContentView.swift           # Root view
│   │   ├── MainWindowView.swift        # Sidebar + content split
│   │   └── SettingsView.swift          # Settings window
│   ├── Features/
│   │   ├── YouTube/
│   │   │   ├── YouTubeService.swift
│   │   │   ├── OAuth2Handler.swift
│   │   │   ├── YouTubePlayerView.swift (WKWebView wrapper)
│   │   │   └── QuotaBudgetTracker.swift
│   │   ├── LocalFiles/
│   │   │   ├── LocalFileService.swift
│   │   │   ├── FileImporter.swift
│   │   │   ├── AVKitPlayerView.swift
│   │   │   └── BookmarkManager.swift
│   │   ├── AI/
│   │   │   ├── AIService.swift
│   │   │   ├── EmbeddingEngine.swift (Core ML wrapper)
│   │   │   ├── VectorIndex.swift (HNSW implementation)
│   │   │   ├── ClusteringEngine.swift (Leiden/Louvain)
│   │   │   └── RankingService.swift
│   │   ├── Search/
│   │   │   ├── SearchService.swift
│   │   │   ├── HybridSearchEngine.swift
│   │   │   └── SearchViewModel.swift
│   │   ├── Collections/
│   │   │   ├── CollectionRepository.swift
│   │   │   └── CollectionViewModel.swift
│   │   ├── Notes/
│   │   │   ├── NoteRepository.swift
│   │   │   ├── MarkdownEditor.swift
│   │   │   └── NoteViewModel.swift
│   │   └── FocusMode/
│   │       ├── FocusModeManager.swift
│   │       ├── FocusModeSettings.swift (SwiftData model)
│   │       └── FocusModeViewModel.swift
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── VideoItem.swift (SwiftData)
│   │   │   ├── ClusterLabel.swift (SwiftData)
│   │   │   ├── Note.swift (SwiftData)
│   │   │   ├── Collection.swift (SwiftData)
│   │   │   └── ChannelBlacklist.swift (SwiftData)
│   │   ├── Repositories/
│   │   │   ├── VideoRepository.swift
│   │   │   ├── ClusterRepository.swift
│   │   │   └── NoteRepository.swift
│   │   ├── Networking/
│   │   │   ├── NetworkService.swift (URLSession wrapper)
│   │   │   ├── APIError.swift
│   │   │   └── CachingLayer.swift (ETag support)
│   │   ├── Security/
│   │   │   ├── KeychainService.swift
│   │   │   └── BookmarkStore.swift
│   │   ├── Utilities/
│   │   │   ├── Extensions/
│   │   │   │   ├── String+Extensions.swift
│   │   │   │   ├── Date+Extensions.swift
│   │   │   │   └── Array+Extensions.swift
│   │   │   ├── LoggingService.swift (OSLog wrapper)
│   │   │   └── Configuration.swift (app config)
│   │   └── MacOSIntegration/
│   │       ├── SpotlightIndexer.swift
│   │       ├── AppIntentsProvider.swift
│   │       └── MenuBarController.swift
│   ├── Resources/
│   │   ├── Assets.xcassets/        # App icon, images
│   │   ├── CoreML Models/
│   │   │   └── sentence-transformer-384.mlpackage
│   │   ├── Localizable/
│   │   │   └── en.lproj/
│   │   │       └── Localizable.strings
│   │   └── HTML/
│   │       └── youtube-player.html  # IFrame Player template
│   └── Views/
│       ├── Components/
│       │   ├── VideoCard.swift
│       │   ├── SearchBar.swift
│       │   ├── FilterPills.swift
│       │   └── MarkdownPreview.swift
│       ├── Library/
│       │   ├── LibraryView.swift
│       │   ├── GridView.swift
│       │   └── ListView.swift
│       ├── Player/
│       │   ├── PlayerView.swift
│       │   ├── YouTubePlayerContainer.swift
│       │   ├── AVKitPlayerContainer.swift
│       │   └── NotesPanel.swift
│       └── Search/
│           ├── SearchResultsView.swift
│           └── FilterPickerView.swift
├── MyToobTests/                # Unit tests
│   ├── YouTubeServiceTests.swift
│   ├── AIServiceTests.swift
│   ├── SearchServiceTests.swift
│   ├── VectorIndexTests.swift
│   └── Mocks/
│       ├── MockVideoRepository.swift
│       └── MockYouTubeService.swift
├── MyToobUITests/              # UI automation tests
│   ├── OnboardingFlowTests.swift
│   ├── SearchFlowTests.swift
│   └── PlaybackFlowTests.swift
├── scripts/
│   ├── setup.sh                # Initial project setup
│   ├── build.sh                # Build for release
│   └── notarize.sh             # Notarize DMG
├── docs/
│   ├── project-brief.md
│   ├── prd.md
│   ├── front-end-spec.md
│   └── architecture.md         # This file
├── .swiftlint.yml              # SwiftLint config
├── .swift-format               # swift-format config
├── .env.example                # Environment template
├── Package.swift               # SwiftPM dependencies (if any)
└── README.md
```

---

# Coding Standards

## Critical Rules

- **SwiftData Models:** Always use `@Model` macro and `@Attribute(.unique)` for identity fields. Never manually manage object IDs.
- **Async/Await:** All network calls, file I/O, and Core ML inference must use async/await. Never block main thread with synchronous APIs.
- **Error Handling:** All throwing functions must be wrapped in do-catch at call site. Never use `try!` except in unit tests.
- **Keychain Access:** Always use `KeychainService` wrapper. Never call `SecItemAdd` directly.
- **Environment Variables:** Access via `Configuration` enum. Never use `ProcessInfo.processInfo.environment` directly in feature code.
- **YouTube API Calls:** Always check quota budget before request. Never make direct URLSession calls—use `YouTubeService`.
- **Player Lifecycle:** Always pause player when view disappears. Never leave players running in background (compliance + battery).
- **Security-Scoped Bookmarks:** Always resolve bookmark before file access. Never assume file URL is valid without resolution.
- **SwiftUI State:** Never mutate `@Published` properties outside `@MainActor` context. Always use `Task { @MainActor in ... }` for async updates.
- **Core ML Models:** Always load models lazily on first use. Never load all models at app launch.

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes/Structs | PascalCase | `VideoItem`, `YouTubeService` |
| Protocols | PascalCase with "Protocol" suffix | `VideoRepositoryProtocol` |
| Properties | camelCase | `watchProgress`, `isLocal` |
| Methods | camelCase | `fetchVideoDetails()`, `generateEmbedding()` |
| Constants | camelCase or UPPER_SNAKE for global | `maxQuotaUnits`, `API_BASE_URL` |
| Enums | PascalCase (enum) + camelCase (cases) | `enum SearchMode { case keyword, vector }` |
| SwiftData Models | PascalCase, singular | `VideoItem` (not `VideoItems`) |
| View Files | PascalCase + "View" suffix | `LibraryView.swift`, `SearchBar.swift` |
| ViewModels | PascalCase + "ViewModel" suffix | `SearchViewModel`, `PlayerViewModel` |
| Test Files | Class name + "Tests" suffix | `YouTubeServiceTests.swift` |

---

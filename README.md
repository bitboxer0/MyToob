# MyToob

A native macOS video client that organizes and discovers YouTube videos and local video files using on-device AI.

## Features

- **YouTube Integration**: Watch YouTube videos via official IFrame Player API (fully compliant with YouTube ToS)
- **Local Video Support**: Play local video files with full AI analysis capabilities
- **On-Device AI**: Semantic search, clustering, and recommendations using Core ML
- **Privacy-First**: All AI processing happens on-device, no external analytics
- **macOS Native**: Built with SwiftUI and AppKit for native macOS experience

## Requirements

- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+
- Swift 5.9+

## Development Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd MyToob
```

### 2. Install Development Tools

#### SwiftLint (Required)

SwiftLint enforces code quality and compliance rules.

```bash
brew install swiftlint
```

Verify installation:
```bash
swiftlint version
```

#### swift-format (Required)

swift-format provides automated code formatting.

```bash
brew install swift-format
```

Verify installation:
```bash
swift-format --version
```

#### Danger (Optional - for PR checks)

Danger automates PR review checks.

```bash
brew install danger/tap/danger-swift
```

### 3. Open the Project

```bash
open MyToob.xcodeproj
```

## Code Quality

### SwiftLint

SwiftLint runs automatically during Xcode builds (configured as a build phase). It enforces:

- **Compliance Rules**: Blocks YouTube ToS violations (e.g., direct googlevideo.com access)
- **Security Rules**: Detects hardcoded API keys and secrets
- **Coding Standards**: Enforces project-specific patterns (Keychain wrappers, Configuration enum usage)
- **Code Style**: Enforces Swift best practices and formatting

#### Running SwiftLint Manually

```bash
# Lint the entire project
swiftlint

# Lint and auto-fix issues
swiftlint --fix

# Lint specific files
swiftlint lint --path MyToob/Models/VideoItem.swift
```

#### Configuration

SwiftLint configuration is in `.swiftlint.yml`. Custom rules include:

- `no_googlevideo_urls`: **ERROR** - Blocks direct googlevideo.com URLs (YouTube ToS compliance)
- `no_hardcoded_api_keys`: **ERROR** - Detects hardcoded API keys
- `no_hardcoded_secrets`: **WARNING** - Detects potential hardcoded secrets
- `no_force_try_outside_tests`: **ERROR** - Blocks `try!` except in test files
- `no_direct_keychain_access`: **ERROR** - Requires KeychainService wrapper
- `no_direct_environment_access`: **ERROR** - Requires Configuration enum
- `no_direct_youtube_urlsession`: **ERROR** - Requires YouTubeService wrapper
- `no_eager_coreml_loading`: **WARNING** - Requires lazy Core ML model loading

### swift-format

swift-format provides automated code formatting.

#### Running swift-format

```bash
# Check formatting (dry run)
swift-format lint --recursive MyToob/

# Auto-format code
swift-format format --in-place --recursive MyToob/

# Format specific file
swift-format format --in-place MyToob/Models/VideoItem.swift
```

#### Configuration

swift-format configuration is in `.swift-format`. Key settings:

- Line length: 120 characters
- Indentation: 2 spaces
- Ordered imports
- No semicolons
- Triple-slash documentation comments

### Pre-Commit Workflow (Recommended)

Before committing code:

```bash
# 1. Format code
swift-format format --in-place --recursive MyToob/

# 2. Run SwiftLint and fix auto-fixable issues
swiftlint --fix

# 3. Run SwiftLint again to check for remaining issues
swiftlint

# 4. Commit if no critical errors
git add .
git commit -m "Your commit message"
```

### Danger (PR Checks)

Danger runs automated checks on pull requests. Configure in your CI/CD pipeline:

```bash
# Run Danger locally
danger-swift pr <PR_URL>
```

Danger checks for:
- Missing PR descriptions
- Large PRs (>500 LOC)
- Policy violation keywords (googlevideo, download, etc.)
- Hardcoded secrets
- Changes to security-sensitive files
- SwiftData model changes without migration plans
- UI changes without screenshots
- Code changes without tests

## Building and Testing

### Build the App

```bash
# From command line
xcodebuild -project MyToob.xcodeproj -scheme MyToob -destination 'platform=macOS' build

# Or use Xcode: Cmd+B
```

### Run Tests

```bash
# Run all tests
xcodebuild test -project MyToob.xcodeproj -scheme MyToob -destination 'platform=macOS'

# Run specific test target
xcodebuild test -project MyToob.xcodeproj -scheme MyToob -only-testing:MyToobTests

# Or use Xcode: Cmd+U
```

## Project Structure

```
MyToob/
├── MyToob/                    # Main app target
│   ├── Models/               # SwiftData models
│   ├── Views/                # SwiftUI views
│   ├── ViewModels/           # View models
│   ├── Services/             # Business logic & APIs
│   └── Resources/            # Assets, configs
├── MyToobTests/              # Unit tests
├── MyToobUITests/            # UI tests
├── .swiftlint.yml           # SwiftLint configuration
├── .swift-format            # swift-format configuration
├── Dangerfile               # Danger PR checks
└── docs/                    # Documentation
```

## Compliance & Security

### YouTube API Compliance

⚠️ **CRITICAL**: This app must comply with YouTube's Terms of Service:

- ✅ **DO**: Use IFrame Player API for YouTube playback
- ✅ **DO**: Respect ads and player UI
- ✅ **DO**: AI analysis on metadata only (title, description, thumbnails)
- ❌ **DON'T**: Download or cache YouTube video/audio streams
- ❌ **DON'T**: Manipulate player DOM or block ads
- ❌ **DON'T**: Direct access to googlevideo.com URLs

SwiftLint will **fail the build** if you violate these rules.

### Security Best Practices

- **Never commit secrets**: Use environment variables or Keychain
- **Always use wrappers**: KeychainService for Keychain, Configuration for env vars
- **Validate inputs**: All API responses validated with Codable
- **Sandbox compliance**: Minimal entitlements (network, user-selected files)

## Contributing

1. Create a feature branch from `main`
2. Follow naming convention: `feature/description`, `bugfix/description`
3. Write tests for new functionality
4. Run code quality checks (SwiftLint, swift-format)
5. Ensure all tests pass
6. Create a pull request with detailed description
7. Address Danger automated checks
8. Wait for code review

## License

[To be determined]

## Acknowledgments

- Built with SwiftUI and SwiftData
- Uses YouTube IFrame Player API
- On-device AI powered by Core ML

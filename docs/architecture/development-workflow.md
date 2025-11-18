# Development Workflow

## Local Development Setup

**Prerequisites:**
```bash
# Xcode 15+ with Command Line Tools
xcode-select --install

# SwiftLint
brew install swiftlint

# swift-format
brew install swift-format

# (Optional) Core ML Tools for model conversion
pip3 install coremltools
```

**Initial Setup:**
```bash
# Clone repository
git clone https://github.com/yourusername/MyToob.git
cd MyToob

# Open Xcode project
open MyToob.xcodeproj

# Copy environment template (add OAuth credentials)
cp .env.example .env
# Edit .env with your Google OAuth Client ID/Secret

# Build and run
⌘R in Xcode
```

**Development Commands:**
```bash
# Run app in Xcode: ⌘R
# Run tests: ⌘U
# Run UI tests: Xcode > Product > Test (select UI test scheme)

# Lint code
swiftlint

# Format code
swift-format -i -r MyToob/

# Build for release
xcodebuild -scheme MyToob -configuration Release build
```

## Environment Configuration

**Required Environment Variables:**

Create `.env` file (not committed):
```bash
# Google OAuth (YouTube Data API)
GOOGLE_OAUTH_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=your-client-secret

# YouTube Data API Key (for non-authenticated requests)
YOUTUBE_API_KEY=your-api-key

# CloudKit Container ID (auto-configured in Xcode)
CLOUDKIT_CONTAINER_ID=iCloud.com.yourcompany.mytoob

# App Store Connect API (for CI/CD)
APP_STORE_CONNECT_API_KEY=your-api-key
```

Load via `Configuration.swift`:
```swift
enum Configuration {
    static let googleOAuthClientID = ProcessInfo.processInfo.environment["GOOGLE_OAUTH_CLIENT_ID"] ?? ""
    static let youtubeAPIKey = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"] ?? ""
}
```

---

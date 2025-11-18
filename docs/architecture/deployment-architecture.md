# Deployment Architecture

## Deployment Strategy

**App Store Deployment:**
- **Platform:** Mac App Store (macOS 14.0+)
- **Build Command:** `xcodebuild -scheme MyToob -configuration Release archive`
- **Output:** `MyToob.xcarchive` → Export as `.pkg` for App Store
- **Signing:** App Store distribution certificate + provisioning profile
- **Entitlements:** App Sandbox, Network Client, User Selected Files (Read/Write)
- **Submission:** Upload via Xcode Organizer or Transporter app

**DMG Deployment (Notarized):**
- **Platform:** Direct download from website
- **Build Command:** `xcodebuild -scheme MyToob -configuration Release build`
- **Output:** `MyToob.app` → Create DMG with `hdiutil`
- **Signing:** Developer ID Application certificate
- **Notarization:** `xcrun notarytool submit MyToob.dmg --apple-id ... --password ... --team-id ...`
- **Stapling:** `xcrun stapler staple MyToob.dmg`
- **Distribution:** Host on `https://yourwebsite.com/downloads/MyToob.dmg`

## CI/CD Pipeline

**GitHub Actions Workflow** (`.github/workflows/ci.yml`):
```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Run SwiftLint
        run: swiftlint --strict

  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Run Tests
        run: xcodebuild test -scheme MyToob -destination 'platform=macOS'

  build:
    runs-on: macos-14
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - name: Build Release
        run: xcodebuild -scheme MyToob -configuration Release build
      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: MyToob.app
          path: build/Release/MyToob.app
```

**Release Workflow** (`.github/workflows/release.yml`):
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Build Archive
        run: xcodebuild -scheme MyToob -configuration Release archive
      - name: Export for App Store
        run: xcodebuild -exportArchive -archivePath MyToob.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist
      - name: Create DMG
        run: |
          create-dmg --volname "MyToob" --window-size 600 400 MyToob.dmg build/MyToob.app
      - name: Notarize DMG
        run: xcrun notarytool submit MyToob.dmg --apple-id $APPLE_ID --password $APPLE_PASSWORD --team-id $TEAM_ID --wait
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
          TEAM_ID: ${{ secrets.TEAM_ID }}
      - name: Staple DMG
        run: xcrun stapler staple MyToob.dmg
      - name: Upload Release
        uses: softprops/action-gh-release@v1
        with:
          files: MyToob.dmg
```

## Environments

| Environment | URL | Purpose |
|-------------|-----|---------|
| **Development** | Local Mac | Local development and testing |
| **TestFlight** | App Store Connect | Beta testing with external users |
| **Production (App Store)** | Mac App Store | Live App Store distribution |
| **Production (DMG)** | https://yourwebsite.com/download | Direct download for power users |

---

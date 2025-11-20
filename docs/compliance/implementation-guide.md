# UGC Safeguards Implementation Guide

**Document Version:** 1.0  
**Last Updated:** 2025-11-18  
**Target Audience:** Developers implementing Epic 12 Stories  
**Status:** Active

## Overview

This guide provides step-by-step instructions for implementing UGC safeguards and compliance features defined in Epic 12. Each section corresponds to a story in the epic and includes code samples, integration points, and testing requirements.

## Prerequisites

Before implementing UGC safeguards:

- [x] ChannelBlacklist model implemented (exists in `MyToob/Models/ChannelBlacklist.swift`)
- [ ] YouTube IFrame Player integration complete (Epic 3)
- [ ] SwiftData persistence layer working (Epic 6)
- [ ] Settings UI framework in place
- [ ] Compliance logging system (OSLog) configured

## Story 12.1: Report Content Action

### Implementation Steps

**1. Add Report Action to Video Context Menu**

**File:** `MyToob/Features/YouTube/VideoContextMenu.swift`

```swift
import SwiftUI

struct VideoContextMenu: View {
    let videoItem: VideoItem
    
    var body: some View {
        Group {
            // Existing actions...
            Button("Add to Collection") { /* ... */ }
            Button("Add Note") { /* ... */ }
            
            Divider()
            
            // COMPLIANCE: Report action for YouTube videos only
            if !videoItem.isLocal {
                Button(action: reportContent) {
                    Label("Report Content", systemImage: "exclamationmark.triangle")
                }
                .foregroundColor(.red)
            }
            
            Button(action: hideChannel) {
                Label("Hide Channel", systemImage: "eye.slash")
            }
        }
    }
    
    private func reportContent() {
        guard let videoID = videoItem.videoID else { return }
        
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Report this video?"
        alert.informativeText = "This will open YouTube's reporting page in your web browser."
        alert.addButton(withTitle: "Report on YouTube")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Open YouTube reporting URL
            let reportURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)&report=1")!
            NSWorkspace.shared.open(reportURL)
            
            // Log compliance event
            Logger.compliance.info("User reported video", metadata: [
                "videoID": .string(videoID),
                "timestamp": .string(ISO8601DateFormatter().string(from: Date()))
            ])
        }
    }
    
    private func hideChannel() {
        // Implementation in Story 12.2
    }
}
```

**2. Add Unit Test**

**File:** `MyToobTests/Features/YouTube/VideoContextMenuTests.swift`

```swift
import XCTest
@testable import MyToob

class VideoContextMenuTests: XCTestCase {
    func testReportContentOpensYouTubeURL() {
        let videoItem = VideoItem(videoID: "dQw4w9WgXcQ", title: "Test Video", isLocal: false)
        
        // Verify report URL is correctly formatted
        let expectedURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ&report=1"
        let reportURL = VideoContextMenu.buildReportURL(for: videoItem.videoID!)
        
        XCTAssertEqual(reportURL.absoluteString, expectedURL)
    }
    
    func testReportActionOnlyForYouTubeVideos() {
        let localVideo = VideoItem(localURL: URL(fileURLWithPath: "/test.mp4"), isLocal: true)
        let youtubeVideo = VideoItem(videoID: "abc123", title: "Test", isLocal: false)
        
        XCTAssertFalse(VideoContextMenu.shouldShowReportAction(for: localVideo))
        XCTAssertTrue(VideoContextMenu.shouldShowReportAction(for: youtubeVideo))
    }
}
```

**3. Add UI Test**

**File:** `MyToobUITests/ComplianceUITests.swift`

```swift
import XCTest

class ComplianceUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        app.launch()
    }
    
    func testReportContentFlow() {
        // Navigate to YouTube video
        app.tables["VideoLibrary"].cells.firstMatch.rightClick()
        
        // Verify "Report Content" appears in context menu
        XCTAssertTrue(app.menuItems["Report Content"].exists)
        
        // Click Report Content
        app.menuItems["Report Content"].click()
        
        // Verify confirmation dialog shown
        XCTAssertTrue(app.dialogs["Report this video?"].exists)
        
        // Click "Report on YouTube"
        app.buttons["Report on YouTube"].click()
        
        // Verify browser opened (check for Safari window - may require accessibility permissions)
        // Note: Full E2E verification requires mocking NSWorkspace.shared.open
    }
}
```

### Acceptance Criteria Checklist

- [ ] "Report Content" action appears in context menu for YouTube videos only
- [ ] Clicking action shows confirmation dialog with clear messaging
- [ ] "Report on YouTube" button opens correct URL: `https://www.youtube.com/watch?v={videoID}&report=1`
- [ ] Action hidden for local files
- [ ] Report event logged to compliance subsystem
- [ ] Unit tests verify URL construction
- [ ] UI test verifies end-to-end flow

---

## Story 12.2: Hide & Blacklist Channels

### Implementation Steps

**1. Add Hide Channel Action**

**File:** `MyToob/Features/YouTube/VideoContextMenu.swift` (extend from 12.1)

```swift
private func hideChannel() {
    guard let channelID = videoItem.channelID,
          let channelName = videoItem.channelName else { return }
    
    // Show confirmation dialog
    let alert = NSAlert()
    alert.messageText = "Hide all videos from \(channelName)?"
    alert.informativeText = "You can unhide channels in Settings > Hidden Channels."
    alert.addButton(withTitle: "Hide Channel")
    alert.addButton(withTitle: "Cancel")
    alert.alertStyle = .warning
    
    if alert.runModal() == .alertFirstButtonReturn {
        Task {
            await ChannelBlacklistService.shared.hideChannel(
                channelID: channelID,
                channelName: channelName,
                reason: "User hidden"
            )
        }
    }
}
```

**2. Create ChannelBlacklistService**

**File:** `MyToob/Services/ChannelBlacklistService.swift`

```swift
import SwiftData
import OSLog

@MainActor
class ChannelBlacklistService: ObservableObject {
    static let shared = ChannelBlacklistService()
    
    @Published var hiddenChannels: [ChannelBlacklist] = []
    private var modelContext: ModelContext?
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadHiddenChannels()
    }
    
    func hideChannel(channelID: String, channelName: String?, reason: String) async {
        guard let context = modelContext else { return }
        
        // Check if already blacklisted
        let descriptor = FetchDescriptor<ChannelBlacklist>(
            predicate: #Predicate { $0.channelID == channelID }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            Logger.compliance.info("Channel already blacklisted: \(channelID)")
            return
        }
        
        // Create new blacklist entry
        let blacklist = ChannelBlacklist(
            channelID: channelID,
            reason: reason,
            blockedAt: Date(),
            channelName: channelName
        )
        
        context.insert(blacklist)
        try? context.save()
        
        // Log compliance event
        Logger.compliance.info("User hid channel", metadata: [
            "channelID": .string(channelID),
            "reason": .string(reason)
        ])
        
        // Reload hidden channels
        loadHiddenChannels()
        
        // Post notification to refresh UI
        NotificationCenter.default.post(name: .channelBlacklistUpdated, object: nil)
    }
    
    func unhideChannel(channelID: String) async {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<ChannelBlacklist>(
            predicate: #Predicate { $0.channelID == channelID }
        )
        
        guard let blacklist = try? context.fetch(descriptor).first else { return }
        
        context.delete(blacklist)
        try? context.save()
        
        Logger.compliance.info("User unhid channel: \(channelID)")
        
        loadHiddenChannels()
        NotificationCenter.default.post(name: .channelBlacklistUpdated, object: nil)
    }
    
    private func loadHiddenChannels() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<ChannelBlacklist>(
            sortBy: [SortDescriptor(\.blockedAt, order: .reverse)]
        )
        
        hiddenChannels = (try? context.fetch(descriptor)) ?? []
    }
    
    func isChannelHidden(_ channelID: String?) -> Bool {
        guard let channelID = channelID else { return false }
        return hiddenChannels.contains { $0.channelID == channelID }
    }
}

// Notification name extension
extension Notification.Name {
    static let channelBlacklistUpdated = Notification.Name("channelBlacklistUpdated")
}
```

**3. Create Hidden Channels Settings UI**

**File:** `MyToob/Features/Settings/HiddenChannelsView.swift`

```swift
import SwiftUI
import SwiftData

struct HiddenChannelsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChannelBlacklist.blockedAt, order: .reverse) var hiddenChannels: [ChannelBlacklist]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hidden Channels")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Videos from these channels are hidden from your library and search results.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if hiddenChannels.isEmpty {
                emptyState
            } else {
                channelList
            }
        }
        .padding()
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Hidden Channels")
                .font(.headline)
            
            Text("Right-click any YouTube video and select \"Hide Channel\" to hide content from specific creators.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var channelList: some View {
        VStack(alignment: .leading, spacing: 8) {
            List {
                ForEach(hiddenChannels) { blacklist in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(blacklist.channelName ?? blacklist.channelID)
                                .font(.body)
                            
                            Text("Hidden on \(blacklist.blockedAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let reason = blacklist.reason {
                                Text(reason)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Unhide") {
                            unhideChannel(blacklist)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            if hiddenChannels.count > 1 {
                Button(action: unhideAll) {
                    Label("Unhide All Channels", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func unhideChannel(_ blacklist: ChannelBlacklist) {
        Task {
            await ChannelBlacklistService.shared.unhideChannel(channelID: blacklist.channelID)
        }
    }
    
    private func unhideAll() {
        let alert = NSAlert()
        alert.messageText = "Unhide all channels?"
        alert.informativeText = "This will restore \(hiddenChannels.count) channels to your library."
        alert.addButton(withTitle: "Unhide All")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            Task {
                for blacklist in hiddenChannels {
                    await ChannelBlacklistService.shared.unhideChannel(channelID: blacklist.channelID)
                }
            }
        }
    }
}
```

**4. Apply Blacklist Filter to Video Queries**

**File:** `MyToob/Features/Library/VideoLibraryView.swift`

```swift
import SwiftUI
import SwiftData

struct VideoLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allVideos: [VideoItem]
    @ObservedObject private var blacklistService = ChannelBlacklistService.shared
    
    private var filteredVideos: [VideoItem] {
        allVideos.filter { video in
            !blacklistService.isChannelHidden(video.channelID)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))]) {
                ForEach(filteredVideos) { video in
                    VideoThumbnailView(video: video)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .channelBlacklistUpdated)) { _ in
            // Trigger view refresh when blacklist changes
        }
    }
}
```

### Acceptance Criteria Checklist

- [ ] "Hide Channel" action in context menu for YouTube videos
- [ ] Confirmation dialog shows channel name and unhide instructions
- [ ] Channel added to ChannelBlacklist with channelID, reason, blockedAt
- [ ] All videos from blacklisted channel hidden from library
- [ ] Blacklisted channels hidden from search results
- [ ] "Hidden Channels" section in Settings shows all blacklisted channels
- [ ] "Unhide" button removes channel from blacklist
- [ ] Blacklist syncs via CloudKit (if sync enabled)
- [ ] Unit tests verify filtering logic
- [ ] UI tests verify hide/unhide flow

---

## Story 12.3: Content Policy Page

### Implementation Steps

**1. Create Static Content Policy Page**

**File:** `MyToob/Resources/ContentPolicy.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MyToob Content Policy</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            color: #333;
        }
        h1 { color: #1a1a1a; border-bottom: 2px solid #007AFF; padding-bottom: 10px; }
        h2 { color: #333; margin-top: 30px; }
        .highlight { background-color: #f0f8ff; padding: 15px; border-left: 4px solid #007AFF; }
        a { color: #007AFF; text-decoration: none; }
        a:hover { text-decoration: underline; }
        ul { padding-left: 20px; }
        .icon { margin-right: 8px; }
    </style>
</head>
<body>
    <h1>MyToob Content Policy</h1>
    
    <div class="highlight">
        <p><strong>Last Updated:</strong> November 18, 2025</p>
        <p>MyToob organizes and discovers video content from YouTube and your local files. We do not host third-party content.</p>
    </div>
    
    <h2>YouTube Content Standards</h2>
    <p>All YouTube content accessed through MyToob is subject to <a href="https://www.youtube.com/howyoutubeworks/policies/community-guidelines/" target="_blank">YouTube's Community Guidelines</a>.</p>
    
    <p>Prohibited content includes:</p>
    <ul>
        <li>Violent or graphic content</li>
        <li>Hate speech and harassment</li>
        <li>Spam, misleading metadata, and scams</li>
        <li>Harmful or dangerous content</li>
        <li>Child safety violations</li>
    </ul>
    
    <h2>How to Report YouTube Content</h2>
    <p><span class="icon">⚠️</span> Right-click any YouTube video → "Report Content" → Opens YouTube's official reporting page</p>
    <p>YouTube's moderation team reviews reports within 24 hours per their policies.</p>
    
    <h2>How to Hide Unwanted Channels</h2>
    <p><span class="icon">👁️</span> Right-click video → "Hide Channel" → All videos from that channel hidden from your library</p>
    <p>Manage hidden channels: Settings → Hidden Channels</p>
    
    <h2>Local File Responsibilities</h2>
    <p>You are responsible for ensuring your local video files:</p>
    <ul>
        <li>Comply with applicable laws (copyright, decency, etc.)</li>
        <li>Do not contain illegal or harmful content</li>
        <li>Respect intellectual property rights</li>
    </ul>
    <p>MyToob does not monitor, filter, or moderate your local files.</p>
    
    <h2>What We Do</h2>
    <ul>
        <li>✅ Provide tools to hide YouTube channels you find objectionable</li>
        <li>✅ Offer direct reporting link to YouTube's moderation team</li>
        <li>✅ Process all AI features on-device (no data sent to servers)</li>
        <li>✅ Respond to user reports within 24 hours</li>
    </ul>
    
    <h2>What We Don't Do</h2>
    <ul>
        <li>❌ Host or moderate YouTube content (YouTube's responsibility)</li>
        <li>❌ Upload or share your local files (they stay on your Mac)</li>
        <li>❌ Collect or analyze your viewing habits (on-device AI only)</li>
        <li>❌ Download or cache YouTube video streams (metadata only)</li>
    </ul>
    
    <h2>Contact & Support</h2>
    <p>Questions about this policy: <a href="mailto:support@mytoob.app">support@mytoob.app</a></p>
    <p>Report issues: Settings → Support → Send Diagnostics</p>
    
    <hr>
    
    <p style="font-size: 0.9em; color: #666; margin-top: 40px;">
        MyToob is not affiliated with YouTube. YouTube is a trademark of Google LLC.
    </p>
</body>
</html>
```

**2. Add Content Policy Link to Settings**

**File:** `MyToob/Features/Settings/AboutView.swift`

```swift
import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            Section("App Information") {
                LabeledContent("Version", value: Bundle.main.appVersion)
                LabeledContent("Build", value: Bundle.main.buildNumber)
            }
            
            Section("Legal & Policies") {
                Button(action: openContentPolicy) {
                    Label("Content Policy", systemImage: "doc.text")
                }
                
                Button(action: openTermsOfService) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                
                Button(action: openPrivacyPolicy) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
            
            Section("Disclaimers") {
                Text("MyToob is not affiliated with YouTube. YouTube is a trademark of Google LLC.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Powered by YouTube")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Support") {
                Button(action: openSupport) {
                    Label("Contact Support", systemImage: "envelope")
                }
                
                Button(action: sendDiagnostics) {
                    Label("Send Diagnostics", systemImage: "ladybug")
                }
            }
        }
        .formStyle(.grouped)
    }
    
    private func openContentPolicy() {
        // Option 1: Open bundled HTML file in default browser
        if let policyURL = Bundle.main.url(forResource: "ContentPolicy", withExtension: "html") {
            NSWorkspace.shared.open(policyURL)
        }
        
        // Option 2: Open hosted policy page (preferred for App Store build)
        // let policyURL = URL(string: "https://mytoob.app/content-policy")!
        // NSWorkspace.shared.open(policyURL)
        
        // Log compliance event
        Logger.compliance.info("User accessed Content Policy")
    }
    
    private func openTermsOfService() {
        // Implementation similar to openContentPolicy
    }
    
    private func openPrivacyPolicy() {
        // Implementation similar to openContentPolicy
    }
    
    private func openSupport() {
        if let emailURL = URL(string: "mailto:support@mytoob.app") {
            NSWorkspace.shared.open(emailURL)
        }
    }
    
    private func sendDiagnostics() {
        // Implementation in Story 12.4
    }
}
```

### Acceptance Criteria Checklist

- [ ] "Content Policy" link in Settings > About section
- [ ] Clicking link opens policy page (bundled HTML or website)
- [ ] Policy page includes all required sections (see framework doc)
- [ ] Policy page accessible without authentication
- [ ] Policy language clear, non-technical, user-friendly
- [ ] Event logged when user accesses policy

---

## Story 12.4: Support & Contact Information

### Implementation Steps

**1. Add Send Diagnostics Feature**

**File:** `MyToob/Utilities/DiagnosticsExporter.swift`

```swift
import Foundation
import OSLog

class DiagnosticsExporter {
    static func exportDiagnostics() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let diagnosticsURL = tempDir.appendingPathComponent("MyToob-Diagnostics-\(Date().timeIntervalSince1970).zip")
        
        // Collect diagnostics data
        var diagnosticsData: [String: Any] = [:]
        
        // 1. App version info
        diagnosticsData["app_version"] = Bundle.main.appVersion
        diagnosticsData["build_number"] = Bundle.main.buildNumber
        diagnosticsData["macos_version"] = ProcessInfo.processInfo.operatingSystemVersionString
        
        // 2. Aggregated metrics (no PII)
        diagnosticsData["metrics"] = TelemetryService.shared.exportMetrics()
        
        // 3. Compliance logs (last 7 days, sanitized)
        diagnosticsData["compliance_logs"] = exportComplianceLogs(days: 7)
        
        // 4. Crash logs (sanitized)
        diagnosticsData["crash_logs"] = exportSanitizedCrashLogs()
        
        // 5. System info
        diagnosticsData["system_info"] = [
            "processor": ProcessInfo.processInfo.processorCount,
            "memory": ProcessInfo.processInfo.physicalMemory / 1_000_000_000, // GB
            "architecture": ProcessInfo.processInfo.machineHardwareName
        ]
        
        // Write to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: diagnosticsData, options: .prettyPrinted)
            try jsonData.write(to: diagnosticsURL)
            return diagnosticsURL
        } catch {
            Logger.system.error("Failed to export diagnostics: \(error)")
            return nil
        }
    }
    
    private static func exportComplianceLogs(days: Int) -> [[String: String]] {
        // Fetch compliance logs from OSLog
        // Sanitize (remove PII, video IDs, channel names)
        // Return array of log entries
        return [] // Placeholder
    }
    
    private static func exportSanitizedCrashLogs() -> [String] {
        // Fetch recent crash logs
        // Apply CrashReporter.sanitizeCrashLog() to each
        return [] // Placeholder
    }
}
```

**2. Integrate Send Diagnostics in Settings**

```swift
// In AboutView.swift (from Story 12.3)
private func sendDiagnostics() {
    guard let diagnosticsURL = DiagnosticsExporter.exportDiagnostics() else {
        showError("Failed to export diagnostics")
        return
    }
    
    // Open email client with diagnostics attached
    let emailService = NSSharingService(named: .composeEmail)
    emailService?.recipients = ["support@mytoob.app"]
    emailService?.subject = "MyToob Diagnostics Report"
    
    let emailBody = """
    Please describe the issue you're experiencing:
    
    
    
    ---
    Diagnostics file attached. No personal data included.
    """
    
    // Create temporary text file for email body
    let bodyURL = FileManager.default.temporaryDirectory.appendingPathComponent("email-body.txt")
    try? emailBody.write(to: bodyURL, atomically: true, encoding: .utf8)
    
    emailService?.perform(withItems: [bodyURL, diagnosticsURL])
    
    Logger.compliance.info("User exported diagnostics for support")
}

private func showError(_ message: String) {
    let alert = NSAlert()
    alert.messageText = "Error"
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
}
```

### Acceptance Criteria Checklist

- [ ] "Contact Support" link in Settings opens email client (support@mytoob.app)
- [ ] "Send Diagnostics" button creates sanitized diagnostics bundle
- [ ] Diagnostics include: app version, system info, aggregated metrics, compliance logs
- [ ] Diagnostics exclude: PII, video IDs, channel names, viewing history
- [ ] Email pre-filled with support address and diagnostics attached
- [ ] Support response time commitment documented (24 hours)
- [ ] Unit tests verify diagnostics sanitization

---

## Story 12.5: YouTube Disclaimers & Attributions

### Implementation Steps

**1. Add "Powered by YouTube" Badge to Player**

**File:** `MyToob/Features/YouTube/YouTubePlayerView.swift`

```swift
struct YouTubePlayerView: View {
    let videoID: String
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // IFrame Player WKWebView
            WKWebViewRepresentation(videoID: videoID)
            
            // YouTube attribution badge
            VStack(spacing: 4) {
                Image("youtube-logo") // Asset from YouTube branding guidelines
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                
                Text("Powered by YouTube")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            .padding(12)
        }
    }
}
```

**2. Add "Not Affiliated" Disclaimer to About**

Already implemented in AboutView.swift (Story 12.3):
```swift
Section("Disclaimers") {
    Text("MyToob is not affiliated with YouTube. YouTube is a trademark of Google LLC.")
        .font(.caption)
        .foregroundColor(.secondary)
    
    Text("Powered by YouTube")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

**3. Verify App Name & Icon Compliance**

**Checklist:**
- [ ] App name is "MyToob" (does not contain "YouTube")
- [ ] App icon custom-designed, does not resemble YouTube logo
- [ ] "YouTube" logo used in sidebar is official asset (not modified)
- [ ] Attribution badges use official YouTube branding assets

### Acceptance Criteria Checklist

- [ ] "Not affiliated with YouTube" disclaimer in About screen
- [ ] "Powered by YouTube" badge near IFrame Player
- [ ] YouTube logo in sidebar uses official asset
- [ ] App name avoids "YouTube" trademark
- [ ] App icon custom, non-derivative
- [ ] Terms of Service includes YouTube ToS reference
- [ ] Reviewer notes explain branding compliance

---

## Story 12.6: Compliance Audit Logging

Already largely implemented via framework. Final integration steps:

**1. Ensure All Compliance Events Logged**

**Checklist:**
- [ ] User reported video → `ComplianceEvent.userReportedVideo.log()`
- [ ] User hid channel → `ComplianceEvent.userHidChannel.log()`
- [ ] Quota limit reached → `ComplianceEvent.quotaLimitReached.log()`
- [ ] Cache violation blocked → `ComplianceEvent.cacheViolationBlocked.log()`
- [ ] Playback paused (not visible) → `ComplianceEvent.playbackPausedNotVisible.log()`
- [ ] EULA accepted → `ComplianceEvent.eulaAccepted.log()`
- [ ] Content policy viewed → `ComplianceEvent.contentPolicyViewed.log()`

**2. Add Developer-Only Export**

**File:** `MyToob/Utilities/ComplianceLogExporter.swift`

```swift
class ComplianceLogExporter {
    static func exportLogs() -> URL? {
        // Developer-only menu: ⌘⌥⇧C
        // Exports last 90 days of compliance logs as JSON
        // For App Store reviewer submission
        
        let logs = fetchComplianceLogs(days: 90)
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("compliance-logs-\(Date().timeIntervalSince1970).json")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: logs, options: .prettyPrinted)
            try jsonData.write(to: exportURL)
            return exportURL
        } catch {
            return nil
        }
    }
    
    private static func fetchComplianceLogs(days: Int) -> [[String: Any]] {
        // Fetch from OSLog subsystem: com.mytoob.compliance
        // Last `days` days only
        // Sanitized (no PII)
        return [] // Placeholder
    }
}
```

### Acceptance Criteria Checklist

- [ ] All compliance events logged to OSLog (subsystem: com.mytoob.compliance)
- [ ] Logs include: timestamp, event type, videoID/channelID (no titles/names)
- [ ] Logs stored securely, auto-deleted after 90 days
- [ ] Developer export available for App Store review
- [ ] Logs formatted as JSON for machine-readability

---

## Integration Testing

### End-to-End Compliance Flow Test

**File:** `MyToobUITests/ComplianceE2ETests.swift`

```swift
import XCTest

class ComplianceE2ETests: XCTestCase {
    func testFullComplianceWorkflow() {
        let app = XCUIApplication()
        app.launch()
        
        // 1. Accept EULA
        if app.buttons["I Agree"].exists {
            app.buttons["I Agree"].click()
        }
        
        // 2. View Content Policy
        app.menuBars.menuItems["Settings"].click()
        app.windows["Settings"].buttons["About"].click()
        app.buttons["Content Policy"].click()
        // Verify browser/HTML viewer opened
        
        // 3. Hide Channel
        app.tables["VideoLibrary"].cells.firstMatch.rightClick()
        app.menuItems["Hide Channel"].click()
        app.dialogs.buttons["Hide Channel"].click()
        
        // Verify channel hidden
        XCTAssertFalse(app.tables["VideoLibrary"].cells.matching(identifier: "hiddenChannelCell").firstMatch.exists)
        
        // 4. Unhide Channel in Settings
        app.windows["Settings"].buttons["Hidden Channels"].click()
        app.tables["HiddenChannelsList"].cells.firstMatch.buttons["Unhide"].click()
        
        // 5. Report Content
        app.tables["VideoLibrary"].cells.firstMatch.rightClick()
        app.menuItems["Report Content"].click()
        app.dialogs.buttons["Report on YouTube"].click()
        // Verify browser opened to YouTube reporting URL
        
        // 6. Export Diagnostics
        app.windows["Settings"].buttons["Support"].click()
        app.buttons["Send Diagnostics"].click()
        // Verify email client opened with diagnostics
    }
}
```

---

## Deployment Checklist

### Pre-Launch Validation

**Code Quality:**
- [ ] All SwiftLint compliance rules passing
- [ ] Danger CI checks green
- [ ] No hardcoded secrets in codebase
- [ ] All unit tests passing (>85% coverage)
- [ ] All UI tests passing

**Functional Testing:**
- [ ] Report Content opens correct YouTube URL
- [ ] Hide Channel adds to blacklist and filters videos
- [ ] Hidden Channels UI shows/hides channels correctly
- [ ] Content Policy page accessible and renders correctly
- [ ] Send Diagnostics exports sanitized data
- [ ] Disclaimers visible in About screen

**Compliance Documentation:**
- [ ] `ugc-safeguards-framework.md` complete
- [ ] `parental-controls.md` reviewed
- [ ] `policy-enforcement.md` reflects implementation
- [ ] App Store reviewer notes package prepared

**External Assets:**
- [ ] Content Policy page deployed (mytoob.app/content-policy)
- [ ] Support email configured (support@mytoob.app)
- [ ] YouTube branding assets licensed and included

### App Store Submission Package

**Required Documents:**
1. **Reviewer Notes** (`docs/app-store/reviewer-notes.md`):
   - Explanation of UGC delegation model
   - Screenshots of compliance features
   - Test account credentials (if needed)
   
2. **Compliance Checklist** (based on Story 12.5 AC):
   - Content filtering: ✅ ChannelBlacklist
   - Reporting: ✅ Deep-link to YouTube
   - User blocking: ✅ Channel-level blocking
   - Timely response: ✅ 24-hour SLA
   - EULA: ✅ First-launch acceptance
   - Content policy: ✅ Public page

3. **Screenshots**:
   - Report Content dialog
   - Hide Channel confirmation
   - Hidden Channels settings
   - Content Policy page
   - About screen with disclaimers

---

## Maintenance Plan

### Monthly Review
- [ ] Test all compliance flows still functional
- [ ] Verify YouTube reporting URL still valid
- [ ] Check compliance logs for patterns
- [ ] Review support email response times

### Quarterly Audit
- [ ] Re-review App Store Guidelines for changes
- [ ] Update Content Policy if needed
- [ ] Review YouTube ToS for API policy updates
- [ ] Conduct full compliance testing

### Annual Refresh
- [ ] Legal review of all policy documents
- [ ] Update EULA if material changes
- [ ] Refresh App Store reviewer documentation
- [ ] Team training on policy changes

---

## Troubleshooting

### Common Issues

**Issue: "Report Content" link doesn't open browser**
- **Cause:** NSWorkspace.shared.open() permission issue
- **Fix:** Verify entitlements include `com.apple.security.network.client`

**Issue: Blacklisted channels still appearing**
- **Cause:** Filter not applied to search results
- **Fix:** Ensure `ChannelBlacklistService.isChannelHidden()` called in all views

**Issue: Compliance logs not persisting**
- **Cause:** OSLog subsystem misconfigured
- **Fix:** Verify Logger.compliance uses correct subsystem: `com.mytoob.compliance`

**Issue: Diagnostics export fails**
- **Cause:** File permissions or missing data
- **Fix:** Check temp directory write permissions, verify all data sources available

---

## References

- [UGC Safeguards Framework](./ugc-safeguards-framework.md) - High-level compliance strategy
- [Parental Controls Specification](./parental-controls.md) - Future enhancement details
- [Policy Enforcement Framework](./policy-enforcement.md) - Compile-time and runtime enforcement
- [Epic 12: UGC Safeguards](../prd/epic-12-ugc-safeguards-compliance-features.md) - Full story breakdown
- [ChannelBlacklist Model](../../MyToob/Models/ChannelBlacklist.swift) - Existing implementation

---

**Document Control:**  
This implementation guide is the authoritative resource for developers working on Epic 12. Update as implementation progresses. Version history tracked in git.

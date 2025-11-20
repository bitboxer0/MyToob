# Policy Enforcement Framework

**Document Version:** 1.0  
**Last Updated:** 2025-11-18  
**Status:** Active

## Overview

This document defines MyToob's policy enforcement mechanisms to ensure compliance with App Store Guidelines, YouTube Terms of Service, and internal content standards. Policy enforcement operates at three levels: compile-time (linting), runtime (behavioral checks), and operational (monitoring and response).

## Enforcement Levels

### Level 1: Compile-Time Prevention (Linting)

**Goal:** Block policy violations before code is merged.

**Implementation:** SwiftLint custom rules + Danger CI checks

#### Custom SwiftLint Rules

**File:** `.swiftlint.yml`

```yaml
custom_rules:
  # Rule 1: Block direct YouTube stream access
  no_youtube_stream_access:
    name: "No YouTube Stream Access"
    regex: "googlevideo\\.com|ytimg\\.com/vi/[^/]+/maxres"
    message: "COMPLIANCE VIOLATION: Direct access to YouTube video streams prohibited. Use IFrame Player API only."
    severity: error
    
  # Rule 2: Block ad-blocking keywords
  no_ad_blocking:
    name: "No Ad Blocking"
    regex: "(?i)(remove.*ad|block.*ad|skip.*ad|hide.*ad|adblock|ublock)"
    message: "COMPLIANCE VIOLATION: Ad blocking/removal violates YouTube ToS. Do not implement ad manipulation."
    severity: error
    match_kinds:
      - comment
      - string
      - identifier
    
  # Rule 3: Block stream downloading keywords
  no_stream_download:
    name: "No Stream Download"
    regex: "(?i)(download.*stream|cache.*video|save.*video|yt-dlp|youtube-dl)"
    message: "COMPLIANCE VIOLATION: Downloading YouTube streams violates ToS. Metadata caching only."
    severity: error
    
  # Rule 4: Require IFrame Player for YouTube playback
  iframe_player_required:
    name: "IFrame Player Required"
    regex: "youtube\\.com/watch\\?v="
    message: "Use YouTube IFrame Player embed URL (youtube.com/embed/VIDEO_ID), not watch URL."
    severity: warning
    
  # Rule 5: Block hardcoded secrets
  no_hardcoded_secrets:
    name: "No Hardcoded Secrets"
    regex: "(?i)(api[_-]?key|client[_-]?secret|oauth[_-]?token)\\s*=\\s*[\"'][^\"']{20,}"
    message: "SECURITY VIOLATION: Do not hardcode API keys or secrets. Use environment variables."
    severity: error
    
  # Rule 6: Require privacy annotations for logging
  require_privacy_annotation:
    name: "Require Privacy Annotation"
    regex: "Logger.*\\.(info|debug|notice)\\("
    message: "Add privacy annotation to log statements: .public, .private, or .sensitive"
    severity: warning
    match_kinds:
      - string
```

**Enforcement:**
- SwiftLint runs on every build (Xcode build phase)
- CI pipeline fails if errors detected
- Warnings allowed but flagged in PR review

#### Danger CI Checks

**File:** `.github/workflows/danger.yml`

```ruby
# Dangerfile
# Check for policy-violating file changes

# Rule 1: Block changes to YouTube stream handling
if git.modified_files.include?("MyToob/Services/YouTubeService.swift")
  message "YouTube service modified. Ensure changes comply with ToS (no stream access)."
end

# Rule 2: Require tests for compliance-critical features
if git.modified_files.include?("MyToob/Features/Reporting/")
  if git.modified_files.grep(/Test/).empty?
    fail "Compliance-critical feature modified without tests. Add tests for Reporting features."
  end
end

# Rule 3: Flag large binary commits (potential model/asset violations)
if git.added_files.any? { |f| f.end_with?(".mlmodel", ".mlpackage") }
  message "Core ML model added. Verify model license and compliance before merge."
end

# Rule 4: Require documentation for new compliance features
if git.modified_files.include?("MyToob/Models/ChannelBlacklist.swift")
  if !git.modified_files.include?("docs/compliance/")
    warn "ChannelBlacklist modified. Update compliance documentation if behavior changed."
  end
end

# Rule 5: Block commits with secrets patterns
git.added_files.each do |file|
  if File.read(file).match?(/(api[_-]?key|client[_-]?secret).*=.*["'][^"']{20,}/i)
    fail "Potential secret detected in #{file}. Remove and use environment variables."
  end
end
```

**Enforcement:**
- Danger runs on every PR in GitHub Actions
- PR cannot merge if `fail` conditions triggered
- `warn` and `message` shown in PR comments

### Level 2: Runtime Behavioral Checks

**Goal:** Enforce policy compliance during app execution.

#### YouTube Playback Visibility Enforcement

**File:** `MyToob/Features/YouTube/YouTubePlayerView.swift`

```swift
import SwiftUI
import Combine

struct YouTubePlayerView: View {
    @StateObject private var visibilityMonitor = PlayerVisibilityMonitor()
    @State private var isPictureInPicture: Bool = false
    
    var body: some View {
        WKWebViewRepresentation(...)
            .onAppear {
                visibilityMonitor.startMonitoring()
            }
            .onDisappear {
                // COMPLIANCE: Pause playback when player not visible
                if !isPictureInPicture {
                    pauseVideo()
                    Logger.compliance.info("YouTube playback paused (player not visible)")
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background && !isPictureInPicture {
                    pauseVideo()
                    Logger.compliance.info("YouTube playback paused (app backgrounded)")
                }
            }
    }
}

class PlayerVisibilityMonitor: ObservableObject {
    private var windowObserver: NSKeyValueObservation?
    
    func startMonitoring() {
        // Monitor window visibility
        windowObserver = NSApp.keyWindow?.observe(\.isVisible) { window, _ in
            if !window.isVisible {
                // Player window hidden, pause playback
                NotificationCenter.default.post(name: .pauseYouTubePlayback, object: nil)
                Logger.compliance.info("YouTube playback paused (window hidden)")
            }
        }
    }
}
```

**Enforcement:**
- Automatic pause when app/window hidden
- Exception: PiP mode (player still visible)
- Logged for compliance audit

#### API Quota Budget Enforcement

**File:** `MyToob/Services/YouTube/QuotaBudget.swift`

```swift
actor QuotaBudget {
    private var dailyUsed: Int = 0
    private var lastResetDate: Date = Date()
    private let dailyLimit: Int = 10_000 // YouTube default quota
    
    enum QuotaCost {
        case searchList = 100
        case videosList = 1
        case channelsList = 1
        case playlistItemsList = 1
    }
    
    func canMakeRequest(cost: QuotaCost) -> Bool {
        resetIfNewDay()
        return (dailyUsed + cost.rawValue) <= dailyLimit
    }
    
    func recordRequest(cost: QuotaCost) {
        dailyUsed += cost.rawValue
        Logger.youtube.info("API quota used: \(dailyUsed)/\(dailyLimit)")
        
        // COMPLIANCE: Hard block at 90% quota to prevent accidental overage
        if Double(dailyUsed) / Double(dailyLimit) > 0.9 {
            Logger.compliance.warning("YouTube API quota at 90% (\(dailyUsed)/\(dailyLimit)). Blocking new requests.")
            NotificationCenter.default.post(name: .quotaLimitReached, object: nil)
        }
    }
    
    private func resetIfNewDay() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            dailyUsed = 0
            lastResetDate = Date()
            Logger.youtube.info("API quota reset for new day")
        }
    }
}
```

**Enforcement:**
- Pre-flight quota check before API calls
- Automatic blocking at 90% quota (safety buffer)
- User notification when quota exhausted

#### Cache Compliance Validation

**File:** `MyToob/Services/Storage/CacheManager.swift`

```swift
class CacheManager {
    enum CacheType {
        case metadata      // ✅ Allowed: JSON responses from YouTube API
        case thumbnails    // ✅ Allowed: Image files (respect HTTP cache headers)
        case embeddings    // ✅ Allowed: User-generated AI vectors
        case videoStream   // ❌ PROHIBITED: YouTube video/audio bytes
    }
    
    func cache(_ data: Data, for key: String, type: CacheType) throws {
        // COMPLIANCE: Block caching of video streams
        guard type != .videoStream else {
            Logger.compliance.fault("COMPLIANCE VIOLATION: Attempted to cache video stream data")
            throw CacheError.prohibitedCacheType("Video stream caching violates YouTube ToS")
        }
        
        // Validate cache type based on URL pattern
        if key.contains("googlevideo.com") || key.contains(".m3u8") {
            Logger.compliance.fault("COMPLIANCE VIOLATION: Attempted to cache stream URL: \(key, privacy: .public)")
            throw CacheError.prohibitedURL("Stream URL caching prohibited")
        }
        
        // Proceed with allowed cache types
        try performCache(data, key: key, type: type)
    }
}
```

**Enforcement:**
- Type-based cache validation
- URL pattern blocking (googlevideo.com)
- Runtime error prevents accidental violations

### Level 3: Operational Monitoring

**Goal:** Detect and respond to policy violations in production.

#### Compliance Audit Logging

**File:** `MyToob/Utilities/ComplianceLogger.swift`

```swift
import OSLog

extension Logger {
    static let compliance = Logger(subsystem: "com.mytoob.compliance", category: "audit")
}

enum ComplianceEvent: String {
    case userReportedVideo = "user_reported_video"
    case userHidChannel = "user_hid_channel"
    case quotaLimitReached = "quota_limit_reached"
    case cacheViolationBlocked = "cache_violation_blocked"
    case playbackPausedNotVisible = "playback_paused_not_visible"
    case eulaAccepted = "eula_accepted"
    case contentPolicyViewed = "content_policy_viewed"
    
    func log(metadata: [String: Any] = [:]) {
        var logMetadata: [String: String] = [
            "event": self.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Merge additional metadata (sanitized, no PII)
        for (key, value) in metadata {
            // PRIVACY: Redact video IDs, channel names, user input
            if key.contains("ID") || key.contains("channelID") {
                logMetadata[key] = value as? String ?? ""
            } else if key == "count" || key == "quota" {
                logMetadata[key] = "\(value)"
            }
        }
        
        Logger.compliance.info("\(logMetadata.description)")
    }
}
```

**Usage Example:**
```swift
// User reports video
ComplianceEvent.userReportedVideo.log(metadata: [
    "videoID": videoID,
    "reportedAt": Date()
])

// Quota limit reached
ComplianceEvent.quotaLimitReached.log(metadata: [
    "quota": dailyUsed,
    "limit": dailyLimit
])
```

**Log Retention:**
- Stored in system OSLog (90-day auto-rotation)
- Exportable via developer-only menu for App Store review
- No PII logged (no video titles, user names, watch history)

#### Crash Log Sanitization

**File:** `MyToob/Utilities/CrashReporter.swift`

```swift
class CrashReporter {
    static func sanitizeCrashLog(_ log: String) -> String {
        var sanitized = log
        
        // Remove API keys and tokens
        sanitized = sanitized.replacingOccurrences(
            of: "Bearer [A-Za-z0-9._-]+",
            with: "[REDACTED_TOKEN]",
            options: .regularExpression
        )
        
        // Remove video IDs (might contain user viewing patterns)
        sanitized = sanitized.replacingOccurrences(
            of: "videoID: [A-Za-z0-9_-]{11}",
            with: "videoID: [REDACTED]",
            options: .regularExpression
        )
        
        // Remove channel IDs
        sanitized = sanitized.replacingOccurrences(
            of: "channelID: UC[A-Za-z0-9_-]{22}",
            with: "channelID: [REDACTED]",
            options: .regularExpression
        )
        
        // Remove file paths (may contain usernames)
        sanitized = sanitized.replacingOccurrences(
            of: "/Users/[^/]+/",
            with: "/Users/[USER]/",
            options: .regularExpression
        )
        
        return sanitized
    }
}
```

**Enforcement:**
- All crash logs sanitized before export
- User consent required for diagnostics sharing
- Sanitized logs attached to support emails

#### User Behavior Monitoring (Anonymized)

**File:** `MyToob/Utilities/TelemetryService.swift`

```swift
actor TelemetryService {
    // PRIVACY: All metrics aggregated on-device, no user-level tracking
    
    struct AggregatedMetrics: Codable {
        var totalVideosImported: Int = 0
        var totalChannelsHidden: Int = 0
        var totalReportsSubmitted: Int = 0
        var totalSearchesPerformed: Int = 0
        var averageSessionDuration: TimeInterval = 0
        var featureUsageCounts: [String: Int] = [:]
        
        // COMPLIANCE: No video IDs, channel names, or search queries
    }
    
    private var metrics = AggregatedMetrics()
    
    func recordEvent(_ event: String) {
        metrics.featureUsageCounts[event, default: 0] += 1
        
        // Save to UserDefaults (local only, never uploaded)
        try? UserDefaults.standard.set(
            JSONEncoder().encode(metrics),
            forKey: "aggregated_metrics"
        )
    }
    
    func exportForDiagnostics() -> String {
        // User-initiated export only (Settings > Send Diagnostics)
        """
        MyToob Anonymized Usage Metrics
        
        Videos Imported: \(metrics.totalVideosImported)
        Channels Hidden: \(metrics.totalChannelsHidden)
        Reports Submitted: \(metrics.totalReportsSubmitted)
        Searches Performed: \(metrics.totalSearchesPerformed)
        
        Feature Usage:
        \(metrics.featureUsageCounts.map { "  \($0.key): \($0.value)" }.joined(separator: "\n"))
        
        Note: All metrics are aggregated and anonymized. No individual viewing history or search queries are recorded.
        """
    }
}
```

**Privacy Guarantee:**
- No user-level data collected
- No data sent to external servers
- Export only via user-initiated diagnostics bundle

## Policy Violation Response

### Automated Response

**Violation Detected at Compile-Time:**
1. SwiftLint error prevents build
2. Developer must fix code before merge
3. CI pipeline blocks PR merge

**Violation Detected at Runtime:**
1. Log compliance fault to OSLog
2. Throw error preventing prohibited action
3. Display user-friendly error message
4. Fallback to safe behavior (e.g., use cached data if quota exceeded)

**Violation Detected in Production:**
1. Crash log sanitized and reported
2. If widespread issue, push hotfix update
3. Notify App Store review team if ToS-violating bug discovered

### Manual Response (User Reports)

**User Reports Policy Violation in App:**
1. Support email receives report: support@mytoob.app
2. Acknowledge within 24 hours (auto-responder + manual follow-up)
3. Investigate claim:
   - Review crash logs, compliance logs
   - Reproduce issue if possible
4. Respond with resolution:
   - If valid violation: Fix in next update, notify user of timeline
   - If user misunderstanding: Clarify policy, provide documentation
   - If YouTube content issue: Direct user to YouTube reporting

**App Store Reviewer Flags Violation:**
1. Immediate review by engineering + legal teams
2. Determine if violation is:
   - Code bug (fix and resubmit)
   - Policy misunderstanding (provide documentation)
   - Intentional behavior (revise feature or remove)
3. Respond to reviewer within 48 hours with resolution plan

## Continuous Compliance Monitoring

### Weekly Automated Checks

**Script:** `.github/workflows/compliance-scan.yml`

```yaml
name: Compliance Scan
on:
  schedule:
    - cron: '0 0 * * 0' # Every Sunday at midnight
  workflow_dispatch: # Manual trigger

jobs:
  scan:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run SwiftLint compliance rules
        run: swiftlint lint --strict --config .swiftlint.yml
      
      - name: Scan for hardcoded secrets
        run: |
          # Use gitleaks or similar tool
          gitleaks detect --no-git --verbose
      
      - name: Verify no YouTube stream URLs in codebase
        run: |
          if grep -r "googlevideo\.com" MyToob/; then
            echo "ERROR: YouTube stream URL detected in codebase"
            exit 1
          fi
      
      - name: Check for ad-blocking keywords
        run: |
          if grep -ri "adblock\|ublock\|skip.*ad" MyToob/; then
            echo "ERROR: Ad-blocking keywords detected"
            exit 1
          fi
      
      - name: Notify team if violations found
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Compliance Scan Failed',
              body: 'Automated compliance scan detected policy violations. Review logs and fix immediately.',
              labels: ['compliance', 'urgent']
            })
```

**Enforcement:**
- Automated weekly scan for policy violations
- GitHub issue created if violations detected
- Team notified via Slack/email integration

### Quarterly Manual Audit

**Checklist:**
1. Review compliance audit logs for patterns
2. Verify ChannelBlacklist functionality still works
3. Test YouTube reporting flow (URL still valid)
4. Check Content Policy page still accessible
5. Confirm EULA still displayed on first launch
6. Review App Store Guidelines for policy changes
7. Review YouTube ToS for API policy updates
8. Update documentation if policies changed

**Responsible Team:** Product, Legal, Engineering leads  
**Schedule:** Q1, Q2, Q3, Q4 (January, April, July, October)

## Policy Documentation Maintenance

### Version Control

**All policy documents tracked in git:**
- `docs/compliance/ugc-safeguards-framework.md`
- `docs/compliance/parental-controls.md`
- `docs/compliance/policy-enforcement.md` (this document)

**Change Management:**
1. Propose policy change via PR
2. Review by Product + Legal + Engineering
3. Approval required from all three teams
4. Update version number and Last Updated date
5. Notify team of changes via Slack announcement

### External Policy References

**Tracked in git for version comparison:**
- `docs/external-policies/youtube-tos-snapshot.md` (snapshot of YouTube ToS)
- `docs/external-policies/app-store-guidelines-snapshot.md` (snapshot of Section 1.2)

**Update Frequency:** Quarterly (or immediately if major policy change announced)

**Diff Tool:** Use `git diff` to compare snapshots and identify changes

## Training & Awareness

### Developer Onboarding

**New Developer Checklist:**
- [ ] Read `docs/compliance/ugc-safeguards-framework.md`
- [ ] Review SwiftLint custom rules (`.swiftlint.yml`)
- [ ] Understand YouTube ToS compliance requirements
- [ ] Practice running compliance scan locally
- [ ] Quiz: Identify policy violations in sample code

### Team Training Sessions

**Frequency:** Quarterly (aligned with compliance audit)  
**Topics:**
- Recent policy changes (App Store, YouTube)
- Case studies: Policy violations in other apps
- Q&A: Clarify edge cases and ambiguities

## Incident Response Plan

### Severity Levels

**Critical (P0):** ToS violation affecting all users in production
- Example: Bug causes YouTube streams to be cached
- Response: Hotfix within 24 hours, notify App Store review team

**High (P1):** Compliance feature broken in production
- Example: "Report Content" link broken (404 error)
- Response: Fix in next patch release (within 1 week)

**Medium (P2):** Policy documentation outdated
- Example: Content Policy page references old YouTube URL
- Response: Update documentation within 2 weeks

**Low (P3):** Minor compliance issue not affecting users
- Example: Compliance log missing event type
- Response: Fix in next regular release cycle

### Escalation Path

1. **Developer** discovers issue → Report to **Tech Lead**
2. **Tech Lead** assesses severity → Escalate to **Product Manager** if P0/P1
3. **Product Manager** involves **Legal** if ToS violation
4. **Legal** approves response plan → **Engineering** implements fix
5. **Product Manager** communicates with **App Store Review** if needed

## References

### Internal Documentation
- [UGC Safeguards Framework](./ugc-safeguards-framework.md)
- [Parental Controls Specification](./parental-controls.md)
- [Epic 12: UGC Safeguards](../prd/epic-12-ugc-safeguards-compliance-features.md)

### External Policies
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [YouTube Terms of Service](https://www.youtube.com/t/terms)
- [YouTube Developer Policies](https://developers.google.com/youtube/terms/developer-policies)

### Tools & Automation
- [SwiftLint Documentation](https://github.com/realm/SwiftLint)
- [Danger Documentation](https://danger.systems/ruby/)
- [Gitleaks (Secret Scanning)](https://github.com/gitleaks/gitleaks)

---

**Document Control:**  
This document defines active policy enforcement mechanisms. Changes require approval from Engineering, Product, and Legal teams. Version history tracked in git.

# UGC Safeguards & Compliance Framework

**Document Version:** 1.0  
**Last Updated:** 2025-11-18  
**Owner:** Compliance & Security Team  
**Status:** Active

## Executive Summary

This document defines MyToob's User-Generated Content (UGC) safeguards framework to ensure compliance with Apple App Store Guideline 1.2 (Safety - User Generated Content) and YouTube Terms of Service. MyToob handles two categories of content:

1. **YouTube Content** (third-party UGC): Videos accessed via YouTube IFrame Player and Data API
2. **User-Created Content** (local files): Personal video files imported by users

Our compliance strategy delegates moderation of YouTube content to YouTube's official reporting mechanisms while providing robust user controls for content filtering. For local files, users maintain full responsibility as they control file selection.

## Regulatory Requirements

### Apple App Store Guideline 1.2 - UGC Requirements

Apps that host or display user-generated content must implement:

1. ✅ **Content Filtering** - Method to filter objectionable material
2. ✅ **Reporting Mechanism** - User-accessible method to flag/report objectionable content
3. ✅ **User Blocking** - Ability to block abusive users or content sources
4. ✅ **Timely Response** - Commitment to respond to reports within 24 hours
5. ✅ **Custom EULA** - Terms prohibiting objectionable content and abusive behavior
6. ✅ **Content Policy** - Clear, accessible content standards document

### YouTube Terms of Service Compliance

- Use YouTube IFrame Player API exclusively for playback (no stream extraction)
- Delegate all content moderation to YouTube's official reporting flow
- Do not modify or obscure YouTube player UI, ads, or branding
- Display "Not affiliated with YouTube" disclaimer
- Include proper YouTube branding attribution

## Architecture: Two-Tier Content Model

### Tier 1: YouTube Content (Third-Party UGC)

**Moderation Delegation Strategy:**
- MyToob acts as a **viewer/organizer** of YouTube content, not a host
- All YouTube content moderation delegated to YouTube's Community Guidelines enforcement
- Users report violations directly to YouTube via official reporting flow
- MyToob provides user-controlled filtering via ChannelBlacklist feature

**Compliance Rationale:**
- YouTube content remains hosted on YouTube's servers (not MyToob's)
- YouTube maintains all responsibility for content moderation
- MyToob merely provides an alternative viewing interface (like web browser)
- User controls (hide/blacklist channels) supplement YouTube's moderation

### Tier 2: Local Files (User-Owned Content)

**User Responsibility Model:**
- Users select and import their own local video files via macOS file picker
- Users maintain full control and responsibility for local file content
- No third-party content hosting or sharing features
- Local files never uploaded or shared via MyToob infrastructure

**Compliance Rationale:**
- Equivalent to macOS Finder or QuickTime Player (file viewer role)
- No UGC moderation required for user's own files
- Users cannot share local files with other MyToob users (no network distribution)

## UGC Safeguard Features

### 1. Content Filtering (ChannelBlacklist)

**Feature:** `ChannelBlacklist` SwiftData model  
**Location:** `MyToob/Models/ChannelBlacklist.swift`

**Functionality:**
- Users can hide/block specific YouTube channels from appearing in their library
- Filtered channels removed from:
  - Main video library view
  - Search results
  - AI clustering and recommendations
  - Subscription feeds

**User Flow:**
1. Right-click YouTube video → "Hide Channel"
2. Confirmation dialog: "Hide all videos from [Channel Name]?"
3. Channel added to blacklist with reason ("User hidden") and timestamp
4. All videos from channel immediately hidden across app
5. Reversible via Settings > Hidden Channels > "Unhide"

**Technical Implementation:**
```swift
@Model
final class ChannelBlacklist {
    @Attribute(.unique) var channelID: String
    var reason: String?  // "User hidden", "Inappropriate content", etc.
    var blockedAt: Date
    var channelName: String?  // Cached for UI display
    var requiresConfirmation: Bool
    
    func shouldFilter(_ videoItem: VideoItem) -> Bool {
        guard let itemChannelID = videoItem.channelID else { return false }
        return itemChannelID == self.channelID
    }
}
```

**CloudKit Sync:** Blacklist syncs across user's devices if CloudKit sync enabled

### 2. Reporting Mechanism

**Feature:** "Report Content" action for YouTube videos  
**Location:** Video context menu (right-click)

**User Flow:**
1. Right-click YouTube video → "Report Content"
2. Dialog: "Report this video for violating YouTube's Community Guidelines?"
3. "Report on YouTube" button (primary action)
4. Opens YouTube's official reporting page in default browser: `https://www.youtube.com/watch?v={videoID}&report=1`

**Compliance Notes:**
- Direct deep-link to YouTube's reporting flow (not custom in-app form)
- Leverages YouTube's existing Community Guidelines enforcement
- Reports handled by YouTube's moderation team (24-hour response commitment)
- MyToob logs report action for audit trail (no user PII logged)

**Audit Logging:**
```swift
Logger.compliance.info("User reported video", metadata: [
    "videoID": videoID,
    "timestamp": ISO8601DateFormatter().string(from: Date()),
    "action": "report_youtube_content"
])
```

### 3. User Blocking (Channel-Level)

**Feature:** Channel hide/blacklist (see Content Filtering above)

**Extended Capabilities:**
- **Granular Control:** Hide individual channels vs. bulk hide
- **Temporary vs. Permanent:** Users can unhide channels at any time
- **Reason Tracking:** Optional user-provided reason for hiding (helps users remember context)
- **Confirmation Required:** First-time hide requires confirmation to prevent accidental blocks

**Settings UI:**
- Settings > Content & Privacy > Hidden Channels
- List shows: Channel name, hide date, reason (if provided), "Unhide" button
- Bulk unhide: "Unhide All" button (confirmation required)

### 4. Timely Response Commitment

**Support Email:** support@mytoob.app (to be configured)  
**Response Time SLA:** 24 hours for content reports, 48 hours for general inquiries

**Response Process:**
1. User sends report/inquiry via in-app "Send Diagnostics" or support email
2. Support team acknowledges receipt within 24 hours
3. YouTube-related content reports: Direct user to YouTube's reporting flow + explain delegation model
4. App-specific issues: Investigate and respond with resolution or next steps

**Escalation Path:**
- Critical safety issues: Immediate review (<4 hours)
- Repeated abuse reports for same channel: Consider adding to default blacklist (with user consent)
- App Store reviewer inquiries: Priority response within 12 hours

### 5. Custom EULA (End User License Agreement)

**Location:** Displayed during first app launch, accessible via Settings > Legal  
**Key Provisions:**

```
USER-GENERATED CONTENT POLICY

1. YouTube Content
   - You access YouTube content via YouTube's official IFrame Player
   - YouTube's Community Guidelines apply to all YouTube content
   - Report violations directly to YouTube via in-app reporting tool
   - MyToob is not responsible for YouTube content; YouTube moderates per their policies

2. Local Files
   - You are solely responsible for local video files you import
   - Do not import files containing illegal, abusive, or objectionable content
   - Local files are not shared with other users or uploaded to MyToob servers
   - MyToob acts solely as a file viewer for your personal library

3. Prohibited Content (Local Files)
   You agree not to import local files containing:
   - Illegal content (child exploitation, violence, hate speech, etc.)
   - Content violating intellectual property rights
   - Malware or harmful code embedded in video files

4. Content Filtering & Moderation
   - You can hide YouTube channels you find objectionable
   - Report YouTube content via YouTube's official reporting mechanism
   - MyToob reserves the right to disable accounts violating these terms

5. User Responsibilities
   - Comply with YouTube Terms of Service when accessing YouTube content
   - Respect copyright and intellectual property rights
   - Do not attempt to download, extract, or redistribute YouTube content

By using MyToob, you agree to these terms and acknowledge YouTube's Community Guidelines.
```

**Acceptance Flow:**
- First launch: Full-screen EULA with "I Agree" / "Decline" buttons
- Declining EULA prevents app usage (exits app)
- Acceptance logged with timestamp (stored in UserDefaults, not sent to server)

### 6. Content Policy Page

**Location:** Settings > About > Content Policy  
**URL:** `https://mytoob.app/content-policy` (static site, publicly accessible)

**Policy Document Structure:**

```markdown
# MyToob Content Policy

## Our Approach to Content

MyToob organizes and discovers video content from two sources:

1. **YouTube Content**: Accessed via YouTube's official APIs and player
2. **Your Local Files**: Personal video files you import from your Mac

We do not host third-party content. We provide tools to organize content from external sources.

## YouTube Content Standards

All YouTube content is subject to YouTube's Community Guidelines:
- Violent or graphic content
- Hate speech and harassment
- Spam, misleading metadata, and scams
- etc. (link to full guidelines)

**How to Report YouTube Content:**
Right-click any YouTube video → "Report Content" → Opens YouTube's official reporting page

**How to Hide Unwanted Channels:**
Right-click video → "Hide Channel" → All videos from that channel hidden from your library

## Local File Responsibilities

You are responsible for ensuring your local video files:
- Comply with applicable laws (copyright, decency, etc.)
- Do not contain illegal or harmful content
- Respect intellectual property rights

MyToob does not monitor, filter, or moderate your local files.

## What We Do

✅ Provide tools to hide YouTube channels you find objectionable
✅ Offer direct reporting link to YouTube's moderation team
✅ Log compliance actions for App Store review (no personal data)
✅ Respond to user reports within 24 hours

## What We Don't Do

❌ Host or moderate YouTube content (YouTube's responsibility)
❌ Upload or share your local files (they stay on your Mac)
❌ Collect or analyze your viewing habits (on-device AI only)

## Contact & Support

Questions about this policy: support@mytoob.app
Report issues: Settings > Support > Send Diagnostics
```

## Compliance Audit Logging

### Events Logged

**Logged Events:**
1. User reported YouTube video (videoID, timestamp)
2. User hid channel (channelID, timestamp, reason)
3. User accessed Content Policy page (timestamp)
4. User contacted support (timestamp, via diagnostics export)
5. User accepted EULA (timestamp)

**Not Logged (Privacy):**
- Video titles, descriptions, or content
- User viewing history or watch patterns
- Channel names (only channelID stored)

### Log Storage & Security

**Location:** System OSLog with subsystem `com.mytoob.compliance`  
**Retention:** 90 days, auto-deleted thereafter  
**Access:** Developer-only export for App Store review submission  
**Format:** JSON for machine-readability

**Example Log Entry:**
```json
{
  "timestamp": "2024-01-15T14:32:18Z",
  "event": "channel_hidden",
  "channelID": "UCxyz123abc",
  "reason": "user_initiated",
  "metadata": {
    "hideCount": 1,
    "confirmationShown": true
  }
}
```

### Compliance Reporting

**App Store Reviewer Access:**
- "Export Compliance Logs" hidden developer menu (⌘⌥⇧C)
- Exports last 90 days of compliance events as JSON
- Sanitized (no PII, no video content)
- Includes summary statistics: total reports, total hides, average response time

## Integration with ChannelBlacklist Model

### Model Reference

**File:** `MyToob/Models/ChannelBlacklist.swift`

**Key Methods:**
```swift
// Check if video should be filtered
func shouldFilter(_ videoItem: VideoItem) -> Bool

// Filter query to exclude blacklisted channels
static func applyBlacklist(to query: FetchDescriptor<VideoItem>) -> FetchDescriptor<VideoItem>
```

### Integration Points

**1. Video Library View:**
```swift
// Apply blacklist filter to all video queries
@Query(filter: ChannelBlacklist.excludeBlacklisted())
var videos: [VideoItem]
```

**2. Search Results:**
```swift
// Post-filter search results to remove blacklisted channels
searchResults.filter { video in
    !ChannelBlacklist.isBlacklisted(video.channelID)
}
```

**3. AI Clustering:**
```swift
// Exclude blacklisted videos from embedding generation and clustering
let eligibleVideos = allVideos.filter { !ChannelBlacklist.isBlacklisted($0.channelID) }
```

**4. Recommendations:**
```swift
// Ensure recommended videos exclude blacklisted channels
recommendations.filter { !ChannelBlacklist.isBlacklisted($0.channelID) }
```

## App Store Reviewer Notes

### Addressing Guideline 1.2

**Compliance Checklist:**

✅ **Content Filtering:** ChannelBlacklist feature allows users to hide objectionable channels  
✅ **Reporting Mechanism:** "Report Content" action deep-links to YouTube's official reporting  
✅ **User Blocking:** Channel-level blocking via ChannelBlacklist  
✅ **Timely Response:** 24-hour support response commitment documented  
✅ **Custom EULA:** First-launch EULA includes UGC policy and YouTube Terms acceptance  
✅ **Content Policy:** Publicly accessible policy page at mytoob.app/content-policy

**Key Points for Reviewers:**

1. **Delegation Model:** MyToob does not host YouTube content. All YouTube content moderation is handled by YouTube's existing systems. Users report violations directly to YouTube.

2. **User Controls:** ChannelBlacklist provides granular user control over visible content, exceeding minimum filtering requirements.

3. **Scope Limitation:** MyToob accesses YouTube content via official IFrame Player (read-only, view-only). No uploading, commenting, or sharing features that would require in-app moderation.

4. **Local Files:** Equivalent to macOS file viewer (Finder, QuickTime). Users select their own files; no third-party content.

5. **Audit Trail:** Compliance logging demonstrates responsible operation and response to user reports.

## Implementation Roadmap

### Story 12.5 Tasks

**Phase 1: Core Features (Week 1)**
- [x] ChannelBlacklist model implemented (existing)
- [ ] "Report Content" action in video context menu
- [ ] "Hide Channel" action in video context menu
- [ ] YouTube reporting URL deep-link handler

**Phase 2: UI & Settings (Week 1-2)**
- [ ] Settings > Hidden Channels management UI
- [ ] Settings > Content Policy link
- [ ] Settings > Support contact information
- [ ] First-launch EULA screen with acceptance flow

**Phase 3: Compliance Infrastructure (Week 2)**
- [ ] Compliance audit logging system (OSLog subsystem)
- [ ] Developer-only compliance log export
- [ ] Support email setup (support@mytoob.app)
- [ ] Content Policy page deployment (static site)

**Phase 4: Testing & Documentation (Week 2-3)**
- [ ] UI tests for report/hide flows
- [ ] Blacklist filter integration tests
- [ ] App Store reviewer documentation package
- [ ] User-facing help documentation

### Testing Requirements

**UI Tests:**
1. Report Content flow opens correct YouTube URL
2. Hide Channel adds to ChannelBlacklist and filters video
3. Unhide Channel removes from blacklist and restores visibility
4. EULA acceptance required before app usage
5. Content Policy accessible from Settings

**Integration Tests:**
1. Blacklisted channels excluded from library views
2. Blacklisted channels excluded from search results
3. Blacklisted channels excluded from AI clustering
4. CloudKit sync propagates blacklist across devices

**Compliance Tests:**
1. Compliance events logged to OSLog
2. Log export includes all required metadata
3. Log retention enforced (90-day auto-delete)
4. No PII or video content in logs

## Risk Assessment & Mitigations

### Risk: Reviewer Questions YouTube Content Moderation

**Mitigation:**
- Clearly document delegation model in reviewer notes
- Provide example of YouTube's reporting flow (screenshots)
- Emphasize MyToob's role as viewer, not host
- Reference precedent: Safari, Chrome, other browsers show YouTube content without moderation requirements

### Risk: User Reports Go Unanswered

**Mitigation:**
- Set up support email with auto-responder (acknowledges within 1 hour)
- Escalation process for critical reports
- Track response time metrics in support system
- Document SLA in App Store description and Content Policy

### Risk: Blacklist Circumvention

**Mitigation:**
- Blacklist applied at data layer (not just UI filter)
- CloudKit sync ensures consistency across devices
- No API or URL scheme to bypass blacklist
- Audit logs track blacklist modifications

### Risk: Local File Illegal Content

**Mitigation:**
- EULA explicitly prohibits illegal content in local files
- Emphasize user responsibility in Content Policy
- No upload/sharing features (content stays local)
- Equivalent to other file viewers (Finder, QuickTime) - not liable for user file content

## Maintenance & Review

### Periodic Review Schedule

**Quarterly (Every 3 months):**
- Review compliance audit logs for patterns
- Update Content Policy based on user feedback
- Test report/hide flows still functional (YouTube URLs, UI)
- Verify support response time SLA met

**Annually:**
- Re-review App Store Guidelines for changes
- Update EULA if policy changes
- Review YouTube ToS for API policy updates
- Conduct full compliance audit

### Change Management

**Policy Changes:**
1. Draft updated policy document
2. Legal review (if significant changes)
3. Update EULA version number
4. Notify existing users via in-app banner (for material changes)
5. Require re-acceptance for major changes

**Feature Changes:**
1. Document impact on compliance (this document)
2. Update reviewer notes if affecting UGC handling
3. Re-test compliance flows if UI changes
4. Update audit logging if new events introduced

## References

### Apple Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) - Section 1.2
- [App Store Review Guidelines - Safety](https://developer.apple.com/app-store/review/guidelines/#safety)

### YouTube Documentation
- [YouTube Terms of Service](https://www.youtube.com/t/terms)
- [YouTube Community Guidelines](https://www.youtube.com/howyoutubeworks/policies/community-guidelines/)
- [YouTube API Services Terms](https://developers.google.com/youtube/terms/api-services-terms-of-service)
- [YouTube Developer Policies](https://developers.google.com/youtube/terms/developer-policies)

### Internal Documentation
- [Epic 12: UGC Safeguards & Compliance Features](../prd/epic-12-ugc-safeguards-compliance-features.md)
- [Security and Performance Requirements](../architecture/security-and-performance.md)
- [ChannelBlacklist Model Implementation](../../MyToob/Models/ChannelBlacklist.swift)

---

**Document Control:**  
This document is the authoritative source for MyToob's UGC compliance framework. Changes require approval from Product, Legal, and Engineering teams. Version history tracked in git.

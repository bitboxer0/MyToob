# Epic 12: UGC Safeguards & Compliance Features

**Goal:** Implement user-generated content (UGC) moderation tools and compliance features required for App Store approval: content reporting (deep-link to YouTube), channel blocking, content policy page, and support contact. This epic ensures the app meets Apple's Guideline 1.2 (UGC) requirements and demonstrates responsible platform behavior.

## Story 12.1: Report Content Action

As a **user**,
I want **to report inappropriate YouTube content**,
so that **YouTube can review and take action according to their policies**.

**Acceptance Criteria:**
1. "Report Content" action in video context menu (right-click on YouTube video)
2. Clicking action shows dialog: "Report this video for violating YouTube's Community Guidelines?"
3. Dialog includes "Report on YouTube" button (primary) and "Cancel" button
4. "Report on YouTube" opens YouTube's reporting page in default web browser: `https://www.youtube.com/watch?v={videoID}&report=1`
5. Action only available for YouTube videos (hidden for local files)
6. "Report" action logged for compliance audit: "User reported video {videoID} at {timestamp}"
7. UI test verifies report action opens correct URL

## Story 12.2: Hide & Blacklist Channels

As a **user**,
I want **to hide content from specific YouTube channels**,
so that **I can avoid creators whose content I find inappropriate or unwanted**.

**Acceptance Criteria:**
1. "Hide Channel" action in video context menu for YouTube videos
2. Clicking action shows confirmation: "Hide all videos from [Channel Name]? You can unhide channels in Settings."
3. Channel added to `ChannelBlacklist` model with `channelID`, `reason = "User hidden"`, `blockedAt`
4. All videos from blacklisted channel hidden from library and search results
5. "Hidden Channels" list in Settings shows all blacklisted channels
6. "Unhide" button in Settings removes channel from blacklist (videos reappear)
7. Blacklist syncs via CloudKit (if sync enabled) so channel is hidden across devices

## Story 12.3: Content Policy Page

As a **user**,
I want **to view the app's content policy**,
so that **I understand what content is acceptable and how to report violations**.

**Acceptance Criteria:**
1. "Content Policy" link in Settings > About section
2. Clicking link opens policy page (in-app web view or external browser)
3. Policy page includes:
   - Clear explanation of content standards (links to YouTube's Community Guidelines for YouTube content)
   - How to report violations (Report Content action)
   - How to hide unwanted content (Hide Channel action)
   - Statement that user is responsible for local file content
   - Contact information for policy questions
4. Policy page accessible without authentication (public page)
5. Policy page URL: `https://yourwebsite.com/mytoob/content-policy` (hosted on static site)
6. Policy page language clear, non-technical, user-friendly

## Story 12.4: Support & Contact Information

As a **user**,
I want **easily accessible support contact information**,
so that **I can report issues or ask questions**.

**Acceptance Criteria:**
1. "Support" or "Contact" link in Settings > About section
2. Contact options provided: email (support@yourapp.com), support page URL, GitHub issues (for open-source projects)
3. "Send Diagnostics" button creates sanitized log archive and opens email client with pre-filled support request
4. Support email response time commitment stated (e.g., "We aim to respond within 48 hours")
5. FAQ or Help Center link provided (if available)
6. Support information shown in App Store listing (consistent with in-app info)
7. UI test verifies support links are accessible from Settings

## Story 12.5: YouTube Disclaimers & Attributions

As a **user**,
I want **clear disclaimers that this app is not affiliated with YouTube**,
so that **I understand the relationship between the app and YouTube**.

**Acceptance Criteria:**
1. "Not affiliated with YouTube" disclaimer shown in About screen (Settings > About)
2. YouTube branding attribution: "Powered by YouTube" badge shown near IFrame Player (per YouTube Branding Guidelines)
3. YouTube logo displayed in sidebar "YouTube" section (using official logo, not modified)
4. App name "MyToob" avoids using "YouTube" trademark
5. App icon custom-designed, does not resemble YouTube logo
6. Terms of Service link includes statement: "This app uses YouTube services via official APIs and is subject to YouTube's Terms of Service"
7. Reviewer Notes document includes section explaining compliance with YouTube branding guidelines

## Story 12.6: Compliance Audit Logging

As a **developer**,
I want **audit logs for compliance-related actions (reports, channel hides)**,
so that **I can demonstrate responsible platform operation if questioned by reviewers**.

**Acceptance Criteria:**
1. Compliance events logged using OSLog with dedicated subsystem: `com.mytoob.compliance`
2. Events logged: "User reported video {videoID}", "User hid channel {channelID}", "User accessed Content Policy", "User contacted support"
3. Logs include: timestamp, user action, video/channel ID, no PII (no video titles, usernames)
4. Logs stored securely, not accessible to users (only via diagnostics export with user consent)
5. Log retention: 90 days, then auto-deleted
6. "Export Compliance Logs" action (hidden, developer-only) for App Store review submission
7. Logs formatted as JSON for machine-readability

---

# YouTube Branding Compliance

**Document Version:** 1.0  
**Last Updated:** 2025-12-01  
**Story:** 12.5 - YouTube Disclaimers and Attributions  
**Status:** Active

## Overview

This document outlines MyToob's compliance with YouTube's branding guidelines and API terms of service. These measures ensure the app adheres to YouTube's requirements for third-party applications using their APIs and embedding their content.

## Compliance Checklist

### 1. App Name & Identity
- [x] App name "MyToob" avoids trademarked terms ("YouTube", "Tube", etc.)
- [x] App icon is custom designed and does not resemble YouTube's play button
- [x] No use of YouTube's color scheme as primary branding

### 2. Attribution & Disclaimers

#### Settings > About Screen
Location: `MyToob/Features/Settings/AboutView.swift`

The About screen includes:
- **Not Affiliated Disclaimer:** "Not affiliated with or endorsed by YouTube or Google."
- **ToS Statement:** "This app uses YouTube services via official APIs and is subject to YouTube's Terms of Service."
- **ToS Link:** Direct link to https://www.youtube.com/t/terms

Accessibility Identifiers:
- `AboutNotAffiliatedText`
- `AboutYouTubeToSText`
- `AboutToSLink`

#### Sidebar YouTube Section
Location: `MyToob/ContentView.swift`

- YouTube logo displayed in section header (official asset or SF Symbol fallback)
- Accessibility identifier: `YouTubeSidebarLogo`

### 3. IFrame Player Compliance

Location: `MyToob/Resources/HTML/youtube-player.html`

Player configuration adheres to YouTube requirements:
```javascript
playerVars: {
  'controls': 1,        // Required: Show player controls
  'modestbranding': 1,  // Minimal YouTube branding
  'rel': 0,             // Don't show unrelated videos
  'fs': 1,              // Allow fullscreen
  'enablejsapi': 1      // Enable JavaScript API
}
```

Key compliance points:
- No ad-blocking or ad-skipping
- No DOM manipulation of player UI
- No overlay that obscures YouTube branding
- Picture-in-Picture via official API only

### 4. Official Assets

Location: `MyToob/Assets.xcassets/YouTube/`

Assets folder prepared for official YouTube logo images:
- `Logo.imageset/` - Primary YouTube logo for sidebar and attribution
- Images should be obtained from YouTube's official branding resources

**Important:** Actual logo files must be downloaded from YouTube's official branding guidelines at https://www.youtube.com/howyoutubeworks/resources/brand-resources/

### 5. Content Reporting

Users can report content directly to YouTube:
- Right-click context menu "Report Content" action
- Opens YouTube's native reporting interface
- Logged via ComplianceLogger for audit trail

## Reviewer Notes (App Store Submission)

For App Store review, please note:

1. **YouTube Integration:** This app uses the official YouTube IFrame Player API and YouTube Data API v3 for all YouTube content access. No content is downloaded or cached locally.

2. **API Compliance:** The app operates within YouTube's API quota limits (10,000 units/day default) and implements exponential backoff for rate limiting.

3. **User-Generated Content:** The app provides mechanisms for users to report inappropriate content (redirects to YouTube's reporting interface) and hide channels they don't wish to see.

4. **Privacy:** All AI/ML processing for recommendations occurs on-device. No user viewing data is transmitted to external servers.

5. **Branding:** The app name "MyToob" and all branding elements are original creations and do not infringe on YouTube's trademarks.

## Testing

UI tests verifying compliance are located in:
`MyToobUITests/DisclaimersUITests.swift`

Tests cover:
- `testDisclaimerInAboutScreen` - Verifies disclaimer text presence
- `testYouTubeLogoInSidebar` - Verifies logo/icon in sidebar
- `testAppNameAvoidsTrademark` - Verifies app name compliance
- `testAppIconUnique` - Verifies icon is not YouTube-like

## References

- [YouTube Branding Guidelines](https://www.youtube.com/howyoutubeworks/resources/brand-resources/)
- [YouTube API Terms of Service](https://developers.google.com/youtube/terms/api-services-terms-of-service)
- [YouTube Developer Policies](https://developers.google.com/youtube/terms/developer-policies)
- [App Store Review Guidelines - Section 5.2.3](https://developer.apple.com/app-store/review/guidelines/#user-generated-content)

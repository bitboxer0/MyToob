# Parental Controls & Content Restrictions

**Document Version:** 1.0  
**Last Updated:** 2025-11-18  
**Status:** Specification (Not Yet Implemented)

## Overview

While MyToob is primarily designed for adult knowledge workers and researchers, we recognize that families may use the app on shared Mac computers. This document outlines parental control considerations and integration with macOS Screen Time restrictions.

## macOS Screen Time Integration

### Native macOS Restrictions (Recommended Approach)

**Strategy:** Leverage macOS Screen Time instead of building custom parental controls.

**Rationale:**
1. macOS Screen Time provides robust content filtering at OS level
2. Consistent with system-wide parental controls (Safari, App Store, etc.)
3. No need to duplicate existing platform functionality
4. Parents already familiar with Screen Time interface
5. Enforced even if child tries to bypass in-app restrictions

### macOS Screen Time Features Applicable to MyToob

**1. App Limits:**
- Parents can set daily time limits for MyToob app usage
- Enforced by macOS, cannot be bypassed by app

**2. Content & Privacy Restrictions:**
- Restrict access to web content (affects YouTube IFrame Player)
- Block explicit content via Safari restrictions (inherited by WKWebView)

**3. Downtime:**
- Schedule times when MyToob cannot be used
- Integrates with system-wide downtime settings

**4. Communication Limits:**
- Not directly applicable (MyToob has no messaging/social features)

### MyToob's Responsibility

**What We Do:**
- ✅ Respect macOS Screen Time restrictions when displaying web content
- ✅ Honor macOS content ratings (if applicable)
- ✅ Do not provide workarounds to bypass Screen Time

**What We Don't Do:**
- ❌ Build duplicate parental control UI (use macOS Screen Time instead)
- ❌ Attempt to detect or bypass Screen Time restrictions
- ❌ Store parental control PINs or credentials

## YouTube Restricted Mode Integration

### YouTube's Built-In Restricted Mode

**Feature:** YouTube provides Restricted Mode to hide potentially mature content.

**Current Limitation:**
- YouTube IFrame Player does not automatically inherit YouTube account's Restricted Mode setting
- Requires explicit URL parameter or YouTube account authentication

**Implementation Options:**

**Option 1: URL Parameter (No Authentication Required)**
```swift
// Append restricted mode parameter to IFrame URL
let iframeURL = "https://www.youtube.com/embed/\(videoID)?controls=1&rel=0&restricted=1"
```

**Option 2: Leverage User's YouTube Account Settings**
- If user signed into YouTube account in Safari, WKWebView may inherit session
- Restricted Mode preference from YouTube account applies automatically
- No additional MyToob implementation needed

**Recommendation:** Implement Option 1 as default, with toggle in Settings > Content & Privacy > "Enable YouTube Restricted Mode"

### Restricted Mode Toggle (Future Enhancement)

**Settings UI:**
```
Settings > Content & Privacy
├── YouTube Restricted Mode: [Toggle ON/OFF]
│   └── Help text: "Hide potentially mature content in YouTube videos. 
│       Uses YouTube's Restricted Mode filtering."
└── Protect Settings with Password: [Toggle ON/OFF] (macOS Keychain)
```

**Implementation:**
1. User enables toggle in Settings
2. All YouTube IFrame embeds include `restricted=1` parameter
3. Optional: Password-protect Settings to prevent child from disabling
4. Persists via UserDefaults, syncs via CloudKit (if enabled)

## Age-Appropriate Content Filtering

### Content Ratings

**YouTube Content:**
- YouTube does not provide consistent age ratings via API
- Restricted Mode is primary filtering mechanism
- Some channels self-identify as "Made for Kids" (available in API metadata)

**Local Files:**
- No content rating metadata in standard video files
- Parents responsible for selecting appropriate files

**MyToob's Role:**
- Display "Made for Kids" badge if available from YouTube API
- Allow parents to hide non-kid channels via ChannelBlacklist
- Provide clear Content Policy explaining limitations

### Recommended Parental Controls Setup

**For Families Using MyToob:**

**Step 1: Enable macOS Screen Time**
1. System Settings > Screen Time > Turn On
2. Set up Downtime (e.g., no app usage after 9 PM)
3. Set App Limits for MyToob (e.g., 2 hours/day)

**Step 2: Enable YouTube Restricted Mode in MyToob**
1. MyToob Settings > Content & Privacy
2. Toggle "YouTube Restricted Mode" ON
3. Enable "Protect Settings with Password" (optional)

**Step 3: Hide Inappropriate Channels**
1. Review child's YouTube subscription imports
2. Right-click any inappropriate channels → "Hide Channel"
3. Hidden channels sync across family's devices (if CloudKit enabled)

**Step 4: Disable Local File Import (Optional)**
1. MyToob Settings > Local Files
2. Toggle "Allow Local File Import" OFF
3. Prevents child from importing personal files

## Privacy Considerations for Minors

### COPPA Compliance (Children Under 13)

**Current Status:** MyToob does not target children under 13.

**Age Gate (Future Consideration):**
- Add first-launch age verification: "Are you 13 years or older?"
- If under 13, require parental consent or block app usage
- Log consent for compliance audit

**Data Collection for Minors:**
- On-device AI processing (no data sent to servers)
- CloudKit sync uses child's own iCloud account (parent-controlled)
- No advertising or third-party data sharing
- Complies with "Data Not Collected" privacy label

### YouTube's Children's Privacy

**YouTube's Requirements:**
- Videos marked "Made for Kids" have restricted features (comments disabled, personalization disabled)
- MyToob displays these videos in IFrame Player without modification
- No additional MyToob obligations (YouTube enforces)

## Parental Control Limitations

### What MyToob Can Control

✅ YouTube Restricted Mode toggle  
✅ Channel blacklist (hide specific channels)  
✅ Settings password protection (macOS Keychain)  
✅ Local file import enable/disable

### What MyToob Cannot Control (macOS Responsibility)

❌ Time limits (use macOS Screen Time)  
❌ Downtime schedules (use macOS Screen Time)  
❌ Web content filtering (use macOS Safari restrictions)  
❌ App installation restrictions (use macOS parental controls)

### What YouTube Controls (Not MyToob)

❌ Content ratings and classification  
❌ Restricted Mode filtering algorithms  
❌ Age-gating for mature content  
❌ Community Guidelines enforcement

## Transparency & Communication

### User-Facing Documentation

**Help Center Article: "Using MyToob Safely with Children"**

```markdown
# Using MyToob Safely with Children

MyToob is designed for adults but can be used by families with proper controls.

## Recommended Setup for Parents

1. **macOS Screen Time:** Set app limits and downtime in System Settings
2. **YouTube Restricted Mode:** Enable in MyToob Settings > Content & Privacy
3. **Hide Channels:** Right-click videos to hide inappropriate channels
4. **Protect Settings:** Enable Settings password in MyToob preferences

## What Parents Should Know

- YouTube content is moderated by YouTube, not MyToob
- Report inappropriate videos directly to YouTube (right-click > Report)
- Local files: Only import videos you approve for your child
- On-device AI: No data sent to servers; privacy-safe for children

## Age Recommendations

MyToob is rated for ages 12+ (to be determined during App Store submission).
Parental supervision recommended for children under 13.

## Questions?

Contact: support@mytoob.app
```

### App Store Age Rating

**Recommended Rating:** 12+ (Infrequent/Mild Mature/Suggestive Themes)

**Justification:**
- YouTube content may contain mature themes (even with Restricted Mode)
- MyToob does not create content, only displays third-party content
- Parental controls available via macOS Screen Time + in-app toggles

**Age Rating Questionnaire (App Store Connect):**
- **Cartoon or Fantasy Violence:** None (N/A)
- **Realistic Violence:** None (N/A)
- **Sexual Content or Nudity:** Infrequent/Mild (YouTube third-party content)
- **Profanity or Crude Humor:** Infrequent/Mild (YouTube third-party content)
- **Alcohol, Tobacco, or Drug Use:** Infrequent/Mild (YouTube third-party content)
- **Mature/Suggestive Themes:** Infrequent/Mild (YouTube third-party content)
- **Horror/Fear Themes:** None (N/A)
- **Medical/Treatment Information:** None (N/A)
- **Gambling:** None (N/A)
- **Made for Kids:** No
- **Third-Party Content:** Yes (YouTube)

## Implementation Roadmap

### Phase 1: macOS Integration (No Code Changes)
- [ ] Document macOS Screen Time setup for parents
- [ ] Test MyToob behavior under Screen Time restrictions
- [ ] Verify WKWebView respects Safari content restrictions

### Phase 2: YouTube Restricted Mode Toggle
- [ ] Add Settings > Content & Privacy section
- [ ] Implement toggle to enable/disable Restricted Mode
- [ ] Pass `restricted=1` parameter to YouTube IFrame URLs
- [ ] Unit tests for URL parameter injection

### Phase 3: Settings Password Protection
- [ ] Add "Protect Settings" toggle
- [ ] Use macOS Keychain for password storage
- [ ] Require password before accessing Settings (if enabled)
- [ ] Password reset flow (requires macOS admin authentication)

### Phase 4: Local File Import Restriction
- [ ] Add "Allow Local File Import" toggle in Settings
- [ ] Disable file picker if toggle OFF
- [ ] Password-protect toggle (if Settings password enabled)

### Phase 5: Documentation & Support
- [ ] Create Help Center article "Using MyToob with Children"
- [ ] Add parental control FAQ to website
- [ ] Include parental control guidance in App Store description
- [ ] Update Content Policy to mention age recommendations

## Testing & Validation

### Test Cases

**TC-1: macOS Screen Time App Limit**
1. Enable Screen Time, set 1-hour limit for MyToob
2. Use app for 60 minutes
3. Verify macOS blocks app usage after limit reached

**TC-2: YouTube Restricted Mode**
1. Enable Restricted Mode in Settings
2. Open YouTube video known to be filtered by Restricted Mode
3. Verify video does not play or shows "Restricted" message

**TC-3: Settings Password Protection**
1. Enable "Protect Settings" toggle, set password
2. Quit and relaunch app
3. Attempt to access Settings without password
4. Verify password prompt shown, incorrect password rejected

**TC-4: Channel Blacklist for Family Use**
1. Parent hides inappropriate channels via "Hide Channel"
2. Child logs into same iCloud account on different Mac
3. Verify blacklist syncs and channels hidden on child's device

**TC-5: Local File Import Disabled**
1. Parent disables "Allow Local File Import" in Settings
2. Child attempts to drag-drop local files
3. Verify import fails with message "Local file import disabled"

## Risk Assessment

### Risk: Child Bypasses Restrictions

**Mitigation:**
- Rely on macOS Screen Time (OS-level enforcement, cannot bypass)
- Settings password stored in Keychain (requires macOS admin to reset)
- CloudKit blacklist sync prevents per-device circumvention

### Risk: Restricted Mode Ineffective

**Mitigation:**
- Set parent expectations: "Restricted Mode reduces but does not eliminate mature content"
- Document in Help Center: "Supervision recommended even with Restricted Mode"
- Provide ChannelBlacklist as supplemental filtering

### Risk: Local Files Contain Inappropriate Content

**Mitigation:**
- EULA emphasizes user responsibility for local files
- Option to disable local file import entirely
- No upload/sharing features (content stays local)

## Future Enhancements (Post-MVP)

### Consideration 1: Supervised Mode

**Concept:** Child-safe mode with aggressive filtering
- Whitelist-only channels (not blacklist)
- Require parent approval for new subscriptions
- View history shared with parent's device

**Complexity:** High (requires parent-child account linking, approval flows)  
**Priority:** Low (use macOS Screen Time + Restricted Mode instead)

### Consideration 2: Content Rating Display

**Concept:** Show age ratings from YouTube API (if available)
- Display "Made for Kids" badge prominently
- Filter by age rating in search

**Feasibility:** Medium (YouTube API provides limited rating metadata)  
**Priority:** Medium (nice-to-have for parents)

### Consideration 3: Usage Reports for Parents

**Concept:** Export child's viewing history for parent review
- Time spent per channel, per video category
- Flagged videos (exceeded time limits, restricted content)

**Privacy Concern:** High (requires tracking child viewing)  
**Priority:** Low (conflicts with privacy-first positioning)

## References

### Apple Documentation
- [Screen Time - Apple Support](https://support.apple.com/guide/mac-help/set-up-screen-time-mchl0d2c54b9/mac)
- [Set up parental controls - Apple Support](https://support.apple.com/en-us/HT201304)

### YouTube Documentation
- [YouTube Restricted Mode](https://support.google.com/youtube/answer/174084)
- [YouTube Kids Alternative](https://www.youtubekids.com/)

### Regulatory Guidance
- [COPPA - Children's Online Privacy Protection Act](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa)
- [App Store Age Ratings](https://developer.apple.com/app-store/age-ratings/)

---

**Document Control:**  
This document is a specification for future parental control features. Implementation priority: Post-MVP (not required for initial App Store submission). Version history tracked in git.

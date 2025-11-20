# Compliance Documentation

This directory contains all documentation related to User-Generated Content (UGC) safeguards, App Store compliance, and policy enforcement for MyToob.

## Documents

### 1. [UGC Safeguards Framework](./ugc-safeguards-framework.md)
**Primary compliance document.** Defines MyToob's approach to UGC moderation, App Store Guideline 1.2 requirements, and YouTube ToS compliance.

**Key Topics:**
- Two-tier content model (YouTube vs. local files)
- ChannelBlacklist implementation and integration
- Report/block functionality specifications
- Compliance audit logging
- App Store reviewer notes

**Audience:** Product managers, legal team, App Store reviewers, developers

---

### 2. [Parental Controls Specification](./parental-controls.md)
**Future enhancement planning.** Documents potential parental control features, macOS Screen Time integration, and age-appropriate content filtering.

**Key Topics:**
- macOS Screen Time integration strategy
- YouTube Restricted Mode toggle
- Settings password protection
- Age rating considerations
- Privacy considerations for minors

**Audience:** Product managers, future developers, parents (user-facing content)  
**Status:** Specification only (not yet implemented)

---

### 3. [Policy Enforcement Framework](./policy-enforcement.md)
**Technical implementation guide.** Defines compile-time, runtime, and operational enforcement mechanisms to prevent policy violations.

**Key Topics:**
- SwiftLint custom rules for ToS compliance
- Danger CI checks for policy violations
- Runtime behavioral checks (playback visibility, quota budgets, cache validation)
- Compliance audit logging system
- Incident response procedures

**Audience:** Developers, DevOps engineers, security team

---

### 4. [Implementation Guide](./implementation-guide.md)
**Developer handbook for Epic 12.** Step-by-step instructions for implementing each story in the UGC Safeguards epic, with code samples and testing requirements.

**Key Topics:**
- Story-by-story implementation steps
- Code samples for each feature
- Integration points with ChannelBlacklist model
- Unit and UI testing requirements
- Deployment checklist

**Audience:** Developers actively working on Epic 12

---

### 5. [README.md](./README.md) (this file)
**Navigation guide.** Provides overview of compliance documentation and quick reference for finding specific information.

---

## Quick Reference

### For Developers

**Starting Epic 12 implementation?**
→ Read [Implementation Guide](./implementation-guide.md)

**Need to understand compliance rules?**
→ Read [Policy Enforcement Framework](./policy-enforcement.md)

**Adding new features that touch YouTube content?**
→ Review [UGC Safeguards Framework](./ugc-safeguards-framework.md) Section: "Compliance Guardrails"

**Setting up linting or CI checks?**
→ See [Policy Enforcement Framework](./policy-enforcement.md) Section: "Level 1: Compile-Time Prevention"

---

### For Product Managers

**Preparing for App Store submission?**
→ Review [UGC Safeguards Framework](./ugc-safeguards-framework.md) Section: "App Store Reviewer Notes"

**Considering parental control features?**
→ Read [Parental Controls Specification](./parental-controls.md)

**Understanding compliance responsibilities?**
→ Review [UGC Safeguards Framework](./ugc-safeguards-framework.md) Section: "Regulatory Requirements"

**Planning roadmap for future compliance features?**
→ See [Parental Controls Specification](./parental-controls.md) Section: "Implementation Roadmap"

---

### For Legal/Compliance Teams

**Validating App Store Guidelines compliance?**
→ Review [UGC Safeguards Framework](./ugc-safeguards-framework.md) Section: "Addressing Guideline 1.2"

**Reviewing policy documents for accuracy?**
→ Check [UGC Safeguards Framework](./ugc-safeguards-framework.md) Section: "Content Policy Page"

**Understanding enforcement mechanisms?**
→ Read [Policy Enforcement Framework](./policy-enforcement.md)

**Preparing for regulatory audit?**
→ Review [UGC Safeguards Framework](./ugc-safeguards-framework.md) Section: "Compliance Audit Logging"

---

### For App Store Reviewers

**Understanding MyToob's UGC approach?**
→ Start with [UGC Safeguards Framework](./ugc-safeguards-framework.md) Executive Summary

**Verifying Guideline 1.2 compliance?**
→ See [UGC Safeguards Framework](./ugc-safeguards-framework.md) Section: "App Store Reviewer Notes"

**Testing compliance features?**
→ Follow test cases in [Implementation Guide](./implementation-guide.md) Section: "Integration Testing"

**Questions about YouTube content moderation?**
→ Review [UGC Safeguards Framework](./ugc-safeguards-framework.md) Section: "Tier 1: YouTube Content (Third-Party UGC)"

---

## Compliance Feature Status

| Feature | Status | Epic 12 Story | Document Reference |
|---------|--------|---------------|-------------------|
| ChannelBlacklist Model | ✅ Implemented | (Foundation) | [UGC Framework](./ugc-safeguards-framework.md#1-content-filtering-channelblacklist) |
| Report Content Action | ⏳ Planned | 12.1 | [Implementation Guide](./implementation-guide.md#story-121-report-content-action) |
| Hide Channel Action | ⏳ Planned | 12.2 | [Implementation Guide](./implementation-guide.md#story-122-hide--blacklist-channels) |
| Hidden Channels UI | ⏳ Planned | 12.2 | [Implementation Guide](./implementation-guide.md#story-122-hide--blacklist-channels) |
| Content Policy Page | ⏳ Planned | 12.3 | [Implementation Guide](./implementation-guide.md#story-123-content-policy-page) |
| Support Contact | ⏳ Planned | 12.4 | [Implementation Guide](./implementation-guide.md#story-124-support--contact-information) |
| Send Diagnostics | ⏳ Planned | 12.4 | [Implementation Guide](./implementation-guide.md#story-124-support--contact-information) |
| YouTube Disclaimers | ⏳ Planned | 12.5 | [Implementation Guide](./implementation-guide.md#story-125-youtube-disclaimers--attributions) |
| Compliance Logging | ⏳ Planned | 12.6 | [Implementation Guide](./implementation-guide.md#story-126-compliance-audit-logging) |
| Parental Controls | 📋 Specification | (Future) | [Parental Controls](./parental-controls.md) |

---

## External References

### Apple Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) - Section 1.2 Safety
- [App Store Review Guidelines - UGC](https://developer.apple.com/app-store/review/guidelines/#safety)

### YouTube Documentation
- [YouTube Terms of Service](https://www.youtube.com/t/terms)
- [YouTube Community Guidelines](https://www.youtube.com/howyoutubeworks/policies/community-guidelines/)
- [YouTube API Services Terms](https://developers.google.com/youtube/terms/api-services-terms-of-service)
- [YouTube Developer Policies](https://developers.google.com/youtube/terms/developer-policies)
- [YouTube Branding Guidelines](https://developers.google.com/youtube/terms/branding-guidelines)

### Regulatory Resources
- [COPPA - Children's Privacy](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa)
- [App Store Age Ratings Guide](https://developer.apple.com/app-store/age-ratings/)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-18 | Initial compliance documentation suite created | Developer #3 (Documentation Stream) |

---

## Document Maintenance

**Review Schedule:**
- **Monthly:** Verify all links valid, compliance features functional
- **Quarterly:** Review for App Store Guidelines changes, update policies
- **Annually:** Full compliance audit, legal review, team training

**Change Process:**
1. Propose changes via pull request
2. Review by Product, Legal, and Engineering teams
3. Approval required from all three stakeholders
4. Update version numbers and dates
5. Announce changes to team

**Responsible Team:** Product Manager, Legal Counsel, Engineering Lead

---

**Questions or feedback on compliance documentation?**  
Contact: support@mytoob.app or open GitHub issue with `compliance` label

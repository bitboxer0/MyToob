# Epic 15: Monetization & App Store Release

**Goal:** Implement StoreKit 2 in-app purchase paywall for Pro tier, configure App Store submission package with reviewer documentation, and create notarized DMG for alternate distribution. This epic completes the product with monetization and distribution strategy, enabling both App Store approval and power-user alternate distribution.

## Story 15.1: StoreKit 2 Configuration

As a **developer**,
I want **StoreKit 2 configured with Pro tier in-app purchase**,
so that **users can unlock premium features**.

**Acceptance Criteria:**
1. App Store Connect: in-app purchase created (non-consumable, product ID: `com.mytoob.pro`)
2. StoreKit configuration file created for local testing (`.storekit`)
3. Purchase flow tested in Xcode with StoreKit testing environment (no real money)
4. Pro tier price set: $9.99 USD (adjust for other regions)
5. Product description written: "Unlock advanced AI organization, vector search, research tools, Spotlight integration, and more."
6. Purchase UI shown to free users: "Upgrade to Pro" button in toolbar or feature-gated screens
7. Receipt validation implemented: verify purchase on app launch, cache result

## Story 15.2: Paywall & Feature Gating

As a **free user**,
I want **to see which features require Pro and easily upgrade**,
so that **I understand the value proposition and can unlock features when ready**.

**Acceptance Criteria:**
1. Feature comparison sheet shown when clicking "Upgrade to Pro": Free vs. Pro columns
2. Free tier features: basic playback (YouTube + local), simple search, manual collections
3. Pro tier features: AI embeddings/clustering/search, research notes, Spotlight/App Intents, note templates, advanced filters
4. Gated features show lock icon + "Pro" badge in UI
5. Clicking gated feature shows paywall: "Unlock with Pro" + "Upgrade Now" button
6. Purchase flow: click "Upgrade Now" → StoreKit 2 sheet → authenticate with Apple ID → purchase confirmed → features unlocked
7. No dark patterns: clear value proposition, easy to dismiss paywall, "Restore Purchase" option prominently displayed

## Story 15.3: Restore Purchase & Subscription Management

As a **user**,
I want **to restore my Pro purchase on new devices or after reinstall**,
so that **I don't have to pay again**.

**Acceptance Criteria:**
1. "Restore Purchase" button in Settings > Pro tier section
2. Clicking button calls `AppStore.sync()` (StoreKit 2 receipt sync)
3. If valid purchase found, unlock Pro features immediately
4. If no purchase found, show message: "No Pro purchase found for this Apple ID"
5. "Manage Subscription" link opens App Store subscriptions page (if using subscription model)
6. Purchase status shown in Settings: "Pro (Purchased)" or "Free (Upgrade to Pro)"
7. UI test verifies restore purchase flow in StoreKit testing environment

## Story 15.4: App Store Submission Package

As a **developer**,
I want **all App Store submission materials prepared**,
so that **the app can be uploaded and approved**.

**Acceptance Criteria:**
1. App icon created in all required sizes (1024x1024 for App Store, 512x512, 256x256, etc.)
2. Screenshots created (1280x800, 2560x1600): library view, search, playback, collections, notes (5-10 screenshots)
3. App description written (concise, highlights key features, avoids "YouTube" in name)
4. Keywords selected: video, organizer, research, notes, library, macOS, AI, semantic search (under 100 characters)
5. Privacy Policy URL hosted: `https://yourwebsite.com/mytoob/privacy`
6. Support URL: `https://yourwebsite.com/mytoob/support`
7. App Store Connect listing completed: all metadata fields filled, screenshots uploaded

## Story 15.5: Reviewer Documentation & Compliance Notes

As a **developer**,
I want **comprehensive reviewer notes explaining compliance strategy**,
so that **App Store reviewers understand the architecture and approve the app**.

**Acceptance Criteria:**
1. `ReviewerNotes.md` document created in project repo
2. Document sections:
   - **Architecture Overview:** Explains IFrame Player + Data API usage (no stream access)
   - **YouTube Compliance:** How app adheres to ToS (no downloading, no ad removal, UGC safeguards)
   - **App Store Guidelines:** How app meets 1.2 (UGC moderation) and 5.2.3 (no IP violation)
   - **Demo Workflow:** Step-by-step instructions for testing key features
   - **Test Account:** Demo YouTube account credentials (if needed for review)
3. Document includes screenshots: player UI (showing YouTube ads intact), UGC reporting flow, content policy page
4. Document uploaded to App Store Connect: "App Review Information" > "Notes" field (paste or attach)
5. Contact information provided for follow-up questions
6. Document reviewed by legal (if available) for accuracy

## Story 15.6: Notarized DMG Build for Alternate Distribution

As a **developer**,
I want **a notarized DMG build with power-user features enabled**,
so that **users who prefer direct downloads can access advanced local file features**.

**Acceptance Criteria:**
1. "DMG Build" configuration created in Xcode (separate from App Store build)
2. DMG build enables power-user features: deeper CV/ASR for local files (disabled in App Store build)
3. App codesigned with Developer ID certificate (not App Store certificate)
4. DMG notarized via `xcrun notarytool` (submits to Apple for malware scan)
5. Notarization ticket stapled to app bundle: `xcrun stapler staple MyToob.app`
6. DMG created with app + README: drag-to-Applications instructions
7. DMG hosted on project website: `https://yourwebsite.com/mytoob/download`
8. DMG build versioned separately (e.g., 1.0.1-dmg to distinguish from App Store 1.0.1)

---

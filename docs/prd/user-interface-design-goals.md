# User Interface Design Goals

## Overall UX Vision

MyToob provides a **clean, native macOS experience** that feels instantly familiar to Mac users while introducing intelligent, AI-powered organization that "just works." The interface prioritizes **content over chrome**—video and collections are the focus, with controls and features accessible but unobtrusive. The app embraces **progressive disclosure**: basic features (playback, browsing) are immediately obvious, while advanced capabilities (vector search, clustering, research tools) reveal themselves naturally as users explore.

The experience should feel **fast, fluid, and intelligent**. Search results appear instantly, AI-suggested clusters help users discover content they didn't know they had, and the interface adapts to user behavior. Privacy and compliance are communicated **transparently** without being heavy-handed—users understand what the app can and cannot do with YouTube content.

## Key Interaction Paradigms

**Unified Content View:**
- YouTube and local videos are **presented uniformly** in the main content grid/list
- Visual badges distinguish source (YouTube icon vs. local file icon)
- Seamless switching between YouTube IFrame Player and AVKit playback based on source

**AI-Powered Discovery:**
- **Natural language search bar** as primary entry point: "Show me Swift tutorials from last month"
- **Auto-generated topic clusters** appear as smart collections in sidebar
- **Recommendations surface organically** based on current viewing and research topics

**Research-Oriented Workflow:**
- **Side-by-side viewing**: Video player + notes panel (resizable split view)
- **Timestamp-based note taking**: Click video moment to anchor note
- **Collections as knowledge bases**: Organize research topics with nested structure

**Keyboard-First Power User Mode:**
- **Command palette** (⌘K) for quick access to all actions
- **Vim-style navigation** optional for search results and collections
- **Global hotkeys** for playback control even when app is backgrounded

**Contextual Actions:**
- **Right-click context menus** for video items with relevant actions (add to collection, create note, hide channel, report)
- **Drag-and-drop everywhere**: URLs from browser, files from Finder, videos between collections

## Core Screens and Views

**Main Window (Primary Interface):**
- **Sidebar:** Collections, auto-clusters, subscriptions (YouTube), playlists
- **Content Grid/List:** Video thumbnails with metadata (title, channel, duration, watch progress)
- **Player View:** Embedded YouTube IFrame Player or AVKit player (full-screen capable)
- **Search Bar:** Prominent at top with filter pills (duration, date, channel, cluster)
- **Toolbar:** Primary actions (search mode toggle, view options, sync status, Pro upgrade)

**Search & Discovery View:**
- **Search results grid** with relevance scores and highlighted terms
- **Filter sidebar:** Faceted search (duration ranges, date ranges, channels, clusters)
- **Related videos panel:** AI-suggested similar content based on vector similarity

**Collection Detail View:**
- **Collection metadata:** Title, description, auto/manual tag, video count
- **Video list:** Videos in collection with reorder capability (drag-and-drop)
- **Quick actions:** Play all, shuffle, export to Markdown

**Video Detail / Player View:**
- **Primary player area:** YouTube IFrame Player or AVKit player (16:9 or content aspect ratio)
- **Video metadata panel:** Title, channel, description, tags, watch progress
- **Notes panel:** Timestamp-based notes with Markdown editor
- **Related videos:** AI-suggested similar content from user's library

**Settings / Preferences:**
- **General:** App appearance, default player behavior, keyboard shortcuts
- **YouTube Account:** OAuth status, disconnect account, API quota dashboard (dev mode)
- **AI & Privacy:** CloudKit sync toggle, AI feature controls (Pro), local file analysis options (DMG build)
- **Advanced:** Performance settings, cache management, diagnostics export

**Onboarding Flow:**
- **Welcome screen:** Value proposition, compliance transparency ("Uses official YouTube APIs")
- **OAuth authentication:** Google sign-in flow with scope explanation
- **Permission requests:** Local file access (if user imports local videos)
- **Feature tour:** Quick interactive tutorial highlighting search, collections, clustering

**UGC & Compliance Screens:**
- **Content Policy Page:** Easy-to-understand explanation of what content is allowed
- **Report Content Flow:** Deep-link to YouTube reporting + channel hide/blacklist option
- **About / Legal:** Disclaimers, attributions, contact, terms of service, privacy policy

**Pro Upgrade / Paywall:**
- **Feature comparison:** Free vs. Pro features (AI organization, research tools, Spotlight)
- **Purchase flow:** StoreKit 2 in-app purchase with restore option
- **Success confirmation:** Welcome to Pro, feature unlocks

## Accessibility

**Target: WCAG AA compliance** for macOS native apps with the following specific requirements:

- **VoiceOver:** Full support with descriptive labels for all interactive elements, custom actions for video controls
- **Keyboard Navigation:** Complete keyboard-only operation with visible focus indicators, logical tab order
- **Dynamic Type:** Support for macOS text size preferences, layout adapts without content truncation
- **High Contrast:** Dedicated high-contrast theme with sufficient contrast ratios (4.5:1 for body text, 3:1 for large text)
- **Reduced Motion:** Respect macOS reduced motion setting, disable non-essential animations
- **Color:** Never rely on color alone to convey information (use icons, labels, patterns)

## Branding

**Visual Identity:**
- **App Name:** "MyToob" (avoids "YouTube" per branding guidelines)
- **App Icon:** Custom design suggesting video organization/discovery (NOT YouTube logo or derivative)
- **Color Palette:** Modern, Mac-native colors (SF Symbols-compatible), avoid YouTube red as primary color
- **Typography:** SF Pro (system font) for native feel, SF Mono for technical details (quota dashboard, diagnostics)

**Compliance Branding:**
- **YouTube Attribution:** Show "Powered by YouTube" badge near player per branding guidelines
- **Disclaimer:** "Not affiliated with YouTube" in About screen
- **Player Integrity:** Display YouTube logo/branding as provided by IFrame Player (no removal/overlay)

**Tone:**
- **Professional yet approachable:** This is a productivity tool, not a consumer entertainment app
- **Transparent about capabilities:** Clear communication about what is/isn't possible with YouTube integration
- **Privacy-forward:** Emphasize on-device processing and user data ownership

## Target Device and Platforms

**Primary Target: macOS 14.0 (Sonoma) or later**
- **Hardware Focus:** Apple Silicon Macs (M1/M2/M3) as primary target for AI performance
- **Intel Support:** Best-effort compatibility (Core ML may be slower, user-facing performance warnings)
- **Screen Sizes:** Optimized for 13" to 27"+ displays, minimum window size 1024x768
- **Input Methods:** Keyboard + mouse/trackpad (no touch screen assumptions)

**NOT Supported in MVP:**
- iOS/iPadOS (future consideration for view-only companion apps)
- Apple TV (future consideration for collection playback)
- Apple Watch (future consideration for remote control)
- Web browser version

---

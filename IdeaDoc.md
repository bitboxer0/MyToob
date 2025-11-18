Got it — here’s a compliance-safe, Claude-Code-ready rewrite you can paste straight into Obsidian. I’ve removed timeframes and converted everything into epics with task/subtask checklists, acceptance criteria, and guardrails. It keeps your privacy-first positioning, replaces stream caching with metadata/embedding caches only, and cleanly separates YouTube (IFrame) from local files (full CV/ASR allowed).

⸻

AI-Powered macOS Video Client (YouTube-capable): Technical & Product Requirements

Goal: A native macOS app that organizes and discovers online (YouTube via official IFrame Player) and local videos using on-device AI. Privacy-first, App Store–compliant, and operable end-to-end by Claude Code + MCP.

One-page Summary
	•	Playback: YouTube via IFrame Player inside WKWebView (no stream extraction, no ad-blocking, no overlay that obscures the player). Local files via AVKit.
	•	Data: YouTube Data API for metadata only (strict quota budgeting, ETags, field filtering). Persist app data with SwiftData + CloudKit (user’s embeddings, tags, notes, watch progress).
	•	AI: On-device embeddings, clustering, retrieval, and lightweight ranking; operate only on metadata, thumbnails, and user interactions for YouTube. Full CV/ASR allowed only for local files.
	•	Compliance: “Advanced Video Player & Organizer.” No “YouTube” in app name/icon. UGC safeguards (report links, channel hide/blacklist, content policy). Two distributions: App Store SKU (strict) and notarized DMG (power-user features for local files only).
	•	Monetization: Freemium with Pro unlock for AI organization, research tooling, and notes. Never imply ad-removal or Premium-like playback benefits.

Non-Goals / Guardrails
	•	⛔ No downloading/caching/prefetching YouTube audio/video bytes.
	•	⛔ No SponsorBlock, ad-skipping, or DOM manipulation that removes ads/logos.
	•	⛔ No external backends (Invidious/Piped) in the App Store build.
	•	✅ Allowed caching: metadata, thumbnails (respect cache headers), embeddings, cluster labels, user notes.

Core Architecture
	•	UI: SwiftUI + WKWebView (YouTube) + AVKit (local files).
	•	Storage: SwiftData models for items, tags, embeddings, clusters, notes; CloudKit sync.
	•	AI: Core ML for embeddings (small sentence model), HNSW index for retrieval, graph-based clustering (kNN + Leiden/Louvain), gradient-boosted ranking (Core ML).
	•	Search: Hybrid (keyword + vector). Spotlight & App Intents integration.

Data Model (SwiftData)

@Model
final class VideoItem {
  @Attribute(.unique) var videoID: String?   // YouTube: "dQw4w9WgXcQ"; Local: nil
  var localURL: URL?                          // Local files only
  var title: String
  var channelID: String?
  var duration: TimeInterval
  var watchProgress: TimeInterval
  var isLocal: Bool
  @Attribute(.transformable) var aiTopicTags: [String]
  @Attribute(.transformable) var embedding: [Float]?   // 384-dim typical
  var addedAt: Date
  var lastWatchedAt: Date?
}

@Model
final class ClusterLabel {
  @Attribute(.unique) var clusterID: String
  var label: String
  @Attribute(.transformable) var centroid: [Float]
  var itemCount: Int
}

Note: Use YouTube videoID as identity for online items. Arrays stored as transformable or child models. Migrate via versioned models.

⸻

Epics, Tasks, and Acceptance Criteria

Tip: Use these as Claude Code “MDC rules” + MCP workflows. Each epic includes a Definition of Done (DoD) and Acceptance Criteria (AC).

Epic A — Repo, CI/CD, and Claude Code + MCP Orchestration
	•	A1. Project scaffolding
	•	Xcode project (Swift 5.10+, macOS 14+ target), SwiftPM only.
	•	App group, signing, and entitlements (app-sandbox, network.client, user-selected file R/W).
	•	A2. Workflows for Claude Code
	•	.mcp.json pointing to: Workflows-MCP, RepoPromptMCP, MemoryMCP, XcodeBuildMCP, Lint/Format MCP.
	•	workflows-yaml/ with tasks for build, test, lint, bundle, release, notarize, store assets.
	•	A3. CI
	•	GitHub Actions for PR lint/test, release tags, notarization pipeline.
	•	A4. Coding standards
	•	SwiftLint, swift-format, danger rules for API keys and policy keywords.

DoD: Green build, signed app artifacts, MCP commands run end-to-end.
AC: make ci + MCP “build & test” workflow passes locally and in CI.

⸻

Epic B — OAuth & YouTube Data API (Metadata Only)
	•	B1. OAuth
	•	Google OAuth w/ minimal scopes (e.g., youtube.readonly).
	•	Keychain storage for refresh tokens.
	•	B2. API client
	•	Typed endpoints for search/list/videos/channels/playlists.
	•	ETag support + If-None-Match.
	•	Field filtering (part= and fields=) and pagination helpers.
	•	B3. Quota budgeting
	•	Request “unit” budget table per endpoint.
	•	Circuit-breaker on 429; exponential backoff; retry policy.
	•	B4. Importers
	•	Subscriptions, playlists, “My history” if scope is granted (optional).

DoD: Auth flow works, sample metadata loads, quota logged per call.
AC: 95% cache hit on repeated refresh; hard cap guard on total “units” per day.

⸻

Epic C — Playback Layer
	•	C1. YouTube playback (IFrame inside WKWebView)
	•	Load IFrame Player; JS bridge for play/pause/seek, time updates, state changes.
	•	Respect default YouTube UI; no overlays that obscure UI/ads.
	•	Picture-in-Picture (use player/OS support where available).
	•	C2. Local file playback (AVKit)
	•	AVPlayerView for local files; transport controls; scrubbing; snapshots.
	•	Waveform/chapters (optional, local only).

DoD: Seamless switch between online (IFrame) and local (AVKit).
AC: Seek/play/pause work reliably; PiP available where player/OS allows.

⸻

Epic D — Storage & Caching (Metadata/Embeddings Only)
	•	D1. SwiftData schema
	•	Items, clusters, labels, user notes, channel blacklist.
	•	D2. Caching
	•	Metadata cache w/ ETags.
	•	Thumbnail cache (respect cache headers).
	•	No video/audio byte cache for YouTube.
	•	D3. CloudKit sync
	•	Private DB sync for user data; conflict tests; partial sync toggles.

DoD: Cold start < 2s to first render, warm start < 500ms.
AC: Clearing cache does not break identity; sync conflicts resolved deterministically.

⸻

Epic E — On-Device AI (Compliant Scope)
	•	E1. Embeddings
	•	Export a small sentence-embedding model to Core ML (≈384-dim), 8-bit quantization.
	•	Generate vectors for titles/description + thumbnail OCR text.
	•	E2. Vector search
	•	HNSW index persisted in SwiftData; background rebuild; delta updates.
	•	E3. Clustering
	•	Build kNN graph; Leiden/Louvain community detection.
	•	Label clusters via keyword extraction + centroid terms.
	•	E4. Ranking
	•	Gradient-boosted tree model (Core ML) with features:
recency, similarity to session intent, dwell time, completion %, novelty/diversity.
	•	E5. Compliance boundaries
	•	YouTube: AI runs on metadata, thumbnails, and user interactions only.
	•	Local: Enable optional frame-level CV/ASR pipelines (explicitly “Local only”).

DoD: Topic groups appear within seconds; recommendations feel personal and diverse.
AC: Query → top-k retrieval latency < 50ms on M-series; cluster stability across reboots.

⸻

Epic F — Search, Discovery & Organization UX
	•	F1. Search
	•	Hybrid query (keyword + vector). Natural language queries supported.
	•	Filter pills (duration, recency, channel, cluster).
	•	F2. Collections
	•	User-defined folders; auto-collections (e.g., “Coding,” “Coaching,” “News”).
	•	Drag-and-drop from search to collections.
	•	F3. Key moments (metadata-only for YouTube)
	•	Summaries from descriptions/chapters/comments (no downloading streams).
	•	F4. Notes & citations
	•	Inline notes, bidirectional links; export to Markdown.

DoD: Users can find, cluster, and save what matters in two clicks.
AC: >80% of tested queries return relevant items in top-5.

⸻

Epic G — macOS Integrations
	•	G1. Spotlight indexing for items, tags, clusters.
	•	G2. App Intents / Shortcuts for “play next,” “add to collection,” “search cluster.”
	•	G3. Menu bar mini-controller (play/pause/next, now-playing info).
	•	G4. Now Playing integration where feasible.
	•	G5. Keyboard shortcuts full coverage; command palette.

DoD: Spotlight finds saved items; Shortcuts invoke app actions.
AC: >95% of primary actions reachable via keyboard.

⸻

Epic H — Privacy, Security, and UGC Safeguards
	•	H1. Privacy posture
	•	“Data Not Collected” where true; otherwise explicit opt-in analytics with on-device aggregation.
	•	H2. OAuth safety
	•	Keychain-backed tokens; token rotation; minimal scopes.
	•	H3. UGC
	•	Report content (deep-link to YouTube report flow).
	•	Hide/blacklist channels.
	•	In-app content policy + EULA; easy contact/support.
	•	H4. Permissions
	•	Explainers for local file access; narrow bookmarks.

DoD: Privacy labels accurate; reviewers can follow UGC and support flows.
AC: Security audit shows no secrets in repo or crash logs.

⸻

Epic I — Network Resilience & Quota Management
	•	I1. ETags/If-None-Match everywhere.
	•	I2. Rate-limiters per endpoint; exponential backoff on 429/5xx.
	•	I3. Unit budget dashboard (dev-only) with warnings/blocks.
	•	I4. Field filtering to minimize payload size.

DoD: Soak tests show stable operation at target DAU.
AC: Repeated sync cycles reuse ≥90% cached responses.

⸻

Epic J — Observability & QA
	•	J1. Telemetry (on-device)
	•	Feature usage, latency, errors; exportable diagnostics bundle (user-initiated).
	•	J2. Tests
	•	Unit tests (models, stores, ranker).
	•	UI tests for IFrame bridge (play/pause/seek).
	•	Migration tests for SwiftData schema changes.
	•	J3. Performance
	•	Cold/warm start, search latency, memory pressure, energy impact.

DoD: >85% unit coverage on core logic; UI smoke tests stable.
AC: UI remains responsive (<16ms frame budget) during background indexing.

⸻

Epic K — Accessibility & Internationalization
	•	K1. VoiceOver labels for all controls; focus order.
	•	K2. Keyboard-only operation.
	•	**K3. Dynamic type/high-contrast themes.
	•	K4. Localizable strings framework; seed en/… JSON.

DoD: Accessibility audit passes.
AC: Complete playback & browse flows via keyboard + VoiceOver.

⸻

Epic L — App Store Readiness & Alternate Distribution
	•	L1. Branding & wording
	•	No “YouTube” in app name/icon; clear “not affiliated” disclaimer.
	•	L2. Reviewer notes
	•	Architecture explainer: IFrame Player + Data API only; no stream caching.
	•	UGC safeguards, privacy stance, contact, demo account (if needed).
	•	L3. Entitlements
	•	Sandbox, network client, user-selected files.
	•	L4. Notarized DMG (site download)
	•	Power-user features for local files only (e.g., full CV/ASR).

DoD: App Store package + DMG both ship from CI.
AC: Review kit includes screen-by-screen compliance notes.

⸻

Epic M — Monetization & Licensing
	•	M1. Paywall
	•	Free: basic viewing & simple organization.
	•	Pro: advanced AI (embeddings index, clustering, ranker), research notes, vector search, Spotlight/App Intents.
	•	M2. Purchase flow
	•	StoreKit 2 receipts, restore purchase.
	•	M3. Messaging
	•	No claims about ad removal or Premium-like features.

DoD: Purchase & restore verified in sandbox & TestFlight.
AC: Paywall copy cleared for compliance.

⸻

Epic N — Documentation & Support
	•	N1. Developer docs
	•	Architecture, data model, policies, migration playbook.
	•	N2. User docs
	•	Privacy, UGC reporting, local vs online capabilities.
	•	N3. Support
	•	In-app “Send diagnostics” (user-initiated), FAQ, issue templates.

DoD: Docs part of repo; built as a static site artifact.
AC: Reviewer can reproduce flows using docs alone.

⸻

Definition of Ready (per Story)
	•	Clear scope (YouTube vs Local).
	•	Compliance note attached (what’s allowed).
	•	Telemetry & tests identified.
	•	Performance budget stated (latency/energy).

Acceptance Criteria Templates
	•	Functionality: Given X state, when Y action, then Z observable result (UI + telemetry).
	•	Policy: Feature does not cache or manipulate YouTube streams; uses IFrame API only.
	•	Perf: P95 latency under stated budget on M1/M2 Mac.
	•	A11y: Fully operable via keyboard/VoiceOver.

Risk Register (Mitigations Inline)
	•	App Store variance → Maintain DMG path; reviewer pack and toggles.
	•	Quota spikes → Budget dashboard, ETags, field filtering, user-initiated heavy calls.
	•	Model updates → Version embeddings; background re-index; rollback plan.

MCP / Claude Code Operator Notes (Quick-Start)
	•	Workflows (suggested):
	•	workflow: bootstrap_repo → init project, add SwiftLint/format, entitlements, CI.
	•	workflow: add_youtube_oauth → add OAuth screen, scopes, Keychain.
	•	workflow: iframe_player_bridge → inject IFrame, JS bridge, message handlers.
	•	workflow: swiftdata_schema_v1 → add models, migrations, unit tests.
	•	workflow: embeddings_coreml_setup → add model, quantize, API wrapper, tests.
	•	workflow: vector_index_hnsw → build index store, background rebuild.
	•	workflow: clustering_graph → kNN graph + Leiden/Louvain, labeler.
	•	workflow: hybrid_search → keyword + vector query, UI filter pills.
	•	workflow: spotlight_appintents → indexer + intents handlers.
	•	workflow: ugc_safeguards → report links, blacklist, policy sheet.
	•	workflow: store_release → App Store asset generation, privacy labels, reviewer notes.
	•	workflow: dmg_release → Notarize, staple, website asset.
	•	MDC Rules
	•	Separate “YouTube Online” from “Local Files” in specs and tests.
	•	Enforce guardrails in lint rules (e.g., forbid use of URLSession for googlevideo domains).
	•	Require a “Policy Acceptance” checklist in every PR.

⸻

Open Questions (track as issues)
	•	Should we ship optional downloadable on-device models (bigger, better embeddings) behind a Pro toggle?
	•	Which OCR strategy for thumbnails (Vision vs Tesseract bridge) performs best offline?
	•	Level of chapter/summary extraction permissible from YouTube metadata only (without content capture)?

⸻
Perfect — here’s a drop-in .mcp.json that wires up your Workflows, XcodeBuild, RepoPrompt, and Memory MCP servers, points the workflows server at your .workflows layout, and forces JSON workflow outputs.

Place this at your repo root as .mcp.json. Create a .env (or set shell env) for the placeholders.

{
  "mcpServers": {
    "workflows": {
      "command": "workflows-mcp-server",
      "args": [
        "--dir", ".workflows/categories",
        "--index", ".workflows/_index.json"
      ],
      "env": {
        "WORKFLOWS_DIR": ".workflows/categories",
        "WORKFLOWS_INDEX": ".workflows/_index.json",
        "WORKFLOWS_OUTPUT_FORMAT": "json",        // JSON reporting
        "WORKFLOWS_STRICT": "1"                   // fail if dir/index not found
      },
      "timeout": 180000
    },

    "xcodebuild": {
      "command": "xcodebuild-mcp",
      "args": [],
      "env": {
        "XCODE_SCHEME": "App",
        "XCODE_DESTINATION": "platform=macOS",
        "DERIVED_DATA_PATH": "DerivedData"
      },
      "timeout": 600000
    },

    "repo": {
      "command": "repoprompt-mcp",
      "args": [
        "--root", ".",
        "--hidden", "false"
      ],
      "env": {
        "REPO_INCLUDE_GLOBS": "Sources/**,App/**,Tests/**,.workflows/**",
        "REPO_EXCLUDE_GLOBS": "node_modules/**,.build/**,DerivedData/**,Pods/**"
      },
      "timeout": 180000
    },

    "memory": {
      "command": "openmemory-mcp",
      "args": [
        "--namespace", "macos-video-client"
      ],
      "env": {
        "MEM0_API_KEY": "${MEM0_API_KEY}",
        "MEM0_BASE_URL": "${MEM0_BASE_URL}",      // e.g., https://mem0.yourhost/v1
        "MEM0_DEFAULT_TTL_DAYS": "0"              // 0 = no expiry
      },
      "timeout": 180000
    }
  },

  "defaultServers": ["workflows", "xcodebuild", "repo", "memory"]
}

Notes & quick checks
	•	Fix for “workflows not listing”: the server is explicitly pointed at .workflows/categories with _index.json in .workflows. The strict flag will error if paths are wrong (better than silently listing nothing).
	•	JSON outputs: WORKFLOWS_OUTPUT_FORMAT=json ensures Claude Code gets machine-readable results from the workflows server.
	•	Env setup: put API keys/URLs in your shell or a .env file sourced by your MCP launcher (e.g., MEM0_API_KEY, MEM0_BASE_URL).
	•	Smoke tests (in Claude Code):
	1.	“List workflows” → should enumerate everything from .workflows/_index.json.
	2.	“Run workflow: bootstrap_repo” → should scaffold lint, CI, entitlements.
	3.	“Build app” → xcodebuild-mcp uses the scheme/destination above (override via env if needed).
	4.	“Summarize repo” → RepoPrompt should read only your included globs.

Below is a complete, agent-consumable PRD + Technical Architecture for a native macOS video client that is YouTube-capable via the IFrame Player (no raw streams) and delivers privacy-first, on-device AI organization. It’s structured so Claude Code / MCP or similar agents can pick up sections, IDs, and checklists directly.

I’ve embedded authoritative policy references for the parts that change over time (YouTube ToS & developer policies, IFrame Player API, Data API quotas, Apple App Store Guidelines). Keep these citations in your repo docs so agents (and reviewers) can trace the compliance gates.  ￼

⸻

Product Requirements Document (PRD)

PRD-001 — Executive Summary

Build a native macOS video client that organizes and discovers online videos (YouTube via the YouTube IFrame Player in a WKWebView) and local files (AVKit) using on-device AI. The App Store build must not access or download YouTube streams outside official services, must not modify or obscure the YouTube player or ads, and must provide UGC safeguards (report/hide/contact). A notarized DMG build may include additional power-user features for local files only.  ￼

PRD-002 — Goals
	•	Native macOS experience for watching + organizing YouTube and local videos.
	•	Privacy-first: all AI runs on-device via Core ML; user data synced via CloudKit (optional).  ￼
	•	Tangible independent value beyond a simple wrapper: embeddings search, topic clustering, notes, research collections.

PRD-003 — Non-Goals (Guardrails)
	•	No saving/downloading, converting, caching, or prefetching YouTube audio/video bytes; no alternative front-ends (e.g., Invidious/Piped) in the App Store build; no ad-skipping or UI removal/overlay on the YouTube player.  ￼

PRD-004 — Key Personas
	•	Researcher/Pro User: Deep discovery, tagging, collections, notes.
	•	Subscriber: Watches channels, wants better organization than YouTube UX.
	•	Local-Library User: Heavy local files; expects robust AVKit features.

PRD-005 — Top User Stories
	•	As a user, I can sign in to YouTube (read-only scope) and browse/search channels, playlists, and videos, with playback in a native window.  ￼
	•	As a user, I can play YouTube videos using the IFrame Player in a WKWebView, controlling play/pause/seek via the JS API (no DOM manipulation of ads/branding).  ￼
	•	As a user, I can play local files with AVKit and organize them with the same AI features (CV/ASR allowed for local files).
	•	As a user, I can search by keywords or natural language and get vector-similar results ranked smartly.
	•	As a user, I can save, tag, cluster, and take notes on videos, and sync my own data via CloudKit.
	•	As a user, I can report content (deep-link to YouTube’s reporting), hide channels, and access a policy page and contact.  ￼

PRD-006 — Scope (Functional)
	•	Playback
	•	YouTube: WKWebView + IFrame Player API, no changes to player UI/ads; control via JS bridge; pause when hidden unless PiP is active/visible.  ￼
	•	Local: AVKit (AVPlayerView) with scrubbing, chapters; optional waveform.
	•	Discovery & Organization
	•	On-device embeddings (text + thumbnail OCR text), HNSW retrieval, clustering (kNN graph + Leiden/Louvain), auto labels, collections, tags.
	•	Search
	•	Hybrid (keyword + vector), filters (duration, recency, channel, cluster).
	•	Notes & Export
	•	Inline notes, backlinks, Markdown export.
	•	UGC Safeguards
	•	Report link (to YouTube), hide/blacklist channel, visible policy + contact.  ￼
	•	Settings
	•	CloudKit sync toggle; privacy toggles; API quota dashboard (dev).

PRD-007 — Out of Scope
	•	Downloading/saving YouTube videos for offline use, ad removal, SponsorBlock, alternate non-YouTube playback backends in App Store build.  ￼

PRD-008 — Compliance Requirements (App Store + YouTube)
	•	App Store
	•	Guideline 1.2: UGC moderation (report/hide/contact).
	•	Guideline 5.2.3: No downloading/converting 3rd-party media (e.g., YouTube).
Include reviewer notes explaining IFrame usage and safeguards.  ￼
	•	YouTube
	•	Use IFrame Player API for playback; do not access streams otherwise.
	•	Do not modify/obscure the player or ads; comply with Required Minimum Functionality and Developer Policies.
	•	Respect quotas: default 10,000 units/day; e.g., search.list 100 units.  ￼
	•	Branding
	•	Follow YouTube branding guidelines; avoid using “YouTube” in app name/icon; include “not affiliated” disclaimer.  ￼

PRD-009 — Success Metrics
	•	Experience: P95 search < 50 ms (in-memory index), cold start to first render < 2 s.
	•	Adoption: >60% weekly users engage with AI organization features.
	•	Compliance: 0 policy violations; App Store approval (if rejected, DMG path intact).

PRD-010 — Risks & Mitigations
	•	Reviewer variance (macOS) → Provide reviewer doc + screenflows; keep DMG distribution for power users (local-file features only).  ￼
	•	Quota spikes → ETags/If-None-Match, fields filtering, unit budget dashboard, batch videos.list.  ￼
	•	Policy drift → Pin policy links in app, CI gate on lint rules, periodic policy audit.

⸻

Technical Architecture

ARC-001 — System Overview

A single-process macOS app with three major lanes:
	1.	YouTube lane: OAuth + Data API (metadata only) → SwiftData store → IFrame Player in WKWebView for playback.
	2.	Local lane: File import → AVKit playback + full local CV/ASR (optional).
	3.	AI lane: On-device embeddings, vector index, clustering, ranker, Spotlight/App Intents.

Policy boundary: For YouTube items, AI only uses metadata (title, description, chapters), thumbnails (OCR text), and user interactions—no frame-level analysis of YouTube streams.  ￼

ARC-002 — Components
	•	WKWebView + IFrame Player bridge: Swift↔︎JS messaging for play/pause/seek, state/time events. Player UI/ads untouched.  ￼
	•	YouTube Data API client: OAuth minimal scopes, ETags/If-None-Match, fields filtering, quota budgeting (10k units/day default; search.list=100).  ￼
	•	Storage: SwiftData models (VideoItem, ClusterLabel, Note, ChannelBlacklist); CloudKit optional sync.
	•	AI:
	•	Embeddings: small sentence model (≈384-d) Core ML; 8-bit quantization.  ￼
	•	Vector index: HNSW (persisted), delta updates.
	•	Clustering: Build kNN graph → Leiden/Louvain; label via keywords from metadata & thumbnail OCR text.
	•	Ranker: Gradient-boosted trees (Core ML): features = recency, similarity, dwell time, completion %, novelty/diversity.
	•	Search UX: Keyword + vector hybrid; filter pills.
	•	Integrations: Spotlight indexing; App Intents (Shortcuts).
	•	Observability: On-device telemetry; exportable diagnostics bundle; no external analytics without explicit opt-in.

ARC-003 — Data Model (SwiftData)

Essential subset (expand as needed):

@Model
final class VideoItem {
  @Attribute(.unique) var videoID: String?   // YouTube id or nil for local
  var localURL: URL?
  var title: String
  var channelID: String?
  var isLocal: Bool
  var duration: TimeInterval
  var watchProgress: TimeInterval
  @Attribute(.transformable) var embedding: [Float]?
  @Attribute(.transformable) var aiTopicTags: [String]
  var addedAt: Date
  var lastWatchedAt: Date?
}

@Model
final class ClusterLabel {
  @Attribute(.unique) var clusterID: String
  var label: String
  @Attribute(.transformable) var centroid: [Float]
  var itemCount: Int
}

@Model
final class ChannelBlacklist {
  @Attribute(.unique) var channelID: String
  var reason: String?
}

ARC-004 — API Interaction & Quota Budget

Default daily quota: 10,000 units. Key costs: search.list=100 units; videos.list=1; channels.list=1; playlistItems.list=1. Use ETags and fields to shrink payloads; batch IDs where possible; dev dashboard warns or halts when predicted usage exceeds daily cap.  ￼

ARC-005 — Compliance Enforcement
	•	Policy Lint: Block usage of googlevideo.com or any non-IFrame streaming endpoints at compile/lint time.
	•	Playback Visibility: Pause when the player is not visible; allow PiP only when web content/OS supports it (use IFrame/HTML5 PiP; do not hack the DOM).  ￼
	•	UGC Controls: Report link (to YouTube UI), channel blacklist, policy page & contact.  ￼
	•	Branding: Show attribution as required; avoid “YouTube” in app name/icon per branding rules.  ￼

ARC-006 — Security & Privacy
	•	OAuth tokens in Keychain; minimum scopes (e.g., youtube.readonly).
	•	No server-side collection by default; on-device Core ML; CloudKit sync for user data only.  ￼

ARC-007 — Performance Targets
	•	Index build (1k items) < 5 s on M1; query P95 < 50 ms; cold start < 2 s; smooth playback (UI thread < 16 ms frame budget).

ARC-008 — Testing Strategy
	•	Unit: model transforms, indexers, ranker features.
	•	UI: IFrame bridge (play/pause/seek), search flows, UGC actions.
	•	Migration: SwiftData versioned schemas.
	•	Soak: quota burn simulation; network failure (429/5xx) backoff.

ARC-009 — Distribution
	•	App Store build (strict): IFrame-only YouTube playback; no ad blocking/overlays; UGC safeguards; reviewer notes.  ￼
	•	Notarized DMG: Adds power-user features for local files only (e.g., deeper CV/ASR).

⸻

Acceptance Criteria (Agent-checkable)

Use these IDs in PRs and CI/agent gates.
	•	AC-PLAY-001: YouTube playback uses IFrame Player API in WKWebView; control via JS API only; no DOM removal/overlay of player elements/ads. Evidence: UI test + code scan.  ￼
	•	AC-PLAY-002: When app window hidden/minimized, playback pauses; PiP permitted only when supported/visible. Evidence: UI test; event logs.
	•	AC-DATA-001: API requests send If-None-Match with cached ETag; responses store new ETag. Evidence: network logs.  ￼
	•	AC-DATA-002: search.list usage limited (budgeted), with fields filtering. Evidence: quota dashboard.  ￼
	•	AC-AI-001: For YouTube, embeddings are computed from metadata & thumbnail OCR text only; no frame extraction. Evidence: pipeline config.  ￼
	•	AC-UGC-001: Report link, channel hide/blacklist, policy page & contact available from video screen. Evidence: UI test paths.  ￼
	•	AC-BRAND-001: App name/icon avoid “YouTube”; attributions follow branding rules. Evidence: assets + About screen.  ￼

⸻

Implementation Work Plan (Agent Tasks)

These tasks mirror the epics you already adopted; each is runnable by a build agent or MCP workflow. No timeframes—just ordered dependencies.

Tasks Overview
	1.	T-BOOT: Repo bootstrap, entitlements, CI, lint rules (policy lint).
	2.	T-AUTH: OAuth (minimal scopes), Keychain, token refresh.
	3.	T-API: Data API client with ETags, fields, pagination, quota guard.
	4.	T-IFRAME: WKWebView + IFrame Player bridge; play/pause/seek; state/time events.
	5.	T-AVKIT: Local file playback with AVKit.
	6.	T-STORE: SwiftData schema; caches (metadata/thumbnails only); CloudKit sync.
	7.	T-EMB: Core ML embeddings wrapper; thumbnail OCR text pipeline.  ￼
	8.	T-INDEX: HNSW vector index (persisted), delta updates.
	9.	T-CLUST: kNN graph + Leiden/Louvain clustering; labeler.
	10.	T-RANK: GBDT ranker (Core ML) with features; re-ranking for diversity.
	11.	T-SEARCH: Hybrid search (keyword + vector); filter pills.
	12.	T-UGC: Report link, channel blacklist, policy page & contact.  ￼
	13.	T-INTEG: Spotlight indexing; App Intents actions.
	14.	T-OBS: On-device telemetry; diagnostics bundle.
	15.	T-A11Y: VoiceOver, keyboard-only, high-contrast.
	16.	T-QA: Unit/UI/migration/soak tests; perf harness.
	17.	T-DIST: App Store bundle + reviewer notes; notarized DMG (local-only extras).

Machine-Readable Task Spec (YAML)

Agents can read this and execute stepwise. Keep alongside your workflows.

product:
  id: macos-video-client
  version: 1.0
  compliance_refs:
    app_store_guidelines: "https://developer.apple.com/app-store/review/guidelines/"
    youtube_iframe_api: "https://developers.google.com/youtube/iframe_api_reference"
    youtube_policies: "https://developers.google.com/youtube/terms/developer-policies"
    youtube_quota: "https://developers.google.com/youtube/v3/determine_quota_cost"
    youtube_branding: "https://developers.google.com/youtube/terms/branding-guidelines"

tasks:
  - id: T-BOOT
    title: Bootstrap repo & policy lint
    deps: []
    done_when:
      - ".github/workflows/ci.yml exists"
      - "lint fails on 'googlevideo.com' usage"
  - id: T-AUTH
    title: OAuth (readonly) + Keychain
    deps: [T-BOOT]
    done_when:
      - "Sign-in flow completes; tokens in Keychain"
  - id: T-API
    title: YouTube Data API client
    deps: [T-AUTH]
    done_when:
      - "ETags used on repeat requests"
      - "fields filtering enabled"
      - "quota budget dashboard shows live counts"
  - id: T-IFRAME
    title: WKWebView + IFrame Player bridge
    deps: [T-BOOT]
    policy_gates:
      - "No DOM removal/overlays on player or ads"
    done_when:
      - "Play/Pause/Seek work via JS API"
      - "Time/state events received"
  - id: T-AVKIT
    title: Local playback via AVKit
    deps: [T-BOOT]
    done_when:
      - "Transport controls & scrubbing work"
  - id: T-STORE
    title: SwiftData + CloudKit + caches
    deps: [T-API]
    done_when:
      - "Metadata & thumbnail cache only"
      - "Migrations tested"
  - id: T-EMB
    title: Core ML embeddings + thumbnail OCR text
    deps: [T-STORE]
    done_when:
      - "Text->vector calls under 10ms avg"
  - id: T-INDEX
    title: HNSW vector index
    deps: [T-EMB]
    done_when:
      - "Query top-k < 50ms P95"
  - id: T-CLUST
    title: Graph clustering & labels
    deps: [T-INDEX]
    done_when:
      - "Stable clusters across reboots"
  - id: T-RANK
    title: Ranker (Core ML)
    deps: [T-INDEX]
    done_when:
      - "Diversity-preserving re-rank enabled"
  - id: T-SEARCH
    title: Hybrid search UX
    deps: [T-INDEX, T-RANK]
    done_when:
      - "Filters (duration, recency, channel, cluster)"
  - id: T-UGC
    title: UGC safeguards
    deps: [T-IFRAME]
    done_when:
      - "Report link, channel blacklist, policy/contact"
  - id: T-INTEG
    title: Spotlight & App Intents
    deps: [T-STORE]
    done_when:
      - "Spotlight finds saved items"
  - id: T-OBS
    title: On-device telemetry/diagnostics
    deps: [T-BOOT]
    done_when:
      - "User-initiated diagnostics export"
  - id: T-A11Y
    title: Accessibility
    deps: [T-IFRAME, T-SEARCH]
    done_when:
      - "Keyboard-only & VoiceOver pass"
  - id: T-QA
    title: Tests & perf harness
    deps: [T-IFRAME, T-API, T-STORE, T-INDEX]
    done_when:
      - ">80% unit coverage on core logic"
  - id: T-DIST
    title: Store build & DMG notarization
    deps: [T-QA, T-UGC]
    done_when:
      - "App Store pkg + ReviewerNotes.md"
      - "DMG notarized and stapled"


⸻

Appendix A — API Unit Budget (for Dev Dashboard)

Keep this table live in your repo wiki; agents can render it in a quota panel.

Method	Units	Notes
search.list	100	Use sparingly; narrow part + fields.  ￼
videos.list	1	Batch IDs; cache w/ ETags.  ￼
channels.list	1	Cache; avoid repeated calls.  ￼
playlistItems.list	1	Paginate; cache page tokens.  ￼

Default daily quota: 10,000 units; all requests cost ≥1 unit; resets at midnight PT.  ￼

⸻

Appendix B — Reviewer Notes (store with your release artifacts)
	•	Playback uses YouTube IFrame Player in WKWebView; the app does not access YouTube streams outside official services and does not modify or obscure player UI/ads.  ￼
	•	UGC safeguards present: report link to YouTube reporting, channel hide/blacklist, policy & contact pages.  ￼
	•	No downloading/converting/saving of YouTube content; only metadata/thumbnails cached.  ￼
	•	Branding complies with YouTube branding guidelines; app name/icon avoid “YouTube”; includes “not affiliated” disclaimer.  ￼

⸻

Appendix C — References (pin these in repo)
	•	YouTube IFrame Player API (controls & events).  ￼
	•	YouTube API Services Terms & Developer Policies (playback, data handling).  ￼
	•	Required Minimum Functionality (embedded player expectations).  ￼
	•	Data API quota & costs (10k/day; search.list=100).  ￼
	•	App Store Review Guidelines (UGC 1.2; IP/downloading 5.2.3).  ￼
	•	Branding Guidelines (name/icon/attribution).  ￼
	•	Core ML (on-device ML; privacy & performance).  ￼

⸻

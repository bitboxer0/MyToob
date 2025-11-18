# Epic 2: YouTube OAuth & Data API Integration

**Goal:** Enable users to authenticate with their YouTube account and retrieve metadata (subscriptions, playlists, video details) via the official YouTube Data API v3. This epic establishes the compliant integration pattern with OAuth, token management, quota budgeting, and efficient caching—all foundational to YouTube features without violating ToS.

## Story 2.1: Google OAuth Authentication Flow

As a **user**,
I want **to sign in with my Google account to access YouTube data**,
so that **the app can retrieve my subscriptions, playlists, and viewing history**.

**Acceptance Criteria:**
1. OAuth 2.0 flow implemented using `ASWebAuthenticationSession` (native macOS authentication UI)
2. OAuth scopes requested: `https://www.googleapis.com/auth/youtube.readonly` (minimal scope)
3. OAuth credentials (client ID, client secret) stored securely (not hardcoded, loaded from config file excluded from repo)
4. Authorization code exchange implemented to obtain access token and refresh token
5. Tokens stored securely in macOS Keychain with appropriate access controls
6. User shown clear explanation of what data the app will access before OAuth redirect
7. OAuth flow cancellable by user without app crash
8. Success/failure states handled gracefully with user-friendly error messages

## Story 2.2: Token Storage & Automatic Refresh

As a **developer**,
I want **OAuth tokens securely stored in Keychain with automatic refresh when expired**,
so that **users remain authenticated without repeated sign-ins**.

**Acceptance Criteria:**
1. Keychain wrapper created for storing/retrieving access token and refresh token
2. Token expiry time tracked (typically 3600 seconds for access token)
3. Before each API call, check if access token is expired (within 5-minute buffer)
4. If expired, automatically refresh using refresh token via OAuth token endpoint
5. If refresh fails (invalid refresh token), prompt user to re-authenticate
6. "Sign Out" action in Settings clears all tokens from Keychain
7. Unit tests verify token refresh logic with mocked OAuth endpoints

## Story 2.3: YouTube Data API Client Foundation

As a **developer**,
I want **a strongly-typed API client for YouTube Data API v3 endpoints**,
so that **I can reliably fetch metadata with proper error handling**.

**Acceptance Criteria:**
1. API client created using `URLSession` with async/await
2. Base URL configured: `https://www.googleapis.com/youtube/v3/`
3. API client automatically injects OAuth access token in `Authorization: Bearer` header
4. Typed request/response models created for key endpoints: `search.list`, `videos.list`, `channels.list`, `playlists.list`, `playlistItems.list`
5. Error handling for HTTP status codes: 401 (unauthorized, trigger token refresh), 403 (quota exceeded), 429 (rate limit), 5xx (server error)
6. API responses parsed into Swift structs (Codable)
7. Unit tests with mocked HTTP responses verify parsing and error handling

## Story 2.4: ETag-Based Caching for Metadata

As a **developer**,
I want **ETag-based caching with If-None-Match headers to minimize API quota usage**,
so that **repeated requests for the same data don't consume quota unnecessarily**.

**Acceptance Criteria:**
1. Caching layer stores API responses keyed by request URL + parameters
2. When response includes `ETag` header, cache stores both ETag and response body
3. On subsequent requests, include `If-None-Match: <cached-ETag>` header
4. If server returns `304 Not Modified`, use cached response body (no quota charge)
5. If server returns `200 OK` with new data, update cache with new ETag and body
6. Cache eviction policy: LRU with 1000-item limit or 7-day TTL, whichever comes first
7. Cache hit rate logged for performance monitoring (goal: >90% hit rate on repeated refreshes)

## Story 2.5: API Quota Budgeting & Circuit Breaker

As a **developer**,
I want **per-endpoint quota budgeting with circuit breaker pattern on 429 errors**,
so that **the app doesn't exhaust the user's daily API quota**.

**Acceptance Criteria:**
1. Quota cost table defined for each endpoint: `search.list` = 100 units, `videos.list` = 1 unit, etc. (per YouTube docs)
2. Quota budget tracker increments consumed units per request (reset daily at midnight PT)
3. Before each request, check if budget would exceed daily limit (10,000 units default)
4. If quota would be exceeded, return cached data or show user warning ("Daily API limit reached, showing cached data")
5. On 429 response, implement exponential backoff: retry after 1s, 2s, 4s, 8s (max 3 retries)
6. Circuit breaker opens after 5 consecutive 429s (blocks further requests for 1 hour)
7. Dev-only quota dashboard shows real-time unit consumption per endpoint (removed in release builds)

## Story 2.6: Import User Subscriptions

As a **user**,
I want **to import my YouTube subscriptions into the app**,
so that **I can organize and search videos from channels I follow**.

**Acceptance Criteria:**
1. "Import Subscriptions" button in YouTube section of sidebar
2. Calls `subscriptions.list` API with pagination (50 results per page)
3. For each subscription, fetches channel metadata: `channelID`, `title`, `thumbnailURL`
4. Creates `VideoItem` entries for recent uploads from each channel (optional: calls `channels.list` to get `uploads` playlist ID, then `playlistItems.list`)
5. Progress indicator shows import status ("Importing subscriptions: 45/120 channels...")
6. Handles API errors gracefully (quota exceeded, network failure)—user can retry
7. Import can be paused/resumed (stores state in SwiftData)
8. After import, subscriptions appear in sidebar under "YouTube > Subscriptions"

---

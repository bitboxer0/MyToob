# External APIs

## YouTube Data API v3

- **Purpose:** Retrieve metadata for YouTube videos, channels, playlists, subscriptions
- **Documentation:** https://developers.google.com/youtube/v3
- **Base URL:** `https://www.googleapis.com/youtube/v3/`
- **Authentication:** OAuth 2.0 (youtube.readonly scope) + API Key
- **Rate Limits:** 10,000 quota units/day (default, can request increase); search.list=100 units, videos.list=1 unit

**Key Endpoints Used:**
- `GET /subscriptions` - List user's subscriptions (1 unit)
- `GET /playlistItems` - Get videos in playlist (1 unit)
- `GET /videos` - Fetch video metadata (1 unit, batchable up to 50 IDs)
- `GET /search` - Search YouTube videos (100 units, use sparingly)
- `GET /channels` - Get channel info (1 unit)

**Integration Notes:**
- Always use ETag headers with If-None-Match to minimize quota consumption
- Apply field filtering (part= and fields= parameters) to reduce payload size
- Batch video.list requests when fetching multiple videos (up to 50 per request)
- Implement quota budget tracker: warn at 80%, block at 100%
- Circuit breaker on 429 responses: exponential backoff (1s, 2s, 4s, 8s)

---

## YouTube IFrame Player API

- **Purpose:** Embed YouTube player in WKWebView for compliant video playback
- **Documentation:** https://developers.google.com/youtube/iframe_api_reference
- **Base URL:** `https://www.youtube.com/iframe_api`
- **Authentication:** None (public API)
- **Rate Limits:** None

**Key Endpoints Used:**
- Embed player: `<iframe src="https://www.youtube.com/embed/{videoID}?enablejsapi=1">`
- JavaScript API: `player.playVideo()`, `player.pauseVideo()`, `player.seekTo(seconds)`
- Events: `onStateChange`, `onReady`, `onError`

**Integration Notes:**
- Load IFrame Player API script in embedded HTML page
- JavaScript ↔ Swift bridge via WKScriptMessageHandler for bidirectional communication
- Player parameters: `controls=1` (show controls), `modestbranding=1`, `rel=0` (no related from other channels)
- **Compliance:** Never modify/overlay player UI or ads, respect Required Minimum Functionality
- Pause playback when window hidden/minimized (unless PiP active)

---

## Google OAuth 2.0

- **Purpose:** Authenticate user for YouTube Data API access
- **Documentation:** https://developers.google.com/identity/protocols/oauth2
- **Authorization URL:** `https://accounts.google.com/o/oauth2/v2/auth`
- **Token URL:** `https://oauth2.googleapis.com/token`
- **Scopes:** `https://www.googleapis.com/auth/youtube.readonly`

**Integration Notes:**
- Use ASWebAuthenticationSession for native macOS OAuth flow
- Store access token (expires ~3600s) and refresh token in Keychain
- Automatic token refresh when access token expired (5-minute buffer)
- Client ID/secret stored in secure config (not committed to repo)

---

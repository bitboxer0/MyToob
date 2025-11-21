# OAuth Setup Instructions for MyToob

## Prerequisites

1. **Google Cloud Console Setup:**
   - Go to https://console.cloud.google.com/apis/credentials
   - Create a new OAuth 2.0 Client ID
   - Application type: **macOS** (or Desktop App)
   - Copy the Client ID and Client Secret

2. **Update OAuth Credentials:**
   - Copy `.env.example` to `.env` in the project root
   - Edit `.env` and add your actual credentials:
     ```
     GOOGLE_OAUTH_CLIENT_ID=YOUR_ACTUAL_CLIENT_ID_HERE.apps.googleusercontent.com
     GOOGLE_OAUTH_CLIENT_SECRET=YOUR_ACTUAL_SECRET_HERE
     ```
   - The `.env` file is gitignored and will not be committed

## Xcode Configuration

### 1. Add Files to Project

Add these new files to the MyToob target:
- `MyToob/Core/Utilities/Configuration.swift`
- `MyToob/Core/Security/KeychainService.swift`
- `MyToob/Features/YouTube/OAuth2Handler.swift`
- `MyToob/Features/YouTube/OAuthConsentView.swift`

### 2. Configure Custom URL Scheme

**Required for OAuth redirect callback:**

1. Open MyToob.xcodeproj in Xcode
2. Select the MyToob target
3. Go to the **Info** tab
4. Expand **URL Types**
5. Click **+** to add a new URL Type
6. Configure:
   - **Identifier:** `com.yourcompany.mytoob.oauth`
   - **URL Schemes:** `com.googleusercontent.apps.YOUR-CLIENT-ID` 
     - Replace `YOUR-CLIENT-ID` with your actual Google OAuth Client ID
     - Example: `com.googleusercontent.apps.123456789-abcdefg.apps.googleusercontent.com`
   - **Role:** Editor

### 3. Update Configuration.swift Redirect URI

After adding the URL scheme, update `Configuration.googleOAuthRedirectURI` in `Configuration.swift`:

```swift
static var googleOAuthRedirectURI: String {
  // Replace YOUR-CLIENT-ID with your actual client ID
  "com.googleusercontent.apps.YOUR-CLIENT-ID:/oauth2redirect"
}
```

### 4. Set Environment Variable (Optional)

For development, you can set the `PROJECT_DIR` environment variable in Xcode to point to the project root (for .env file loading):

1. Edit Scheme (Product > Scheme > Edit Scheme)
2. Select **Run** > **Arguments**
3. Add Environment Variable:
   - Name: `PROJECT_DIR`
   - Value: `/Users/YOUR_USERNAME/path/to/MyToob`

Alternatively, credentials can be passed via environment variables directly without a `.env` file:
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`

## Testing the OAuth Flow

1. **Build and Run** the app
2. Click **"Connect YouTube Account"** in the sidebar
3. Review the consent screen
4. Click **"Continue to Google"**
5. You should see the Google authorization page in a browser
6. Authorize the app
7. The browser should redirect back to MyToob
8. Tokens will be stored securely in the Keychain

## Troubleshooting

### "OAuth configuration is invalid" error
- Check that `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` are set correctly
- Verify `.env` file is in the project root
- Verify `PROJECT_DIR` environment variable is set (if using .env)

### OAuth redirect doesn't work
- Verify the custom URL scheme is added correctly in Xcode (Info tab)
- Verify the redirect URI in `Configuration.swift` matches the URL scheme
- Verify the redirect URI in Google Cloud Console matches exactly

### "Authorization cancelled" message
- User clicked "Cancel" in the Google authorization screen
- This is expected behavior - user can try again

## Security Notes

- ✅ `.env` file is gitignored and will not be committed
- ✅ Tokens are stored in macOS Keychain with `kSecAttrAccessibleWhenUnlocked`
- ✅ All OAuth traffic uses HTTPS
- ✅ Minimal scope requested: `youtube.readonly`
- ✅ SwiftLint rules enforce no hardcoded secrets
- ✅ SwiftLint rules enforce use of KeychainService wrapper

## Next Steps

After OAuth is working:
- Story 2.2: Token refresh and expiration handling (already implemented in OAuth2Handler)
- Story 2.3: YouTube Data API client implementation
- Story 2.4: Fetch user's YouTube subscriptions and playlists

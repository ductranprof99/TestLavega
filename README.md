# README

## Overview
This is a minimal SwiftUI iOS app that implements **Google Sign-In with OAuth 2.0 + PKCE** using **ASWebAuthenticationSession** (no third-party SDKs).  
It securely stores tokens in **Keychain**, auto-restores sessions, refreshes access tokens when needed, and shows a simple profile screen.

## How the app works

### Flow
1. **App launch**
   - Check Keychain for a saved `AuthState` (access token, expiry, optional refresh token).
   - If token is **valid** → go straight to **Profile**.
   - If token is **expired** and there’s a **refresh token** → refresh and continue.
   - Otherwise → show **Login with Google** screen.

2. **Login (ASWebAuthenticationSession + PKCE)**
   - Generate `code_verifier` & `code_challenge` (S256).
   - Open Google auth URL with `response_type=code`, `client_id`, `redirect_uri`, `scope=openid email profile`, `state`, `code_challenge`.
   - On callback, verify `state` and extract `code`.

3. **Token exchange**
   - POST to Google `/token` with `authorization_code` + `code_verifier`.
   - Save `access_token`, `expires_in` (→ `expiryDate`), and `refresh_token` (if present) to **Keychain**.

4. **Fetch profile**
   - Call OpenID `/userinfo` with `Bearer <access_token>` and display **name, email, avatar**.

5. **Auto refresh & 401 handling**
   - If `/userinfo` returns `401`, mark `expiryDate = .distantPast`, refresh once, and retry.

6. **Logout**
   - Delete Keychain entries and reset UI state.

### Architecture (files)
- `GoogleOAuthConfig.swift` — endpoints, scopes, **clientID** and **redirectURI**
- `KeychainHelper.swift` — simple save/load/delete wrappers
- `Models.swift` — `TokenResponse`, `AuthState`, `UserProfile`
- `AuthManager.swift` — all auth logic (PKCE, web auth session, token exchange/refresh, userinfo)
- `ContentView.swift` — switches between Login and Profile views
- `App.swift` — SwiftUI app entry

---

## Setup

1. **Create an iOS OAuth Client in Google Cloud Console**
   - APIs & Services → Credentials → **Create Credentials → OAuth client ID → iOS**
   - Use your app **Bundle ID**.
   - Note the generated:
     - **CLIENT_ID**: `xxxx.apps.googleusercontent.com`
     - **REVERSED_CLIENT_ID** (iOS URL scheme): `com.googleusercontent.apps.xxxx`

2. **Fill config in code**
   ```swift
   enum GoogleOAuthConfig {
       static let clientID    = "<YOUR_CLIENT_ID>.apps.googleusercontent.com"
       static let redirectURI = "com.googleusercontent.apps.<YOUR_CLIENT_ID_WITHOUT_DOMAIN>:/oauthredirect"
   }
   ```

3. **Register URL Scheme in Xcode**
   - Target → **Info** → **URL Types** → **+**
   - **URL Schemes** = `com.googleusercontent.apps.<YOUR_CLIENT_ID_WITHOUT_DOMAIN>`

4. **(Optional) Use Google’s provided plist**
   - If you have a file like `client_<id>.apps.googleusercontent.com.plist`, it contains:
     - `CLIENT_ID`
     - `REVERSED_CLIENT_ID`
     - `BUNDLE_ID`
   - It’s a convenience reference; you still must set **URL Types** manually.

5. **Minimum requirements**
   - iOS 15+
   - Swift 5.9+
   - Frameworks: `AuthenticationServices`, `CryptoKit`, `SwiftUI`

---

## Troubleshooting
- **`redirect_uri_mismatch`** — Use the iOS client’s reversed scheme + `:/oauthredirect` (not a web client).
- **Login returns immediately without UI** — Ensure URL scheme in **URL Types** matches `REVERSED_CLIENT_ID` exactly.
- **401 after login** — We invalidate `expiryDate` and refresh once; verify device time, scopes, and refresh token presence.
- **Nothing happens on button tap** — Ensure `ASWebAuthenticationSession` is retained (property on `AuthManager`).

---

## My development approach (prior experience + how I sped things up)

I’ve implemented OAuth/SSO on iOS multiple times (Google, Apple, Facebook). For this exercise I reused proven patterns:

- A lean `AuthManager` isolating PKCE, token exchange, refresh, and `/userinfo`.
- A minimal `KeychainHelper` for secure token storage.
- A reliable `ASWebAuthenticationSession` setup with `presentationContextProvider` and `state` verification.

**How I prompted with ChatGPT to speed up coding**
- Wrote focused prompts like: “SwiftUI Google OAuth with PKCE using ASWebAuthenticationSession (no SDKs), Keychain storage, token refresh, and `/userinfo`. Split into files.”
- Iterated with small, targeted edits (e.g., fix form URL encoding, add `import UIKit`, make `expiryDate` mutable).
- Validated locally, then requested refinements to reduce boilerplate and keep code idiomatic.

This approach accelerated delivery while keeping the solution native and maintainable.

---

## Thanks
Thanks for reviewing my submission and the opportunity to work on this exercise. I’m happy to extend it with more tests, richer UI, or additional providers (Sign in with Apple) if helpful.

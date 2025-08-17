//
//  AuthManager.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//


import Foundation
import AuthenticationServices
import CryptoKit
import SwiftUI
import UIKit

@MainActor
final class AuthManager: NSObject, ObservableObject {
    // UI state
    @Published var isLoading = false
    @Published var user: UserProfile?
    @Published var errorMessage: String?

    // Token state
    private var authState: AuthState? {
        didSet { saveAuthState() }
    }

    // PKCE + session
    private var currentState = ""
    private var codeVerifier = ""
    private var session: ASWebAuthenticationSession?
    private let accountKey = "google.oauth.state"
    private let urlSession = URLSession(configuration: .default)

    // MARK: - Public API
    func restoreSession() {
        Task {
            do {
                if let data = try KeychainHelper.load(account: accountKey) {
                    let state = try JSONDecoder().decode(AuthState.self, from: data)
                    self.authState = state
                    try await ensureValidToken()
                    try await fetchUserInfo()
                }
            } catch {
                self.authState = nil
                self.user = nil
            }
        }
    }

    func login() {
        isLoading = true
        errorMessage = nil

        let (verifier, challenge) = Self.makeCodeVerifierAndChallenge()
        self.codeVerifier = verifier
        self.currentState = Self.randomURLSafe(length: 24)

        var comps = URLComponents(url: GoogleOAuthConfig.authEndpoint, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: GoogleOAuthConfig.clientID),
            .init(name: "redirect_uri", value: GoogleOAuthConfig.redirectURI),
            .init(name: "scope", value: GoogleOAuthConfig.scopes.joined(separator: " ")),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "state", value: currentState),
            .init(name: "access_type", value: "offline"),
            .init(name: "prompt", value: "consent")
        ]

        guard let authURL = comps.url else {
            self.isLoading = false
            self.errorMessage = "Invalid auth URL."
            return
        }

        let scheme = URL(string: GoogleOAuthConfig.redirectURI)!.scheme
        session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: scheme
        ) { [weak self] callbackURL, error in
            guard let self else { return }
            Task { await self.handleAuthCallback(callbackURL: callbackURL, error: error) }
        }
        session?.presentationContextProvider = self
        session?.prefersEphemeralWebBrowserSession = false
        _ = session?.start()
    }

    func logout() {
        KeychainHelper.delete(account: accountKey)
        authState = nil
        user = nil
    }

    // MARK: - Internals

    private func handleAuthCallback(callbackURL: URL?, error: Error?) async {
        defer { self.isLoading = false }

        if let err = error as? ASWebAuthenticationSessionError, err.code == .canceledLogin {
            self.errorMessage = "Login canceled."
            return
        } else if let error = error {
            self.errorMessage = error.localizedDescription
            return
        }

        guard
            let url = callbackURL,
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let items = comps.queryItems
        else {
            self.errorMessage = "Invalid callback."
            return
        }

        if let err = items.first(where: { $0.name == "error" })?.value {
            self.errorMessage = "Auth error: \(err)"
            return
        }

        guard
            let returnedState = items.first(where: { $0.name == "state" })?.value,
            returnedState == currentState,
            let code = items.first(where: { $0.name == "code" })?.value
        else {
            self.errorMessage = "State mismatch or missing code."
            return
        }

        do {
            try await exchangeCodeForToken(code: code)
            try await fetchUserInfo()
        } catch {
            self.errorMessage = "Auth failed: \(error.localizedDescription)"
        }
    }

    private func exchangeCodeForToken(code: String) async throws {
        var req = URLRequest(url: GoogleOAuthConfig.tokenEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": GoogleOAuthConfig.clientID,
            "redirect_uri": GoogleOAuthConfig.redirectURI,
            "code_verifier": codeVerifier
        ]
        req.httpBody = body.percentFormEncoded().data(using: .utf8)

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "TokenExchange", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errText])
        }

        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        let expiry = Date().addingTimeInterval(TimeInterval(token.expires_in))
        self.authState = AuthState(
            accessToken: token.access_token,
            expiryDate: expiry,
            refreshToken: token.refresh_token
        )
    }

    private func ensureValidToken() async throws {
        guard var state = self.authState else { return }
        if state.expiryDate > Date().addingTimeInterval(60) { return } // still valid

        guard let refresh = state.refreshToken else {
            throw URLError(.userAuthenticationRequired)
        }

        // Refresh
        var req = URLRequest(url: GoogleOAuthConfig.tokenEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": GoogleOAuthConfig.clientID
        ]
        req.httpBody = body.percentFormEncoded().data(using: .utf8)

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.userAuthenticationRequired)
        }
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        state = AuthState(
            accessToken: token.access_token,
            expiryDate: Date().addingTimeInterval(TimeInterval(token.expires_in)),
            refreshToken: state.refreshToken ?? token.refresh_token
        )
        self.authState = state
    }

    private func fetchUserInfo() async throws {
        try await ensureValidToken()
        guard let token = authState?.accessToken else { throw URLError(.userAuthenticationRequired) }

        var req = URLRequest(url: GoogleOAuthConfig.userInfoURL)
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await urlSession.data(for: req)

        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 401 { // try refresh once
            self.authState?.expiryDate = .distantPast
            try await ensureValidToken()
            return try await fetchUserInfo()
        }
        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.cannotParseResponse)
        }

        struct GoogleUser: Decodable {
            let name: String
            let email: String
            let picture: String?
        }
        let g = try JSONDecoder().decode(GoogleUser.self, from: data)
        self.user = UserProfile(name: g.name, email: g.email, picture: g.picture.flatMap(URL.init(string:)))
    }

    private func saveAuthState() {
        do {
            if let state = authState {
                let data = try JSONEncoder().encode(state)
                try KeychainHelper.save(data, account: accountKey)
            } else {
                KeychainHelper.delete(account: accountKey)
            }
        } catch {
            self.errorMessage = "Keychain error: \(error.localizedDescription)"
        }
    }

    // MARK: - PKCE helpers
    private static func makeCodeVerifierAndChallenge() -> (verifier: String, challenge: String) {
        let verifier = randomURLSafe(length: 64)
        let hash = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(hash).base64URLEncodedString()
        return (verifier, challenge)
    }

    fileprivate static func randomURLSafe(length: Int) -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            result.append(chars[Int.random(in: 0..<chars.count)])
        }
        return result
    }
}

// MARK: - Helpers

private extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension Dictionary where Key == String, Value == String {
    func percentFormEncoded() -> String {
        map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(k)=\(v)"
        }
        .joined(separator: "&")
    }
}

// MARK: - ASWebAuthentication presentation anchor

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        return scenes.first?.keyWindow ?? ASPresentationAnchor()
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first { $0.isKeyWindow } }
}

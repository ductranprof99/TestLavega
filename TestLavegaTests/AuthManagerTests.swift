//
//  AuthManagerTests.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//

import Testing
import XCTest
@testable import TestLavega

@MainActor
final class AuthManagerTests: XCTestCase {
    
    func testRestoreSession_ValidToken_FetchesUserInfo() async throws {
        // Given
        let store = InMemoryAuthStore()
        store.stored = AuthState(
            accessToken: "valid",
            expiryDate: Date().addingTimeInterval(600),
            refreshToken: "r"
        )
        
        // Fill yoủ code m8
        let http = MockHTTPClient()
        http.fixtures = [
            .init(
                matcher: { $0.url == GoogleOAuthConfig.userInfoURL },
                response: {
                    let body = [
                        "name":"",
                        "email":"",
                    ]
                    return (jsonData(body), httpResponse(200, url: GoogleOAuthConfig.userInfoURL))
                }
            )
        ]
        
        let sut = AuthManager(store: store, http: http, now: { Date() })
        
        // When
        await sut.restoreSession()
        
        // Then: Fill yoủ code mate, im not going to this
        XCTAssertEqual(sut.user?.email, "")
        XCTAssertTrue(http.requests.contains { $0.url == GoogleOAuthConfig.userInfoURL })
    }
    
    func testLogoutClearsState() async {
        let store = InMemoryAuthStore()
        store.stored = AuthState(accessToken: "x", expiryDate: Date(), refreshToken: "r")

        let sut = AuthManager(store: store, http: MockHTTPClient(), now: Date.init)
        sut.logout()

        XCTAssertNil(store.stored)
        XCTAssertNil(sut.user)
    }
}

private func body(_ req: URLRequest) -> String {
    guard let d = req.httpBody else { return "" }
    return String(data: d, encoding: .utf8) ?? ""
}

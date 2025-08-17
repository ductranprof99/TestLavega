//
//  TokenResponseTests.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//

import Testing
import XCTest
@testable import TestLavega

final class TokenResponseTests: XCTestCase {
    func testDecodeToken() throws {
        let data = """
        {"access_token":"abc","expires_in":3600,"token_type":"Bearer","scope":"openid email profile","refresh_token":"r","id_token":"i"}
        """.data(using: .utf8)!
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        XCTAssertEqual(token.access_token, "abc")
        XCTAssertEqual(token.expires_in, 3600)
        XCTAssertEqual(token.token_type, "Bearer")
        XCTAssertEqual(token.refresh_token, "r")
    }
}

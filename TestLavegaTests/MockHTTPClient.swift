//
//  MockHTTPClient.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//


import XCTest
@testable import TestLavega

// MARK: - Mocks

final class MockHTTPClient: HTTPClient {
    struct Fixture {
        let matcher: (URLRequest) -> Bool
        let response: () -> (Data, HTTPURLResponse)
    }
    var fixtures: [Fixture] = []
    private(set) var requests: [URLRequest] = []

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        if let fx = fixtures.first(where: { $0.matcher(request) }) {
            let (d, r) = fx.response()
            return (d, r)
        }
        throw URLError(.badURL)
    }
}

final class InMemoryAuthStore: AuthStore {
    var stored: AuthState?
    func load() throws -> AuthState? { stored }
    func save(_ state: AuthState?) throws { stored = state }
}

// Helpers
func httpResponse(_ code: Int, url: URL) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
}

func jsonData(_ obj: Any) -> Data {
    try! JSONSerialization.data(withJSONObject: obj, options: [])
}
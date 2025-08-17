//
//  HTTPClient.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//

import Foundation


// HTTP client seam
protocol HTTPClient {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionHTTPClient: HTTPClient {
    let session: URLSession = .shared
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

// Persistence seam for AuthState
protocol AuthStore {
    func load() throws -> AuthState?
    func save(_ state: AuthState?) throws
}

struct KeychainAuthStore: AuthStore {
    private let accountKey: String
    init(accountKey: String) { self.accountKey = accountKey }
    func load() throws -> AuthState? {
        if let data = try KeychainHelper.load(account: accountKey) {
            return try JSONDecoder().decode(AuthState.self, from: data)
        }
        return nil
    }
    func save(_ state: AuthState?) throws {
        if let state {
            let data = try JSONEncoder().encode(state)
            try KeychainHelper.save(data, account: accountKey)
        } else {
            KeychainHelper.delete(account: accountKey)
        }
    }
}

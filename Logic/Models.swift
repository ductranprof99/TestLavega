//
//  Models.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//


import Foundation

struct TokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let token_type: String
    let scope: String?
    let refresh_token: String?
    let id_token: String?
}

struct AuthState: Codable {
    let accessToken: String
    var expiryDate: Date
    let refreshToken: String?
}

struct UserProfile: Codable, Equatable {
    let name: String
    let email: String
    let picture: URL?
}

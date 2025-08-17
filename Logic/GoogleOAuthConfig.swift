//
//  GoogleOAuthConfig.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//


import Foundation

enum GoogleOAuthConfig {
    // MARK: - Credentials
    // TODO: Fill key here
    static let clientID      = "TODO"
    static let redirectURI   = "TODO"
    static let authEndpoint  = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    static let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token")!
    static let userInfoURL   = URL(string: "https://openidconnect.googleapis.com/v1/userinfo")!

    // Request scopes (layout yo)
    static let scopes        = ["openid", "email", "profile"]
}

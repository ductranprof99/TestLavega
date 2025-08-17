//
//  ContentView.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var auth = AuthManager()
    
    var body: some View {
        Group {
            if let user = auth.user {
                UserInfoView(user: user) { auth.logout() }
            } else {
                LoginView(isLoading: auth.isLoading,
                          error: auth.errorMessage,
                          onLogin: { auth.login() })
            }
        }
        .onAppear { auth.restoreSession() }
    }
}

#Preview {
    ContentView()
}

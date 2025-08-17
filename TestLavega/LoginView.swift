//
//  LoginView.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//

import SwiftUI

struct LoginView: View {
    let isLoading: Bool
    let error: String?
    let onLogin: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Welcome").font(.largeTitle).bold()

            if isLoading { ProgressView().scaleEffect(1.2) }

            Button(action: onLogin) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                    Text("Login with Google").bold()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isLoading)
            .padding(.horizontal)

            if let error = error {
                Text(error).foregroundColor(.red).font(.footnote).multilineTextAlignment(.center).padding(.horizontal)
            }
            Spacer()
        }
    }
}

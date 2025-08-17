//
//  UserInfoView.swift
//  TestLavega
//
//  Created by Duc Tran  on 17/8/25.
//

import SwiftUI

struct UserInfoView: View {
    let user: UserProfile
    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            if let url = user.picture {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: { ProgressView() }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .shadow(radius: 8)
            } else {
                Image(systemName: "person.circle.fill").resizable().frame(width: 120, height: 120).foregroundStyle(.secondary)
            }
            Text(user.name).font(.title2).bold()
            Text(user.email).foregroundStyle(.secondary)

            Button(role: .destructive, action: onLogout) {
                Text("Logout").bold()
            }
            .padding(.top, 12)
            Spacer()
        }
        .padding()
    }
}

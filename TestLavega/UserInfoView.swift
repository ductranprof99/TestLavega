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
                .frame(height: 30)
            
            Text("User Info")
                .font(.largeTitle)
                .foregroundStyle(Color.black)
            
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
                HStack(spacing: 12) {
                    Text("Sign Out").bold()
                        .foregroundStyle(Color.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 12)
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding()
    }
}

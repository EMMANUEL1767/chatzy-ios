//
//  SelectedUserBubble.swift
//  chatzy
//
//  Created by Emmanuel Biju on 22/12/24.
//

import SwiftUI

struct SelectedUserBubble: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            
            Text(user.username)
                .font(.subheadline)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.2))
        )
    }
}

struct UserRow: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}


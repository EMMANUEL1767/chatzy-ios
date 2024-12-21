//
//  MessageBubble.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private var isCurrentUser: Bool {
        message.senderId == authViewModel.currentUser?.id
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading) {
                Text(message.content)
                    .padding()
                    .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(20)
                
                Text(message.senderName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if isCurrentUser {
                    HStack {
                        switch message.status {
                        case .sent:
                            Image(systemName: "checkmark")
                        case .delivered:
                            Image(systemName: "checkmark.circle")
                        case .read:
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .foregroundColor(.gray)
                }
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

#Preview {
    MessageBubble(message: Message(id: 1, conversationId: 1, senderId: 1, content: "test message", status: .delivered, createdAt: .now, senderName: "Rahul"))
        .environmentObject(AuthViewModel())
}

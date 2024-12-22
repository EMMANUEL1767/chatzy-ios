//
//  ConversationRow.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(conversation.displayName)
                    .font(.headline)
                Spacer()
                if (conversation.unreadCount ?? 0) > 0 {
                    Text("\(conversation.unreadCount ?? 0)")
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            
            if let lastMessage = conversation.lastMessage {
                Text(lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            } else {
                Text("Send \"Hi\" to start a conversation")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConversationRow(conversation: Conversation(
            id: 1,
            name: "Test Group",
            type: .group,
            createdAt: "2024-12-21 16:05:58",
            lastMessage: "Hello World",
            lastMessageTime: "2024-12-21 16:05:58",
            lastMessageSenderId: 1,
            lastMessageSenderName: "User",
            participantCount: 3,
            unreadCount: 2,
            participants: [
                User(id: 1, username: "User1", email: "user1@example.com", createdAt: ""),
                User(id: 2, username: "User2", email: "user2@example.com", createdAt: "")
            ]
        ))
        .padding()
}

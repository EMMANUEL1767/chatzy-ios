//
//  ConversationRow.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatViewModel()
    
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(conversation.displayName)
                    .font(.headline)
                
                Spacer()
                
                if let lastMessageTime = DateUtils.getDate(from: conversation.lastMessageTime ?? "") {
                    Text(lastMessageTime.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                if !viewModel.typingUsers.isEmpty {
                    // Show typing indicator
                    HStack(spacing: 4) {
                        Text(typingIndicatorText)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .italic()
                        
                        // Animated dots
                        TypingDotsView()
                    }
                } else if let lastMessage = conversation.lastMessage {
                    // Show last message with status
                    HStack(spacing: 4) {
                        if conversation.type == .group && conversation.lastMessageSenderName != nil {
                            Text("\(conversation.lastMessageSenderName!): ")
                                .foregroundColor(.gray)
                        }
                        
                        Text(lastMessage)
                            .lineLimit(1)
                            .foregroundColor(.gray)
                        
                        
                    }
                } else {
                    Text("Send \"Hi\" to start a conversation")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if (conversation.unreadCount ?? 0) > 0 {
                    Text("\(conversation.unreadCount ?? 0)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            viewModel.observeTyping(for: conversation.id)
        }
        .onDisappear {
            viewModel.stopObservingTyping(for: conversation.id)
        }
    }
    
    private var typingIndicatorText: String {
        switch viewModel.typingUsers.count {
        case 0: return ""
        case 1: return "\(viewModel.typingUsers.first!) is typing"
        case 2: return "\(viewModel.typingUsers.joined(separator: " and ")) are typing"
        default: return "Several people are typing"
        }
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

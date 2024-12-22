//
//  ChatDetailView.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI

struct ChatDetailView: View {
    let conversation: Conversation
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.currentMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.currentMessages) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.currentMessages.last?.id)
                    }
                }
            }
            
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                
                Button(action: {
                    Task { await sendMessage() }
                }) {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding()
        }
        .navigationTitle(conversation.displayName)
        .task {
            await viewModel.joinConversation(conversation.id)
        }
        .onChange(of: isFocused) { focused in
            viewModel.updateTypingStatus(isTyping: focused)
        }
    }
    
    private func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        await viewModel.sendMessage(messageText)
        messageText = ""
    }
}

#Preview {
    ChatDetailView(conversation: Conversation(
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
}

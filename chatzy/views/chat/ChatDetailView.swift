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
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding()
        }
        .navigationTitle(conversation.name ?? "Chat")
        .task {
            await viewModel.joinConversation(conversation.id)
        }
        .onChange(of: isFocused) { focused in
            viewModel.updateTypingStatus(isTyping: focused)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(messageText)
        messageText = ""
    }
}

#Preview {
    ChatDetailView(conversation: Conversation(id: 4, name: "Test", type: .direct, participants: [], lastMessage: nil, createdAt: Date.now, unreadCount: 5))
}

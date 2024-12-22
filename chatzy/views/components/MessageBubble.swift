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
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 12) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
                    
                    
                    Text(message.content)
                    
                    HStack(spacing: 8) {
                        if message.status != .failed {
                            Text(DateUtils.getDate(from: message.createdAt ?? "")?.formatMessageTime() ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Failed")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if isCurrentUser {
                            HStack {
                                switch message.status {
                                case .sent:
                                    Image("tick")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(height: 10)
                                        .foregroundColor(.gray)
                                case .delivered:
                                    Image("two-tick")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(height: 10)
                                        .foregroundColor(.gray)
                                case .read:
                                    Image("two-tick")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(height: 10)
                                        .foregroundColor(.blue)
                                case .failed:
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: false)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isCurrentUser ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

#Preview {
    MessageBubble(message: Message(id: 1, conversationId: 1, senderId: 1, content: "test message", status: .delivered, createdAt: "", senderName: "Rahul"))
        .environmentObject(AuthViewModel())
}

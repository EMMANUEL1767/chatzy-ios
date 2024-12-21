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
                Text(conversation.name ?? "")
                    .font(.headline)
                Spacer()
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            
            if let lastMessage = conversation.lastMessage {
                Text(lastMessage.content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConversationRow(conversation: Conversation(id: 4, name: "Test", type: .direct, participants: [], lastMessage: nil, createdAt: Date.now, unreadCount: 5))
}

//
//  Conversation.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

struct Conversation: Codable, Identifiable {
    let id: Int
    let name: String?
    let type: ConversationType
    let createdAt: String?
    let lastMessage: String?
    let lastMessageTime: String?
    let lastMessageSenderId: Int?
    let lastMessageSenderName: String?
    let participantCount: Int?
    let unreadCount: Int?
    let participants: [User]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case createdAt = "created_at"
        case lastMessage = "last_message"
        case lastMessageTime = "last_message_time"
        case lastMessageSenderId = "last_message_sender_id"
        case lastMessageSenderName = "last_message_sender_name"
        case participantCount = "participant_count"
        case unreadCount = "unread_count"
        case participants
    }
}

enum ConversationType: String, Codable {
    case direct
    case group
}

extension Conversation {
    var otherParticipants: [User] {
        guard let currentUserId = UserDefaults.standard.userId else {
            return participants
        }
        return participants.filter { $0.id != currentUserId }
    }
    
    var displayName: String {
        if type == .group {
            return name ?? "Group Chat"
        } else {
            return otherParticipants.first?.username ?? "Chat"
        }
    }
    
    var lastActivityDate: Date? {
        guard let timeString = lastMessageTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: timeString)
    }
}

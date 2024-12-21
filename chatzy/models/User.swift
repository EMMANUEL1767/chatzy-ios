//
//  User.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

// Models/User.swift
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt = "created_at"
    }
}

// Models/Conversation.swift
struct Conversation: Codable, Identifiable {
    let id: Int
    let name: String?
    let type: ConversationType
    let participants: [User]
    let lastMessage: Message?
    let createdAt: Date
    var unreadCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case participants
        case lastMessage = "last_message"
        case createdAt = "created_at"
        case unreadCount = "unread_count"
    }
}

enum ConversationType: String, Codable {
    case direct
    case group
}

// Models/Message.swift
struct Message: Codable, Identifiable, Equatable {
    let id: Int
    let conversationId: Int
    let senderId: Int
    let content: String
    var status: MessageStatus
    let createdAt: Date
    let senderName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case status
        case createdAt = "created_at"
        case senderName = "sender_name"
    }
}

enum MessageStatus: String, Codable {
    case sent
    case delivered
    case read
}

// Models/APIResponses.swift
struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct ErrorResponse: Codable {
    let error: String
    let message: String?
}

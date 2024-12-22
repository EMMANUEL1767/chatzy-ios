//
//  Message.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: Int
    let conversationId: Int
    let senderId: Int
    let content: String
    var status: MessageStatus
    let createdAt: String?
    let senderName: String
    var isQueued: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case status
        case createdAt = "created_at"
        case senderName = "sender_name"
        case isQueued = "is_queued"
    }
}

enum MessageStatus: String, Codable {
    case sent
    case delivered
    case read
    case failed
}

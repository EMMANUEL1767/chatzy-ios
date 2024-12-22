//
//  User.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: Int
    let username: String
    let email: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt = "created_at"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


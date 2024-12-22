//
//  ApiResponse.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct ErrorResponse: Codable {
    let error: String
    let message: String?
}

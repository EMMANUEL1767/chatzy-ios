//
//  NetworkService.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

enum Constants {
    static let baseURL = "https://58b5-157-46-1-45.ngrok-free.app/api"
    static let socketURL = "https://58b5-157-46-1-45.ngrok-free.app"
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case decodingError
    case serverError(String)
    case unknown
    case notConnected
}

class NetworkService {
    static let shared = NetworkService()
    private var authToken: String?
    
    private init() {}
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    private func createRequest(_ endpoint: String, method: String, body: [String: Any]? = nil) throws -> URLRequest {
        guard let url = URL(string: Constants.baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        let request = try createRequest(endpoint, method: method, body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                print(String(data: data, encoding: .utf8) ?? "")
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Key '\(key)' not found:", context.debugDescription)
                    case .valueNotFound(let value, let context):
                        print("Value '\(value)' not found:", context.debugDescription)
                    case .typeMismatch(let type, let context):
                        print("Type '\(type)' mismatch:", context.debugDescription)
                    case .dataCorrupted(let context):
                        print("Data corrupted:", context.debugDescription)
                    @unknown default:
                        print("Unknown decoding error:", error)
                    }
                }
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(error.message ?? error.error)
            }
            throw NetworkError.unknown
        }
    }
}


extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
    static let messageStatusUpdated = Notification.Name("messageStatusUpdated")
    static let typingStatusChanged = Notification.Name("typingStatusChanged")
    static let messageError = Notification.Name("messageError")
    static let messageSent = Notification.Name("messageSent")
}

//
//  NetworkService.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

// Services/Constants.swift
enum Constants {
    static let baseURL = "https://58b5-157-46-1-45.ngrok-free.app/api"
    static let socketURL = "https://58b5-157-46-1-45.ngrok-free.app"
}

// Services/NetworkService.swift
import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case decodingError
    case serverError(String)
    case unknown
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

// Services/SocketService.swift
import Foundation
import SocketIO

class SocketService: ObservableObject {
    static let shared = SocketService()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    private init() {}
    
    func connect(token: String) {
        let config: SocketIOClientConfiguration = [
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .log(true),
            .compress
        ]
        
        manager = SocketManager(socketURL: URL(string: Constants.socketURL)!, config: config)
        socket = manager?.defaultSocket
        
        setupEventHandlers()
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
    }
    
    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            self?.isConnected = true
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.isConnected = false
        }
        
        socket?.on("new_message") { data, _ in
            guard let messageData = data.first as? [String: Any] else { return }
            NotificationCenter.default.post(
                name: .newMessageReceived,
                object: nil,
                userInfo: ["messageData": messageData]
            )
        }
    }
    
    func joinConversation(_ conversationId: Int) {
        socket?.emit("join_conversation", conversationId)
    }
    
    func leaveConversation(_ conversationId: Int) {
        socket?.emit("leave_conversation", conversationId)
    }
    
    func sendMessage(_ message: [String: Any], completion: @escaping (Error?) -> Void) {
        socket?.emit("send_message", message) {
            completion(nil)
        }
    }
    
    func startTyping(in conversationId: Int) {
        socket?.emit("typing_start", conversationId)
    }
    
    func stopTyping(in conversationId: Int) {
        socket?.emit("typing_stop", conversationId)
    }
}

extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
    static let messageStatusUpdated = Notification.Name("messageStatusUpdated")
    static let typingStatusChanged = Notification.Name("typingStatusChanged")
}

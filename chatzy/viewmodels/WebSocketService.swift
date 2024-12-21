//
//  WebSocketService.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

actor WebSocketService {
    static let shared = WebSocketService()
    private var socket: URLSessionWebSocketTask?
    private var isConnected = false
    
    private var messageHandlers: [String: (Data) -> Void] = [:]
    
    private init() {}
    
    func connect(token: String) async {
        guard !isConnected else { return }
        
        guard let url = URL(string: "ws://58b5-157-46-1-45.ngrok-free.app") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession(configuration: .default)
        socket = session.webSocketTask(with: request)
        
        isConnected = true
        socket?.resume()
        
        await receiveMessage()
    }
    
    func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        isConnected = false
    }
    
    private func receiveMessage() async {
        guard let socket = socket, isConnected else { return }
        
        do {
            let message = try await socket.receive()
            switch message {
            case .string(let text):
                if let data = text.data(using: .utf8) {
                    await handleMessage(data)
                }
            case .data(let data):
                await handleMessage(data)
            @unknown default:
                break
            }
            
            await receiveMessage()
        } catch {
            isConnected = false
            print("WebSocket error: \(error)")
        }
    }
    
    private func handleMessage(_ data: Data) async {
        // Handle different message types
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let type = json?["type"] as? String {
                messageHandlers[type]?(data)
            }
        } catch {
            print("Message handling error: \(error)")
        }
    }
    
    func sendMessage(_ message: [String: Any]) async throws {
        guard let socket = socket, isConnected else {
            throw NetworkError.unknown
        }
        
        let data = try JSONSerialization.data(withJSONObject: message)
        let string = String(data: data, encoding: .utf8)!
        try await socket.send(.string(string))
    }
    
    func onMessage(_ type: String, handler: @escaping (Data) -> Void) {
        messageHandlers[type] = handler
    }
    
    func joinConversation(_ conversationId: Int) async throws {
        try await sendMessage([
            "type": "join_conversation",
            "conversationId": conversationId
        ])
    }
    
    func leaveConversation(_ conversationId: Int) async throws {
        try await sendMessage([
            "type": "leave_conversation",
            "conversationId": conversationId
        ])
    }
    
    func sendChatMessage(conversationId: Int, content: String) async throws {
        try await sendMessage([
            "type": "send_message",
            "conversationId": conversationId,
            "content": content
        ])
    }
    
    func startTyping(conversationId: Int) async throws {
        try await sendMessage([
            "type": "typing_start",
            "conversationId": conversationId
        ])
    }
    
    func stopTyping(conversationId: Int) async throws {
        try await sendMessage([
            "type": "typing_stop",
            "conversationId": conversationId
        ])
    }
}

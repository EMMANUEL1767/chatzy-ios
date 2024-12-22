//
//  SocketIOManager.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation
import SocketIO

class SocketService {
    static let shared = SocketService()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    private init() {}
    
    func connect(token: String) {
        // Create configuration with auth token
        let config: SocketIOClientConfiguration = [
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .forceWebsockets(true),
            .compress,
            .connectParams(["token": token]), // Add token to connection params
            .log(true)
        ]
        
        // Initialize manager and socket
        manager = SocketManager(
            socketURL: URL(string: Constants.socketURL)!,
            config: config
        )
        
        socket = manager?.defaultSocket
        
        setupEventHandlers()
        socket?.connect()
    }
    
    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("Socket connected")
            self?.isConnected = true
            
            self?.socket?.emit("authenticate", ["token": UserDefaults.standard.authToken ?? ""])
        }
        
        socket?.on(clientEvent: .error) { data, ack in
            print("Socket error:", data)
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("Socket disconnected")
            self?.isConnected = false
        }
        
        socket?.on("authenticated") { [weak self] data, ack in
            print("Socket authenticated")
            self?.isConnected = true
        }
        
        socket?.on("unauthorized") { data, ack in
            print("Socket authentication failed:", data)
        }
        
        socket?.on("typing_start") { [weak self] data, ack in
            guard let typingData = data.first as? [String: Any] else { return }
            self?.handleTypingStatus(typingData, isTyping: true)
            
        }
        
        // Chat event handlers
        socket?.on("message_status") { [weak self] data, _ in
            guard let statusData = data.first as? [String: Any],
                  let messageId = statusData["messageId"] as? Int,
                  let statusString = statusData["status"] as? String,
                  let status = MessageStatus(rawValue: statusString) else {
                return
            }
            
            NotificationCenter.default.post(
                name: .messageStatusUpdated,
                object: nil,
                userInfo: [
                    "messageId": messageId,
                    "status": status
                ]
            )
        }
        
        // Listen for message sent confirmation
        socket?.on("message_sent") { data, _ in
            guard let responseData = data.first as? [String: Any],
                  let messageId = responseData["messageId"] as? Int,
                  let statusString = responseData["status"] as? String,
                  let status = MessageStatus(rawValue: statusString) else {
                return
            }
            
            NotificationCenter.default.post(
                name: .messageSent,
                object: nil,
                userInfo: [
                    "messageId": messageId,
                    "status": status
                ]
            )
        }
        
        // Listen for message errors
        socket?.on("message_error") { data, _ in
            guard let errorData = data.first as? [String: Any],
                  let error = errorData["error"] as? String else {
                return
            }
            
            NotificationCenter.default.post(
                name: .messageError,
                object: nil,
                userInfo: ["error": error]
            )
        }
        
        socket?.on("new_message") { [weak self] data, ack in
            guard let messageData = data.first as? [String: Any] else { return }
            self?.handleNewMessage(messageData)
        }
        
        socket?.on("message_status") { [weak self] data, ack in
            guard let statusData = data.first as? [String: Any] else { return }
            self?.handleMessageStatus(statusData)
        }
        
        socket?.on("typing_stop") { [weak self] data, ack in
            guard let typingData = data.first as? [String: Any] else { return }
            self?.handleTypingStatus(typingData, isTyping: false)
        }
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
    }
    
    func joinConversation(_ conversationId: Int) {
        guard isConnected else { return }
        socket?.emit("join_conversation", conversationId)
    }
    
    func leaveConversation(_ conversationId: Int) {
        guard isConnected else { return }
        socket?.emit("leave_conversation", conversationId)
    }
    
    func sendMessage(to conversationId: Int, content: String) async throws -> Message {
        guard isConnected else {
            throw NetworkError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let messageData: [String: Any] = [
                "conversationId": conversationId,
                "content": content
            ]
            
            socket?.emit("send_message", messageData) { [weak self] in
                let tempMessage = Message(
                    id: Int.random(in: 1...1000000), // Temporary ID
                    conversationId: conversationId,
                    senderId: UserDefaults.standard.integer(forKey: "userId"),
                    content: content,
                    status: .sent,
                    createdAt: Date().toString(),
                    senderName: UserDefaults.standard.string(forKey: "username") ?? ""
                )
                continuation.resume(returning: tempMessage)
            }
        }
    }
    
    func startTyping(in conversationId: Int) {
        guard isConnected else { return }
        socket?.emit("typing_start", conversationId)
    }
    
    func stopTyping(in conversationId: Int) {
        guard isConnected else { return }
        socket?.emit("typing_stop", conversationId)
        
    }
    
    func markMessageAsDelivered(_ messageId: Int) {
        guard isConnected else { return }
        socket?.emit("message_delivered", ["messageId": messageId])
    }
    
    func markMessageAsRead(_ messageId: Int) {
        guard isConnected else { return }
        socket?.emit("message_read", ["messageId": messageId])
    }
    
    
    // MARK: - Event Handlers
    
    private func handleNewMessage(_ messageData: [String: Any]) {
        NotificationCenter.default.post(
            name: .newMessageReceived,
            object: nil,
            userInfo: ["messageData": messageData]
        )
    }
    
    private func handleMessageStatus(_ statusData: [String: Any]) {
        NotificationCenter.default.post(
            name: .messageStatusUpdated,
            object: nil,
            userInfo: ["statusData": statusData]
        )
    }
    
    private func handleTypingStatus(_ typingData: [String: Any], isTyping: Bool = true) {
        var userInfo = typingData
        userInfo["isTyping"] = isTyping
        NotificationCenter.default.post(
            name: .typingStatusChanged,
            object: nil,
            userInfo: userInfo
        )
    }
}
//

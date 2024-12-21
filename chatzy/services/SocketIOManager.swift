//
//  SocketIOManager.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation
import SocketIO

class SocketIOManager: ObservableObject {
    static let shared = SocketIOManager()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    private init() {}
    
    func connect(token: String) {
        let config: SocketIOClientConfiguration = [
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .log(true),
            .compress,
            .forceWebsockets(true)
        ]
        
        manager = SocketManager(socketURL: URL(string: "https://58b5-157-46-1-45.ngrok-free.app")!, config: config)
        socket = manager?.defaultSocket
        
        setupEventHandlers()
        socket?.connect()
    }
    
    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("Socket connected")
            self?.isConnected = true
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("Socket disconnected")
            self?.isConnected = false
        }
        
        socket?.on(clientEvent: .error) { data, ack in
            print("Socket error: \(data)")
        }
        
        // Chat event handlers
        socket?.on("new_message") { [weak self] data, ack in
            guard let messageData = data[0] as? [String: Any] else { return }
            self?.handleNewMessage(messageData)
        }
        
        socket?.on("message_status") { [weak self] data, ack in
            guard let statusData = data[0] as? [String: Any] else { return }
            self?.handleMessageStatus(statusData)
        }
        
        socket?.on("user_typing") { [weak self] data, ack in
            guard let typingData = data[0] as? [String: Any] else { return }
            self?.handleTypingStatus(typingData)
        }
        
        socket?.on("user_stopped_typing") { [weak self] data, ack in
            guard let typingData = data[0] as? [String: Any] else { return }
            self?.handleTypingStatus(typingData, isTyping: false)
        }
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
    }
    
    // MARK: - Emitting Events
    
    func joinConversation(_ conversationId: Int) {
        socket?.emit("join_conversation", conversationId)
    }
    
    func leaveConversation(_ conversationId: Int) {
        socket?.emit("leave_conversation", conversationId)
    }
    
    func sendMessage(conversationId: Int, content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let messageData: [String: Any] = [
            "conversationId": conversationId,
            "content": content
        ]
        
        socket?.emit("send_message", messageData) {
            completion(.success(()))
        }
    }
    
    func startTyping(in conversationId: Int) {
        socket?.emit("typing_start", conversationId)
    }
    
    func stopTyping(in conversationId: Int) {
        socket?.emit("typing_stop", conversationId)
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

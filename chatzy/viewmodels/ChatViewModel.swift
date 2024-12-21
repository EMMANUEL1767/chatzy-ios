//
//  ChatViewModel.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentMessages: [Message] = []
    @Published var error: String?
    @Published var isLoading = false
    @Published var typingUsers: Set<String> = []
    
    private var currentConversationId: Int?
    private var cancellables = Set<AnyCancellable>()
    
    private let networkService = NetworkService.shared
    private let socketService = SocketService.shared
    
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .newMessageReceived)
            .compactMap { $0.userInfo?["messageData"] as? [String: Any] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messageData in
                self?.handleNewMessage(messageData)
            }
            .store(in: &cancellables)
    }
    
    func loadConversations() async {
        isLoading = true
        do {
            conversations = try await networkService.request("/chat/conversations")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func joinConversation(_ conversationId: Int) async {
        currentConversationId = conversationId
        socketService.joinConversation(conversationId)
        await loadMessages(for: conversationId)
    }
    
    private func loadMessages(for conversationId: Int) async {
        isLoading = true
        do {
            currentMessages = try await networkService.request("/chat/conversations/\(conversationId)/messages")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func sendMessage(_ content: String) {
        guard let conversationId = currentConversationId else { return }
        
        let messageData: [String: Any] = [
            "conversationId": conversationId,
            "content": content
        ]
        
        socketService.sendMessage(messageData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    private func handleNewMessage(_ messageData: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: messageData),
              let message = try? JSONDecoder().decode(Message.self, from: data)
        else { return }
        
        if message.conversationId == currentConversationId {
            currentMessages.append(message)
        }
        
        Task {
            await loadConversations()
        }
    }
    
    func updateTypingStatus(isTyping: Bool) {
        guard let conversationId = currentConversationId else { return }
        
        if isTyping {
            socketService.startTyping(in: conversationId)
        } else {
            socketService.stopTyping(in: conversationId)
        }
    }
}

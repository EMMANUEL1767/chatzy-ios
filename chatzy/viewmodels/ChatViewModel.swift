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
    private var messageStatusObserver: NSObjectProtocol?
    private var observedConversationId: Int?
    private var currentConversationId: Int?
    private var cancellables = Set<AnyCancellable>()
    private var typingDebouncer: Timer?
    private let networkService = NetworkService.shared
    private let socketService = SocketService.shared
    private let coreDataManager = CoreDataManager.shared
    private let networkMonitor = NetworkMonitor.shared
    
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        socketService.$typingUsers
            .receive(on: RunLoop.main)
            .assign(to: &$typingUsers)
        
        NotificationCenter.default.publisher(for: .newMessageReceived)
            .compactMap { $0.userInfo?["messageData"] as? [String: Any] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messageData in
                self?.handleNewMessage(messageData)
            }
            .store(in: &cancellables)
        
        messageStatusObserver = NotificationCenter.default.addObserver(
            forName: .messageStatusUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let messageId = notification.userInfo?["messageId"] as? Int,
                  let status = notification.userInfo?["status"] as? MessageStatus else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateMessageStatus(messageId: messageId, status: status)
            }
        }
        
        // Handle message sent confirmation
        NotificationCenter.default.publisher(for: .messageSent)
            .compactMap { notification -> (Int, MessageStatus)? in
                guard let userInfo = notification.userInfo,
                      let messageId = userInfo["messageId"] as? Int,
                      let status = userInfo["status"] as? MessageStatus else {
                    return nil
                }
                return (messageId, status)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messageId, status in
                self?.handleMessageSent(messageId: messageId, status: status)
            }
            .store(in: &cancellables)
        
        // Handle message errors
        NotificationCenter.default.publisher(for: .messageError)
            .compactMap { notification -> String? in
                notification.userInfo?["error"] as? String
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    
    
    // Load conversations from Core Data and server
    func loadConversations() async {
        isLoading = true
        
        do {
            let cachedConversations = try coreDataManager.fetchConversations()
            conversations = cachedConversations.map { managedObject in
                Conversation(
                    id: managedObject.value(forKey: "id") as! Int,
                    name: managedObject.value(forKey: "name") as? String,
                    type: ConversationType(rawValue: managedObject.value(forKey: "type") as! String)!,
                    createdAt: managedObject.value(forKey: "createdAt") as? String,
                    lastMessage: nil,
                    lastMessageTime: nil,
                    lastMessageSenderId: nil,
                    lastMessageSenderName: nil,
                    participantCount: nil,
                    unreadCount: nil,
                    participants: []
                )
            }
            
            // Then fetch from server
            let serverConversations: [Conversation] = try await networkService.request("/chat/conversations")
            
            // Update Core Data with server data
            for conversation in serverConversations {
                let _ = try coreDataManager.createOrUpdateConversation(from: conversation)
            }
            
            try coreDataManager.save()
            conversations = serverConversations.sorted(by: {  ($0.lastActivityDate ?? .distantPast) > ($1.lastActivityDate ?? .distantPast) })
            
            // Send queued messages if any
            try await sendQueuedMessages()
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func sendMessage(_ content: String) async {
            guard let conversationId = currentConversationId else { return }
            
            // Create temporary message
            let tempMessage = Message(
                id: UUID().hashValue,
                conversationId: conversationId,
                senderId: UserDefaults.standard.userId ?? 0,
                content: content,
                status: .sent,
                createdAt: Date().toString(),
                senderName: UserDefaults.standard.string(forKey: "username") ?? ""
            )
            
            // Add to UI immediately
            currentMessages.append(tempMessage)
            
            if networkMonitor.isConnected {
                // Online - send immediately
                do {
                    let sentMessage = try await socketService.sendMessage(
                        to: conversationId,
                        content: content
                    )
                    
                    // Update UI with server response
                    if let index = currentMessages.firstIndex(where: { $0.id == tempMessage.id }) {
                        currentMessages.remove(at: index)
                    }
                    
                    // Save to Core Data
                    try await coreDataManager.createMessage(from: sentMessage)
                } catch {
                    // Handle failure
                    if let index = currentMessages.firstIndex(where: { $0.id == tempMessage.id }) {
                        currentMessages[index].status = .failed
                    }
                    self.error = "Failed to send message"
                }
            } else {
                // Offline - queue message
                do {
                    try await coreDataManager.queueOfflineMessage(
                        content: content,
                        conversationId: Int64(conversationId),
                        senderId: Int64(UserDefaults.standard.userId ?? 0)
                    )
                } catch {
                    self.error = "Failed to queue message"
                }
            }
        }
        
        // Process queued messages when coming online
        func processQueuedMessages() async {
            guard networkMonitor.isConnected else { return }
            
            do {
                let queuedMessages = try await coreDataManager.getQueuedMessages()
                for message in queuedMessages {
                    guard let content = message.value(forKey: "content") as? String,
                          let conversationId = message.value(forKey: "conversationId") as? Int64 else {
                        continue
                    }
                    
                    do {
                        let sentMessage = try await socketService.sendMessage(
                            to: Int(conversationId),
                            content: content
                        )
                        
                        // Remove queued message and save sent message
                        coreDataManager.viewContext.delete(message)
                        try await coreDataManager.createMessage(from: sentMessage)
                        
                        // Update UI if in same conversation
                        if Int(conversationId) == currentConversationId {
                            await MainActor.run {
                                currentMessages.append(sentMessage)
                            }
                        }
                    } catch {
                        print("Failed to send queued message: \(error)")
                    }
                }
                
                try await coreDataManager.save()
            } catch {
                print("Failed to process queued messages: \(error)")
            }
        }
    
    private func sendQueuedMessages() async throws {
        let queuedMessages = try coreDataManager.getQueuedMessages()
        
        for message in queuedMessages {
            let content = message.value(forKey: "content") as! String
            let conversationId = message.value(forKey: "conversationId") as! Int64
            
            do {
                let sendMessage = try await socketService.sendMessage(
                    to: Int(conversationId),
                    content: content
                )
                
                // Remove queued message and save sent message
                coreDataManager.viewContext.delete(message)
                try await coreDataManager.createMessage(from: sendMessage)
                try coreDataManager.save()
            } catch {
                print("Failed to send queued message: \(error)")
            }
        }
    }
    
    
    func joinConversation(_ conversationId: Int) async {
        currentConversationId = conversationId
        socketService.joinConversation(conversationId)
        await loadMessages(for: conversationId)
    }
    
    private func loadMessages(for conversationId: Int) async {
        isLoading = true
        do {
            let messages: [Message] = try await networkService.request("/chat/conversations/\(conversationId)/messages")
            currentMessages = messages.sorted(by: { (DateUtils.getDate(from: $0.createdAt ?? "") ?? .now) < (DateUtils.getDate(from: $1.createdAt ?? "") ?? .now) })
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
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
    
    func searchUsers(query: String) async throws -> [User] {
        return try await networkService.request(
            "/users/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        )
    }
    
    func createConversation(name: String?, type: ConversationType, participantIds: [Int]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let conversation = try await networkService.request(
            "/chat/conversations",
            method: "POST",
            body: [
                "name": name as Any,
                "type": type.rawValue,
                "participantIds": participantIds
            ]
        ) as Conversation
        
        await MainActor.run {
            conversations.append(conversation)
        }
    }
    
    private func updateMessageStatus(messageId: Int, status: MessageStatus = .sent) {
        if let index = currentMessages.firstIndex(where: { $0.id == messageId }) {
            currentMessages[index].status = status
        }
    }
    
    private func handleMessageSent(messageId: Int, status: MessageStatus) {
        if let index = currentMessages.firstIndex(where: { $0.id == messageId }) {
            currentMessages[index].status = status
        }
    }
    
    func markMessagesAsRead(in conversationId: Int) {
        guard let currentConversationId = currentConversationId,
              currentConversationId == conversationId else {
            return
        }
        
        for message in currentMessages where message.status != .read {
            socketService.markMessageAsRead(message.id)
        }
    }
    
    func observeTyping(for conversationId: Int) {
        observedConversationId = conversationId
        socketService.joinConversation(conversationId)
    }
    
    func stopObservingTyping(for conversationId: Int) {
        if observedConversationId == conversationId {
            observedConversationId = nil
            socketService.leaveConversation(conversationId)
        }
    }
    
    func startTyping() {
        guard let conversationId = currentConversationId else { return }
        
        // Cancel existing timer
        typingDebouncer?.invalidate()
        
        // Emit typing start
        socketService.startTyping(in: conversationId)
        
        // Set timer to stop typing after 3 seconds
        typingDebouncer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.stopTyping()
            }
        }
    }
    
    func stopTyping() {
        guard let conversationId = currentConversationId else { return }
        socketService.stopTyping(in: conversationId)
    }
    
    deinit {
        if let observer = messageStatusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        typingDebouncer?.invalidate()
    }

}

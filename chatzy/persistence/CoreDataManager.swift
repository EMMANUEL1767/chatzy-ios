//
//  CoreDataManager.swift
//  chatzy
//
//  Created by Emmanuel Biju on 22/12/24.
//


import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ChatzyApp")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - CRUD Operations
    
    func save() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
    
    // MARK: - User Operations
    
    func createOrUpdateUser(from userDTO: User) throws -> NSManagedObject {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Users")
        fetchRequest.predicate = NSPredicate(format: "id == %d", userDTO.id)
        
        let context = viewContext
        
        if let existingUser = try context.fetch(fetchRequest).first {
            // Update existing user
            existingUser.setValue(userDTO.username, forKey: "username")
            existingUser.setValue(userDTO.email, forKey: "email")
            existingUser.setValue(userDTO.createdAt, forKey: "createdAt")
            return existingUser
        } else {
            // Create new user
            let user = NSEntityDescription.insertNewObject(forEntityName: "Users", into: context)
            user.setValue(userDTO.id, forKey: "id")
            user.setValue(userDTO.username, forKey: "username")
            user.setValue(userDTO.email, forKey: "email")
            user.setValue(userDTO.createdAt, forKey: "createdAt")
            return user
        }
    }
    
    // MARK: - Conversation Operations
    
    func createOrUpdateConversation(from conversationDTO: Conversation) throws -> NSManagedObject {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Conversations")
        fetchRequest.predicate = NSPredicate(format: "id == %d", conversationDTO.id)
        
        let context = viewContext
        
        if let existingConversation = try context.fetch(fetchRequest).first {
            // Update existing conversation
            existingConversation.setValue(conversationDTO.name, forKey: "name")
            existingConversation.setValue(conversationDTO.type.rawValue, forKey: "type")
            existingConversation.setValue(conversationDTO.createdAt, forKey: "createdAt")
            existingConversation.setValue(conversationDTO.unreadCount, forKey: "unreadCount")
            return existingConversation
        } else {
            // Create new conversation
            let conversation = NSEntityDescription.insertNewObject(forEntityName: "Conversations", into: context)
            conversation.setValue(conversationDTO.id, forKey: "id")
            conversation.setValue(conversationDTO.name, forKey: "name")
            conversation.setValue(conversationDTO.type.rawValue, forKey: "type")
            conversation.setValue(conversationDTO.createdAt, forKey: "createdAt")
            conversation.setValue(conversationDTO.unreadCount, forKey: "unreadCount")
            return conversation
        }
    }
    
    // MARK: - Message Operations
    
    func createMessage(from messageDTO: Message) throws -> NSManagedObject {
        let context = viewContext
        let message = NSEntityDescription.insertNewObject(forEntityName: "Messages", into: context)
        
        message.setValue(messageDTO.id, forKey: "id")
        message.setValue(messageDTO.content, forKey: "content")
        message.setValue(messageDTO.createdAt, forKey: "createdAt")
        message.setValue(messageDTO.status.rawValue, forKey: "status")
        message.setValue(messageDTO.conversationId, forKey: "conversationId")
        message.setValue(messageDTO.senderId, forKey: "senderId")
        message.setValue(false, forKey: "isQueued")
        
        return message
    }
    
    func queueOfflineMessage(content: String, conversationId: Int64, senderId: Int64) throws -> NSManagedObject {
        let context = viewContext
        let message = NSEntityDescription.insertNewObject(forEntityName: "Messages", into: context)
        
        message.setValue(UUID().hashValue, forKey: "id") // Temporary ID
        message.setValue(content, forKey: "content")
        message.setValue(Date().toString(), forKey: "createdAt")
        message.setValue(MessageStatus.sent.rawValue, forKey: "status")
        message.setValue(conversationId, forKey: "conversationId")
        message.setValue(senderId, forKey: "senderId")
        message.setValue(true, forKey: "isQueued")
        
        return message
    }
    
    func getQueuedMessages() throws -> [NSManagedObject] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Messages")
        fetchRequest.predicate = NSPredicate(format: "isQueued == YES")
        return try viewContext.fetch(fetchRequest)
    }
    
    func markMessageAsDelivered(_ messageId: Int64) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Messages")
        fetchRequest.predicate = NSPredicate(format: "id == %d", messageId)
        
        if let message = try viewContext.fetch(fetchRequest).first {
            message.setValue(MessageStatus.delivered.rawValue, forKey: "status")
            try save()
        }
    }
    
    func markMessageAsRead(_ messageId: Int64) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Messages")
        fetchRequest.predicate = NSPredicate(format: "id == %d", messageId)
        
        if let message = try viewContext.fetch(fetchRequest).first {
            message.setValue(MessageStatus.read.rawValue, forKey: "status")
            try save()
        }
    }
    
    // MARK: - Fetch Operations
    
    func fetchConversations() throws -> [NSManagedObject] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Conversations")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastMessageTime", ascending: false)]
        return try viewContext.fetch(fetchRequest)
    }
    
    func fetchMessages(for conversationId: Int64, limit: Int = 50) throws -> [NSManagedObject] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Messages")
        fetchRequest.predicate = NSPredicate(format: "conversationId == %d", conversationId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = limit
        return try viewContext.fetch(fetchRequest)
    }
    
    func clearAllData() {
        let context = viewContext
        let entities = persistentContainer.managedObjectModel.entities
        
        entities.forEach { entity in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity.name!)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Error clearing entity \(entity.name!): \(error)")
            }
        }
        
        // Reset the context
        context.reset()
        
        // Save changes
        do {
            try context.save()
        } catch {
            print("Error saving context after clear: \(error)")
        }
    }
}

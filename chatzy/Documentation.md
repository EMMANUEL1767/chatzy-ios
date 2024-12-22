# Chatzy - Real-Time Chat Application Documentation

## Table of Contents
1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Setup and Installation](#setup-and-installation)
4. [Architecture](#architecture)
5. [Features](#features)
6. [Technical Implementation](#technical-implementation)
7. [API Documentation](#api-documentation)
8. [WebSocket Events](#websocket-events)
9. [Security](#security)
10. [Testing](#testing)

## Overview
A real-time chat application built using Swift and SwiftUI for iOS, implementing Socket.IO for real-time communication. The app supports user authentication, direct messaging, group chats, typing indicators, and message status updates.

### Key Technologies
- Swift & SwiftUI
- Socket.IO
- Async/Await
- MVVM Architecture
- SQLite Database (Backend)

## Project Structure
```
ChatApp/
├── ChatApp.swift                 # App entry point
├── ContentView.swift             # App entry point
├── Models/                       # Data models
├── Views/                        # UI components
│   ├── Auth/                     # Authentication views - login and register
│   ├── Chat/                     # Chat Views - conversation and chat details
│   └── Components/               # Reusable components
├── Resources/                    # To store database
├── Persistance/                  # CoreData Mangers
├── ViewModels/                   # Business logic
├── Services/                     # Network and Socket services
└── Utils/                        # Helper functions and extensions

```

## Setup and Installation

### Prerequisites
- Xcode 14.0+
- iOS 15.0+
- Node.js server running Socket.IO
- CocoaPods or Swift Package Manager

### Installation Steps
1. Clone the repository
2. Install dependencies:
```bash
# Using Swift Package Manager
File > Add Packages > https://github.com/socketio/socket.io-client-swift
```

3. Configure environment:
   - Update `Constants.swift` with your server URLs
   - Set up development team in Xcode

4. Build and run the project

## Architecture

### MVVM Pattern
The app follows the MVVM (Model-View-ViewModel) architecture:
- **Models**: Data structures and business logic
- **Views**: SwiftUI views for UI representation
- **ViewModels**: State management and business logic
- **Services**: Network and Socket.IO communication

### Data Flow
1. User interacts with View
2. View notifies ViewModel
3. ViewModel processes data through Services
4. Services communicate with backend
5. Updates flow back through ViewModel to View

## Features

### Authentication
- User registration
- Login/Logout
- Token-based authentication
- Secure password handling

### Messaging
- Real-time message delivery
- Message status updates (sent, delivered, read)
- Typing indicators
- Message history

### Conversations
- One-on-one chats
- Group conversations
- Conversation list
- Unread message counts

## Technical Implementation

### Authentication Flow
```swift
class AuthViewModel: ObservableObject {
    func login(email: String, password: String) async {
        // 1. Validate input
        // 2. Make API request
        // 3. Store token
        // 4. Connect Socket.IO
        // 5. Update UI state
    }
}
```

### Real-Time Communication
```swift
class SocketService {
    func connect(token: String) {
        // 1. Configure Socket.IO
        // 2. Establish connection
        // 3. Set up event handlers
        // 4. Handle reconnection
    }
}
```

### Message Handling
```swift
class ChatViewModel {
    func sendMessage(_ content: String) {
        // 1. Emit socket event
        // 2. Handle acknowledgment
        // 3. Update local state
        // 4. Handle errors
    }
}
```

## API Documentation

### Authentication Endpoints

#### POST /api/auth/register
```json
{
    "username": "string",
    "email": "string",
    "password": "string"
}
```

#### POST /api/auth/login
```json
{
    "email": "string",
    "password": "string"
}
```

### Chat Endpoints

#### GET /api/chat/conversations
Returns list of user's conversations

#### GET /api/chat/conversations/{id}/messages
Returns messages for a specific conversation

## WebSocket Events

### Client to Server
- `join_conversation`: Join a chat room
- `leave_conversation`: Leave a chat room
- `send_message`: Send a new message
- `typing_start`: User started typing
- `typing_stop`: User stopped typing
- `message_delivered`: Message delivered by receiver
- `message_read` : Message read by receiver

### Server to Client
- `new_message`: Receive new message
- `message_status`: Message status updates
- `user_typing`: User typing indicator
- `user_stopped_typing`: User stopped typing

## Security

### Authentication
- JWT token-based authentication
- Secure password hashing
- HTTPS communication

## Best Practices

### Code Organization
- Follow SOLID principles
- Use dependency injection
- Implement error handling

### Performance
- Implement pagination for messages
- Handle background states

### Error Handling
```swift
enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case unauthorized
        case decodingError
        case serverError(String)
        case unknown
        case notConnected
}

// Handle errors appropriately
func handleError(_ error: Error) {
    switch error {
    case NetworkError.unauthorized:
        // Handle unauthorized access
    case NetworkError.serverError(let message):
        // Handle server error
    default:
        // Handle error
    }
}
```

### Debugging
- Use proper logging
- Implement crash reporting
- Monitor network requests

## Future Improvements
1. Implement file sharing
2. Add push notifications
3. Add message search
4. Implement message reactions
5. Add user profiles

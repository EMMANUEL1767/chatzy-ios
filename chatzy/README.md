# Chatzy - Real-Time Chat iOS App

A SwiftUI chat application implementing real-time messaging using Socket.IO.

## Technology Stack

- Swift 5.5+
- SwiftUI
- Socket.IO-Client-Swift
- Core Data
- Async/await
- MVVM Architecture

## Project Structure

```
ChatApp/
├── App/
│   └── ChatzyApp.swift      # App entry point
|   └── ContentView.swift
├── Models/
│   ├── User.swift           # User model
│   ├── Message.swift        # Message model
│   └── Conversation.swift   # Conversation model
├── Views/
│   ├── Auth/               # Login/Register views
│   ├── Chat/               # Chat interface views
│   └── Components/         # Reusable UI components
├── ViewModels/
│   ├── AuthViewModel.swift  # Authentication logic
│   └── ChatViewModel.swift  # Chat operations
├── Services/
│   ├── NetworkService.swift # API client
│   └── SocketService.swift  # Socket.IO handling
|   └── NetworkMonitor.swift # Monitoring Network Connectivity
├── Persistence/
│   └── CoreDataManager.swift # Local storage
└── Resources/
    └── ChatApp.xcdatamodeld # Core Data model
```

## Setup Instructions

### Requirements
- iOS 15.0+
- Xcode 14.0+
- CocoaPods or Swift Package Manager

### Installation

1. Clone the repository:
```bash
git clone https://github.com/EMMANUEL1767/chatzy-ios
```

2. Install dependencies using Swift Package Manager:
- Open Xcode
- File > Add Packages
- Add Socket.IO-Client-Swift: `https://github.com/socketio/socket.io-client-swift`

3. Clone the backend repository:
```bash
git clone https://github.com/EMMANUEL1767/chatzy-backend
```
- Follow the documentation for backend repo to run the backend and socket services

4. Update `Constants` with your server URL

5. Build and run the project

## Features

### Authentication
- User registration
- Login/logout
- Token management
- Session persistence

### Messaging
- Real-time message delivery
- Message status tracking (sent/delivered/read)
- Typing indicators
- Offline message queueing
- Message persistence
- Network Indicator

### User Experience
- Clean, minimal native iOS design
- Responsive interface
- Connection status indication
- Error feedback

## Architecture

### MVVM Pattern
- **Models**: Data structures and Core Data entities
- **Views**: SwiftUI views
- **ViewModels**: Business logic and state management
- **Services**: Network and socket communication

### Data Flow
1. User interacts with View
2. View notifies ViewModel
3. ViewModel processes through Services
4. Updates flow back through ViewModel to View

## Core Data Schema

### User Entity
```swift
entity User {
    attribute id: Integer64
    attribute username: String
    attribute email: String
    attribute createdAt: Date
    relationship conversations: to-many Conversation
    relationship sentMessages: to-many Message
}
```

### Conversation Entity
```swift
entity Conversation {
    attribute id: Integer64
    attribute name: Optional<String>
    attribute type: String
    attribute createdAt: Date
    attribute lastMessageTime: Optional<Date>
    attribute unreadCount: Integer64
    relationship participants: to-many User
    relationship messages: to-many Message
    relationship lastMessage: optional to-one Message
}
```

### Message Entity
```swift
entity Message {
    attribute id: Integer64
    attribute content: String
    attribute createdAt: Date
    attribute status: String
    attribute isQueued: Boolean
    relationship conversation: to-one Conversation
    relationship sender: to-one User
}
```

## Socket Events

### Emitted Events
- `join_conversation`
- `leave_conversation`
- `send_message`
- `typing_start`
- `typing_stop`
- `message_delivered`
- `message_read`

### Received Events
- `new_message`
- `message_status`
- `user_typing`
- `user_stopped_typing`
- `message_error`
- `message_sent`
- `authenticated`
- `unauthorized`

## Network Handling

### Online Mode
- Real-time message delivery
- Status updates
- Typing indicators

### Offline Mode
- Message queueing
- Local storage
- Automatic retry

## Error Handling

- Network errors
- Socket connection issues
- Data validation
- Core Data errors

## Best Practices

### Code Organization
- Dependency injection
- Protocol-oriented programming
- SwiftUI best practices
- Proper error handling

### Performance
- Efficient Core Data queries
- Image caching
- Background task handling
- Memory management

## Testing

Run tests:
```bash
cmd + U
```

## Debugging

Socket.IO logs can be enabled in `SocketService`:
```swift
let config: SocketIOClientConfiguration = [
    .log(true)
]
```

## Known Issues

- Handle Socket.IO reconnection edge cases
- Improve offline message queueing
- Optimize Core Data fetch requests
- Improve Read Receipts

## Future Improvements

- Media message support
- Push notifications
- Message search
- Enhanced group chat features
- End-to-end encryption


## License

MIT License

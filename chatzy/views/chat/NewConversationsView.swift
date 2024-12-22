//
//  NewConversationsView.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI

import SwiftUI

struct NewConversationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ChatViewModel
    
    @State private var name = ""
    @State private var searchText = ""
    @State private var conversationType: ConversationType = .direct
    @State private var selectedUsers: Set<User> = []
    @State private var isSearching = false
    @State private var searchResults: [User] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Conversation Type Picker
                Picker("Conversation Type", selection: $conversationType) {
                    Text("Direct Message").tag(ConversationType.direct)
                    Text("Group Chat").tag(ConversationType.group)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Group Name (only for group chats)
                if conversationType == .group {
                    TextField("Group Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            searchUsers(query: newValue)
                        }
                }
                .padding(.horizontal)
                
                // Selected Users
                if !selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(selectedUsers)) { user in
                                SelectedUserBubble(user: user) {
                                    selectedUsers.remove(user)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // Search Results
                if isSearching {
                    List(searchResults) { user in
                        UserRow(
                            user: user,
                            isSelected: selectedUsers.contains(user)
                        ) {
                            if selectedUsers.contains(user) {
                                selectedUsers.remove(user)
                            } else {
                                if conversationType == .direct && selectedUsers.count >= 1 {
                                    errorMessage = "Direct messages can only have one recipient"
                                } else {
                                    selectedUsers.insert(user)
                                }
                            }
                        }
                    }
                } else {
                    Spacer()
                }
            }
            .navigationTitle(conversationType == .direct ? "New Message" : "New Group")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createConversation()
                    }
                    .disabled(!canCreateConversation)
                    .opacity(canCreateConversation ? 1.0 : 0.5)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    private var canCreateConversation: Bool {
        if conversationType == .direct {
            return selectedUsers.count == 1
        } else {
            return !selectedUsers.isEmpty && !name.isEmpty
        }
    }
    
    private func searchUsers(query: String) {
        guard !query.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }
        
        // Update this to use your actual user search API
        Task {
            do {
                let users: [User] = try await viewModel.searchUsers(query: query)
                await MainActor.run {
                    searchResults = users
                    isSearching = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func createConversation() {
        guard canCreateConversation else { return }
        
        isLoading = true
        let participantIds = selectedUsers.map { $0.id }
        
        Task {
            do {
                try await viewModel.createConversation(
                    name: conversationType == .group ? name : nil,
                    type: conversationType,
                    participantIds: participantIds
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// Helper Views
struct SelectedUserBubble: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(user.username)
                .font(.subheadline)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.2))
        )
    }
}

struct UserRow: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // User Avatar (you can add an avatar image here)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    NewConversationsView()
}

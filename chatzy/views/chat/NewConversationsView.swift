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
                    AppProgressView()                }
            }
            .onChange(of: conversationType) { oldValue, newValue in
                if oldValue != newValue {
                    selectedUsers = []
                }
            }
        }
    }
    
    private var canCreateConversation: Bool {
        if conversationType == .direct, selectedUsers.count == 1 {
            return viewModel.conversations.filter({ $0.type == .direct && $0.participants.contains(where: { $0.id == selectedUsers.first?.id }) }).isEmpty
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
                switch error {
                    case NetworkError.serverError(let message):
                        self.errorMessage = message
                    default:
                        self.errorMessage = error.localizedDescription
                }
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
                switch error {
                    case NetworkError.serverError(let message):
                        self.errorMessage = message
                    default:
                        self.errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }
}



#Preview {
    NewConversationsView()
}

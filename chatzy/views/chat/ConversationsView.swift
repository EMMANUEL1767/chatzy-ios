//
//  ConversationsView.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI

struct ConversationsView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingNewConversation = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink {
                        ChatDetailView(conversation: conversation)
                            .environmentObject(viewModel)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        authViewModel.logout()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewConversation = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewConversation) {
                NewConversationsView()
                    .environmentObject(viewModel)
            }
        }
        .task {
            await viewModel.loadConversations()
        }
    }
}

#Preview {
    ConversationsView()
}

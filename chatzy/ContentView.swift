//
//  ContentView.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared


    var body: some View {
        ZStack(alignment: .top) {
            if !authViewModel.checkingForLoggedInUser {
                if authViewModel.isAuthenticated {
                    ConversationsView()
                        .environmentObject(authViewModel)
                } else {
                    AuthView()
                        .environmentObject(authViewModel)
                }
            } else {
                AppProgressView()
            }
            
            NetworkStatusView()
                .animation(.default, value: networkMonitor.isConnected)
        }
    }
}


#Preview {
    ContentView().environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
}

//
//  AuthViewModel.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var error: String?
    @Published var isLoading = false
    
    private let networkService = NetworkService.shared
    private let socketService = SocketService.shared
    
    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let response: AuthResponse = try await networkService.request(
                "/auth/login",
                method: "POST",
                body: ["email": email, "password": password]
            )
            
            networkService.setAuthToken(response.token)
            currentUser = response.user
            isAuthenticated = true
            socketService.connect(token: response.token)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register(username: String, email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let response: AuthResponse = try await networkService.request(
                "/auth/register",
                method: "POST",
                body: [
                    "username": username,
                    "email": email,
                    "password": password
                ]
            )
            
            networkService.setAuthToken(response.token)
            currentUser = response.user
            isAuthenticated = true
            socketService.connect(token: response.token)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        socketService.disconnect()
        isAuthenticated = false
        currentUser = nil
    }
}

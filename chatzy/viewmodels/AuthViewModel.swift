import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var error: String?
    @Published var isLoading = false
    @Published var checkingForLoggedInUser = true
    
    private let networkService = NetworkService.shared
    private let socketService = SocketService.shared
    
    // Add UserDefaults keys
    private enum UserDefaultsKeys {
        static let userId = "userId"
        static let authToken = "authToken"
    }
    
    init() {
        if let token = UserDefaults.standard.authToken {
            networkService.setAuthToken(token)
            loadSavedUser()
        } else {
            checkingForLoggedInUser = false
        }
    }
    
    private func loadSavedUser() {
        if let userId = UserDefaults.standard.userId {
            Task {
                do {
                    let user: User = try await networkService.request("/users/\(userId)")
                    self.currentUser = user
                    self.isAuthenticated = true
                    checkingForLoggedInUser = false
                    socketService.connect(token: UserDefaults.standard.authToken ?? "")
                } catch {
                    self.logout()
                    checkingForLoggedInUser = false
                }
            }
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let response: AuthResponse = try await networkService.request(
                "/auth/login",
                method: "POST",
                body: ["email": email, "password": password]
            )
            
            UserDefaults.standard.userId = response.user.id
            UserDefaults.standard.authToken = response.token
            
            networkService.setAuthToken(response.token)
            currentUser = response.user
            isAuthenticated = true
            socketService.connect(token: response.token)
        } catch {
            switch error {
                case NetworkError.serverError(let message):
                    self.error = message
                default:
                    self.error = error.localizedDescription
            }
        
        }
        
        isLoading = false
    }
    
    func logout() {
        // Disconnect socket
        socketService.disconnect()
        
        // Clear Core Data
        CoreDataManager.shared.clearAllData()
        
        // Clear UserDefaults
        UserDefaults.standard.clearAuthData()
        UserDefaults.standard.synchronize()
        
        // Clear authentication state
        isAuthenticated = false
        currentUser = nil
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
            
            // Save user data
            UserDefaults.standard.setValue(response.user.id, forKey: UserDefaultsKeys.userId)
            UserDefaults.standard.setValue(response.token, forKey: UserDefaultsKeys.authToken)
            
            networkService.setAuthToken(response.token)
            currentUser = response.user
            isAuthenticated = true
            socketService.connect(token: response.token)
        } catch {
            switch error {
                case NetworkError.serverError(let message):
                    self.error = message
                default:
                    self.error = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}

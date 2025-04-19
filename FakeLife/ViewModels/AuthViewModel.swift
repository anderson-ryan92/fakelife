import Foundation
import Firebase
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isAuthenticated: Bool {
        return userSession != nil
    }
    
    init() {
        self.userSession = Auth.auth().currentUser
        Task {
            await fetchUser()
        }
    }
    
    func fetchUser() async {
        guard let uid = userSession?.uid else { return }
        
        do {
            self.currentUser = try await FirebaseService.shared.getUser(userId: uid)
        } catch {
            await MainActor.run {
                self.errorMessage = "Error fetching user data: \(error.localizedDescription)"
            }
        }
    }
    
    func login(withEmail email: String, password: String) async throws {
        do {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            
            await fetchUser()
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func createUser(email: String, password: String) async throws {
        do {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            let newUser = try await FirebaseService.shared.createUser(email: email, password: password)
            self.userSession = Auth.auth().currentUser
            self.currentUser = newUser
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
} 
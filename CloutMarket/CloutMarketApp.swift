import SwiftUI
import Firebase

@main
struct CloutMarketApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        setupFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
} 
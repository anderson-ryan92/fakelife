import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var walletViewModel = WalletViewModel()
    
    var body: some View {
        TabView {
            // Marketplace Feed
            NavigationView {
                MarketplaceView()
                    .environmentObject(contentViewModel)
            }
            .tabItem {
                Label("Marketplace", systemImage: "bag")
            }
            
            // Upload Content
            NavigationView {
                UploadView()
                    .environmentObject(contentViewModel)
            }
            .tabItem {
                Label("Upload", systemImage: "plus.circle")
            }
            
            // Wallet
            NavigationView {
                WalletView()
                    .environmentObject(walletViewModel)
            }
            .tabItem {
                Label("Wallet", systemImage: "creditcard")
            }
            
            // Profile
            NavigationView {
                ProfileView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
} 
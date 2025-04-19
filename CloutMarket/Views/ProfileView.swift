import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile Header
                VStack(spacing: 15) {
                    // Profile Image
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    // User Info
                    if let user = authViewModel.currentUser {
                        Text(user.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Member since \(dateFormatter.string(from: user.createdAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ProgressView()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Account Section
                VStack(alignment: .leading, spacing: 0) {
                    Text("Account")
                        .font(.headline)
                        .padding()
                        .padding(.bottom, -5)
                    
                    Divider()
                    
                    NavigationLink(destination: Text("Edit Profile")) {
                        SettingsRow(icon: "person.fill", title: "Edit Profile", iconColor: .blue)
                    }
                    
                    Divider()
                    
                    NavigationLink(destination: Text("Notification Settings")) {
                        SettingsRow(icon: "bell.fill", title: "Notifications", iconColor: .orange)
                    }
                    
                    Divider()
                    
                    NavigationLink(destination: Text("Privacy Settings")) {
                        SettingsRow(icon: "lock.fill", title: "Privacy", iconColor: .green)
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Support Section
                VStack(alignment: .leading, spacing: 0) {
                    Text("Support")
                        .font(.headline)
                        .padding()
                        .padding(.bottom, -5)
                    
                    Divider()
                    
                    NavigationLink(destination: Text("Help Center")) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", iconColor: .purple)
                    }
                    
                    Divider()
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        SettingsRow(icon: "doc.text.fill", title: "Terms of Service", iconColor: .gray)
                    }
                    
                    Divider()
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", iconColor: .gray)
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Logout Button
                Button(action: {
                    showLogoutConfirmation = true
                }) {
                    Text("Log Out")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                }
                
                // App Version
                Text("CloutMarket • Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("Profile")
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var iconColor: Color = .blue
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.white)
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
} 
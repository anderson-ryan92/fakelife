import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true
    
    var body: some View {
        NavigationView {
            VStack {
                // App Logo
                VStack(spacing: 5) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("CloutMarket")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Buy & Sell Premium Content")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 50)
                
                // Auth Form
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        handleAuthAction()
                    }) {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Sign Up")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authViewModel.isLoading)
                    
                    if authViewModel.isLoading {
                        ProgressView()
                    }
                    
                    // Toggle auth mode
                    Button(action: {
                        isLoginMode.toggle()
                    }) {
                        Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding(.top, 50)
            .navigationBarHidden(true)
        }
    }
    
    private func handleAuthAction() {
        Task {
            if isLoginMode {
                try? await authViewModel.login(withEmail: email, password: password)
            } else {
                try? await authViewModel.createUser(email: email, password: password)
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
} 
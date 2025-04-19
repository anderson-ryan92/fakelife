import Foundation
import Firebase
import SwiftUI

class WalletViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var walletBalance: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isStripeConnected = false
    @Published var isConnectingStripe = false
    
    init() {
        Task {
            await fetchUserData()
            await fetchTransactions()
        }
    }
    
    func fetchUserData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            if let user = try await FirebaseService.shared.getUser(userId: userId) {
                await MainActor.run {
                    self.walletBalance = user.walletBalance
                    self.isStripeConnected = user.isStripeConnected
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error fetching wallet data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func fetchTransactions() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let userTransactions = try await FirebaseService.shared.getUserTransactions(userId: userId)
            
            await MainActor.run {
                self.transactions = userTransactions
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error fetching transactions: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func connectStripeAccount() async -> URL? {
        guard let userId = Auth.auth().currentUser?.uid,
              let userEmail = Auth.auth().currentUser?.email else {
            self.errorMessage = "User not authenticated"
            return nil
        }
        
        await MainActor.run {
            self.isConnectingStripe = true
            self.errorMessage = nil
        }
        
        do {
            // Create a Stripe Connect account
            let accountId = try await StripeService.shared.createConnectAccount(
                userId: userId,
                email: userEmail
            )
            
            // Save the account ID to the user record
            if var user = try await FirebaseService.shared.getUser(userId: userId) {
                user.stripeConnectAccountId = accountId
                try await FirebaseService.shared.saveUser(user: user)
                
                await MainActor.run {
                    self.isStripeConnected = true
                }
            }
            
            // Get the account link URL for onboarding
            let accountLinkURL = try await StripeService.shared.createConnectAccountLink(
                connectAccountId: accountId
            )
            
            await MainActor.run {
                self.isConnectingStripe = false
            }
            
            return accountLinkURL
        } catch {
            await MainActor.run {
                self.errorMessage = "Error connecting Stripe: \(error.localizedDescription)"
                self.isConnectingStripe = false
            }
            return nil
        }
    }
    
    func initiateWithdrawal(amount: Double) async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated"
            return false
        }
        
        guard let user = try? await FirebaseService.shared.getUser(userId: userId),
              let connectAccountId = user.stripeConnectAccountId else {
            self.errorMessage = "Stripe account not connected"
            return false
        }
        
        guard user.walletBalance >= amount else {
            self.errorMessage = "Insufficient balance"
            return false
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Create a withdrawal transaction
            let transaction = Transaction(
                userId: userId,
                amount: amount,
                type: .payout,
                status: .pending,
                createdAt: Date()
            )
            
            let savedTransaction = try await FirebaseService.shared.createTransaction(transaction: transaction)
            
            // Initiate transfer via Stripe
            let transferSuccess = try await StripeService.shared.initiateTransfer(
                amount: amount,
                destinationAccountId: connectAccountId
            )
            
            if transferSuccess {
                // Update transaction status
                try await FirebaseService.shared.updateTransactionStatus(
                    transactionId: savedTransaction.id!,
                    status: .completed
                )
                
                // Update user wallet balance
                let newBalance = user.walletBalance - amount
                try await FirebaseService.shared.updateUserWalletBalance(
                    userId: userId,
                    newBalance: newBalance
                )
                
                await fetchUserData()
                await fetchTransactions()
                
                await MainActor.run {
                    self.isLoading = false
                }
                
                return true
            } else {
                // Update transaction status to failed
                try await FirebaseService.shared.updateTransactionStatus(
                    transactionId: savedTransaction.id!,
                    status: .failed
                )
                
                await MainActor.run {
                    self.errorMessage = "Transfer failed"
                    self.isLoading = false
                }
                
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error processing withdrawal: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
} 
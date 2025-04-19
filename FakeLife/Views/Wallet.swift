import SwiftUI
import SafariServices

struct WalletView: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @State private var withdrawalAmount = ""
    @State private var showStripeConnectSheet = false
    @State private var stripeConnectURL: URL?
    @State private var showWithdrawalSheet = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Wallet Balance Card
                VStack(spacing: 5) {
                    Text("Wallet Balance")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(String(format: "%.2f", walletViewModel.walletBalance))")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if !walletViewModel.isStripeConnected {
                        Text("Connect with Stripe to withdraw funds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Action Buttons
                HStack(spacing: 15) {
                    if walletViewModel.isStripeConnected {
                        // Withdraw Button
                        Button(action: {
                            showWithdrawalSheet = true
                        }) {
                            VStack {
                                Image(systemName: "arrow.down.to.line")
                                    .font(.system(size: 20))
                                    .padding(.bottom, 5)
                                Text("Withdraw")
                                    .font(.callout)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(walletViewModel.walletBalance <= 0 || walletViewModel.isLoading)
                    } else {
                        // Connect Stripe Button
                        Button(action: {
                            connectStripe()
                        }) {
                            VStack {
                                if walletViewModel.isConnectingStripe {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.bottom, 5)
                                    Text("Connecting...")
                                        .font(.callout)
                                } else {
                                    Image(systemName: "link")
                                        .font(.system(size: 20))
                                        .padding(.bottom, 5)
                                    Text("Connect Stripe")
                                        .font(.callout)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(walletViewModel.isConnectingStripe)
                    }
                }
                .padding(.horizontal)
                
                // Transaction History
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transaction History")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if walletViewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    } else if walletViewModel.transactions.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                                Text("No transactions yet")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            Spacer()
                        }
                    } else {
                        ForEach(walletViewModel.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.vertical)
        }
        .navigationTitle("Wallet")
        .onAppear {
            Task {
                await walletViewModel.fetchUserData()
                await walletViewModel.fetchTransactions()
            }
        }
        .refreshable {
            await walletViewModel.fetchUserData()
            await walletViewModel.fetchTransactions()
        }
        .sheet(isPresented: $showWithdrawalSheet) {
            WithdrawalSheet(amount: $withdrawalAmount, onWithdraw: initiateWithdrawal)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showStripeConnectSheet) {
            if let url = stripeConnectURL {
                SafariView(url: url)
            }
        }
        .alert(item: Binding(
            get: { walletViewModel.errorMessage.map { ErrorMessage(message: $0) } },
            set: { _ in walletViewModel.errorMessage = nil }
        )) { errorMessage in
            Alert(
                title: Text("Error"),
                message: Text(errorMessage.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Withdrawal Successful", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                withdrawalAmount = ""
            }
        } message: {
            Text("Your withdrawal request has been processed. Funds will be transferred to your connected bank account.")
        }
    }
    
    private func connectStripe() {
        Task {
            if let url = await walletViewModel.connectStripeAccount() {
                stripeConnectURL = url
                showStripeConnectSheet = true
            }
        }
    }
    
    private func initiateWithdrawal() {
        guard let amount = Double(withdrawalAmount), amount > 0 else {
            walletViewModel.errorMessage = "Please enter a valid amount"
            return
        }
        
        guard amount <= walletViewModel.walletBalance else {
            walletViewModel.errorMessage = "Insufficient balance"
            return
        }
        
        Task {
            showWithdrawalSheet = false
            let success = await walletViewModel.initiateWithdrawal(amount: amount)
            if success {
                showSuccessAlert = true
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var icon: String {
        switch transaction.type {
        case .purchase: return "cart.fill"
        case .sale: return "bag.fill"
        case .payout: return "arrow.down.to.line"
        }
    }
    
    var iconColor: Color {
        switch transaction.type {
        case .purchase: return .red
        case .sale: return .green
        case .payout: return .blue
        }
    }
    
    var amountPrefix: String {
        switch transaction.type {
        case .purchase: return "-"
        case .sale: return "+"
        case .payout: return "-"
        }
    }
    
    var typeString: String {
        switch transaction.type {
        case .purchase: return "Purchase"
        case .sale: return "Sale"
        case .payout: return "Withdrawal"
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(typeString)
                    .font(.headline)
                
                Text(dateFormatter.string(from: transaction.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if transaction.status != .completed {
                    Text(transaction.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(transaction.status == .pending ? .orange : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(transaction.status == .pending ? Color.orange.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Text("\(amountPrefix)$\(String(format: "%.2f", transaction.amount))")
                .font(.headline)
                .foregroundColor(iconColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct WithdrawalSheet: View {
    @Binding var amount: String
    let onWithdraw: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Withdraw Funds")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Enter the amount you want to withdraw to your bank account.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack {
                Text("$")
                    .font(.headline)
                
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                onWithdraw()
            }) {
                Text("Withdraw")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    NavigationView {
        WalletView()
            .environmentObject(WalletViewModel())
    }
} 
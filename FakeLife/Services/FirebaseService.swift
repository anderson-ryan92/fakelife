import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    // MARK: - User Methods
    
    func getCurrentUser() -> User? {
        guard let currentUser = Auth.auth().currentUser else { return nil }
        return User(id: currentUser.uid, email: currentUser.email ?? "", username: "", createdAt: Date())
    }
    
    func createUser(email: String, password: String) async throws -> User {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        let username = email.components(separatedBy: "@").first ?? "user"
        
        let newUser = User(
            id: userId,
            email: email,
            username: username,
            createdAt: Date()
        )
        
        try await saveUser(user: newUser)
        return newUser
    }
    
    func saveUser(user: User) async throws {
        guard let userId = user.id else { return }
        try db.collection("users").document(userId).setData(from: user)
    }
    
    func getUser(userId: String) async throws -> User? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        return try? snapshot.data(as: User.self)
    }
    
    func updateUserWalletBalance(userId: String, newBalance: Double) async throws {
        try await db.collection("users").document(userId).updateData(["walletBalance": newBalance])
    }
    
    // MARK: - Content Methods
    
    func uploadContent(content: Content, imageData: Data, contentData: Data) async throws -> Content {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirebaseService", code: 400, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var updatedContent = content
        updatedContent.userId = userId
        
        // Upload thumbnail
        let thumbnailPath = "thumbnails/\(UUID().uuidString).jpg"
        let thumbnailRef = storage.child(thumbnailPath)
        let _ = try await thumbnailRef.putDataAsync(imageData)
        let thumbnailURL = try await thumbnailRef.downloadURL().absoluteString
        
        // Upload content
        let extension = content.contentType == .video ? "mp4" : "jpg"
        let contentPath = "content/\(UUID().uuidString).\(extension)"
        let contentRef = storage.child(contentPath)
        let _ = try await contentRef.putDataAsync(contentData)
        let contentURL = try await contentRef.downloadURL().absoluteString
        
        // Update content with URLs
        updatedContent.thumbnailURL = thumbnailURL
        updatedContent.contentURL = contentURL
        
        // Save to Firestore
        let docRef = try db.collection("content").addDocument(from: updatedContent)
        updatedContent.id = docRef.documentID
        
        // Update user's uploaded content
        try await db.collection("users").document(userId).updateData([
            "uploadedContentIds": FieldValue.arrayUnion([docRef.documentID])
        ])
        
        return updatedContent
    }
    
    func getAllContent() async throws -> [Content] {
        let snapshot = try await db.collection("content").order(by: "createdAt", descending: true).getDocuments()
        
        var contentItems = [Content]()
        let currentUserId = Auth.auth().currentUser?.uid
        
        if let currentUserId = currentUserId {
            let userDoc = try await db.collection("users").document(currentUserId).getDocument()
            let user = try userDoc.data(as: User.self)
            let purchasedIds = user.purchasedContentIds
            
            for document in snapshot.documents {
                var content = try document.data(as: Content.self)
                content.isPurchased = purchasedIds.contains(content.id ?? "")
                contentItems.append(content)
            }
        } else {
            contentItems = try snapshot.documents.compactMap { try $0.data(as: Content.self) }
        }
        
        return contentItems
    }
    
    func getContentById(contentId: String) async throws -> Content? {
        let snapshot = try await db.collection("content").document(contentId).getDocument()
        return try? snapshot.data(as: Content.self)
    }
    
    func incrementDownloadCount(contentId: String) async throws {
        try await db.collection("content").document(contentId).updateData([
            "downloadCount": FieldValue.increment(Int64(1))
        ])
    }
    
    // MARK: - Transaction Methods
    
    func createTransaction(transaction: Transaction) async throws -> Transaction {
        var updatedTransaction = transaction
        
        let docRef = try db.collection("transactions").addDocument(from: transaction)
        updatedTransaction.id = docRef.documentID
        
        return updatedTransaction
    }
    
    func updateTransactionStatus(transactionId: String, status: TransactionStatus) async throws {
        try await db.collection("transactions").document(transactionId).updateData([
            "status": status.rawValue
        ])
    }
    
    func getUserTransactions(userId: String) async throws -> [Transaction] {
        let snapshot = try await db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Transaction.self) }
    }
} 
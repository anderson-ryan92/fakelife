import Foundation
import SwiftUI
import PhotosUI
import AVKit

class ContentViewModel: ObservableObject {
    @Published var contents: [Content] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Upload properties
    @Published var selectedContentType: ContentType = .photo
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var thumbnailImage: UIImage?
    @Published var contentData: Data?
    @Published var title = ""
    @Published var description = ""
    @Published var price: Double = 0.99
    @Published var tags = ""
    @Published var isUploading = false
    
    // Detail view properties
    @Published var selectedContent: Content?
    @Published var isPurchasing = false
    @Published var isDownloading = false
    
    init() {
        Task {
            await fetchAllContent()
        }
    }
    
    func fetchAllContent() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let fetchedContents = try await FirebaseService.shared.getAllContent()
            
            await MainActor.run {
                self.contents = fetchedContents
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error fetching content: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func uploadContent() async -> Bool {
        guard let thumbnailImage = thumbnailImage, let imageData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
            self.errorMessage = "Please select a thumbnail image"
            return false
        }
        
        guard let contentData = contentData else {
            self.errorMessage = "Please select content to upload"
            return false
        }
        
        guard !title.isEmpty else {
            self.errorMessage = "Please enter a title"
            return false
        }
        
        guard price > 0 else {
            self.errorMessage = "Please enter a valid price"
            return false
        }
        
        await MainActor.run {
            self.isUploading = true
            self.errorMessage = nil
        }
        
        do {
            // Create tags array from comma-separated string
            let tagsArray = tags.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let newContent = Content(
                userId: "",  // Will be set in Firebase service
                username: "",  // Will be set in Firebase service
                title: title,
                description: description,
                price: price,
                contentType: selectedContentType,
                thumbnailURL: "",  // Will be set after upload
                contentURL: "",  // Will be set after upload
                tags: tagsArray,
                createdAt: Date()
            )
            
            let _ = try await FirebaseService.shared.uploadContent(
                content: newContent,
                imageData: imageData,
                contentData: contentData
            )
            
            await fetchAllContent()
            
            await MainActor.run {
                self.resetUploadState()
                self.isUploading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Error uploading content: \(error.localizedDescription)"
                self.isUploading = false
            }
            return false
        }
    }
    
    func resetUploadState() {
        self.selectedPhotoItem = nil
        self.selectedVideoItem = nil
        self.thumbnailImage = nil
        self.contentData = nil
        self.title = ""
        self.description = ""
        self.price = 0.99
        self.tags = ""
    }
    
    func fetchContentDetail(contentId: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            if let content = try await FirebaseService.shared.getContentById(contentId: contentId) {
                await MainActor.run {
                    self.selectedContent = content
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Content not found"
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error fetching content: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func purchaseContent(content: Content) async -> Bool {
        guard let contentId = content.id else {
            self.errorMessage = "Invalid content"
            return false
        }
        
        await MainActor.run {
            self.isPurchasing = true
            self.errorMessage = nil
        }
        
        do {
            // Create intention configuration from Stripe
            let intentConfig = try await StripeService.shared.createPaymentIntent(
                amount: content.price,
                contentId: contentId,
                sellerUserId: content.userId
            )
            
            // Create transaction
            let transaction = Transaction(
                userId: Auth.auth().currentUser?.uid ?? "",
                contentId: contentId,
                sellerUserId: content.userId,
                amount: content.price,
                type: .purchase,
                status: .pending,
                createdAt: Date()
            )
            
            let savedTransaction = try await FirebaseService.shared.createTransaction(transaction: transaction)
            
            // Update user's purchased content
            if let userId = Auth.auth().currentUser?.uid {
                try await FirebaseService.shared.db.collection("users").document(userId).updateData([
                    "purchasedContentIds": FieldValue.arrayUnion([contentId])
                ])
            }
            
            // Update transaction status
            try await FirebaseService.shared.updateTransactionStatus(
                transactionId: savedTransaction.id!,
                status: .completed
            )
            
            // Update seller's wallet balance
            if let seller = try await FirebaseService.shared.getUser(userId: content.userId) {
                let newBalance = seller.walletBalance + content.price
                try await FirebaseService.shared.updateUserWalletBalance(
                    userId: content.userId,
                    newBalance: newBalance
                )
            }
            
            await fetchAllContent()
            
            await MainActor.run {
                self.isPurchasing = false
                if let index = self.contents.firstIndex(where: { $0.id == contentId }) {
                    self.contents[index].isPurchased = true
                }
                if self.selectedContent?.id == contentId {
                    self.selectedContent?.isPurchased = true
                }
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Error purchasing content: \(error.localizedDescription)"
                self.isPurchasing = false
            }
            return false
        }
    }
    
    func downloadContent(content: Content) async -> URL? {
        guard let contentId = content.id, content.isPurchased == true else {
            self.errorMessage = "You must purchase this content before downloading"
            return nil
        }
        
        await MainActor.run {
            self.isDownloading = true
            self.errorMessage = nil
        }
        
        do {
            // In a real app, this would download the file from Firebase Storage
            // For this demo, we're just using the content URL directly
            
            // Increment download count
            try await FirebaseService.shared.incrementDownloadCount(contentId: contentId)
            
            await MainActor.run {
                self.isDownloading = false
            }
            
            return URL(string: content.contentURL)
        } catch {
            await MainActor.run {
                self.errorMessage = "Error downloading content: \(error.localizedDescription)"
                self.isDownloading = false
            }
            return nil
        }
    }
    
    // MARK: - Image/Video Loading Methods
    
    func loadThumbnail(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.thumbnailImage = image
                    self.contentData = data
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error loading image: \(error.localizedDescription)"
            }
        }
    }
    
    func loadVideo(from item: PhotosPickerItem) async {
        do {
            if let movie = try await item.loadTransferable(type: MovieTransferable.self) {
                // Load thumbnail from video
                let asset = AVAsset(url: movie.url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                let time = CMTime(seconds: 0, preferredTimescale: 1)
                let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: imageRef)
                
                await MainActor.run {
                    self.thumbnailImage = thumbnail
                    self.contentData = try? Data(contentsOf: movie.url)
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error loading video: \(error.localizedDescription)"
            }
        }
    }
}

// Helper struct for loading movies from PhotosPicker
struct MovieTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
} 
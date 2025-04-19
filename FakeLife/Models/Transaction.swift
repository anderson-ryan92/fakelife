import Foundation
import FirebaseFirestoreSwift

enum TransactionType: String, Codable {
    case purchase
    case sale
    case payout
}

enum TransactionStatus: String, Codable {
    case pending
    case completed
    case failed
}

struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var contentId: String?
    var sellerUserId: String?
    var amount: Double
    var type: TransactionType
    var status: TransactionStatus
    var stripePaymentIntentId: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case contentId
        case sellerUserId
        case amount
        case type
        case status
        case stripePaymentIntentId
        case createdAt
    }
} 
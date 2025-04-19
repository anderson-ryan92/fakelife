import Foundation
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var username: String
    var profileImageURL: String?
    var createdAt: Date
    var walletBalance: Double = 0.0
    var stripeConnectAccountId: String?
    var purchasedContentIds: [String] = []
    var uploadedContentIds: [String] = []
    
    var isStripeConnected: Bool {
        return stripeConnectAccountId != nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case profileImageURL
        case createdAt
        case walletBalance
        case stripeConnectAccountId
        case purchasedContentIds
        case uploadedContentIds
    }
} 
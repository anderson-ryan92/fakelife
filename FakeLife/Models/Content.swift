import Foundation
import FirebaseFirestoreSwift

enum ContentType: String, Codable {
    case photo
    case video
}

struct Content: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var username: String
    var title: String
    var description: String
    var price: Double
    var contentType: ContentType
    var thumbnailURL: String
    var contentURL: String
    var tags: [String]
    var downloadCount: Int = 0
    var createdAt: Date
    var isPurchased: Bool? = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case title
        case description
        case price
        case contentType
        case thumbnailURL
        case contentURL
        case tags
        case downloadCount
        case createdAt
    }
} 
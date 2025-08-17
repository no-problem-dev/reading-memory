import Foundation

struct BookChat: Identifiable, Codable {
    let id: String
    let userBookId: String
    let userId: String
    let message: String
    let imageUrl: String?
    let isAI: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userBookId
        case userId
        case message
        case imageUrl
        case isAI
        case createdAt
    }
    
    init(id: String = UUID().uuidString,
         userBookId: String,
         userId: String,
         message: String,
         imageUrl: String? = nil,
         isAI: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.userBookId = userBookId
        self.userId = userId
        self.message = message
        self.imageUrl = imageUrl
        self.isAI = isAI
        self.createdAt = createdAt
    }
}
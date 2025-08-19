import Foundation
import FirebaseFirestore

struct Achievement: Identifiable, Codable {
    let id: String
    let badgeId: String
    let userId: String
    let unlockedAt: Date?
    var progress: Double
    var isUnlocked: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case badgeId
        case userId
        case unlockedAt
        case progress
        case isUnlocked
        case createdAt
        case updatedAt
    }
    
    init(id: String = UUID().uuidString,
         badgeId: String,
         userId: String,
         unlockedAt: Date? = nil,
         progress: Double = 0.0,
         isUnlocked: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.badgeId = badgeId
        self.userId = userId
        self.unlockedAt = unlockedAt
        self.progress = progress
        self.isUnlocked = isUnlocked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    mutating func unlock() {
        self.isUnlocked = true
        self.unlockedAt = Date()
        self.progress = 1.0
        self.updatedAt = Date()
    }
    
    mutating func updateProgress(_ newProgress: Double) {
        self.progress = min(max(newProgress, 0.0), 1.0)
        if progress >= 1.0 && !isUnlocked {
            unlock()
        }
        self.updatedAt = Date()
    }
}
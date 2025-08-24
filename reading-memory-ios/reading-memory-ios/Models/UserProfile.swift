import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String // Same as userId
    let displayName: String
    let avatarImageId: String?
    let bio: String?
    let favoriteGenres: [String]
    let readingGoal: Int? // Books per year
    let monthlyGoal: Int? // Books per month
    let streakStartDate: Date?
    let longestStreak: Int
    let currentStreak: Int
    let lastActivityDate: Date?
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case avatarImageId
        case bio
        case favoriteGenres
        case readingGoal
        case monthlyGoal
        case streakStartDate
        case longestStreak
        case currentStreak
        case lastActivityDate
        case isPublic
        case createdAt
        case updatedAt
    }
    
    init(id: String,
         displayName: String,
         avatarImageId: String? = nil,
         bio: String? = nil,
         favoriteGenres: [String] = [],
         readingGoal: Int? = nil,
         monthlyGoal: Int? = nil,
         streakStartDate: Date? = nil,
         longestStreak: Int = 0,
         currentStreak: Int = 0,
         lastActivityDate: Date? = nil,
         isPublic: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.displayName = displayName
        self.avatarImageId = avatarImageId
        self.bio = bio
        self.favoriteGenres = favoriteGenres
        self.readingGoal = readingGoal
        self.monthlyGoal = monthlyGoal
        self.streakStartDate = streakStartDate
        self.longestStreak = longestStreak
        self.currentStreak = currentStreak
        self.lastActivityDate = lastActivityDate
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
import Foundation

struct UserProfileDTO: Codable {
    let id: String
    let displayName: String
    let profileImageUrl: String?
    let bio: String?
    let favoriteGenres: [String]
    let readingGoal: Int?
    let monthlyGoal: Int?
    let streakStartDate: Date?
    let longestStreak: Int?
    let currentStreak: Int?
    let lastActivityDate: Date?
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    
    func toDomain() -> UserProfile {
        return UserProfile(
            id: id,
            displayName: displayName,
            profileImageUrl: profileImageUrl,
            bio: bio,
            favoriteGenres: favoriteGenres,
            readingGoal: readingGoal,
            monthlyGoal: monthlyGoal,
            streakStartDate: streakStartDate,
            longestStreak: longestStreak ?? 0,
            currentStreak: currentStreak ?? 0,
            lastActivityDate: lastActivityDate,
            isPublic: isPublic,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    init(from profile: UserProfile) {
        self.id = profile.id
        self.displayName = profile.displayName
        self.profileImageUrl = profile.profileImageUrl
        self.bio = profile.bio
        self.favoriteGenres = profile.favoriteGenres
        self.readingGoal = profile.readingGoal
        self.monthlyGoal = profile.monthlyGoal
        self.streakStartDate = profile.streakStartDate
        self.longestStreak = profile.longestStreak
        self.currentStreak = profile.currentStreak
        self.lastActivityDate = profile.lastActivityDate
        self.isPublic = profile.isPublic
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
    }
}

struct CreateUserProfileRequest: Codable {
    let displayName: String
    let favoriteGenres: [String]
    let readingGoal: Int?
    let monthlyGoal: Int?
    let bio: String?
    let isPublic: Bool
}

struct UpdateUserProfileRequest: Codable {
    let displayName: String?
    let profileImageUrl: String?
    let bio: String?
    let favoriteGenres: [String]?
    let readingGoal: Int?
    let monthlyGoal: Int?
    let isPublic: Bool?
}
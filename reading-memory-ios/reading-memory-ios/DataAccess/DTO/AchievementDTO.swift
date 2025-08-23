import Foundation

struct AchievementDTO: Codable {
    let id: String
    let badgeId: String
    let progress: Double
    let isUnlocked: Bool
    let unlockedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    func toDomain() -> Achievement {
        return Achievement(
            id: id,
            badgeId: badgeId,
            unlockedAt: unlockedAt,
            progress: progress,
            isUnlocked: isUnlocked,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    init(from achievement: Achievement) {
        self.id = achievement.id
        self.badgeId = achievement.badgeId
        self.progress = achievement.progress
        self.isUnlocked = achievement.isUnlocked
        self.unlockedAt = achievement.unlockedAt
        self.createdAt = achievement.createdAt
        self.updatedAt = achievement.updatedAt
    }
}
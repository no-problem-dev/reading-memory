import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol AchievementRepositoryProtocol {
    func createAchievement(_ achievement: Achievement) async throws
    func updateAchievement(_ achievement: Achievement) async throws
    func getAchievement(userId: String, badgeId: String) async throws -> Achievement?
    func getUserAchievements(userId: String) async throws -> [Achievement]
    func getUnlockedAchievements(userId: String) async throws -> [Achievement]
    func checkAndUpdateAchievements(userId: String, userBooks: [UserBook], streaks: [ReadingStreak]) async throws
}

class AchievementRepository: BaseRepository, AchievementRepositoryProtocol {
    static let shared = AchievementRepository()
    
    private override init() {
        super.init()
    }
    
    func createAchievement(_ achievement: Achievement) async throws {
        let document = db.collection("users")
            .document(achievement.userId)
            .collection("achievements")
            .document(achievement.id)
        
        try await document.setData(from: achievement)
    }
    
    func updateAchievement(_ achievement: Achievement) async throws {
        let document = db.collection("users")
            .document(achievement.userId)
            .collection("achievements")
            .document(achievement.id)
        
        var updatedAchievement = achievement
        updatedAchievement.updatedAt = Date()
        
        try await document.setData(from: updatedAchievement)
    }
    
    func getAchievement(userId: String, badgeId: String) async throws -> Achievement? {
        let query = db.collection("users")
            .document(userId)
            .collection("achievements")
            .whereField("badgeId", isEqualTo: badgeId)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else { return nil }
        
        return try? document.data(as: Achievement.self)
    }
    
    func getUserAchievements(userId: String) async throws -> [Achievement] {
        let query = db.collection("users")
            .document(userId)
            .collection("achievements")
            .order(by: "createdAt", descending: false)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Achievement.self)
        }
    }
    
    func getUnlockedAchievements(userId: String) async throws -> [Achievement] {
        let query = db.collection("users")
            .document(userId)
            .collection("achievements")
            .whereField("isUnlocked", isEqualTo: true)
            .order(by: "unlockedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Achievement.self)
        }
    }
    
    func checkAndUpdateAchievements(userId: String, userBooks: [UserBook], streaks: [ReadingStreak]) async throws {
        // すべてのバッジを取得
        let badges = Badge.defaultBadges
        
        // ユーザーの既存のアチーブメントを取得
        let existingAchievements = try await getUserAchievements(userId: userId)
        let existingBadgeIds = Set(existingAchievements.map { $0.badgeId })
        
        for badge in badges {
            // 既存のアチーブメントを取得または新規作成
            var achievement: Achievement
            
            if let existing = existingAchievements.first(where: { $0.badgeId == badge.id }) {
                achievement = existing
            } else {
                achievement = Achievement(
                    badgeId: badge.id,
                    userId: userId
                )
            }
            
            // 進捗を計算
            let progress = calculateProgress(for: badge, userBooks: userBooks, streaks: streaks)
            
            // 進捗が変わった場合のみ更新
            if achievement.progress != progress {
                achievement.updateProgress(progress)
                
                if existingBadgeIds.contains(badge.id) {
                    try await updateAchievement(achievement)
                } else {
                    try await createAchievement(achievement)
                }
            }
        }
    }
    
    private func calculateProgress(for badge: Badge, userBooks: [UserBook], streaks: [ReadingStreak]) -> Double {
        switch badge.requirement.type {
        case .booksRead:
            let completedBooks = userBooks.filter { $0.status == .completed }.count
            return min(Double(completedBooks) / Double(badge.requirement.value), 1.0)
            
        case .streakDays:
            let maxStreak = streaks.map { $0.longestStreak }.max() ?? 0
            return min(Double(maxStreak) / Double(badge.requirement.value), 1.0)
            
        case .genreBooks:
            guard let targetGenre = badge.requirement.genre else { return 0 }
            let genreBooks = userBooks.filter { book in
                book.status == .completed && (book.tags ?? []).contains(targetGenre)
            }.count
            return min(Double(genreBooks) / Double(badge.requirement.value), 1.0)
            
        case .yearlyGoal:
            // 年間目標達成は別途GoalViewModelで判定
            return 0
            
        case .reviews:
            let booksWithRating = userBooks.filter { $0.rating != nil }.count
            return min(Double(booksWithRating) / Double(badge.requirement.value), 1.0)
            
        case .memos:
            // メモ数のカウントは別途実装が必要
            return 0
        }
    }
}
import Foundation

protocol AchievementRepositoryProtocol {
    func createAchievement(_ achievement: Achievement) async throws
    func updateAchievement(_ achievement: Achievement) async throws
    func getAchievement(badgeId: String) async throws -> Achievement?
    func getUserAchievements() async throws -> [Achievement]
    func getUnlockedAchievements() async throws -> [Achievement]
    func checkAndUpdateAchievements(books: [Book], streaks: [ReadingStreak]) async throws
}

class AchievementRepository: AchievementRepositoryProtocol {
    static let shared = AchievementRepository()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func createAchievement(_ achievement: Achievement) async throws {
        _ = try await apiClient.createAchievement(achievement)
    }
    
    func updateAchievement(_ achievement: Achievement) async throws {
        // APIでは作成と更新が同じエンドポイント
        _ = try await apiClient.createAchievement(achievement)
    }
    
    func getAchievement(badgeId: String) async throws -> Achievement? {
        let achievements = try await apiClient.getAchievements()
        return achievements.first { $0.badgeId == badgeId }
    }
    
    func getUserAchievements() async throws -> [Achievement] {
        return try await apiClient.getAchievements()
    }
    
    func getUnlockedAchievements() async throws -> [Achievement] {
        let achievements = try await apiClient.getAchievements()
        return achievements.filter { $0.isUnlocked }
    }
    
    func checkAndUpdateAchievements(books: [Book], streaks: [ReadingStreak]) async throws {
        // すべてのバッジを取得
        let badges = Badge.defaultBadges
        
        // ユーザーの既存のアチーブメントを取得
        let existingAchievements = try await getUserAchievements()
        let existingBadgeIds = Set(existingAchievements.map { $0.badgeId })
        
        for badge in badges {
            // 既存のアチーブメントを取得または新規作成
            var achievement: Achievement
            
            if let existing = existingAchievements.first(where: { $0.badgeId == badge.id }) {
                achievement = existing
            } else {
                // サーバー側でuserIdが設定される
                achievement = Achievement(
                    badgeId: badge.id
                )
            }
            
            // 進捗を計算
            let progress = calculateProgress(for: badge, books: books, streaks: streaks)
            
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
    
    private func calculateProgress(for badge: Badge, books: [Book], streaks: [ReadingStreak]) -> Double {
        switch badge.requirement.type {
        case .booksRead:
            let completedBooks = books.filter { $0.status == .completed }.count
            return min(Double(completedBooks) / Double(badge.requirement.value), 1.0)
            
        case .streakDays:
            let maxStreak = streaks.map { $0.longestStreak }.max() ?? 0
            return min(Double(maxStreak) / Double(badge.requirement.value), 1.0)
            
        case .genreBooks:
            guard let targetGenre = badge.requirement.genre else { return 0 }
            let genreBooks = books.filter { book in
                book.status == .completed && book.tags.contains(targetGenre)
            }.count
            return min(Double(genreBooks) / Double(badge.requirement.value), 1.0)
            
        case .yearlyGoal:
            // 年間目標達成は別途GoalViewModelで判定
            return 0
            
        case .reviews:
            let booksWithRating = books.filter { $0.rating != nil }.count
            return min(Double(booksWithRating) / Double(badge.requirement.value), 1.0)
            
        case .memos:
            // メモ数のカウントは別途実装が必要
            return 0
        }
    }
}
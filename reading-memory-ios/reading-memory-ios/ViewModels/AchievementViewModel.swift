import Foundation
import FirebaseAuth

@Observable
class AchievementViewModel: BaseViewModel {
    private let achievementRepository = AchievementRepository.shared
    private let userBookRepository = UserBookRepository.shared
    private let streakRepository = StreakRepository.shared
    
    var allAchievements: [Achievement] = []
    var unlockedAchievements: [Achievement] = []
    var badges: [Badge] = Badge.defaultBadges
    var badgesByCategory: [Badge.BadgeCategory: [Badge]] = [:]
    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    override init() {
        super.init()
        // アチーブメントデータは比較的変更が少ないため、キャッシュ期間を長めに設定
        cacheValidityDuration = 600 // 10分
    }
    
    func loadAchievements() async {
        await executeLoadTask { [weak self] in
            guard let self = self else { return }
            // 初回読み込みまたはキャッシュ期限切れの場合のみデータを取得
            if self.shouldRefreshData() {
                await self.fetchAchievementData()
            }
        }
    }
    
    @MainActor
    private func fetchAchievementData() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // ユーザーのアチーブメントを取得
            allAchievements = try await achievementRepository.getUserAchievements(userId: userId)
            unlockedAchievements = allAchievements.filter { $0.isUnlocked }
            
            // バッジをカテゴリー別に分類
            organizeBadgesByCategory()
            
            // 進捗を更新（別タスクで実行）
            Task {
                await updateAchievementProgress(shouldReload: false)
            }
            
            // データ取得完了をマーク
            markDataAsFetched()
            
        } catch {
            errorMessage = "バッジの読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func organizeBadgesByCategory() {
        badgesByCategory = Dictionary(grouping: badges) { $0.category }
    }
    
    func updateAchievementProgress(shouldReload: Bool = true) async {
        guard let userId = userId else { return }
        
        do {
            // 必要なデータを取得
            let userBooks = try await userBookRepository.getUserBooks(for: userId)
            let streaks = try await streakRepository.getAllStreaks(userId: userId)
            
            // アチーブメントの進捗を更新
            try await achievementRepository.checkAndUpdateAchievements(
                userId: userId,
                userBooks: userBooks,
                streaks: streaks
            )
            
            // 必要に応じてリロード
            if shouldReload {
                forceRefresh()
                await loadAchievements()
            }
        } catch {
            print("アチーブメント進捗の更新に失敗: \(error)")
        }
    }
    
    // バッジのアチーブメント情報を取得
    func getAchievement(for badge: Badge) -> Achievement? {
        return allAchievements.first { $0.badgeId == badge.id }
    }
    
    // バッジの進捗を取得
    func getProgress(for badge: Badge) -> Double {
        return getAchievement(for: badge)?.progress ?? 0.0
    }
    
    // バッジが解除されているか
    func isUnlocked(badge: Badge) -> Bool {
        return getAchievement(for: badge)?.isUnlocked ?? false
    }
    
    // 次に獲得可能なバッジを取得
    func getNextAchievableBadges(limit: Int = 3) -> [Badge] {
        let unlockedBadgeIds = Set(unlockedAchievements.map { $0.badgeId })
        
        return badges
            .filter { !unlockedBadgeIds.contains($0.id) }
            .sorted { badge1, badge2 in
                let progress1 = getProgress(for: badge1)
                let progress2 = getProgress(for: badge2)
                return progress1 > progress2
            }
            .prefix(limit)
            .map { $0 }
    }
    
    // 最近解除されたバッジを取得
    func getRecentlyUnlockedBadges(limit: Int = 5) -> [(badge: Badge, achievement: Achievement)] {
        let sortedUnlocked = unlockedAchievements
            .sorted { ($0.unlockedAt ?? Date()) > ($1.unlockedAt ?? Date()) }
            .prefix(limit)
        
        var results: [(Badge, Achievement)] = []
        
        for achievement in sortedUnlocked {
            if let badge = badges.first(where: { $0.id == achievement.badgeId }) {
                results.append((badge, achievement))
            }
        }
        
        return results
    }
    
    // カテゴリー別の進捗を取得
    func getCategoryProgress(category: Badge.BadgeCategory) -> (unlocked: Int, total: Int) {
        let categoryBadges = badgesByCategory[category] ?? []
        let unlockedCount = categoryBadges.filter { isUnlocked(badge: $0) }.count
        return (unlockedCount, categoryBadges.count)
    }
    
    // 全体の達成率
    var overallCompletionRate: Double {
        guard !badges.isEmpty else { return 0 }
        return Double(unlockedAchievements.count) / Double(badges.count)
    }
    
    // バッジ獲得時の処理（通知など）
    func celebrateUnlock(badge: Badge) {
        // TODO: 通知を表示、アニメーション、効果音など
        print("🎉 バッジ「\(badge.name)」を獲得しました！")
    }
}
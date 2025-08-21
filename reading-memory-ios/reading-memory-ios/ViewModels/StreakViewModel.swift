import Foundation
import FirebaseAuth

@Observable
class StreakViewModel: BaseViewModel {
    private let streakRepository = StreakRepository.shared
    private let activityRepository = ActivityRepository.shared
    
    var streaks: [ReadingStreak] = []
    var combinedStreak: ReadingStreak?
    var readingStreak: ReadingStreak?
    var memoStreak: ReadingStreak?
    var weeklyActivity: [Bool] = []
    var recentActivities: [ReadingActivity] = []
    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    override init() {
        super.init()
        // ストリークデータは頻繁に更新されるため、キャッシュ期間を短めに設定
        cacheValidityDuration = 60 // 1分
    }
    
    func loadStreaks() async {
        await executeLoadTask { [weak self] in
            guard let self = self else { return }
            // 初回読み込みまたはキャッシュ期限切れの場合のみデータを取得
            if self.shouldRefreshData() {
                await self.fetchStreakData()
            }
        }
    }
    
    @MainActor
    private func fetchStreakData() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // すべてのストリークを取得
            streaks = try await streakRepository.getAllStreaks(userId: userId)
            
            // タイプ別に分類
            combinedStreak = streaks.first { $0.type == .combined }
            readingStreak = streaks.first { $0.type == .reading }
            memoStreak = streaks.first { $0.type == .chatMemo }
            
            // 週間アクティビティを取得
            if let combined = combinedStreak {
                weeklyActivity = combined.getWeeklyActivity()
            } else {
                weeklyActivity = Array(repeating: false, count: 7)
            }
            
            // 最近のアクティビティを取得
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            recentActivities = try await activityRepository.getActivitiesInRange(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            
            // データ取得完了をマーク
            markDataAsFetched()
            
        } catch {
            errorMessage = "ストリークの読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func recordActivity(type: ReadingStreak.StreakType, date: Date = Date()) async {
        guard let userId = userId else { return }
        
        do {
            try await streakRepository.recordActivity(
                userId: userId,
                type: type,
                date: date
            )
            
            // キャッシュを無効化して再読み込み
            forceRefresh()
            await loadStreaks()
        } catch {
            errorMessage = "アクティビティの記録に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func recordBookActivity() async {
        guard let userId = userId else { return }
        
        do {
            // 本の読書アクティビティを記録
            try await activityRepository.recordBookRead(userId: userId)
            
            // キャッシュを無効化して再読み込み
            forceRefresh()
            await loadStreaks()
        } catch {
            errorMessage = "読書アクティビティの記録に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func recordMemoActivity() async {
        guard let userId = userId else { return }
        
        do {
            // メモ作成アクティビティを記録
            try await activityRepository.recordMemoWritten(userId: userId)
            
            // キャッシュを無効化して再読み込み
            forceRefresh()
            await loadStreaks()
        } catch {
            errorMessage = "メモアクティビティの記録に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // ストリークが途切れるまでの時間を取得
    var hoursUntilStreakEnds: Int {
        combinedStreak?.hoursUntilStreakEnds ?? 0
    }
    
    // 今日のアクティビティ状況
    var hasActivityToday: Bool {
        combinedStreak?.isActiveToday ?? false
    }
    
    // ストリークを継続可能か
    var canContinueStreak: Bool {
        combinedStreak?.canContinueStreak ?? true
    }
    
    // 月間アクティビティカウント
    var monthlyActivityCount: Int {
        combinedStreak?.getMonthlyActivityCount() ?? 0
    }
    
    // アクティビティサマリーを取得
    func getActivitySummary(days: Int) async -> (totalBooks: Int, totalMemos: Int, activeDays: Int) {
        guard let userId = userId else { return (0, 0, 0) }
        
        do {
            return try await activityRepository.getActivitySummary(
                userId: userId,
                days: days
            )
        } catch {
            print("アクティビティサマリーの取得に失敗: \(error)")
            return (0, 0, 0)
        }
    }
    
    // カレンダー用：特定月のアクティビティを取得
    func getMonthlyActivities(year: Int, month: Int) async -> [Date] {
        guard let userId = userId else { return [] }
        
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month)
        
        guard let startDate = calendar.date(from: components),
              let endDate = calendar.dateInterval(of: .month, for: startDate)?.end else {
            return []
        }
        
        do {
            let activities = try await activityRepository.getActivitiesInRange(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            
            return activities.filter { $0.hasActivity }.map { $0.date }
        } catch {
            print("月間アクティビティの取得に失敗: \(error)")
            return []
        }
    }
}
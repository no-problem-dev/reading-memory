import Foundation

protocol ActivityRepositoryProtocol {
    func createActivity(_ activity: ReadingActivity) async throws
    func updateActivity(_ activity: ReadingActivity) async throws
    func getTodayActivity() async throws -> ReadingActivity?
    func getActivity(date: Date) async throws -> ReadingActivity?
    func getActivitiesInRange(startDate: Date, endDate: Date) async throws -> [ReadingActivity]
    func recordBookRead(date: Date) async throws
    func recordMemoWritten(date: Date) async throws
}

class ActivityRepository: ActivityRepositoryProtocol {
    static let shared = ActivityRepository()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func createActivity(_ activity: ReadingActivity) async throws {
        _ = try await apiClient.createActivity(activity)
    }
    
    func updateActivity(_ activity: ReadingActivity) async throws {
        // APIでは作成と更新が同じエンドポイント
        _ = try await apiClient.createActivity(activity)
    }
    
    func getTodayActivity() async throws -> ReadingActivity? {
        return try await getActivity(date: Date())
    }
    
    func getActivity(date: Date) async throws -> ReadingActivity? {
        let activities = try await apiClient.getActivities()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return activities.first { activity in
            calendar.isDate(activity.date, inSameDayAs: startOfDay)
        }
    }
    
    func getActivitiesInRange(startDate: Date, endDate: Date) async throws -> [ReadingActivity] {
        let activities = try await apiClient.getActivities()
        
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let endOfEndDate = calendar.dateInterval(of: .day, for: endDate)?.end ?? endDate
        
        return activities.filter { activity in
            activity.date >= startOfStartDate && activity.date < endOfEndDate
        }.sorted { $0.date < $1.date }
    }
    
    func recordBookRead(date: Date = Date()) async throws {
        var activity = try await getActivity(date: date)
        
        if activity == nil {
            // サーバー側でuserIdが設定される
            activity = ReadingActivity.createTodayActivity()
        }
        
        activity?.recordBookRead()
        
        if let updatedActivity = activity {
            try await updateActivity(updatedActivity)
        }
        
        // ストリークも更新
        try await StreakRepository.shared.recordMultipleActivities(
            types: [.reading, .combined],
            date: date
        )
    }
    
    func recordMemoWritten(date: Date = Date()) async throws {
        var activity = try await getActivity(date: date)
        
        if activity == nil {
            // サーバー側でuserIdが設定される
            activity = ReadingActivity.createTodayActivity()
        }
        
        activity?.recordMemoWritten()
        
        if let updatedActivity = activity {
            try await updateActivity(updatedActivity)
        }
        
        // ストリークも更新
        try await StreakRepository.shared.recordMultipleActivities(
            types: [.chatMemo, .combined],
            date: date
        )
    }
    
    // 統計用：特定期間のアクティビティサマリーを取得
    func getActivitySummary(days: Int) async throws -> (totalBooks: Int, totalMemos: Int, activeDays: Int) {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            return (0, 0, 0)
        }
        
        let activities = try await getActivitiesInRange(startDate: startDate, endDate: endDate)
        
        let totalBooks = activities.reduce(0) { $0 + $1.booksRead }
        let totalMemos = activities.reduce(0) { $0 + $1.memosWritten }
        let activeDays = activities.filter { $0.hasActivity }.count
        
        return (totalBooks, totalMemos, activeDays)
    }
}
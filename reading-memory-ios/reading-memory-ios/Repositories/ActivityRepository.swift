import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol ActivityRepositoryProtocol {
    func createActivity(_ activity: ReadingActivity) async throws
    func updateActivity(_ activity: ReadingActivity) async throws
    func getTodayActivity(userId: String) async throws -> ReadingActivity?
    func getActivity(userId: String, date: Date) async throws -> ReadingActivity?
    func getActivitiesInRange(userId: String, startDate: Date, endDate: Date) async throws -> [ReadingActivity]
    func recordBookRead(userId: String, date: Date) async throws
    func recordMemoWritten(userId: String, date: Date) async throws
}

class ActivityRepository: BaseRepository, ActivityRepositoryProtocol {
    static let shared = ActivityRepository()
    
    private override init() {
        super.init()
    }
    
    func createActivity(_ activity: ReadingActivity) async throws {
        let document = db.collection("users")
            .document(activity.userId)
            .collection("activities")
            .document(activity.id)
        
        try await document.setData(from: activity)
    }
    
    func updateActivity(_ activity: ReadingActivity) async throws {
        let document = db.collection("users")
            .document(activity.userId)
            .collection("activities")
            .document(activity.id)
        
        var updatedActivity = activity
        updatedActivity.updatedAt = Date()
        
        try await document.setData(from: updatedActivity)
    }
    
    func getTodayActivity(userId: String) async throws -> ReadingActivity? {
        return try await getActivity(userId: userId, date: Date())
    }
    
    func getActivity(userId: String, date: Date) async throws -> ReadingActivity? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // 日付ベースのIDを生成
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: startOfDay)
        let activityId = "\(userId)_\(dateString)"
        
        let document = db.collection("users")
            .document(userId)
            .collection("activities")
            .document(activityId)
        
        let snapshot = try await document.getDocument()
        return try? snapshot.data(as: ReadingActivity.self)
    }
    
    func getActivitiesInRange(userId: String, startDate: Date, endDate: Date) async throws -> [ReadingActivity] {
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let endOfEndDate = calendar.dateInterval(of: .day, for: endDate)?.end ?? endDate
        
        let query = db.collection("users")
            .document(userId)
            .collection("activities")
            .whereField("date", isGreaterThanOrEqualTo: startOfStartDate)
            .whereField("date", isLessThan: endOfEndDate)
            .order(by: "date", descending: false)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: ReadingActivity.self)
        }
    }
    
    func recordBookRead(userId: String, date: Date = Date()) async throws {
        var activity = try await getActivity(userId: userId, date: date)
        
        if activity == nil {
            activity = ReadingActivity.createTodayActivity(userId: userId)
        }
        
        activity?.recordBookRead()
        
        if let updatedActivity = activity {
            try await updateActivity(updatedActivity)
        }
        
        // ストリークも更新
        try await StreakRepository.shared.recordMultipleActivities(
            userId: userId,
            types: [.reading, .combined],
            date: date
        )
    }
    
    func recordMemoWritten(userId: String, date: Date = Date()) async throws {
        var activity = try await getActivity(userId: userId, date: date)
        
        if activity == nil {
            activity = ReadingActivity.createTodayActivity(userId: userId)
        }
        
        activity?.recordMemoWritten()
        
        if let updatedActivity = activity {
            try await updateActivity(updatedActivity)
        }
        
        // ストリークも更新
        try await StreakRepository.shared.recordMultipleActivities(
            userId: userId,
            types: [.chatMemo, .combined],
            date: date
        )
    }
    
    // 統計用：特定期間のアクティビティサマリーを取得
    func getActivitySummary(userId: String, days: Int) async throws -> (totalBooks: Int, totalMemos: Int, activeDays: Int) {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            return (0, 0, 0)
        }
        
        let activities = try await getActivitiesInRange(userId: userId, startDate: startDate, endDate: endDate)
        
        let totalBooks = activities.reduce(0) { $0 + $1.booksRead }
        let totalMemos = activities.reduce(0) { $0 + $1.memosWritten }
        let activeDays = activities.filter { $0.hasActivity }.count
        
        return (totalBooks, totalMemos, activeDays)
    }
}
import Foundation

protocol StreakRepositoryProtocol {
    func createStreak(_ streak: ReadingStreak) async throws
    func updateStreak(_ streak: ReadingStreak) async throws
    func getStreak(type: ReadingStreak.StreakType) async throws -> ReadingStreak?
    func getAllStreaks() async throws -> [ReadingStreak]
    func recordActivity(type: ReadingStreak.StreakType, date: Date) async throws
}

class StreakRepository: StreakRepositoryProtocol {
    static let shared = StreakRepository()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func createStreak(_ streak: ReadingStreak) async throws {
        _ = try await apiClient.createOrUpdateStreak(streak)
    }
    
    func updateStreak(_ streak: ReadingStreak) async throws {
        _ = try await apiClient.createOrUpdateStreak(streak)
    }
    
    func getStreak(type: ReadingStreak.StreakType) async throws -> ReadingStreak? {
        let streaks = try await apiClient.getStreaks()
        return streaks.first { $0.type == type }
    }
    
    func getAllStreaks() async throws -> [ReadingStreak] {
        return try await apiClient.getStreaks()
    }
    
    func recordActivity(type: ReadingStreak.StreakType, date: Date = Date()) async throws {
        // 既存のストリークを取得または新規作成
        var streak = try await getStreak(type: type)
        
        if streak == nil {
            // 新規ストリークを作成（サーバー側でuserIdが設定される）
            streak = ReadingStreak(
                type: type
            )
        }
        
        // アクティビティを記録
        streak?.recordActivity(on: date)
        
        // データベースに保存
        if let updatedStreak = streak {
            try await updateStreak(updatedStreak)
        }
    }
    
    // バッチ処理用：複数のアクティビティタイプを同時に記録
    func recordMultipleActivities(types: [ReadingStreak.StreakType], date: Date = Date()) async throws {
        for type in types {
            try await recordActivity(type: type, date: date)
        }
    }
}
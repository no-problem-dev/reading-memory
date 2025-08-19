import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol StreakRepositoryProtocol {
    func createStreak(_ streak: ReadingStreak) async throws
    func updateStreak(_ streak: ReadingStreak) async throws
    func getStreak(userId: String, type: ReadingStreak.StreakType) async throws -> ReadingStreak?
    func getAllStreaks(userId: String) async throws -> [ReadingStreak]
    func recordActivity(userId: String, type: ReadingStreak.StreakType, date: Date) async throws
}

class StreakRepository: BaseRepository, StreakRepositoryProtocol {
    static let shared = StreakRepository()
    
    private override init() {
        super.init()
    }
    
    func createStreak(_ streak: ReadingStreak) async throws {
        let document = db.collection("users")
            .document(streak.userId)
            .collection("streaks")
            .document(streak.id)
        
        try await document.setData(from: streak)
    }
    
    func updateStreak(_ streak: ReadingStreak) async throws {
        let document = db.collection("users")
            .document(streak.userId)
            .collection("streaks")
            .document(streak.id)
        
        var updatedStreak = streak
        updatedStreak.updatedAt = Date()
        
        try await document.setData(from: updatedStreak)
    }
    
    func getStreak(userId: String, type: ReadingStreak.StreakType) async throws -> ReadingStreak? {
        let query = db.collection("users")
            .document(userId)
            .collection("streaks")
            .whereField("type", isEqualTo: type.rawValue)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else { return nil }
        
        return try? document.data(as: ReadingStreak.self)
    }
    
    func getAllStreaks(userId: String) async throws -> [ReadingStreak] {
        let query = db.collection("users")
            .document(userId)
            .collection("streaks")
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: ReadingStreak.self)
        }
    }
    
    func recordActivity(userId: String, type: ReadingStreak.StreakType, date: Date = Date()) async throws {
        // 既存のストリークを取得または新規作成
        var streak = try await getStreak(userId: userId, type: type)
        
        if streak == nil {
            // 新規ストリークを作成
            streak = ReadingStreak(
                userId: userId,
                type: type
            )
        }
        
        // アクティビティを記録
        streak?.recordActivity(on: date)
        
        // データベースに保存
        if let updatedStreak = streak {
            try await updateStreak(updatedStreak)
            
            // UserProfileのストリーク情報も更新
            try await updateUserProfileStreak(userId: userId, streak: updatedStreak)
        }
    }
    
    private func updateUserProfileStreak(userId: String, streak: ReadingStreak) async throws {
        // 複合ストリーク（combined）の場合のみUserProfileを更新
        guard streak.type == .combined else { return }
        
        let profileDoc = db.collection("userProfiles").document(userId)
        
        try await profileDoc.updateData([
            "currentStreak": streak.currentStreak,
            "longestStreak": streak.longestStreak,
            "lastActivityDate": streak.lastActivityDate ?? NSNull(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // バッチ処理用：複数のアクティビティタイプを同時に記録
    func recordMultipleActivities(userId: String, types: [ReadingStreak.StreakType], date: Date = Date()) async throws {
        for type in types {
            try await recordActivity(userId: userId, type: type, date: date)
        }
    }
}
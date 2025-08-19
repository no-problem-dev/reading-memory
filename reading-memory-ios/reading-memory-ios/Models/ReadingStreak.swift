import Foundation
import FirebaseFirestore

struct ReadingStreak: Identifiable, Codable {
    let id: String
    let userId: String
    let type: StreakType
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?
    var streakDates: [Date]
    let createdAt: Date
    var updatedAt: Date
    
    enum StreakType: String, Codable {
        case reading = "reading"       // 読書した日
        case chatMemo = "chatMemo"     // メモを書いた日
        case combined = "combined"     // いずれかの活動
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case currentStreak
        case longestStreak
        case lastActivityDate
        case streakDates
        case createdAt
        case updatedAt
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         type: StreakType,
         currentStreak: Int = 0,
         longestStreak: Int = 0,
         lastActivityDate: Date? = nil,
         streakDates: [Date] = [],
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.type = type
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
        self.streakDates = streakDates
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var isActiveToday: Bool {
        guard let lastActivity = lastActivityDate else { return false }
        return Calendar.current.isDateInToday(lastActivity)
    }
    
    var canContinueStreak: Bool {
        guard let lastActivity = lastActivityDate else { return true }
        let calendar = Calendar.current
        let daysSinceLastActivity = calendar.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
        return daysSinceLastActivity <= 1
    }
    
    var streakEndDate: Date? {
        guard let lastActivity = lastActivityDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: 1, to: lastActivity)
    }
    
    var hoursUntilStreakEnds: Int? {
        guard let endDate = streakEndDate else { return nil }
        let hours = Calendar.current.dateComponents([.hour], from: Date(), to: endDate).hour ?? 0
        return max(0, hours)
    }
    
    mutating func recordActivity(on date: Date = Date()) {
        let calendar = Calendar.current
        let activityDate = calendar.startOfDay(for: date)
        
        // 既に今日の活動が記録されている場合は何もしない
        if let lastActivity = lastActivityDate,
           calendar.isDate(lastActivity, inSameDayAs: activityDate) {
            return
        }
        
        // ストリークの継続判定
        if canContinueStreak {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
        
        // 最長ストリークの更新
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        // 活動日の記録
        lastActivityDate = activityDate
        streakDates.append(activityDate)
        
        // 古い日付を削除（直近365日分のみ保持）
        if streakDates.count > 365 {
            streakDates = Array(streakDates.suffix(365))
        }
        
        updatedAt = Date()
    }
    
    func getWeeklyActivity() -> [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var weekActivity: [Bool] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let hasActivity = streakDates.contains { calendar.isDate($0, inSameDayAs: date) }
                weekActivity.insert(hasActivity, at: 0)
            }
        }
        
        return weekActivity
    }
    
    func getMonthlyActivityCount() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return streakDates.filter { date in
            date >= startOfMonth && date <= now
        }.count
    }
}
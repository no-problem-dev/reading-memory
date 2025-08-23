import Foundation

struct ReadingGoal: Identifiable, Codable {
    let id: String
    let type: GoalType
    let targetValue: Int
    var currentValue: Int
    let period: GoalPeriod
    let startDate: Date
    let endDate: Date
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum GoalType: String, Codable {
        case bookCount = "bookCount"
        case readingDays = "readingDays"
        case genreCount = "genreCount"
        case custom = "custom"
    }
    
    enum GoalPeriod: String, Codable {
        case yearly = "yearly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case custom = "custom"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case targetValue
        case currentValue
        case period
        case startDate
        case endDate
        case isActive
        case createdAt
        case updatedAt
    }
    
    init(id: String = UUID().uuidString,
         type: GoalType,
         targetValue: Int,
         currentValue: Int = 0,
         period: GoalPeriod,
         startDate: Date,
         endDate: Date,
         isActive: Bool = true,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var isCompleted: Bool {
        currentValue >= targetValue
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    var typeDisplayName: String {
        switch type {
        case .bookCount:
            return "読書冊数"
        case .readingDays:
            return "読書日数"
        case .genreCount:
            return "ジャンル数"
        case .custom:
            return "カスタム目標"
        }
    }
    
    var periodDisplayName: String {
        switch period {
        case .yearly:
            return "年間"
        case .monthly:
            return "月間"
        case .quarterly:
            return "四半期"
        case .custom:
            return "カスタム期間"
        }
    }
    
    static func createYearlyGoal(targetBooks: Int) -> ReadingGoal {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
        let endOfYear = calendar.dateInterval(of: .year, for: now)?.end ?? now
        
        return ReadingGoal(
            type: .bookCount,
            targetValue: targetBooks,
            period: .yearly,
            startDate: startOfYear,
            endDate: endOfYear
        )
    }
    
    static func createMonthlyGoal(targetBooks: Int) -> ReadingGoal {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        return ReadingGoal(
            type: .bookCount,
            targetValue: targetBooks,
            period: .monthly,
            startDate: startOfMonth,
            endDate: endOfMonth
        )
    }
}
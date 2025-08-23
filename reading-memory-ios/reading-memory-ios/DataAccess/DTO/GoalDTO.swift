import Foundation

struct GoalDTO: Codable {
    let id: String
    let type: String
    let targetValue: Int
    let currentValue: Int
    let period: String
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    func toDomain() -> ReadingGoal {
        let goalType: ReadingGoal.GoalType
        switch type {
        case "bookCount":
            goalType = .bookCount
        case "readingDays":
            goalType = .readingDays
        case "genreCount":
            goalType = .genreCount
        case "custom":
            goalType = .custom
        default:
            goalType = .bookCount
        }
        
        let goalPeriod: ReadingGoal.GoalPeriod
        switch period {
        case "yearly":
            goalPeriod = .yearly
        case "monthly":
            goalPeriod = .monthly
        case "quarterly":
            goalPeriod = .quarterly
        case "custom":
            goalPeriod = .custom
        default:
            goalPeriod = .monthly
        }
        
        return ReadingGoal(
            id: id,
            type: goalType,
            targetValue: targetValue,
            currentValue: currentValue,
            period: goalPeriod,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    init(from goal: ReadingGoal) {
        self.id = goal.id
        self.type = goal.type.rawValue
        self.targetValue = goal.targetValue
        self.currentValue = goal.currentValue
        self.period = goal.period.rawValue
        self.startDate = goal.startDate
        self.endDate = goal.endDate
        self.isActive = goal.isActive
        self.createdAt = goal.createdAt
        self.updatedAt = goal.updatedAt
    }
}
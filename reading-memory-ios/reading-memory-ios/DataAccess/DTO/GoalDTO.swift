import Foundation

struct GoalDTO: Codable {
    let id: String
    let type: String
    let targetBooks: Int?
    let targetValue: Int?
    let currentBooks: Int?
    let currentValue: Int?
    let startDate: Date
    let endDate: Date
    let isAchieved: Bool?
    let isActive: Bool?
    let period: String?
    let createdAt: Date
    let updatedAt: Date
    
    func toDomain() -> ReadingGoal {
        // Handle both old API format (type: "monthly") and new format (type: "bookCount", period: "monthly")
        let goalType: ReadingGoal.GoalType
        let goalPeriod: ReadingGoal.GoalPeriod
        
        // Check if this is old format where type contains the period
        if type == "monthly" || type == "yearly" || type == "quarterly" {
            goalType = .bookCount
            switch type {
            case "monthly":
                goalPeriod = .monthly
            case "yearly":
                goalPeriod = .yearly
            case "quarterly":
                goalPeriod = .quarterly
            default:
                goalPeriod = .monthly
            }
        } else {
            // New format with separate type and period
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
            
            if let period = period {
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
            } else {
                goalPeriod = .monthly
            }
        }
        
        // Use targetValue if available, otherwise fall back to targetBooks
        let target = targetValue ?? targetBooks ?? 0
        let current = currentValue ?? currentBooks ?? 0
        
        return ReadingGoal(
            id: id,
            type: goalType,
            targetValue: target,
            currentValue: current,
            period: goalPeriod,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive ?? true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    init(from goal: ReadingGoal) {
        self.id = goal.id
        self.type = goal.type.rawValue
        self.targetValue = goal.targetValue
        self.targetBooks = goal.targetValue // For backward compatibility
        self.currentValue = goal.currentValue
        self.currentBooks = goal.currentValue // For backward compatibility
        self.period = goal.period.rawValue
        self.startDate = goal.startDate
        self.endDate = goal.endDate
        self.isActive = goal.isActive
        self.isAchieved = goal.isCompleted
        self.createdAt = goal.createdAt
        self.updatedAt = goal.updatedAt
    }
}
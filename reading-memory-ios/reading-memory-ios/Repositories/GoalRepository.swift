import Foundation

protocol GoalRepositoryProtocol {
    func createGoal(_ goal: ReadingGoal) async throws
    func updateGoal(_ goal: ReadingGoal) async throws
    func deleteGoal(goalId: String) async throws
    func getGoal(goalId: String) async throws -> ReadingGoal?
    func getActiveGoals() async throws -> [ReadingGoal]
    func getAllGoals() async throws -> [ReadingGoal]
    func updateGoalProgress(goalId: String, newValue: Int) async throws
}

class GoalRepository: GoalRepositoryProtocol {
    static let shared = GoalRepository()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func createGoal(_ goal: ReadingGoal) async throws {
        _ = try await apiClient.createGoal(goal)
    }
    
    func updateGoal(_ goal: ReadingGoal) async throws {
        _ = try await apiClient.updateGoal(goal)
    }
    
    func deleteGoal(goalId: String) async throws {
        try await apiClient.deleteGoal(id: goalId)
    }
    
    func getGoal(goalId: String) async throws -> ReadingGoal? {
        let goals = try await apiClient.getGoals()
        return goals.first { $0.id == goalId }
    }
    
    func getActiveGoals() async throws -> [ReadingGoal] {
        let goals = try await apiClient.getGoals()
        let now = Date()
        return goals.filter { goal in
            goal.isActive && goal.endDate > now
        }
    }
    
    func getAllGoals() async throws -> [ReadingGoal] {
        return try await apiClient.getGoals()
    }
    
    func updateGoalProgress(goalId: String, newValue: Int) async throws {
        guard let goal = try await getGoal(goalId: goalId) else {
            throw AppError.custom("目標が見つかりません")
        }
        
        var updatedGoal = goal
        updatedGoal.currentValue = newValue
        updatedGoal.updatedAt = Date()
        
        try await updateGoal(updatedGoal)
    }
    
    // Helper method to calculate current progress based on period
    func calculateCurrentProgress(for goal: ReadingGoal, books: [Book]) -> Int {
        let completedBooks = books.filter { book in
            guard book.status == .completed,
                  let completedDate = book.completedDate else { return false }
            
            // Check if completion date is within goal period
            return completedDate >= goal.startDate && completedDate <= goal.endDate
        }
        
        switch goal.type {
        case .bookCount:
            return completedBooks.count
        case .genreCount:
            let genres = Set(completedBooks.compactMap { $0.tags }.flatMap { $0 })
            return genres.count
        default:
            return 0
        }
    }
}
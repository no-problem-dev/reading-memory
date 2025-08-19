import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol GoalRepositoryProtocol {
    func createGoal(_ goal: ReadingGoal) async throws
    func updateGoal(_ goal: ReadingGoal) async throws
    func deleteGoal(goalId: String, userId: String) async throws
    func getGoal(goalId: String, userId: String) async throws -> ReadingGoal?
    func getActiveGoals(userId: String) async throws -> [ReadingGoal]
    func getAllGoals(userId: String) async throws -> [ReadingGoal]
    func updateGoalProgress(goalId: String, userId: String, newValue: Int) async throws
}

class GoalRepository: BaseRepository, GoalRepositoryProtocol {
    static let shared = GoalRepository()
    
    private override init() {
        super.init()
    }
    
    func createGoal(_ goal: ReadingGoal) async throws {
        let document = db.collection("users")
            .document(goal.userId)
            .collection("goals")
            .document(goal.id)
        
        try await document.setData(from: goal)
    }
    
    func updateGoal(_ goal: ReadingGoal) async throws {
        let document = db.collection("users")
            .document(goal.userId)
            .collection("goals")
            .document(goal.id)
        
        var updatedGoal = goal
        updatedGoal.updatedAt = Date()
        
        try await document.setData(from: updatedGoal)
    }
    
    func deleteGoal(goalId: String, userId: String) async throws {
        let document = db.collection("users")
            .document(userId)
            .collection("goals")
            .document(goalId)
        
        try await document.delete()
    }
    
    func getGoal(goalId: String, userId: String) async throws -> ReadingGoal? {
        let document = db.collection("users")
            .document(userId)
            .collection("goals")
            .document(goalId)
        
        let snapshot = try await document.getDocument()
        return try? snapshot.data(as: ReadingGoal.self)
    }
    
    func getActiveGoals(userId: String) async throws -> [ReadingGoal] {
        let query = db.collection("users")
            .document(userId)
            .collection("goals")
            .whereField("isActive", isEqualTo: true)
            .whereField("endDate", isGreaterThan: Date())
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: ReadingGoal.self)
        }
    }
    
    func getAllGoals(userId: String) async throws -> [ReadingGoal] {
        let query = db.collection("users")
            .document(userId)
            .collection("goals")
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: ReadingGoal.self)
        }
    }
    
    func updateGoalProgress(goalId: String, userId: String, newValue: Int) async throws {
        let document = db.collection("users")
            .document(userId)
            .collection("goals")
            .document(goalId)
        
        try await document.updateData([
            "currentValue": newValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // Helper method to calculate current progress based on period
    func calculateCurrentProgress(for goal: ReadingGoal, userBooks: [UserBook]) -> Int {
        let calendar = Calendar.current
        let completedBooks = userBooks.filter { book in
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
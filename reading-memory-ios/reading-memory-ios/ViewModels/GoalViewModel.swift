import Foundation
import FirebaseAuth

@Observable
class GoalViewModel {
    private let goalRepository = GoalRepository.shared
    private let userBookRepository = UserBookRepository.shared
    private let userProfileRepository = UserProfileRepository.shared
    
    var activeGoals: [ReadingGoal] = []
    var allGoals: [ReadingGoal] = []
    var yearlyGoal: ReadingGoal?
    var monthlyGoal: ReadingGoal?
    var isLoading = false
    var errorMessage: String?
    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func loadGoals() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // アクティブな目標を取得
            activeGoals = try await goalRepository.getActiveGoals(userId: userId)
            
            // すべての目標を取得
            allGoals = try await goalRepository.getAllGoals(userId: userId)
            
            // 年間・月間目標を特定
            yearlyGoal = activeGoals.first { $0.period == .yearly && $0.type == .bookCount }
            monthlyGoal = activeGoals.first { $0.period == .monthly && $0.type == .bookCount }
            
            // 現在の進捗を更新
            await updateGoalProgress()
        } catch {
            errorMessage = "目標の読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createYearlyGoal(targetBooks: Int) async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let goal = ReadingGoal.createYearlyGoal(userId: userId, targetBooks: targetBooks)
            try await goalRepository.createGoal(goal)
            
            // UserProfileの年間目標も更新
            if var profile = try await userProfileRepository.getUserProfile(userId: userId) {
                profile = UserProfile(
                    id: profile.id,
                    displayName: profile.displayName,
                    profileImageUrl: profile.profileImageUrl,
                    bio: profile.bio,
                    favoriteGenres: profile.favoriteGenres,
                    readingGoal: targetBooks,
                    monthlyGoal: profile.monthlyGoal,
                    streakStartDate: profile.streakStartDate,
                    longestStreak: profile.longestStreak,
                    currentStreak: profile.currentStreak,
                    lastActivityDate: profile.lastActivityDate,
                    isPublic: profile.isPublic,
                    createdAt: profile.createdAt,
                    updatedAt: Date()
                )
                try await userProfileRepository.updateUserProfile(profile)
            }
            
            await loadGoals()
        } catch {
            errorMessage = "年間目標の作成に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createMonthlyGoal(targetBooks: Int) async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let goal = ReadingGoal.createMonthlyGoal(userId: userId, targetBooks: targetBooks)
            try await goalRepository.createGoal(goal)
            
            // UserProfileの月間目標も更新
            if var profile = try await userProfileRepository.getUserProfile(userId: userId) {
                profile = UserProfile(
                    id: profile.id,
                    displayName: profile.displayName,
                    profileImageUrl: profile.profileImageUrl,
                    bio: profile.bio,
                    favoriteGenres: profile.favoriteGenres,
                    readingGoal: profile.readingGoal,
                    monthlyGoal: targetBooks,
                    streakStartDate: profile.streakStartDate,
                    longestStreak: profile.longestStreak,
                    currentStreak: profile.currentStreak,
                    lastActivityDate: profile.lastActivityDate,
                    isPublic: profile.isPublic,
                    createdAt: profile.createdAt,
                    updatedAt: Date()
                )
                try await userProfileRepository.updateUserProfile(profile)
            }
            
            await loadGoals()
        } catch {
            errorMessage = "月間目標の作成に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateGoal(_ goal: ReadingGoal) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await goalRepository.updateGoal(goal)
            await loadGoals()
        } catch {
            errorMessage = "目標の更新に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteGoal(_ goal: ReadingGoal) async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await goalRepository.deleteGoal(goalId: goal.id, userId: userId)
            
            // UserProfileの目標も削除
            if goal.period == .yearly && goal.type == .bookCount {
                if var profile = try await userProfileRepository.getUserProfile(userId: userId) {
                    profile = UserProfile(
                        id: profile.id,
                        displayName: profile.displayName,
                        profileImageUrl: profile.profileImageUrl,
                        bio: profile.bio,
                        favoriteGenres: profile.favoriteGenres,
                        readingGoal: nil,
                        monthlyGoal: profile.monthlyGoal,
                        streakStartDate: profile.streakStartDate,
                        longestStreak: profile.longestStreak,
                        currentStreak: profile.currentStreak,
                        lastActivityDate: profile.lastActivityDate,
                        isPublic: profile.isPublic,
                        createdAt: profile.createdAt,
                        updatedAt: Date()
                    )
                    try await userProfileRepository.updateUserProfile(profile)
                }
            }
            
            await loadGoals()
        } catch {
            errorMessage = "目標の削除に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func updateGoalProgress() async {
        guard let userId = userId else { return }
        
        do {
            // ユーザーの本を取得
            let userBooks = try await userBookRepository.getUserBooks(for: userId)
            
            // 各目標の進捗を計算して更新
            for goal in activeGoals {
                let currentProgress = goalRepository.calculateCurrentProgress(for: goal, userBooks: userBooks)
                
                if goal.currentValue != currentProgress {
                    try await goalRepository.updateGoalProgress(
                        goalId: goal.id,
                        userId: userId,
                        newValue: currentProgress
                    )
                }
            }
            
            // 再度読み込んで最新の状態を反映
            await loadGoals()
        } catch {
            print("目標進捗の更新に失敗: \(error)")
        }
    }
    
    // 推奨目標を計算
    func calculateRecommendedGoal(period: ReadingGoal.GoalPeriod) -> Int {
        guard userId != nil else { return 10 }
        
        // 過去の読書ペースから推奨値を計算（簡易版）
        let completedGoals = allGoals.filter { $0.isCompleted && $0.period == period }
        
        if !completedGoals.isEmpty {
            let average = completedGoals.map { $0.targetValue }.reduce(0, +) / completedGoals.count
            return Int(Double(average) * 1.2) // 前回の120%を推奨
        }
        
        // デフォルト値
        switch period {
        case .yearly:
            return 12 // 月1冊ペース
        case .monthly:
            return 2
        case .quarterly:
            return 3
        case .custom:
            return 5
        }
    }
}
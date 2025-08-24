import Foundation
// import FirebaseAuth

@Observable
class GoalViewModel {
    private let goalRepository = GoalRepository.shared
    private let bookRepository = BookRepository.shared
    private let userProfileRepository = UserProfileRepository.shared
    @MainActor private let authService = AuthService.shared
    
    var activeGoals: [ReadingGoal] = []
    var allGoals: [ReadingGoal] = []
    var yearlyGoal: ReadingGoal?
    var monthlyGoal: ReadingGoal?
    var isLoading = false
    var errorMessage: String?
    
    
    // 現在実行中のタスクを追跡
    private var loadTask: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?
    
    deinit {
        loadTask?.cancel()
        updateTask?.cancel()
    }
    
    func loadGoals() async {
        guard let user = await authService.currentUser else { return }
        
        // 既存のタスクをキャンセル
        loadTask?.cancel()
        
        loadTask = Task {
            guard !Task.isCancelled else { return }
            
            isLoading = true
            errorMessage = nil
            
            do {
                // アクティブな目標を取得
                let activeGoalsList = try await goalRepository.getActiveGoals()
                guard !Task.isCancelled else { return }
                
                // すべての目標を取得
                let allGoalsList = try await goalRepository.getAllGoals()
                guard !Task.isCancelled else { return }
                
                // メインスレッドで更新
                await MainActor.run {
                    self.activeGoals = activeGoalsList
                    self.allGoals = allGoalsList
                    
                    // 年間・月間目標を特定
                    self.yearlyGoal = activeGoalsList.first { $0.period == .yearly && $0.type == .bookCount }
                    self.monthlyGoal = activeGoalsList.first { $0.period == .monthly && $0.type == .bookCount }
                }
                
                // 初回読み込み時のみ進捗を更新（無限ループを防ぐ）
                await updateGoalProgressIfNeeded()
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.errorMessage = "目標の読み込みに失敗しました: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
        
        await loadTask?.value
    }
    
    func createYearlyGoal(targetBooks: Int) async {
        guard let user = await authService.currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let goal = ReadingGoal.createYearlyGoal(targetBooks: targetBooks)
            try await goalRepository.createGoal(goal)
            
            // UserProfileの年間目標も更新
            if var profile = try await userProfileRepository.getUserProfile() {
                profile = UserProfile(
                    id: profile.id,
                    displayName: profile.displayName,
                    avatarImageId: profile.avatarImageId,
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
        guard let user = await authService.currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let goal = ReadingGoal.createMonthlyGoal(targetBooks: targetBooks)
            try await goalRepository.createGoal(goal)
            
            // UserProfileの月間目標も更新
            if var profile = try await userProfileRepository.getUserProfile() {
                profile = UserProfile(
                    id: profile.id,
                    displayName: profile.displayName,
                    avatarImageId: profile.avatarImageId,
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
        guard let user = await authService.currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await goalRepository.deleteGoal(goalId: goal.id)
            
            // UserProfileの目標も削除
            if goal.period == .yearly && goal.type == .bookCount {
                if var profile = try await userProfileRepository.getUserProfile() {
                    profile = UserProfile(
                        id: profile.id,
                        displayName: profile.displayName,
                        avatarImageId: profile.avatarImageId,
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
    
    // 進捗更新が必要な場合のみ実行
    private func updateGoalProgressIfNeeded() async {
        guard let user = await authService.currentUser else { return }
        
        // 既存のタスクをキャンセル
        updateTask?.cancel()
        
        updateTask = Task {
            guard !Task.isCancelled else { return }
            
            do {
                // ユーザーの本を取得
                let books = try await bookRepository.getBooks()
                guard !Task.isCancelled else { return }
                
                // 更新が必要な目標を収集
                var goalsToUpdate: [(goal: ReadingGoal, newValue: Int)] = []
                
                for goal in activeGoals {
                    let currentProgress = goalRepository.calculateCurrentProgress(for: goal, books: books)
                    
                    if goal.currentValue != currentProgress {
                        goalsToUpdate.append((goal, currentProgress))
                    }
                }
                
                // 更新が必要な場合のみ実行
                if !goalsToUpdate.isEmpty {
                    for (goal, newValue) in goalsToUpdate {
                        guard !Task.isCancelled else { return }
                        
                        try await goalRepository.updateGoalProgress(
                            goalId: goal.id,
                            newValue: newValue
                        )
                        
                        // ローカルの値も更新（再取得を避ける）
                        await MainActor.run {
                            if let index = self.activeGoals.firstIndex(where: { $0.id == goal.id }) {
                                self.activeGoals[index].currentValue = newValue
                            }
                            if let index = self.allGoals.firstIndex(where: { $0.id == goal.id }) {
                                self.allGoals[index].currentValue = newValue
                            }
                            
                            // 年間・月間目標も更新
                            if self.yearlyGoal?.id == goal.id {
                                self.yearlyGoal?.currentValue = newValue
                            }
                            if self.monthlyGoal?.id == goal.id {
                                self.monthlyGoal?.currentValue = newValue
                            }
                        }
                    }
                }
            } catch {
                print("目標進捗の更新に失敗: \(error)")
            }
        }
        
        await updateTask?.value
    }
    
    // 手動で進捗を更新するメソッド（外部から呼び出し可能）
    func refreshGoalProgress() async {
        await updateGoalProgressIfNeeded()
    }
    
    // 推奨目標を計算
    func calculateRecommendedGoal(period: ReadingGoal.GoalPeriod) -> Int {
        // Note: This method is not async, so we can't await. 
        // For dummy implementation, just return default values
        // In real implementation, this would need to be made async
        
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
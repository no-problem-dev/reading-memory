import SwiftUI

struct GoalDashboardView: View {
    @State private var goalViewModel = GoalViewModel()
    @State private var streakViewModel = StreakViewModel()
    @State private var achievementViewModel = AchievementViewModel()
    @State private var showGoalSetting = false
    @State private var showAchievementGallery = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ストリークセクション
                    streakSection
                    
                    // 目標進捗セクション
                    if !goalViewModel.activeGoals.isEmpty {
                        goalProgressSection
                    }
                    
                    // 週間アクティビティ
                    weeklyActivitySection
                    
                    // 次に獲得可能なバッジ
                    nextBadgesSection
                    
                    // 統計サマリー
                    statisticsSummarySection
                }
                .padding()
            }
            .navigationTitle("目標")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showGoalSetting = true
                    } label: {
                        Image(systemName: "target")
                    }
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .sheet(isPresented: $showGoalSetting) {
                GoalSettingView()
            }
            .sheet(isPresented: $showAchievementGallery) {
                AchievementGalleryView()
            }
        }
    }
    
    private func loadData() async {
        await goalViewModel.loadGoals()
        await streakViewModel.loadStreaks()
        await achievementViewModel.loadAchievements()
    }
    
    private var streakSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("読書ストリーク")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(streakViewModel.combinedStreak?.currentStreak ?? 0)")
                            .font(.system(size: 48, weight: .bold))
                        
                        Text("日")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    
                    if !streakViewModel.hasActivityToday {
                        if streakViewModel.canContinueStreak {
                            Text("あと\(streakViewModel.hoursUntilStreakEnds)時間でストリークが途切れます")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("ストリークが途切れました")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .opacity(streakViewModel.hasActivityToday ? 1.0 : 0.5)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5)
            
            // 最長ストリーク
            HStack {
                Label("最長ストリーク", systemImage: "crown.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(streakViewModel.combinedStreak?.longestStreak ?? 0)日")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
        }
    }
    
    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("目標進捗")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(goalViewModel.activeGoals.prefix(2)) { goal in
                GoalProgressCard(goal: goal)
            }
            
            if goalViewModel.activeGoals.count > 2 {
                Button {
                    showGoalSetting = true
                } label: {
                    Text("すべての目標を見る")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("週間アクティビティ")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(0..<7) { index in
                    let isActive = index < streakViewModel.weeklyActivity.count ? streakViewModel.weeklyActivity[index] : false
                    let dayLabel = getDayLabel(for: index)
                    
                    VStack(spacing: 8) {
                        Text(dayLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(isActive ? Color.green : Color(.systemGray5))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: isActive ? "checkmark" : "minus")
                                    .font(.caption)
                                    .foregroundColor(isActive ? .white : .secondary)
                            )
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
    
    private var nextBadgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("次に獲得可能なバッジ")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showAchievementGallery = true
                } label: {
                    Text("すべて見る")
                        .font(.footnote)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(achievementViewModel.getNextAchievableBadges()) { badge in
                        NextBadgeCard(
                            badge: badge,
                            progress: achievementViewModel.getProgress(for: badge)
                        )
                    }
                }
            }
        }
    }
    
    private var statisticsSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今月の活動")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                StatisticCard(
                    title: "読書日数",
                    value: "\(streakViewModel.monthlyActivityCount)",
                    icon: "calendar",
                    color: .blue
                )
                
                StatisticCard(
                    title: "完了した本",
                    value: "\(goalViewModel.monthlyGoal?.currentValue ?? 0)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
    }
    
    private func getDayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        guard let date = calendar.date(byAdding: .day, value: index - 6, to: today) else { return "" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct GoalProgressCard: View {
    let goal: ReadingGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(goal.periodDisplayName)目標")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(goal.currentValue) / \(goal.targetValue)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(goal.progress >= 1.0 ? Color.green : Color.accentColor)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(goal.progressPercentage)%達成")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if goal.daysRemaining > 0 {
                    Text("残り\(goal.daysRemaining)日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct NextBadgeCard: View {
    let badge: Badge
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: badge.iconName)
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

#Preview {
    GoalDashboardView()
}
import SwiftUI

struct GoalSettingView: View {
    @State private var viewModel = GoalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var yearlyGoalTarget: Double = 12
    @State private var monthlyGoalTarget: Double = 2
    @State private var showYearlyGoalSection = false
    @State private var showMonthlyGoalSection = false
    @State private var showDeleteConfirmation = false
    @State private var goalToDelete: ReadingGoal?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 現在の目標
                    if !viewModel.activeGoals.isEmpty {
                        currentGoalsSection
                    }
                    
                    // 年間目標設定
                    yearlyGoalSection
                    
                    // 月間目標設定
                    monthlyGoalSection
                    
                    // 過去の目標
                    if !viewModel.allGoals.filter({ !$0.isActive }).isEmpty {
                        pastGoalsSection
                    }
                }
                .padding()
            }
            .navigationTitle("読書目標")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadGoals()
                
                // 既存の目標がある場合は初期値を設定
                if let yearly = viewModel.yearlyGoal {
                    yearlyGoalTarget = Double(yearly.targetValue)
                } else {
                    yearlyGoalTarget = Double(viewModel.calculateRecommendedGoal(period: .yearly))
                }
                
                if let monthly = viewModel.monthlyGoal {
                    monthlyGoalTarget = Double(monthly.targetValue)
                } else {
                    monthlyGoalTarget = Double(viewModel.calculateRecommendedGoal(period: .monthly))
                }
            }
            .alert("目標を削除", isPresented: $showDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    if let goal = goalToDelete {
                        Task {
                            await viewModel.deleteGoal(goal)
                        }
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("この目標を削除してもよろしいですか？")
            }
        }
    }
    
    private var currentGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("現在の目標")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(viewModel.activeGoals) { goal in
                GoalCard(goal: goal) {
                    goalToDelete = goal
                    showDeleteConfirmation = true
                }
            }
        }
    }
    
    private var yearlyGoalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("年間読書目標")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.yearlyGoal == nil {
                    Button(showYearlyGoalSection ? "キャンセル" : "設定") {
                        withAnimation {
                            showYearlyGoalSection.toggle()
                        }
                    }
                }
            }
            
            if showYearlyGoalSection && viewModel.yearlyGoal == nil {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("\(Int(yearlyGoalTarget))冊")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Slider(value: $yearlyGoalTarget, in: 1...100, step: 1)
                            .tint(.accentColor)
                    }
                    
                    Text("推奨: \(viewModel.calculateRecommendedGoal(period: .yearly))冊")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        Task {
                            await viewModel.createYearlyGoal(targetBooks: Int(yearlyGoalTarget))
                            showYearlyGoalSection = false
                        }
                    } label: {
                        Label("年間目標を設定", systemImage: "target")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var monthlyGoalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("月間読書目標")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.monthlyGoal == nil {
                    Button(showMonthlyGoalSection ? "キャンセル" : "設定") {
                        withAnimation {
                            showMonthlyGoalSection.toggle()
                        }
                    }
                }
            }
            
            if showMonthlyGoalSection && viewModel.monthlyGoal == nil {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("\(Int(monthlyGoalTarget))冊")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Slider(value: $monthlyGoalTarget, in: 1...20, step: 1)
                            .tint(.accentColor)
                    }
                    
                    Text("推奨: \(viewModel.calculateRecommendedGoal(period: .monthly))冊")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        Task {
                            await viewModel.createMonthlyGoal(targetBooks: Int(monthlyGoalTarget))
                            showMonthlyGoalSection = false
                        }
                    } label: {
                        Label("月間目標を設定", systemImage: "calendar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var pastGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("過去の目標")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(viewModel.allGoals.filter { !$0.isActive }) { goal in
                GoalCard(goal: goal, showActions: false)
            }
        }
    }
}

struct GoalCard: View {
    let goal: ReadingGoal
    var showActions: Bool = true
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(goal.periodDisplayName)\(goal.typeDisplayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(goal.currentValue) / \(goal.targetValue)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else if showActions {
                    Menu {
                        Button(role: .destructive) {
                            onDelete?()
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 進捗バー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(goal.isCompleted ? Color.green : Color.accentColor)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(goal.progressPercentage)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !goal.isCompleted && goal.daysRemaining > 0 {
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

#Preview {
    GoalSettingView()
}
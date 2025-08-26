import SwiftUI
import Charts

struct StatisticsView: View {
    @State private var viewModel = StatisticsViewModel()
    @State private var selectedPeriod: StatisticsPeriod = .month
    @State private var showPaywall = false
    
    enum StatisticsPeriod: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        case year = "年間"
        case all = "全期間"
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else {
                VStack(spacing: MemorySpacing.lg) {
                    // Period Selector - Enhanced Design
                    periodSelectorView
                        .padding(.top, MemorySpacing.md)
                    
                    // Summary Cards - Always visible
                    summaryCardsSection
                    
                    if FeatureGate.canViewFullStatistics {
                        // Premium content
                        // Reading Trend Chart
                        readingTrendChart
                        
                        // Genre Distribution
                        genreDistributionChart
                        
                        // Rating Distribution
                        ratingDistributionChart
                        
                        // Monthly Reading Stats
                        if selectedPeriod != .week {
                            monthlyStatsSection
                        }
                        
                        // Reading Pace
                        readingPaceSection
                    } else {
                        // Free user limitation
                        premiumFeaturePrompt
                    }
                }
                .padding(.bottom, MemorySpacing.xl)
            }
        }
        .task {
            // 初回のみデータを読み込む
            if !viewModel.hasLoadedInitialData {
                await viewModel.loadStatistics(for: selectedPeriod)
            }
        }
        .onChange(of: selectedPeriod) { _, newValue in
            Task {
                await viewModel.loadStatistics(for: newValue)
            }
        }
        .refreshable {
            // プルリフレッシュ時は強制的に再取得
            viewModel.forceRefresh()
            await viewModel.loadStatistics(for: selectedPeriod)
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    
    private var periodSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MemorySpacing.sm) {
                ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                    PeriodButton(
                        title: period.rawValue,
                        icon: periodIcon(for: period),
                        isSelected: selectedPeriod == period
                    ) {
                        withAnimation(MemoryTheme.Animation.fast) {
                            selectedPeriod = period
                        }
                    }
                }
            }
            .padding(.horizontal, MemorySpacing.md)
        }
    }
    
    private func periodIcon(for period: StatisticsPeriod) -> String {
        switch period {
        case .week:
            return "calendar.day.timeline.left"
        case .month:
            return "calendar"
        case .year:
            return "calendar.badge.clock"
        case .all:
            return "clock.arrow.circlepath"
        }
    }
    
    private var summaryCardsSection: some View {
        VStack(spacing: MemorySpacing.md) {
            HStack(spacing: MemorySpacing.md) {
                SummaryCard(
                    title: "読了数",
                    value: "\(viewModel.periodStats.completedBooks)",
                    trend: viewModel.periodStats.completedTrend,
                    icon: "checkmark.circle.fill",
                    color: MemoryTheme.Colors.success
                )
                
                SummaryCard(
                    title: "読書時間",
                    value: "\(viewModel.periodStats.totalReadingDays)日",
                    trend: viewModel.periodStats.readingDaysTrend,
                    icon: "clock.fill",
                    color: MemoryTheme.Colors.primaryBlue
                )
            }
            
            HStack(spacing: MemorySpacing.md) {
                SummaryCard(
                    title: "メモ数",
                    value: "\(viewModel.periodStats.totalMemos)",
                    trend: viewModel.periodStats.memosTrend,
                    icon: "bubble.left.fill",
                    color: MemoryTheme.Colors.warmCoral
                )
                
                SummaryCard(
                    title: "平均評価",
                    value: String(format: "%.1f", viewModel.periodStats.averageRating),
                    trend: viewModel.periodStats.ratingTrend,
                    icon: "star.fill",
                    color: MemoryTheme.Colors.goldenMemory
                )
            }
        }
        .padding(.horizontal, MemorySpacing.md)
    }
    
    private var readingTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("読書傾向")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(viewModel.readingTrendData) { data in
                LineMark(
                    x: .value("日付", data.date),
                    y: .value("冊数", data.count)
                )
                .foregroundStyle(.blue)
                .symbol(.circle)
                
                AreaMark(
                    x: .value("日付", data.date),
                    y: .value("冊数", data.count)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding()
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
        .padding(.horizontal, MemorySpacing.md)
    }
    
    private var genreDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ジャンル分布")
                .font(.headline)
            
            if !viewModel.genreDistribution.isEmpty {
                Chart(viewModel.genreDistribution) { genre in
                    SectorMark(
                        angle: .value("冊数", genre.count),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("ジャンル", genre.name))
                    .cornerRadius(4)
                }
                .frame(height: 250)
                
                // Legend
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(viewModel.genreDistribution) { genre in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(genreColor(for: genre.name))
                                .frame(width: 12, height: 12)
                            Text("\(genre.name) (\(genre.count))")
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            } else {
                Text("データがありません")
                    .foregroundStyle(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
        .padding(.horizontal, MemorySpacing.md)
    }
    
    private var ratingDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("評価分布")
                .font(.headline)
            
            if !viewModel.ratingDistribution.isEmpty {
                Chart(viewModel.ratingDistribution) { rating in
                    BarMark(
                        x: .value("評価", rating.rating),
                        y: .value("冊数", rating.count)
                    )
                    .foregroundStyle(.yellow.gradient)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 0.5)) { value in
                        AxisValueLabel {
                            if let rating = value.as(Double.self) {
                                Text(String(format: "%.1f", rating))
                            }
                        }
                    }
                }
            } else {
                Text("データがありません")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
        .padding(.horizontal, MemorySpacing.md)
    }
    
    private var monthlyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月別読書統計")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.monthlyStats) { stat in
                        VStack(spacing: 8) {
                            Text(stat.monthLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\(stat.completedBooks)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("冊")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 80)
                        .padding()
                        .background(MemoryTheme.Colors.cardBackground)
                        .cornerRadius(MemoryRadius.medium)
                        .memoryShadow(.soft)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var readingPaceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("読書ペース")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均読了日数")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(String(format: "%.1f", viewModel.averageReadingDays))日")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("月間平均")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(String(format: "%.1f", viewModel.monthlyAverage))冊")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("最長連続読書")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.longestStreak)日")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
        .padding(.horizontal, MemorySpacing.md)
    }
    
    private func genreColor(for genre: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow, .indigo, .red]
        let index = abs(genre.hashValue) % colors.count
        return colors[index]
    }
    
    private var premiumFeaturePrompt: some View {
        VStack(spacing: MemorySpacing.lg) {
            MemoryCard(padding: MemorySpacing.lg) {
                VStack(spacing: MemorySpacing.md) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlue,
                                    MemoryTheme.Colors.primaryBlueDark
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("詳細な統計機能")
                        .font(MemoryTheme.Fonts.title3())
                        .fontWeight(.semibold)
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                    
                    Text("プレミアムプランでは、読書傾向グラフ、\nジャンル分析、評価分布など\nより詳しい統計情報をご覧いただけます")
                        .font(MemoryTheme.Fonts.body())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Button {
                        showPaywall = true
                    } label: {
                        Label("プレミアムプランを見る", systemImage: "sparkles")
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MemorySpacing.md)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.primaryBlue,
                                        MemoryTheme.Colors.primaryBlueDark
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(MemoryRadius.medium)
                            .memoryShadow(.medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, MemorySpacing.md)
            .padding(.top, MemorySpacing.lg)
            
            Spacer(minLength: 100)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let trend: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                if trend != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("\(abs(Int(trend)))%")
                            .font(.caption)
                    }
                    .foregroundColor(trend > 0 ? .green : .red)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.medium)
        .memoryShadow(.soft)
    }
}

// Period Button Component
struct PeriodButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: MemorySpacing.xs) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected 
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.primaryBlue,
                                        MemoryTheme.Colors.primaryBlueDark
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.inkPale.opacity(0.5),
                                        MemoryTheme.Colors.inkPale.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(
                            isSelected 
                                ? MemoryTheme.Colors.inkWhite
                                : MemoryTheme.Colors.inkGray
                        )
                }
                
                Text(title)
                    .font(MemoryTheme.Fonts.caption())
                    .foregroundColor(
                        isSelected 
                            ? MemoryTheme.Colors.inkBlack
                            : MemoryTheme.Colors.inkGray
                    )
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .padding(.vertical, MemorySpacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(MemoryTheme.Animation.fast, value: isSelected)
    }
}

#Preview {
    StatisticsView()
}

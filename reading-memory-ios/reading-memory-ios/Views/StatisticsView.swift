import SwiftUI
import Charts

struct StatisticsView: View {
    @State private var viewModel = StatisticsViewModel()
    @State private var selectedPeriod: StatisticsPeriod = .month
    
    enum StatisticsPeriod: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        case year = "年間"
        case all = "全期間"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else {
                    VStack(spacing: 24) {
                        // Period Selector
                        Picker("期間", selection: $selectedPeriod) {
                            ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Summary Cards
                        summaryCardsSection
                        
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
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("読書統計")
            .navigationBarTitleDisplayMode(.large)
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
        }
    }
    
    private var summaryCardsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                SummaryCard(
                    title: "読了数",
                    value: "\(viewModel.periodStats.completedBooks)",
                    trend: viewModel.periodStats.completedTrend,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                SummaryCard(
                    title: "読書時間",
                    value: "\(viewModel.periodStats.totalReadingDays)日",
                    trend: viewModel.periodStats.readingDaysTrend,
                    icon: "clock.fill",
                    color: .blue
                )
            }
            
            HStack(spacing: 16) {
                SummaryCard(
                    title: "メモ数",
                    value: "\(viewModel.periodStats.totalMemos)",
                    trend: viewModel.periodStats.memosTrend,
                    icon: "bubble.left.fill",
                    color: .purple
                )
                
                SummaryCard(
                    title: "平均評価",
                    value: String(format: "%.1f", viewModel.periodStats.averageRating),
                    trend: viewModel.periodStats.ratingTrend,
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
        .padding(.horizontal)
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
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
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func genreColor(for genre: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow, .indigo, .red]
        let index = abs(genre.hashValue) % colors.count
        return colors[index]
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatisticsView()
}
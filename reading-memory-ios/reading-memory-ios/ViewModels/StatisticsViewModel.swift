import Foundation
import FirebaseAuth

@Observable
final class StatisticsViewModel: BaseViewModel {
    private let userBookRepository = UserBookRepository.shared
    private let bookChatRepository = BookChatRepository.shared
    
    // Period Statistics
    var periodStats = PeriodStatistics()
    
    // Chart Data
    var readingTrendData: [ReadingTrendPoint] = []
    var genreDistribution: [GenreData] = []
    var ratingDistribution: [RatingData] = []
    var monthlyStats: [MonthlyStatistic] = []
    
    // Reading Pace
    var averageReadingDays: Double = 0
    var monthlyAverage: Double = 0
    var longestStreak: Int = 0
    
    struct PeriodStatistics {
        var completedBooks: Int = 0
        var totalReadingDays: Int = 0
        var totalMemos: Int = 0
        var averageRating: Double = 0.0
        
        // Trends (percentage change from previous period)
        var completedTrend: Double = 0
        var readingDaysTrend: Double = 0
        var memosTrend: Double = 0
        var ratingTrend: Double = 0
    }
    
    struct ReadingTrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }
    
    struct GenreData: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }
    
    struct RatingData: Identifiable {
        let id = UUID()
        let rating: Double
        let count: Int
    }
    
    struct MonthlyStatistic: Identifiable {
        let id = UUID()
        let month: Date
        let monthLabel: String
        let completedBooks: Int
    }
    
    @MainActor
    func loadStatistics(for period: StatisticsView.StatisticsPeriod = .month) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw AppError.authenticationRequired
            }
            
            // Get all user books
            let allBooks = try await userBookRepository.getUserBooks(for: userId)
            
            // Filter books by period
            let (filteredBooks, previousPeriodBooks) = filterBooksByPeriod(allBooks, period: period)
            
            // Calculate period statistics
            await calculatePeriodStatistics(
                books: filteredBooks,
                previousBooks: previousPeriodBooks,
                userId: userId,
                period: period
            )
            
            // Generate chart data
            generateReadingTrendData(books: filteredBooks, period: period)
            generateGenreDistribution(books: filteredBooks)
            generateRatingDistribution(books: filteredBooks)
            
            // Generate monthly stats for longer periods
            if period != .week {
                generateMonthlyStats(books: allBooks)
            }
            
            // Calculate reading pace
            calculateReadingPace(books: allBooks)
            
        } catch {
            errorMessage = AppError.from(error).localizedDescription
        }
        
        isLoading = false
    }
    
    private func filterBooksByPeriod(_ books: [UserBook], period: StatisticsView.StatisticsPeriod) -> (current: [UserBook], previous: [UserBook]) {
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        var previousStartDate: Date
        var previousEndDate: Date
        
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            previousStartDate = calendar.date(byAdding: .day, value: -14, to: now)!
            previousEndDate = startDate
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            previousStartDate = calendar.date(byAdding: .month, value: -2, to: now)!
            previousEndDate = startDate
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
            previousStartDate = calendar.date(byAdding: .year, value: -2, to: now)!
            previousEndDate = startDate
        case .all:
            return (books, [])
        }
        
        let currentBooks = books.filter { book in
            let date = book.completedDate ?? book.updatedAt
            return date >= startDate
        }
        
        let previousBooks = books.filter { book in
            let date = book.completedDate ?? book.updatedAt
            return date >= previousStartDate && date < previousEndDate
        }
        
        return (currentBooks, previousBooks)
    }
    
    @MainActor
    private func calculatePeriodStatistics(
        books: [UserBook],
        previousBooks: [UserBook],
        userId: String,
        period: StatisticsView.StatisticsPeriod
    ) async {
        // Current period stats
        periodStats.completedBooks = books.filter { $0.status == .completed }.count
        
        // Calculate reading days
        let readingDates = Set(books.map { book -> Date in
            let date = book.completedDate ?? book.updatedAt
            return Calendar.current.startOfDay(for: date)
        })
        periodStats.totalReadingDays = readingDates.count
        
        // Calculate average rating
        let ratedBooks = books.filter { $0.rating != nil && $0.rating! > 0 }
        if !ratedBooks.isEmpty {
            let totalRating = ratedBooks.reduce(0.0) { sum, book in sum + Double(book.rating!) }
            periodStats.averageRating = totalRating / Double(ratedBooks.count)
        }
        
        // Count memos
        var totalMemos = 0
        for book in books {
            let memos = try? await bookChatRepository.getChats(userId: userId, userBookId: book.id, limit: 1000)
            totalMemos += memos?.count ?? 0
        }
        periodStats.totalMemos = totalMemos
        
        // Calculate trends (if not viewing all time)
        if period != .all && !previousBooks.isEmpty {
            // Previous period stats
            let prevCompleted = previousBooks.filter { $0.status == .completed }.count
            let prevReadingDates = Set(previousBooks.map { book -> Date in
                let date = book.completedDate ?? book.updatedAt
                return Calendar.current.startOfDay(for: date)
            })
            let prevReadingDays = prevReadingDates.count
            
            // Calculate trends
            if prevCompleted > 0 {
                periodStats.completedTrend = Double(periodStats.completedBooks - prevCompleted) / Double(prevCompleted) * 100
            }
            if prevReadingDays > 0 {
                periodStats.readingDaysTrend = Double(periodStats.totalReadingDays - prevReadingDays) / Double(prevReadingDays) * 100
            }
            
            // Previous average rating
            let prevRatedBooks = previousBooks.filter { $0.rating != nil && $0.rating! > 0 }
            if !prevRatedBooks.isEmpty {
                let prevTotalRating = prevRatedBooks.reduce(0.0) { sum, book in sum + Double(book.rating!) }
                let prevAvgRating = prevTotalRating / Double(prevRatedBooks.count)
                if prevAvgRating > 0 {
                    periodStats.ratingTrend = (periodStats.averageRating - prevAvgRating) / prevAvgRating * 100
                }
            }
        }
    }
    
    private func generateReadingTrendData(books: [UserBook], period: StatisticsView.StatisticsPeriod) {
        let calendar = Calendar.current
        let now = Date()
        var groupedData: [Date: Int] = [:]
        
        // Group books by date unit based on period
        for book in books {
            let date = book.completedDate ?? book.updatedAt
            
            let groupedDate: Date
            switch period {
            case .week:
                groupedDate = calendar.startOfDay(for: date)
            case .month:
                groupedDate = calendar.startOfDay(for: date)
            case .year:
                let components = calendar.dateComponents([.year, .month], from: date)
                groupedDate = calendar.date(from: components) ?? date
            case .all:
                let components = calendar.dateComponents([.year, .month], from: date)
                groupedDate = calendar.date(from: components) ?? date
            }
            
            groupedData[groupedDate, default: 0] += 1
        }
        
        // Convert to array and sort
        readingTrendData = groupedData.map { ReadingTrendPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
        
        // Fill in missing dates for continuous chart
        if !readingTrendData.isEmpty && period != .all {
            let startDate = readingTrendData.first!.date
            let endDate = now
            var filledData: [ReadingTrendPoint] = []
            
            var currentDate = startDate
            let dateUnit: Calendar.Component = period == .week ? .day : (period == .month ? .day : .month)
            
            while currentDate <= endDate {
                let count = groupedData[currentDate] ?? 0
                filledData.append(ReadingTrendPoint(date: currentDate, count: count))
                currentDate = calendar.date(byAdding: dateUnit, value: 1, to: currentDate) ?? currentDate
            }
            
            readingTrendData = filledData
        }
    }
    
    private func generateGenreDistribution(books: [UserBook]) {
        var genreCounts: [String: Int] = [:]
        
        for book in books {
            // UserBook doesn't have genres property, so we'll use a placeholder
            let genre = "未分類" // TODO: Add genre support to UserBook model
            genreCounts[genre, default: 0] += 1
        }
        
        genreDistribution = genreCounts.map { GenreData(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(8) // Top 8 genres
            .map { $0 }
    }
    
    private func generateRatingDistribution(books: [UserBook]) {
        var ratingCounts: [Double: Int] = [:]
        
        for book in books where book.rating != nil && book.rating! > 0 {
            let rating = Double(book.rating!)
            ratingCounts[rating, default: 0] += 1
        }
        
        // Create distribution for all possible ratings
        var distribution: [RatingData] = []
        for rating in stride(from: 0.5, through: 5.0, by: 0.5) {
            let count = ratingCounts[rating] ?? 0
            distribution.append(RatingData(rating: rating, count: count))
        }
        
        ratingDistribution = distribution
    }
    
    private func generateMonthlyStats(books: [UserBook]) {
        let calendar = Calendar.current
        let now = Date()
        let twelveMonthsAgo = calendar.date(byAdding: .month, value: -11, to: now)!
        
        var monthlyData: [Date: Int] = [:]
        
        // Initialize all months with 0
        var currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: twelveMonthsAgo))!
        while currentMonth <= now {
            monthlyData[currentMonth] = 0
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
        }
        
        // Count completed books per month
        for book in books {
            guard let completedDate = book.completedDate,
                  completedDate >= twelveMonthsAgo,
                  book.status == .completed else { continue }
            
            let monthComponents = calendar.dateComponents([.year, .month], from: completedDate)
            if let monthDate = calendar.date(from: monthComponents) {
                monthlyData[monthDate, default: 0] += 1
            }
        }
        
        // Convert to array and sort
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        
        monthlyStats = monthlyData.map { date, count in
            MonthlyStatistic(
                month: date,
                monthLabel: formatter.string(from: date),
                completedBooks: count
            )
        }
        .sorted { $0.month < $1.month }
    }
    
    private func calculateReadingPace(books: [UserBook]) {
        let completedBooks = books.filter { $0.status == .completed }
        
        // Average reading days
        var totalReadingDays = 0
        var booksWithDates = 0
        
        for book in completedBooks {
            if let startDate = book.startDate,
               let completedDate = book.completedDate {
                let days = Calendar.current.dateComponents([.day], from: startDate, to: completedDate).day ?? 0
                if days > 0 {
                    totalReadingDays += days
                    booksWithDates += 1
                }
            }
        }
        
        if booksWithDates > 0 {
            averageReadingDays = Double(totalReadingDays) / Double(booksWithDates)
        }
        
        // Monthly average
        if !completedBooks.isEmpty {
            let calendar = Calendar.current
            let firstBookDate = completedBooks.compactMap { $0.completedDate }.min() ?? Date()
            let monthsDiff = calendar.dateComponents([.month], from: firstBookDate, to: Date()).month ?? 1
            monthlyAverage = Double(completedBooks.count) / Double(max(monthsDiff, 1))
        }
        
        // Longest streak
        calculateLongestStreak(books: completedBooks)
    }
    
    private func calculateLongestStreak(books: [UserBook]) {
        let calendar = Calendar.current
        let readingDates = Set(books.compactMap { book -> Date? in
            guard let date = book.completedDate else { return nil }
            return calendar.startOfDay(for: date)
        }).sorted()
        
        var currentStreak = 0
        var maxStreak = 0
        var previousDate: Date?
        
        for date in readingDates {
            if let prev = previousDate {
                let daysDiff = calendar.dateComponents([.day], from: prev, to: date).day ?? 0
                if daysDiff == 1 {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            maxStreak = max(maxStreak, currentStreak)
            previousDate = date
        }
        
        longestStreak = maxStreak
    }
}
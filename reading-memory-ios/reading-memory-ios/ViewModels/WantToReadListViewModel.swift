import Foundation
import Observation

@Observable
class WantToReadListViewModel {
    private let bookRepository: BookRepository
    @MainActor private let authService = AuthService.shared
    
    private(set) var books: [Book] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    
    var sortOption: SortOption = .smart {
        didSet {
            sortBooks()
        }
    }
    
    enum SortOption: String, CaseIterable {
        case smart = "おすすめ順"
        case priority = "優先度"
        case addedDate = "追加日"
        case plannedDate = "予定日"
        case title = "タイトル"
        
        var icon: String {
            switch self {
            case .smart:
                return "sparkles"
            case .priority:
                return "star.fill"
            case .addedDate:
                return "calendar.badge.plus"
            case .plannedDate:
                return "calendar"
            case .title:
                return "textformat"
            }
        }
    }
    
    init(bookRepository: BookRepository = BookRepository.shared) {
        self.bookRepository = bookRepository
    }
    
    @MainActor
    func loadWantToReadBooks() async {
        isLoading = true
        error = nil
        
        do {
            let allBooks = try await bookRepository.getBooks()
            self.books = allBooks.filter { $0.status == ReadingStatus.wantToRead }
            sortBooks()
        } catch {
            self.error = error
            print("Error loading want to read books: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func updatePriority(bookId: String, priority: Int?) async {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else { return }
        
        let book = books[index]
        let updatedBook = book.updated(priority: priority)
        
        do {
            try await bookRepository.updateBook(updatedBook)
            books[index] = updatedBook
            sortBooks()
        } catch {
            self.error = error
            print("Error updating priority: \(error)")
        }
    }
    
    @MainActor
    func updatePlannedReadingDate(bookId: String, date: Date?) async {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else { return }
        
        let book = books[index]
        let updatedBook = book.updated(plannedReadingDate: date)
        
        do {
            try await bookRepository.updateBook(updatedBook)
            books[index] = updatedBook
            if sortOption == .plannedDate {
                sortBooks()
            }
        } catch {
            self.error = error
            print("Error updating planned reading date: \(error)")
        }
    }
    
    @MainActor
    func toggleReminder(bookId: String) async {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else { return }
        
        let book = books[index]
        let updatedBook = book.updated(reminderEnabled: !book.reminderEnabled)
        
        do {
            try await bookRepository.updateBook(updatedBook)
            books[index] = updatedBook
        } catch {
            self.error = error
            print("Error toggling reminder: \(error)")
        }
    }
    
    @MainActor
    func updatePurchaseLinks(bookId: String, links: [PurchaseLink]) async {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else { return }
        
        let book = books[index]
        let updatedBook = book.updated(purchaseLinks: links)
        
        do {
            try await bookRepository.updateBook(updatedBook)
            books[index] = updatedBook
        } catch {
            self.error = error
            print("Error updating purchase links: \(error)")
        }
    }
    
    @MainActor
    func startReading(bookId: String) async {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else { return }
        
        let book = books[index]
        let updatedBook = book.updated(
            status: .reading,
            startDate: Date()
        )
        
        do {
            try await bookRepository.updateBook(updatedBook)
            // 読書中になったら、リストから削除
            books.remove(at: index)
        } catch {
            self.error = error
            print("Error starting reading: \(error)")
        }
    }
    
    @MainActor
    func deleteBook(bookId: String) async {
        guard let index = books.firstIndex(where: { $0.id == bookId }) else { return }
        let book = books[index]
        
        do {
            try await bookRepository.deleteBook(bookId: book.id)
            books.remove(at: index)
        } catch {
            self.error = error
            print("Error deleting book: \(error)")
        }
    }
    
    @MainActor
    func reorderBooks(from source: IndexSet, to destination: Int) async {
        // 一時的にローカルで並び替え
        books.move(fromOffsets: source, toOffset: destination)
        
        // 優先度を再計算
        for (index, book) in books.enumerated() {
            let updatedBook = book.updated(priority: index)
            books[index] = updatedBook
            
            // 非同期でサーバーに反映
            Task {
                do {
                    try await bookRepository.updateBook(updatedBook)
                } catch {
                    print("Error updating book priority: \(error)")
                }
            }
        }
    }
    
    private func sortBooks() {
        switch sortOption {
        case .smart:
            sortBooksBySmart()
        case .priority:
            // 優先度順（高い順、nilは最後に）
            books.sort { book1, book2 in
                if let p1 = book1.priority, let p2 = book2.priority {
                    if p1 != p2 {
                        return p1 > p2  // 高い優先度が先
                    }
                } else if book1.priority != nil {
                    return true
                } else if book2.priority != nil {
                    return false
                }
                return book1.addedDate > book2.addedDate
            }
        case .addedDate:
            // 追加日順（新しい順）
            books.sort { book1, book2 in
                let date1 = book1.addedDate
                let date2 = book2.addedDate
                return date1 > date2
            }
        case .plannedDate:
            // 予定日順（nilは最後に）
            books.sort { book1, book2 in
                if let d1 = book1.plannedReadingDate, let d2 = book2.plannedReadingDate {
                    return d1 < d2
                } else if book1.plannedReadingDate != nil {
                    return true
                } else if book2.plannedReadingDate != nil {
                    return false
                } else {
                    return book1.addedDate > book2.addedDate
                }
            }
        case .title:
            // タイトル順
            books.sort { $0.title < $1.title }
        }
    }
    
    private func sortBooksBySmart() {
        let now = Date()
        let calendar = Calendar.current
        
        books.sort { lhs, rhs in
            let lhsScore = calculateSmartScore(for: lhs, now: now, calendar: calendar)
            let rhsScore = calculateSmartScore(for: rhs, now: now, calendar: calendar)
            
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }
            
            // スコアが同じ場合は追加日でソート
            return lhs.addedDate > rhs.addedDate
        }
    }
    
    private func calculateSmartScore(for book: Book, now: Date, calendar: Calendar) -> Double {
        var score: Double = 0
        
        // 1. 読書予定日のスコア（最大50ポイント）
        if let plannedDate = book.plannedReadingDate {
            let daysUntil = calendar.dateComponents([.day], from: now, to: plannedDate).day ?? 0
            
            if daysUntil < 0 {
                // 期限切れ：最高優先度
                score += 50
            } else if daysUntil == 0 {
                // 今日が期限
                score += 48
            } else if daysUntil <= 3 {
                // 3日以内：非常に高い優先度
                score += 45 - Double(daysUntil) * 3
            } else if daysUntil <= 7 {
                // 1週間以内：高優先度
                score += 35 - Double(daysUntil) * 2
            } else if daysUntil <= 30 {
                // 1ヶ月以内：中優先度
                score += 25 - Double(daysUntil) * 0.5
            } else {
                // それ以降：低優先度
                score += 15
            }
            
            // リマインダーが有効な場合はボーナス
            if book.reminderEnabled {
                score += 5
            }
        }
        
        // 2. 優先度スコア（最大30ポイント）
        if let priority = book.priority {
            // 優先度は1-5、高い方が優先
            score += Double(6 - priority) * 6
        }
        
        // 3. 追加からの経過日数（最大20ポイント）
        // 長期間放置されている本にもチャンスを与える
        let daysSinceAdded = calendar.dateComponents([.day], from: book.addedDate, to: now).day ?? 0
        if daysSinceAdded > 0 {
            score += min(Double(daysSinceAdded) * 0.2, 20)
        }
        
        return score
    }
}
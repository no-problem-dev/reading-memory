import Foundation
import Observation

@Observable
@MainActor
class WantToReadListViewModel {
    private var bookStore: BookStore?
    
    private(set) var isLoading = false
    private(set) var error: Error?
    
    var sortOption: SortOption = .smart
    
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
    
    init() {
    }
    
    func setBookStore(_ store: BookStore) {
        self.bookStore = store
    }
    
    // 読みたいリストの本を取得（フィルタリング＆ソート済み）
    var books: [Book] {
        guard let bookStore = bookStore else { return [] }
        
        let filteredBooks = bookStore.allBooks.filter { $0.status == ReadingStatus.wantToRead }
        return sortedBooks(filteredBooks)
    }
    
    func loadWantToReadBooks() async {
        // BookStoreが設定されているか確認
        guard bookStore != nil else {
            print("Error: BookStore not set")
            return
        }
        
        isLoading = true
        error = nil
        
        // BookStoreのallBooksが更新されたら自動的にbooksプロパティも更新される
        
        isLoading = false
    }
    
    func updatePriority(bookId: String, priority: Int?) async {
        guard let bookStore = bookStore else { return }
        guard let book = books.first(where: { $0.id == bookId }) else { return }
        
        let updatedBook = book.updated(priority: priority)
        
        do {
            try await bookStore.updateBook(updatedBook)
        } catch {
            self.error = error
            print("Error updating priority: \(error)")
        }
    }
    
    func updatePlannedReadingDate(bookId: String, date: Date?) async {
        guard let bookStore = bookStore else { return }
        guard let book = books.first(where: { $0.id == bookId }) else { return }
        
        let updatedBook = book.updated(plannedReadingDate: date)
        
        do {
            try await bookStore.updateBook(updatedBook)
        } catch {
            self.error = error
            print("Error updating planned reading date: \(error)")
        }
    }
    
    func toggleReminder(bookId: String) async {
        guard let bookStore = bookStore else { return }
        guard let book = books.first(where: { $0.id == bookId }) else { return }
        
        let updatedBook = book.updated(reminderEnabled: !book.reminderEnabled)
        
        do {
            try await bookStore.updateBook(updatedBook)
        } catch {
            self.error = error
            print("Error toggling reminder: \(error)")
        }
    }
    
    func updatePurchaseLinks(bookId: String, links: [PurchaseLink]) async {
        guard let bookStore = bookStore else { return }
        guard let book = books.first(where: { $0.id == bookId }) else { return }
        
        let updatedBook = book.updated(purchaseLinks: links)
        
        do {
            try await bookStore.updateBook(updatedBook)
        } catch {
            self.error = error
            print("Error updating purchase links: \(error)")
        }
    }
    
    func startReading(bookId: String) async {
        guard let bookStore = bookStore else { return }
        guard let book = books.first(where: { $0.id == bookId }) else { return }
        
        let updatedBook = book.updated(
            status: .reading,
            startDate: Date()
        )
        
        do {
            try await bookStore.updateBook(updatedBook)
            // BookStoreが更新されれば、booksプロパティも自動的に更新される
        } catch {
            self.error = error
            print("Error starting reading: \(error)")
        }
    }
    
    func deleteBook(bookId: String) async {
        guard let bookStore = bookStore else { return }
        
        do {
            try await bookStore.deleteBook(id: bookId)
            // BookStoreが更新されれば、booksプロパティも自動的に更新される
        } catch {
            self.error = error
            print("Error deleting book: \(error)")
        }
    }
    
    
    private func sortedBooks(_ books: [Book]) -> [Book] {
        switch sortOption {
        case .smart:
            return sortBooksBySmart(books)
        case .priority:
            // 優先度順（高い順、nilは最後に）
            return books.sorted { book1, book2 in
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
            return books.sorted { book1, book2 in
                let date1 = book1.addedDate
                let date2 = book2.addedDate
                return date1 > date2
            }
        case .plannedDate:
            // 予定日順（nilは最後に）
            return books.sorted { book1, book2 in
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
            return books.sorted { $0.title < $1.title }
        }
    }
    
    private func sortBooksBySmart(_ books: [Book]) -> [Book] {
        let now = Date()
        let calendar = Calendar.current
        
        return books.sorted { lhs, rhs in
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
import Foundation
import Observation

@Observable
class WantToReadListViewModel {
    private let bookRepository: BookRepository
    private let authService = AuthService.shared
    
    private(set) var books: [Book] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    
    var sortOption: SortOption = .priority {
        didSet {
            sortBooks()
        }
    }
    
    enum SortOption: String, CaseIterable {
        case priority = "優先度"
        case addedDate = "追加日"
        case plannedDate = "予定日"
        case title = "タイトル"
        
        var icon: String {
            switch self {
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
        
        guard let userId = authService.currentUser?.uid else {
            self.error = AppError.authenticationRequired
            isLoading = false
            return
        }
        
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
            guard let userId = authService.currentUser?.uid else {
                throw AppError.authenticationRequired
            }
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
        case .priority:
            // 優先度順（nilは最後に）
            books.sort { book1, book2 in
                if let p1 = book1.priority, let p2 = book2.priority {
                    return p1 < p2
                } else if book1.priority != nil {
                    return true
                } else if book2.priority != nil {
                    return false
                } else {
                    return book1.addedDate > book2.addedDate
                }
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
}
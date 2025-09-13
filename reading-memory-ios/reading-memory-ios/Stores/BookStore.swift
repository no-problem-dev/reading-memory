import Foundation
import SwiftUI

/// アプリ全体の本の状態を管理する環境オブジェクト
/// Single Source of Truthとして機能し、全ての本関連の操作を一元管理
@MainActor
@Observable
final class BookStore {
    // MARK: - Properties
    
    /// 読み込んだ全ての本
    private(set) var allBooks: [Book] = []
    
    /// フィルタリングされた本
    private(set) var filteredBooks: [Book] = []
    
    /// 現在のフィルター
    var currentFilter: BookFilter = .all {
        didSet {
            applyFilterAndSort()
        }
    }
    
    /// 表示モード
    var displayMode: DisplayMode = .grid
    
    /// ソート設定
    private var currentSort: SortOption = .dateAdded {
        didSet {
            applyFilterAndSort()
        }
    }
    
    /// ローディング状態
    private(set) var isLoading = false
    
    /// エラー
    private(set) var error: Error?
    
    // MARK: - Dependencies
    
    private let bookRepository: BookRepository
    
    // MARK: - Initialization
    
    init(bookRepository: BookRepository = BookRepository.shared) {
        self.bookRepository = bookRepository
    }
    
    // MARK: - Public Methods
    
    /// 本を読み込む
    func loadBooks() async {
        isLoading = true
        error = nil
        
        do {
            allBooks = try await bookRepository.getBooks()
            applyFilterAndSort()
        } catch {
            self.error = error
            print("Error loading books: \(error)")
        }
        
        isLoading = false
    }
    
    /// 本を追加
    func addBook(_ book: Book) async throws -> Book {
        // リポジトリ経由で本を作成（画像アップロードなども含む）
        let createdBook = try await bookRepository.createBook(book)
        
        // ローカルの配列に即座に追加（楽観的更新）
        allBooks.append(createdBook)
        applyFilterAndSort()
        
        return createdBook
    }
    
    /// 検索結果から本を追加
    func addBookFromSearchResult(_ searchResult: BookSearchResult, status: ReadingStatus = .wantToRead) async throws -> Book {
        // リポジトリ経由で本を作成（画像のダウンロード・アップロードを含む）
        let createdBook = try await bookRepository.createBookFromSearchResult(searchResult, status: status)
        
        // ローカルの配列に即座に追加（楽観的更新）
        allBooks.append(createdBook)
        applyFilterAndSort()
        
        return createdBook
    }
    
    /// 本を更新
    func updateBook(_ book: Book) async throws {
        try await bookRepository.updateBook(book)
        
        // ローカルの配列を即座に更新（楽観的更新）
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index] = book
            applyFilterAndSort()
        }
    }
    
    /// 本を削除
    func deleteBook(id: String) async throws {
        try await bookRepository.deleteBook(bookId: id)
        
        // ローカルの配列から即座に削除（楽観的更新）
        allBooks.removeAll { $0.id == id }
        applyFilterAndSort()
    }
    
    /// 指定したIDの本を取得
    func getBook(id: String) -> Book? {
        return allBooks.first { $0.id == id }
    }
    
    /// フィルターを設定
    func setFilter(_ filter: BookFilter) {
        currentFilter = filter
    }
    
    /// 表示モードを設定
    func setDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
    }
    
    /// ソート設定を変更
    func setSortOption(_ option: SortOption) {
        currentSort = option
    }
    
    // MARK: - Private Methods
    
    /// フィルターとソートを適用
    private func applyFilterAndSort() {
        // フィルター適用
        var books = allBooks
        if let status = currentFilter.status {
            books = books.filter { $0.status == status }
        }
        
        // ソート適用
        switch currentSort {
        case .dateAdded:
            books.sort { $0.createdAt > $1.createdAt }
        case .title:
            books.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:
            books.sort { $0.author.localizedCompare($1.author) == .orderedAscending }
        case .rating:
            books.sort { 
                let rating0 = $0.rating ?? 0
                let rating1 = $1.rating ?? 0
                return rating0 > rating1
            }
        }
        
        filteredBooks = books
    }
}

// MARK: - Supporting Types

extension BookStore {
    enum BookFilter: String, CaseIterable {
        case all = "すべて"
        case reading = "読書中"
        case completed = "読了"
        case dnf = "積読"
        case wantToRead = "読みたい"
        
        var status: ReadingStatus? {
            switch self {
            case .all:
                return nil
            case .reading:
                return .reading
            case .completed:
                return .completed
            case .dnf:
                return .dnf
            case .wantToRead:
                return .wantToRead
            }
        }
    }
    
    enum DisplayMode {
        case grid
        case list
    }
    
    enum SortOption {
        case dateAdded
        case title
        case author
        case rating
    }
}
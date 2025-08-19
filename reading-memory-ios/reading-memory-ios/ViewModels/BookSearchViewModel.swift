import Foundation

@Observable
@MainActor
final class BookSearchViewModel: BaseViewModel {
    private let bookRepository = BookRepository.shared
    private let userBookRepository = UserBookRepository.shared
    private let authService = AuthService.shared
    private let searchService = UnifiedBookSearchService.shared
    private let cacheService = BookCacheService.shared
    
    // 検索結果
    var searchResults: [Book] = []
    var publicBooks: [Book] = []  // Firestore内の公開本
    var isSearching = false
    var searchQuery = ""
    
    // 検索履歴
    var recentSearches: [String] {
        cacheService.getRecentSearches()
    }
    
    func searchBooks(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        searchQuery = query
        
        // キャッシュをチェック
        if let cachedResults = cacheService.getCachedResults(for: query) {
            searchResults = cachedResults
            return
        }
        
        isSearching = true
        
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            // 並行して検索を実行
            async let firestoreResults = self.searchInFirestore(query: query)
            async let apiResults = self.searchInGoogleBooks(query: query)
            
            // 結果を統合
            let (firestore, api) = await (firestoreResults, apiResults)
            
            // 重複を排除（ISBNベース）
            var uniqueBooks: [Book] = []
            var seenISBNs: Set<String> = []
            
            // Firestoreの結果を優先
            for book in firestore {
                if let isbn = book.isbn, !isbn.isEmpty {
                    if !seenISBNs.contains(isbn) {
                        uniqueBooks.append(book)
                        seenISBNs.insert(isbn)
                    }
                } else {
                    uniqueBooks.append(book)
                }
            }
            
            // API結果を追加（重複を除く）
            for book in api {
                if let isbn = book.isbn, !isbn.isEmpty {
                    if !seenISBNs.contains(isbn) {
                        uniqueBooks.append(book)
                        seenISBNs.insert(isbn)
                    }
                } else {
                    // ISBNがない本もタイトルと著者で重複チェック
                    let isDuplicate = uniqueBooks.contains { existing in
                        existing.title.lowercased() == book.title.lowercased() &&
                        existing.author.lowercased() == book.author.lowercased()
                    }
                    if !isDuplicate {
                        uniqueBooks.append(book)
                    }
                }
            }
            
            self.searchResults = uniqueBooks
            
            // 結果をキャッシュに保存
            self.cacheService.cacheSearchResults(uniqueBooks, for: query)
            
            // 検索履歴に追加
            self.cacheService.addRecentSearch(query)
        }
        
        isSearching = false
    }
    
    private func searchInFirestore(query: String) async -> [Book] {
        do {
            return try await bookRepository.searchPublicBooks(query: query)
        } catch {
            print("Firestore search error: \(error)")
            return []
        }
    }
    
    private func searchInGoogleBooks(query: String) async -> [Book] {
        // 統合検索サービスを使用
        return await searchService.unifiedSearch(query: query)
    }
    
    func loadPublicBooks() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            // TODO: Firestore から公開本を取得
            self.publicBooks = []
        }
    }
    
    func isBookAlreadyRegistered(_ book: Book) async -> Bool {
        guard let userId = authService.currentUser?.uid else { return false }
        
        // ISBNで確認
        if let isbn = book.isbn, !isbn.isEmpty {
            if let existingBook = try? await bookRepository.getBookByISBN(isbn) {
                let userBook = try? await userBookRepository.getUserBookByBookId(
                    userId: userId,
                    bookId: existingBook.id
                )
                return userBook != nil
            }
        }
        
        return false
    }
}
import Foundation

@Observable
@MainActor
final class BookSearchViewModel: BaseViewModel {
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    private let searchService = UnifiedBookSearchService.shared
    private let cacheService = BookCacheService.shared
    private let analytics = AnalyticsService.shared
    
    // 検索結果
    var searchResults: [BookSearchResult] = []
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
        
        // TODO: キャッシュ機能をBookSearchResultに対応させる
        // if let cachedResults = cacheService.getCachedResults(for: query) {
        //     searchResults = cachedResults
        //     return
        // }
        
        isSearching = true
        
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            // API検索を実行
            let apiResults = await self.searchInGoogleBooks(query: query)
            
            // 重複を排除（ISBNベース）
            var uniqueBooks: [BookSearchResult] = []
            var seenISBNs: Set<String> = []
            
            // API結果を処理
            for book in apiResults {
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
            
            // 検索イベントを送信
            self.analytics.track(AnalyticsEvent.userAction(action: .search(
                query: query,
                resultCount: uniqueBooks.count
            )))
            
            // TODO: キャッシュ機能をBookSearchResultに対応させる
            // self.cacheService.cacheSearchResults(uniqueBooks, for: query)
            
            // 検索履歴に追加
            self.cacheService.addRecentSearch(query)
        }
        
        isSearching = false
    }
    
    private func searchInGoogleBooks(query: String) async -> [BookSearchResult] {
        // 統合検索サービスを使用
        return await searchService.unifiedSearch(query: query)
    }
    
    func isBookAlreadyRegistered(_ searchResult: BookSearchResult) async -> Bool {
        // ISBNで確認
        if let isbn = searchResult.isbn, !isbn.isEmpty {
            let existingBook = try? await bookRepository.getBookByISBN(isbn: isbn)
            return existingBook != nil
        }
        
        return false
    }
}
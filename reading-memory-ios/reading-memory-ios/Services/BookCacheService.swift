import Foundation

// 書籍検索結果のキャッシュサービス
final class BookCacheService {
    static let shared = BookCacheService()
    
    private let cache = NSCache<NSString, CachedBookData>()
    private let userDefaults = UserDefaults.standard
    private let recentSearchesKey = "RecentBookSearches"
    private let maxRecentSearches = 10
    private let cacheExpirationMinutes = 15
    
    private init() {
        // キャッシュの設定
        cache.countLimit = 100 // 最大100件
        cache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }
    
    // MARK: - 検索結果のキャッシュ
    
    func cacheSearchResults(_ books: [Book], for query: String) {
        let cacheKey = createCacheKey(for: query)
        let cachedData = CachedBookData(
            books: books,
            timestamp: Date(),
            query: query
        )
        
        cache.setObject(cachedData, forKey: cacheKey as NSString)
    }
    
    func getCachedResults(for query: String) -> [Book]? {
        let cacheKey = createCacheKey(for: query)
        
        guard let cachedData = cache.object(forKey: cacheKey as NSString) else {
            return nil
        }
        
        // キャッシュの有効期限をチェック
        let expirationDate = cachedData.timestamp.addingTimeInterval(TimeInterval(cacheExpirationMinutes * 60))
        if Date() > expirationDate {
            cache.removeObject(forKey: cacheKey as NSString)
            return nil
        }
        
        return cachedData.books
    }
    
    // MARK: - 個別の本のキャッシュ
    
    func cacheBook(_ book: Book) {
        if let isbn = book.isbn {
            let cacheKey = "isbn_\(isbn)" as NSString
            let cachedData = CachedBookData(
                books: [book],
                timestamp: Date(),
                query: isbn
            )
            cache.setObject(cachedData, forKey: cacheKey)
        }
    }
    
    func getCachedBook(by isbn: String) -> Book? {
        let cacheKey = "isbn_\(isbn)" as NSString
        return cache.object(forKey: cacheKey)?.books.first
    }
    
    // MARK: - 最近の検索履歴
    
    func addRecentSearch(_ query: String) {
        var searches = getRecentSearches()
        
        // 既存の同じクエリを削除
        searches.removeAll { $0.lowercased() == query.lowercased() }
        
        // 新しいクエリを先頭に追加
        searches.insert(query, at: 0)
        
        // 最大件数を超えたら古いものを削除
        if searches.count > maxRecentSearches {
            searches = Array(searches.prefix(maxRecentSearches))
        }
        
        userDefaults.set(searches, forKey: recentSearchesKey)
    }
    
    func getRecentSearches() -> [String] {
        return userDefaults.stringArray(forKey: recentSearchesKey) ?? []
    }
    
    func clearRecentSearches() {
        userDefaults.removeObject(forKey: recentSearchesKey)
    }
    
    // MARK: - キャッシュのクリア
    
    func clearAllCache() {
        cache.removeAllObjects()
    }
    
    func clearExpiredCache() {
        // NSCache は自動的にメモリ管理を行うため、明示的な削除は不要
        // ただし、必要に応じて実装可能
    }
    
    // MARK: - Private Methods
    
    private func createCacheKey(for query: String) -> String {
        return "search_\(query.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }
}

// キャッシュデータのラッパー
private class CachedBookData: NSObject {
    let books: [Book]
    let timestamp: Date
    let query: String
    
    init(books: [Book], timestamp: Date, query: String) {
        self.books = books
        self.timestamp = timestamp
        self.query = query
    }
}
import Foundation

/// 複数のAPIを統合した書籍検索サービス
final class UnifiedBookSearchService {
    static let shared = UnifiedBookSearchService()
    
    private let bookSearchService = BookSearchService.shared
    private let cacheService = BookCacheService.shared
    
    private init() {}
    
    /// ISBN検索
    func searchByISBN(_ isbn: String) async -> [Book] {
        let cleanedISBN = isbn.replacingOccurrences(of: "-", with: "")
        
        // キャッシュをチェック
        if let cachedBook = cacheService.getCachedBook(by: cleanedISBN) {
            return [cachedBook]
        }
        
        do {
            let books = try await bookSearchService.searchByISBN(cleanedISBN)
            
            // 結果をキャッシュに保存
            if let firstBook = books.first {
                cacheService.cacheBook(firstBook)
            }
            
            return books
        } catch {
            print("ISBN search error: \(error)")
            return []
        }
    }
    
    /// キーワード検索
    func searchByKeyword(_ keyword: String, maxResults: Int = 20) async -> [Book] {
        // キャッシュをチェック
        if let cachedResults = cacheService.getCachedResults(for: keyword) {
            return cachedResults
        }
        
        do {
            let books = try await bookSearchService.searchByQuery(keyword)
            
            // 結果をキャッシュに保存
            cacheService.cacheSearchResults(books, for: keyword)
            cacheService.addRecentSearch(keyword)
            
            return books
        } catch {
            print("Keyword search error: \(error)")
            return []
        }
    }
    
    /// 統合検索（ISBN、タイトル、著者を判別して適切なAPIを使用）
    func unifiedSearch(query: String) async -> [Book] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空クエリの場合
        if trimmedQuery.isEmpty {
            return []
        }
        
        // ISBN形式の判定
        let cleanedQuery = trimmedQuery.replacingOccurrences(of: "-", with: "")
        if cleanedQuery.count == 10 || cleanedQuery.count == 13,
           cleanedQuery.allSatisfy({ $0.isNumber }) {
            return await searchByISBN(cleanedQuery)
        }
        
        // キーワード検索
        return await searchByKeyword(trimmedQuery)
    }
    
    /// 本の詳細情報を取得
    func fetchBookDetails(isbn: String) async -> Book? {
        let books = await searchByISBN(isbn)
        
        // 複数の結果から最も情報が豊富なものを選択
        return books.max { book1, book2 in
            let score1 = calculateDetailScore(book1)
            let score2 = calculateDetailScore(book2)
            return score1 < score2
        }
    }
    
    private func calculateDetailScore(_ book: Book) -> Int {
        var score = 0
        
        if book.isbn != nil { score += 1 }
        if !book.title.isEmpty { score += 1 }
        if !book.author.isEmpty { score += 1 }
        if book.publisher != nil { score += 1 }
        if book.publishedDate != nil { score += 1 }
        if book.pageCount != nil { score += 1 }
        if book.description != nil { score += 2 }  // 説明は重要
        if book.coverImageId != nil { score += 2 }  // 表紙画像も重要
        
        return score
    }
}
import Foundation

/// 複数のAPIを統合した書籍検索サービス
final class UnifiedBookSearchService {
    static let shared = UnifiedBookSearchService()
    
    private let bookSearchService = BookSearchService.shared
    private let cacheService = BookCacheService.shared
    
    private init() {}
    
    /// ISBN検索
    func searchByISBN(_ isbn: String) async -> [BookSearchResult] {
        let cleanedISBN = isbn.replacingOccurrences(of: "-", with: "")
        
        do {
            let searchResults = try await bookSearchService.searchByISBN(cleanedISBN)
            return searchResults
        } catch {
            print("ISBN search error: \(error)")
            return []
        }
    }
    
    /// キーワード検索
    func searchByKeyword(_ keyword: String, maxResults: Int = 20) async -> [BookSearchResult] {
        do {
            let searchResults = try await bookSearchService.searchByQuery(keyword)
            cacheService.addRecentSearch(keyword)
            return searchResults
        } catch {
            print("Keyword search error: \(error)")
            return []
        }
    }
    
    /// 統合検索（ISBN、タイトル、著者を判別して適切なAPIを使用）
    func unifiedSearch(query: String) async -> [BookSearchResult] {
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
    func fetchBookDetails(isbn: String) async -> BookSearchResult? {
        let searchResults = await searchByISBN(isbn)
        
        // 複数の結果から最も情報が豊富なものを選択
        return searchResults.max { result1, result2 in
            let score1 = calculateDetailScore(result1)
            let score2 = calculateDetailScore(result2)
            return score1 < score2
        }
    }
    
    private func calculateDetailScore(_ searchResult: BookSearchResult) -> Int {
        var score = 0
        
        if searchResult.isbn != nil { score += 1 }
        if !searchResult.title.isEmpty { score += 1 }
        if !searchResult.author.isEmpty { score += 1 }
        if searchResult.publisher != nil { score += 1 }
        if searchResult.publishedDate != nil { score += 1 }
        if searchResult.pageCount != nil { score += 1 }
        if searchResult.description != nil { score += 2 }  // 説明は重要
        if searchResult.coverImageUrl != nil { score += 2 }  // 表紙画像も重要
        
        return score
    }
}
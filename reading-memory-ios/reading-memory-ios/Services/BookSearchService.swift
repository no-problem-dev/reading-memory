import Foundation

/// 書籍検索サービス
final class BookSearchService {
    static let shared = BookSearchService()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - 書籍検索
    
    /// ISBNで書籍を検索
    func searchByISBN(_ isbn: String) async throws -> [Book] {
        let result = try await apiClient.searchBookByISBN(isbn)
        return result.books.compactMap { dto in
            parseBookFromDTO(dto)
        }
    }
    
    /// キーワードで書籍を検索
    func searchByQuery(_ query: String) async throws -> [Book] {
        let result = try await apiClient.searchBooksByQuery(query)
        return result.books.compactMap { dto in
            parseBookFromDTO(dto)
        }
    }
    
    // MARK: - 公開本の取得
    
    /// 人気の本を取得
    func getPopularBooks(limit: Int = 20) async throws -> [Book] {
        let result = try await apiClient.getPopularBooks(limit: limit)
        return result.books.compactMap { dto in
            parseBookFromDTO(dto)
        }
    }
    
    /// 新着の本を取得
    func getRecentBooks(limit: Int = 20) async throws -> [Book] {
        let result = try await apiClient.getRecentBooks(limit: limit)
        return result.books.compactMap { dto in
            parseBookFromDTO(dto)
        }
    }
    
    /// 公開本を検索
    func searchPublicBooks(query: String, limit: Int = 20) async throws -> [Book] {
        let result = try await apiClient.searchPublicBooks(query: query, limit: limit)
        return result.books.compactMap { dto in
            parseBookFromDTO(dto)
        }
    }
    
    // MARK: - Private Methods
    
    private func parseBookFromDTO(_ dto: APIBookDTO) -> Book? {
        let dataSource: BookDataSource
        switch dto.dataSource {
        case "googleBooks":
            dataSource = .googleBooks
        case "openBD":
            dataSource = .openBD
        default:
            dataSource = .manual
        }
        
        let visibility: BookVisibility
        if let visibilityString = dto.visibility,
           let vis = BookVisibility(rawValue: visibilityString) {
            visibility = vis
        } else {
            visibility = .public
        }
        
        // 出版日の変換
        var publishedDate: Date?
        if let dateString = dto.publishedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            publishedDate = formatter.date(from: dateString)
        }
        
        if let id = dto.id {
            // 既存の本
            return Book(
                id: id,
                isbn: dto.isbn,
                title: dto.title,
                author: dto.author,
                publisher: dto.publisher,
                publishedDate: publishedDate,
                pageCount: dto.pageCount,
                description: dto.description,
                coverImageUrl: dto.coverImageUrl,
                dataSource: dataSource,
                visibility: visibility,
                createdAt: dto.createdAt ?? Date(),
                updatedAt: dto.updatedAt ?? Date()
            )
        } else {
            // 新規の本
            return Book.new(
                isbn: dto.isbn,
                title: dto.title,
                author: dto.author,
                publisher: dto.publisher,
                publishedDate: publishedDate,
                pageCount: dto.pageCount,
                description: dto.description,
                coverImageUrl: dto.coverImageUrl,
                dataSource: dataSource,
                visibility: visibility
            )
        }
    }
}
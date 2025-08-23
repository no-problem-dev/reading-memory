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
    
    // MARK: - 公開本の取得（削除予定）
    
    // 以下のメソッドは公開本機能削除のため、将来的に削除予定
    
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
        
        // 出版日の変換
        var publishedDate: Date?
        if let dateString = dto.publishedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            publishedDate = formatter.date(from: dateString)
        }
        
        if let id = dto.id {
            // 既存の本（APIから取得した場合）
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
                status: .wantToRead,
                addedDate: Date(),
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
                dataSource: dataSource
            )
        }
    }
}
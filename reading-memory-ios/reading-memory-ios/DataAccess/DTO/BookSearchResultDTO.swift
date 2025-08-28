import Foundation

/// 書籍検索結果のDTO
/// 外部APIから取得した書籍情報を表現
struct BookSearchResultDTO: Codable {
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: String?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?  // 外部APIからの画像URL
    let dataSource: String
    let affiliateUrl: String?
}

/// 書籍検索APIレスポンス
struct BookSearchResponse: Codable {
    let books: [BookSearchResultDTO]
}
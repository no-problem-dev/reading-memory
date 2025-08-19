import Foundation

// 書籍マスターデータ（全ユーザー共通）
// ドメインモデル - 外部依存なし
struct Book: Identifiable, Equatable {
    let id: String
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: Date?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    let dataSource: BookDataSource
    let visibility: BookVisibility
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String,
        isbn: String? = nil,
        title: String,
        author: String,
        publisher: String? = nil,
        publishedDate: Date? = nil,
        pageCount: Int? = nil,
        description: String? = nil,
        coverImageUrl: String? = nil,
        dataSource: BookDataSource,
        visibility: BookVisibility,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.pageCount = pageCount
        self.description = description
        self.coverImageUrl = coverImageUrl
        self.dataSource = dataSource
        self.visibility = visibility
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 新規作成用のファクトリメソッド
    static func new(
        isbn: String? = nil,
        title: String,
        author: String,
        publisher: String? = nil,
        publishedDate: Date? = nil,
        pageCount: Int? = nil,
        description: String? = nil,
        coverImageUrl: String? = nil,
        dataSource: BookDataSource = .manual,
        visibility: BookVisibility = .private
    ) -> Book {
        let now = Date()
        return Book(
            id: UUID().uuidString,
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedDate: publishedDate,
            pageCount: pageCount,
            description: description,
            coverImageUrl: coverImageUrl,
            dataSource: dataSource,
            visibility: visibility,
            createdAt: now,
            updatedAt: now
        )
    }
}
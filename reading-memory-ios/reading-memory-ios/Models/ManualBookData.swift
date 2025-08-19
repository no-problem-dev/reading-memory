import Foundation

// 手動入力された本の情報
struct ManualBookData: Codable, Equatable {
    let title: String
    let author: String
    let isbn: String?
    let publisher: String?
    let publishedDate: Date?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    
    init(
        title: String,
        author: String,
        isbn: String? = nil,
        publisher: String? = nil,
        publishedDate: Date? = nil,
        pageCount: Int? = nil,
        description: String? = nil,
        coverImageUrl: String? = nil
    ) {
        self.title = title
        self.author = author
        self.isbn = isbn
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.pageCount = pageCount
        self.description = description
        self.coverImageUrl = coverImageUrl
    }
    
    // Bookモデルから変換
    init(from book: Book) {
        self.title = book.title
        self.author = book.author
        self.isbn = book.isbn
        self.publisher = book.publisher
        self.publishedDate = book.publishedDate
        self.pageCount = book.pageCount
        self.description = book.description
        self.coverImageUrl = book.coverImageUrl
    }
}
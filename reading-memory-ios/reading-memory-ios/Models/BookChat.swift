import Foundation

struct BookChat: Identifiable, Equatable {
    let id: String
    let bookId: String
    let message: String
    let imageUrl: String?
    let chapterOrSection: String?
    let pageNumber: Int?
    let isAI: Bool
    let createdAt: Date
    
    // 互換性のため一時的に残す
    var userBookId: String {
        get { bookId }
        set { }
    }
    
    init(
        id: String,
        bookId: String,
        message: String,
        imageUrl: String? = nil,
        chapterOrSection: String? = nil,
        pageNumber: Int? = nil,
        isAI: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.bookId = bookId
        self.message = message
        self.imageUrl = imageUrl
        self.chapterOrSection = chapterOrSection
        self.pageNumber = pageNumber
        self.isAI = isAI
        self.createdAt = createdAt
    }
    
    // 新規作成用のファクトリメソッド
    static func new(
        bookId: String,
        message: String,
        imageUrl: String? = nil,
        chapterOrSection: String? = nil,
        pageNumber: Int? = nil,
        isAI: Bool = false
    ) -> BookChat {
        return BookChat(
            id: UUID().uuidString,
            bookId: bookId,
            message: message,
            imageUrl: imageUrl,
            chapterOrSection: chapterOrSection,
            pageNumber: pageNumber,
            isAI: isAI,
            createdAt: Date()
        )
    }
}
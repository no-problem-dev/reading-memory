import Foundation

struct BookChatDTO: Codable {
    let bookId: String
    let message: String
    let imageUrl: String?
    let chapterOrSection: String?
    let pageNumber: Int?
    let isAI: Bool
    let createdAt: Date
    
    // 後方互換性のため
    var userBookId: String {
        bookId
    }
    
    init(from bookChat: BookChat) {
        self.bookId = bookChat.bookId
        self.message = bookChat.message
        self.imageUrl = bookChat.imageUrl
        self.chapterOrSection = bookChat.chapterOrSection
        self.pageNumber = bookChat.pageNumber
        self.isAI = bookChat.isAI
        self.createdAt = bookChat.createdAt
    }
    
    func toDomain(id: String) -> BookChat {
        return BookChat(
            id: id,
            bookId: bookId,
            message: message,
            imageUrl: imageUrl,
            chapterOrSection: chapterOrSection,
            pageNumber: pageNumber,
            isAI: isAI,
            createdAt: createdAt
        )
    }
}
import Foundation

struct BookChatDTO: Codable {
    let bookId: String
    let message: String
    let messageType: String
    let imageUrl: String?
    let chapterOrSection: String?
    let pageNumber: Int?
    let createdAt: Date
    let updatedAt: Date
    
    // 後方互換性のため
    var userBookId: String {
        bookId
    }
    
    // 後方互換性のため
    var isAI: Bool {
        messageType == "ai"
    }
    
    init(from bookChat: BookChat) {
        self.bookId = bookChat.bookId
        self.message = bookChat.message
        self.messageType = bookChat.messageType.rawValue
        self.imageUrl = bookChat.imageUrl
        self.chapterOrSection = bookChat.chapterOrSection
        self.pageNumber = bookChat.pageNumber
        self.createdAt = bookChat.createdAt
        self.updatedAt = bookChat.updatedAt
    }
    
    func toDomain(id: String) -> BookChat {
        return BookChat(
            id: id,
            bookId: bookId,
            message: message,
            messageType: MessageType(rawValue: messageType) ?? .user,
            imageUrl: imageUrl,
            chapterOrSection: chapterOrSection,
            pageNumber: pageNumber,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
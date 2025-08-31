import Foundation

struct BookChat: Identifiable, Equatable {
    let id: String
    let bookId: String
    let message: String
    let messageType: MessageType
    let imageId: String?
    let chapterOrSection: String?
    let pageNumber: Int?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String,
        bookId: String,
        message: String,
        messageType: MessageType = .user,
        imageId: String? = nil,
        chapterOrSection: String? = nil,
        pageNumber: Int? = nil,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.message = message
        self.messageType = messageType
        self.imageId = imageId
        self.chapterOrSection = chapterOrSection
        self.pageNumber = pageNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
    
    // 新規作成用のファクトリメソッド
    static func new(
        bookId: String,
        message: String,
        messageType: MessageType = .user,
        imageId: String? = nil,
        chapterOrSection: String? = nil,
        pageNumber: Int? = nil
    ) -> BookChat {
        let now = Date()
        return BookChat(
            id: UUID().uuidString,
            bookId: bookId,
            message: message,
            messageType: messageType,
            imageId: imageId,
            chapterOrSection: chapterOrSection,
            pageNumber: pageNumber,
            createdAt: now,
            updatedAt: now
        )
    }
}
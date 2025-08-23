import Foundation

struct BookChat: Identifiable, Equatable {
    let id: String
    let bookId: String
    let message: String
    let messageType: MessageType
    let imageUrl: String?
    let chapterOrSection: String?
    let pageNumber: Int?
    let createdAt: Date
    let updatedAt: Date
    
    // 互換性のため一時的に残す
    var userBookId: String {
        get { bookId }
        set { }
    }
    
    // Computed property for backward compatibility
    var isAI: Bool {
        messageType == .ai
    }
    
    init(
        id: String,
        bookId: String,
        message: String,
        messageType: MessageType = .user,
        imageUrl: String? = nil,
        chapterOrSection: String? = nil,
        pageNumber: Int? = nil,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.message = message
        self.messageType = messageType
        self.imageUrl = imageUrl
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
        imageUrl: String? = nil,
        chapterOrSection: String? = nil,
        pageNumber: Int? = nil
    ) -> BookChat {
        let now = Date()
        return BookChat(
            id: UUID().uuidString,
            bookId: bookId,
            message: message,
            messageType: messageType,
            imageUrl: imageUrl,
            chapterOrSection: chapterOrSection,
            pageNumber: pageNumber,
            createdAt: now,
            updatedAt: now
        )
    }
}
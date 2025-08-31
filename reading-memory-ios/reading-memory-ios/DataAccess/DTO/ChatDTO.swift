import Foundation

struct ChatDTO: Codable {
    let id: String?
    let message: String
    let messageType: String
    let imageId: String?
    let chapterOrSection: String?
    let pageNumber: Int?
    let createdAt: Date
    let updatedAt: Date
    
    init(from chat: BookChat) {
        self.id = chat.id
        self.message = chat.message
        self.messageType = chat.messageType.rawValue
        self.imageId = chat.imageId
        self.chapterOrSection = chat.chapterOrSection
        self.pageNumber = chat.pageNumber
        self.createdAt = chat.createdAt
        self.updatedAt = chat.updatedAt
    }
    
    func toDomain(bookId: String) -> BookChat {
        return BookChat(
            id: id ?? UUID().uuidString,
            bookId: bookId,
            message: message,
            messageType: MessageType(rawValue: messageType) ?? .user,
            imageId: imageId,
            chapterOrSection: chapterOrSection,
            pageNumber: pageNumber,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
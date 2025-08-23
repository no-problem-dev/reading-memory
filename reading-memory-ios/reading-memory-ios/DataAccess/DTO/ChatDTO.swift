import Foundation

struct ChatDTO: Codable {
    let id: String?
    let message: String
    let messageType: String
    let createdAt: Date
    let updatedAt: Date
    
    init(from chat: BookChat) {
        self.id = chat.id
        self.message = chat.message
        self.messageType = chat.messageType.rawValue
        self.createdAt = chat.createdAt
        self.updatedAt = chat.updatedAt
    }
    
    func toDomain(bookId: String) -> BookChat {
        return BookChat(
            id: id ?? UUID().uuidString,
            bookId: bookId,
            message: message,
            messageType: MessageType(rawValue: messageType) ?? .user,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
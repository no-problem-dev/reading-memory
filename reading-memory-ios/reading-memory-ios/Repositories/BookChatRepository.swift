import Foundation

final class BookChatRepository {
    static let shared = BookChatRepository()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func getChats(bookId: String, limit: Int = 50) async throws -> [BookChat] {
        return try await apiClient.getChats(bookId: bookId)
    }
    
    func addChat(_ chat: BookChat, bookId: String) async throws -> BookChat {
        return try await apiClient.createChat(
            bookId: bookId,
            message: chat.message,
            messageType: chat.messageType,
            imageId: chat.imageId
        )
    }
    
    func updateChat(_ chat: BookChat, bookId: String) async throws -> BookChat {
        return try await apiClient.updateChat(
            bookId: bookId,
            chatId: chat.id,
            message: chat.message
        )
    }
    
    func deleteChat(chatId: String, bookId: String) async throws {
        try await apiClient.deleteChat(bookId: bookId, chatId: chatId)
    }
    
}
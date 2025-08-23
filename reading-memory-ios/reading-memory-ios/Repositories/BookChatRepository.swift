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
            messageType: chat.messageType
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
    
    // Note: リアルタイムリスナーは将来的にWebSocketやSSEで実装予定
    func listenToChats(bookId: String, completion: @escaping (Result<[BookChat], Error>) -> Void) -> ListenerRegistration? {
        // 現在はポーリングで実装（将来的にWebSocketに置き換え）
        Task {
            do {
                let chats = try await getChats(bookId: bookId)
                completion(.success(chats))
            } catch {
                completion(.failure(error))
            }
        }
        return DummyListenerRegistration()
    }
}

// ダミーリスナー
class ListenerRegistration {
    func remove() {}
}

class DummyListenerRegistration: ListenerRegistration {
    override func remove() {}
}
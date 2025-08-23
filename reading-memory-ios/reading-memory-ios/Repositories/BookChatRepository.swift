import Foundation

final class BookChatRepository {
    static let shared = BookChatRepository()
    
    private init() {}
    
    // TODO: API実装後に変更
    // 現在はダミー実装
    
    func getChats(bookId: String, limit: Int = 50) async throws -> [BookChat] {
        // ダミーデータを返す
        return []
    }
    
    func addChat(_ chat: BookChat) async throws -> BookChat {
        // ダミーで同じチャットを返す
        return chat
    }
    
    func updateChat(_ chat: BookChat) async throws {
        // 何もしない
    }
    
    func deleteChat(chatId: String, bookId: String) async throws {
        // 何もしない
    }
    
    func listenToChats(bookId: String, completion: @escaping (Result<[BookChat], Error>) -> Void) -> ListenerRegistration? {
        // ダミーリスナーを返す
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
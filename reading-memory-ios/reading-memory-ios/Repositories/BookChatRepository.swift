import Foundation
import FirebaseFirestore
import FirebaseAuth

final class BookChatRepository {
    private let db = Firestore.firestore()
    private let collectionName = "chats"
    
    static let shared = BookChatRepository()
    
    private init() {}
    
    private func chatsCollection(userId: String, userBookId: String) -> CollectionReference {
        return db.collection("users").document(userId)
            .collection("userBooks").document(userBookId)
            .collection(collectionName)
    }
    
    func getChats(userId: String, userBookId: String, limit: Int = 50) async throws -> [BookChat] {
        let snapshot = try await chatsCollection(userId: userId, userBookId: userBookId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        let chats: [BookChat] = snapshot.documents.compactMap { document in
            guard let dto = try? document.data(as: BookChatDTO.self) else { return nil }
            return dto.toDomain(id: document.documentID)
        }
        
        return chats.reversed() // 時系列順に戻す
    }
    
    func addChat(_ chat: BookChat, userId: String) async throws -> BookChat {
        let dto = BookChatDTO(from: chat)
        let encoder = Firestore.Encoder()
        var data = try encoder.encode(dto)
        
        // サーバータイムスタンプを使用
        data["createdAt"] = FieldValue.serverTimestamp()
        
        // 新しいドキュメントを作成（IDは自動生成）
        let docRef = chatsCollection(userId: userId, userBookId: chat.userBookId).document()
        try await docRef.setData(data)
        
        // 作成されたドキュメントを取得して返す
        let document = try await docRef.getDocument()
        let createdDto = try document.data(as: BookChatDTO.self)
        return createdDto.toDomain(id: document.documentID)
    }
    
    func deleteChat(chatId: String, userId: String, userBookId: String) async throws {
        try await chatsCollection(userId: userId, userBookId: userBookId)
            .document(chatId)
            .delete()
    }
    
    func listenToChats(userId: String, userBookId: String, completion: @escaping (Result<[BookChat], Error>) -> Void) -> ListenerRegistration {
        return chatsCollection(userId: userId, userBookId: userBookId)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let chats: [BookChat] = documents.compactMap { document in
                    guard let dto = try? document.data(as: BookChatDTO.self) else { return nil }
                    return dto.toDomain(id: document.documentID)
                }
                completion(.success(chats.reversed()))
            }
    }
}
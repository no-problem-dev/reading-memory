import Foundation
import FirebaseFirestore
import FirebaseAuth

final class BookChatRepository: BaseRepository {
    typealias T = BookChat
    let collectionName = "chats"
    
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
        
        let chats = try snapshot.documents.compactMap { document in
            try documentToModel(document)
        }
        
        return chats.reversed()
    }
    
    func addChat(_ chat: BookChat, userId: String) async throws -> BookChat {
        let data = try modelToData(chat)
        try await chatsCollection(userId: userId, userBookId: chat.userBookId)
            .document(chat.id)
            .setData(data)
        return chat
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
                
                do {
                    let chats = try documents.compactMap { document in
                        try document.data(as: BookChat.self)
                    }
                    completion(.success(chats.reversed()))
                } catch {
                    completion(.failure(error))
                }
            }
    }
}
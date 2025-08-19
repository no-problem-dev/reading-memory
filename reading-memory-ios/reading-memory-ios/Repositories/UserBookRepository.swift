import Foundation
import FirebaseFirestore
import FirebaseAuth

final class UserBookRepository {
    private let db = Firestore.firestore()
    private let collectionName = "userBooks"
    
    static let shared = UserBookRepository()
    
    private init() {}
    
    private func userBooksCollection(for userId: String) -> CollectionReference {
        return db.collection("users").document(userId).collection(collectionName)
    }
    
    func getUserBook(userId: String, userBookId: String) async throws -> UserBook? {
        let document = try await userBooksCollection(for: userId).document(userBookId).getDocument()
        guard document.exists else { return nil }
        
        let dto = try document.data(as: UserBookDTO.self)
        return dto.toDomain(id: document.documentID)
    }
    
    func getUserBooks(for userId: String) async throws -> [UserBook] {
        let snapshot = try await userBooksCollection(for: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            guard let dto = try? document.data(as: UserBookDTO.self) else { return nil }
            return dto.toDomain(id: document.documentID)
        }
    }
    
    func getUserBooksByStatus(userId: String, status: ReadingStatus) async throws -> [UserBook] {
        let snapshot = try await userBooksCollection(for: userId)
            .whereField("status", isEqualTo: status.rawValue)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            guard let dto = try? document.data(as: UserBookDTO.self) else { return nil }
            return dto.toDomain(id: document.documentID)
        }
    }
    
    func createUserBook(_ userBook: UserBook) async throws -> UserBook {
        let dto = UserBookDTO(from: userBook)
        let encoder = Firestore.Encoder()
        var data = try encoder.encode(dto)
        
        // サーバータイムスタンプを使用
        data["createdAt"] = FieldValue.serverTimestamp()
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        // 新しいドキュメントを作成（IDは自動生成）
        let docRef = userBooksCollection(for: userBook.userId).document()
        try await docRef.setData(data)
        
        // 作成されたドキュメントを取得して返す
        let document = try await docRef.getDocument()
        let createdDto = try document.data(as: UserBookDTO.self)
        return createdDto.toDomain(id: document.documentID)!
    }
    
    func updateUserBook(_ userBook: UserBook) async throws {
        let dto = UserBookDTO(from: userBook)
        let encoder = Firestore.Encoder()
        var data = try encoder.encode(dto)
        
        // updatedAtのみサーバータイムスタンプで更新
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        try await userBooksCollection(for: userBook.userId).document(userBook.id).setData(data, merge: true)
    }
    
    func deleteUserBook(userId: String, userBookId: String) async throws {
        // 関連するチャットも削除
        let chatsCollection = userBooksCollection(for: userId).document(userBookId).collection("chats")
        let chats = try await chatsCollection.getDocuments()
        
        // バッチ削除
        let batch = db.batch()
        
        // チャットを削除
        for chat in chats.documents {
            batch.deleteDocument(chat.reference)
        }
        
        // UserBookを削除
        batch.deleteDocument(userBooksCollection(for: userId).document(userBookId))
        
        try await batch.commit()
    }
    
    func getUserBookByBookId(userId: String, bookId: String) async throws -> UserBook? {
        let snapshot = try await userBooksCollection(for: userId)
            .whereField("bookId", isEqualTo: bookId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        let dto = try document.data(as: UserBookDTO.self)
        return dto.toDomain(id: document.documentID)
    }
}
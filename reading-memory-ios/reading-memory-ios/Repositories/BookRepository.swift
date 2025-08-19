import Foundation
import FirebaseFirestore

final class BookRepository {
    private let db = Firestore.firestore()
    private let collectionName = "books"
    
    static let shared = BookRepository()
    
    private init() {}
    
    func getBook(by id: String) async throws -> Book? {
        let document = try await db.collection(collectionName).document(id).getDocument()
        guard document.exists else { return nil }
        
        let dto = try document.data(as: BookDTO.self)
        return dto.toDomain(id: document.documentID)
    }
    
    func getBookByISBN(_ isbn: String) async throws -> Book? {
        let snapshot = try await db.collection(collectionName)
            .whereField("isbn", isEqualTo: isbn)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        let dto = try document.data(as: BookDTO.self)
        return dto.toDomain(id: document.documentID)
    }
    
    func createBook(_ book: Book) async throws -> Book {
        let dto = BookDTO(from: book)
        let encoder = Firestore.Encoder()
        var data = try encoder.encode(dto)
        
        // サーバータイムスタンプを使用
        data["createdAt"] = FieldValue.serverTimestamp()
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        // 新しいドキュメントを作成（IDは自動生成）
        let docRef = db.collection(collectionName).document()
        try await docRef.setData(data)
        
        // 作成されたドキュメントを取得して返す
        let document = try await docRef.getDocument()
        let createdDto = try document.data(as: BookDTO.self)
        return createdDto.toDomain(id: document.documentID)
    }
    
    func createBookWithId(_ book: Book) async throws -> Book {
        let dto = BookDTO(from: book)
        let encoder = Firestore.Encoder()
        var data = try encoder.encode(dto)
        
        // サーバータイムスタンプを使用
        data["createdAt"] = FieldValue.serverTimestamp()
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        // 指定されたIDでドキュメントを作成
        try await db.collection(collectionName).document(book.id).setData(data)
        
        // 作成されたドキュメントを取得して返す
        let document = try await db.collection(collectionName).document(book.id).getDocument()
        let createdDto = try document.data(as: BookDTO.self)
        return createdDto.toDomain(id: document.documentID)
    }
    
    func updateBook(_ book: Book) async throws {
        let dto = BookDTO(from: book)
        let encoder = Firestore.Encoder()
        var data = try encoder.encode(dto)
        
        // updatedAtのみサーバータイムスタンプで更新
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        try await db.collection(collectionName).document(book.id).setData(data, merge: true)
    }
    
    func deleteBook(_ bookId: String) async throws {
        try await db.collection(collectionName).document(bookId).delete()
    }
    
    // MARK: - 検索機能（Cloud Functions経由）
    
    func searchPublicBooks(query: String, limit: Int = 20) async throws -> [Book] {
        // Cloud Functions経由で検索
        return try await CloudFunctionsService.shared.searchPublicBooks(query: query, limit: limit)
    }
    
    func getPopularBooks(limit: Int = 20) async throws -> [Book] {
        // Cloud Functions経由で取得
        return try await CloudFunctionsService.shared.getPopularBooks(limit: limit)
    }
    
    func getRecentlyAddedBooks(limit: Int = 20) async throws -> [Book] {
        // Cloud Functions経由で取得
        return try await CloudFunctionsService.shared.getRecentBooks(limit: limit)
    }
}
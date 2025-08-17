import Foundation
import FirebaseFirestore
import FirebaseAuth

final class UserBookRepository: BaseRepository {
    typealias T = UserBook
    let collectionName = "userBooks"
    
    static let shared = UserBookRepository()
    
    private init() {}
    
    private func userBooksCollection(for userId: String) -> CollectionReference {
        return db.collection("users").document(userId).collection(collectionName)
    }
    
    func getUserBook(userId: String, userBookId: String) async throws -> UserBook? {
        let document = try await userBooksCollection(for: userId).document(userBookId).getDocument()
        return try documentToModel(document)
    }
    
    func getUserBooks(for userId: String) async throws -> [UserBook] {
        let snapshot = try await userBooksCollection(for: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try documentToModel(document)
        }
    }
    
    func getUserBooksByStatus(userId: String, status: UserBook.ReadingStatus) async throws -> [UserBook] {
        let snapshot = try await userBooksCollection(for: userId)
            .whereField("status", isEqualTo: status.rawValue)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try documentToModel(document)
        }
    }
    
    func createUserBook(_ userBook: UserBook) async throws -> UserBook {
        let data = try modelToData(userBook)
        try await userBooksCollection(for: userBook.userId).document(userBook.id).setData(data)
        return userBook
    }
    
    func updateUserBook(_ userBook: UserBook) async throws {
        let updatedUserBook = UserBook(
            id: userBook.id,
            userId: userBook.userId,
            bookId: userBook.bookId,
            status: userBook.status,
            rating: userBook.rating,
            startDate: userBook.startDate,
            completedDate: userBook.completedDate,
            customCoverImageUrl: userBook.customCoverImageUrl,
            notes: userBook.notes,
            isPublic: userBook.isPublic,
            createdAt: userBook.createdAt,
            updatedAt: Date()
        )
        
        let data = try modelToData(updatedUserBook)
        try await userBooksCollection(for: userBook.userId).document(userBook.id).setData(data, merge: true)
    }
    
    func deleteUserBook(userId: String, userBookId: String) async throws {
        try await userBooksCollection(for: userId).document(userBookId).delete()
    }
    
    func getUserBookByBookId(userId: String, bookId: String) async throws -> UserBook? {
        let snapshot = try await userBooksCollection(for: userId)
            .whereField("bookId", isEqualTo: bookId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try documentToModel(document)
    }
}
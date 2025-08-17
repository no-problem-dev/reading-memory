import Foundation
import FirebaseFirestore

final class BookRepository: BaseRepository {
    typealias T = Book
    let collectionName = "books"
    
    static let shared = BookRepository()
    
    private init() {}
    
    func getBook(by id: String) async throws -> Book? {
        let document = try await db.collection(collectionName).document(id).getDocument()
        return try documentToModel(document)
    }
    
    func getBookByISBN(_ isbn: String) async throws -> Book? {
        let snapshot = try await db.collection(collectionName)
            .whereField("isbn", isEqualTo: isbn)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try documentToModel(document)
    }
    
    func createBook(_ book: Book) async throws -> Book {
        let data = try modelToData(book)
        try await db.collection(collectionName).document(book.id).setData(data)
        return book
    }
    
    func updateBook(_ book: Book) async throws {
        var updatedBook = book
        updatedBook = Book(
            id: book.id,
            isbn: book.isbn,
            title: book.title,
            author: book.author,
            publisher: book.publisher,
            publishedDate: book.publishedDate,
            pageCount: book.pageCount,
            description: book.description,
            coverImageUrl: book.coverImageUrl,
            createdAt: book.createdAt,
            updatedAt: Date()
        )
        
        let data = try modelToData(updatedBook)
        try await db.collection(collectionName).document(book.id).setData(data, merge: true)
    }
    
    func deleteBook(_ bookId: String) async throws {
        try await db.collection(collectionName).document(bookId).delete()
    }
}
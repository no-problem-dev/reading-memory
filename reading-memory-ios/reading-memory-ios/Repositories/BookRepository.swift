import Foundation

final class BookRepository {
    static let shared = BookRepository()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - CRUD Operations
    
    func getBook(bookId: String) async throws -> Book? {
        do {
            return try await apiClient.getBook(id: bookId)
        } catch {
            if let appError = error as? AppError,
               case .custom(let message) = appError,
               message.contains("404") {
                return nil
            }
            throw error
        }
    }
    
    func getBooks() async throws -> [Book] {
        return try await apiClient.getBooks()
    }
    
    func getBooksByStatus(status: ReadingStatus) async throws -> [Book] {
        let allBooks = try await getBooks()
        return allBooks.filter { $0.status == status }
    }
    
    func getBookByISBN(isbn: String) async throws -> Book? {
        let allBooks = try await getBooks()
        return allBooks.first { $0.isbn == isbn }
    }
    
    func createBook(_ book: Book) async throws -> Book {
        return try await apiClient.createBook(book)
    }
    
    func updateBook(_ book: Book) async throws {
        _ = try await apiClient.updateBook(book)
    }
    
    func deleteBook(bookId: String) async throws {
        try await apiClient.deleteBook(id: bookId)
    }
    
    // MARK: - Convenience Methods
    
    func deleteBook(_ bookId: String) async throws {
        try await deleteBook(bookId: bookId)
    }
    
    // 読みたいリスト関連
    func getWantToReadBooks() async throws -> [Book] {
        return try await getBooksByStatus(status: .wantToRead)
    }
    
    // 統計用
    func getCompletedBooksCount() async throws -> Int {
        let books = try await getBooksByStatus(status: .completed)
        return books.count
    }
    
    func getReadingBooksCount() async throws -> Int {
        let books = try await getBooksByStatus(status: .reading)
        return books.count
    }
}
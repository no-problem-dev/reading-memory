import Foundation

protocol UserBookRepositoryProtocol {
    func getUserBook(userId: String, userBookId: String) async throws -> UserBook?
    func getUserBooks(for userId: String) async throws -> [UserBook]
    func getUserBooksByStatus(userId: String, status: ReadingStatus) async throws -> [UserBook]
    func createUserBook(_ userBook: UserBook) async throws -> UserBook
    func updateUserBook(_ userBook: UserBook) async throws
    func deleteUserBook(_ userBookId: String) async throws
    func deleteUserBook(userId: String, userBookId: String) async throws
    func getUserBookByBookId(userId: String, bookId: String) async throws -> UserBook?
}
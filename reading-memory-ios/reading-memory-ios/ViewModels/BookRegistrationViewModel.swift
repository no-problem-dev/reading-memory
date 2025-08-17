import Foundation

@Observable
@MainActor
final class BookRegistrationViewModel: BaseViewModel {
    private let bookRepository = BookRepository.shared
    private let userBookRepository = UserBookRepository.shared
    private let authService = AuthService.shared
    
    func registerBook(_ book: Book) async -> Bool {
        var result = false
        await withLoadingNoThrow { [weak self] in
            guard let self = self,
                  let userId = self.authService.currentUser?.uid else {
                throw AppError.authenticationRequired
            }
            
            // 既に同じISBNの本が登録されているかチェック
            if let isbn = book.isbn, !isbn.isEmpty {
                if let existingBook = try await self.bookRepository.getBookByISBN(isbn) {
                    // 既存の本を使用してUserBookを作成
                    let userBook = UserBook(
                        userId: userId,
                        bookId: existingBook.id
                    )
                    _ = try await self.userBookRepository.createUserBook(userBook)
                    result = true
                    return
                }
            }
            
            // 新しい本を作成
            let createdBook = try await self.bookRepository.createBook(book)
            
            // UserBookを作成
            let userBook = UserBook(
                userId: userId,
                bookId: createdBook.id
            )
            _ = try await self.userBookRepository.createUserBook(userBook)
            
            result = true
        }
        return result
    }
}
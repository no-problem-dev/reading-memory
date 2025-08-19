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
            
            print("DEBUG: Registering book...")
            print("Book ID: \(book.id)")
            print("Title: \(book.title)")
            print("Author: \(book.author)")
            print("ISBN: \(book.isbn ?? "nil")")
            print("Data Source: \(book.dataSource.rawValue)")
            print("Visibility: \(book.visibility.rawValue)")
            print("User ID: \(userId)")
            
            let userBook: UserBook
            
            // データソースによって処理を分岐
            if book.dataSource == .manual {
                // 手動入力の本はuserBooksに直接保存
                let manualBookData = ManualBookData(from: book)
                userBook = UserBook.newManual(
                    userId: userId,
                    manualBookData: manualBookData,
                    status: .wantToRead
                )
            } else {
                // API経由の本はbooksコレクションに保存
                var bookToUse: Book
                if let isbn = book.isbn, !isbn.isEmpty {
                    if let existingBook = try await self.bookRepository.getBookByISBN(isbn) {
                        // 既存の本を使用
                        bookToUse = existingBook
                    } else {
                        // 新しい本を作成（API経由なので公開設定）
                        let publicBook = Book(
                            id: book.id,
                            isbn: book.isbn,
                            title: book.title,
                            author: book.author,
                            publisher: book.publisher,
                            publishedDate: book.publishedDate,
                            pageCount: book.pageCount,
                            description: book.description,
                            coverImageUrl: book.coverImageUrl,
                            dataSource: book.dataSource,
                            visibility: .public,  // API経由は常に公開
                            createdAt: book.createdAt,
                            updatedAt: book.updatedAt
                        )
                        bookToUse = try await self.bookRepository.createBook(publicBook)
                    }
                } else {
                    // ISBNがない場合も新しい本を作成
                    let publicBook = Book(
                        id: book.id,
                        isbn: book.isbn,
                        title: book.title,
                        author: book.author,
                        publisher: book.publisher,
                        publishedDate: book.publishedDate,
                        pageCount: book.pageCount,
                        description: book.description,
                        coverImageUrl: book.coverImageUrl,
                        dataSource: book.dataSource,
                        visibility: .public,  // API経由は常に公開
                        createdAt: book.createdAt,
                        updatedAt: book.updatedAt
                    )
                    bookToUse = try await self.bookRepository.createBook(publicBook)
                }
                
                // UserBookを作成（公開本への参照）
                userBook = UserBook.new(userId: userId, book: bookToUse)
            }
            
            // UserBookを保存
            _ = try await self.userBookRepository.createUserBook(userBook)
            
            result = true
        }
        return result
    }
}
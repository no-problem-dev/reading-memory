import Foundation

@Observable
@MainActor
final class BookRegistrationViewModel: BaseViewModel {
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    private let activityRepository = ActivityRepository.shared
    
    func registerBook(_ book: Book) async -> Bool {
        var result = false
        await withLoadingNoThrow { [weak self] in
            guard let self = self else {
                throw AppError.authenticationRequired
            }
            
            print("DEBUG: Registering book...")
            print("Book ID: \(book.id)")
            print("Title: \(book.title)")
            print("Author: \(book.author)")
            print("ISBN: \(book.isbn ?? "nil")")
            print("Data Source: \(book.dataSource.rawValue)")
            
            // 本を保存（すべてユーザーのbooksコレクションに保存）
            _ = try await self.bookRepository.createBook(book)
            
            // アクティビティを記録（読みたいリストに追加）
            if book.status == .wantToRead {
                try? await self.activityRepository.recordBookRead()
            }
            
            result = true
        }
        return result
    }
    
    func registerBookFromSearchResult(_ searchResult: BookSearchResult) async -> Bool {
        var result = false
        await withLoadingNoThrow { [weak self] in
            guard let self = self else {
                throw AppError.authenticationRequired
            }
            
            print("DEBUG: Registering book from search result...")
            print("Title: \(searchResult.title)")
            print("Author: \(searchResult.author)")
            print("ISBN: \(searchResult.isbn ?? "nil")")
            print("Cover Image URL: \(searchResult.coverImageUrl ?? "nil")")
            print("Data Source: \(searchResult.dataSource.rawValue)")
            
            // 検索結果から本を作成（画像のアップロードを含む）
            let createdBook = try await self.bookRepository.createBookFromSearchResult(searchResult)
            
            // アクティビティを記録（読みたいリストに追加）
            if createdBook.status == .wantToRead {
                try? await self.activityRepository.recordBookRead()
            }
            
            result = true
        }
        return result
    }
}
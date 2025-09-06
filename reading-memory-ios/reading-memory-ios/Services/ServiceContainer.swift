import Foundation
// TODO: Remove Firebase dependency
// import FirebaseFirestore

final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {}
    
    // Repositories
    private lazy var bookRepository = BookRepository.shared
    private lazy var bookChatRepository = BookChatRepository.shared
    private lazy var userProfileRepository = UserProfileRepository.shared
    
    // Stores - 環境オブジェクトとして使用
    @MainActor
    private lazy var bookStore = BookStore(
        bookRepository: bookRepository,
        authService: AuthService.shared
    )
    
    // ViewModels
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel()
    }
    
    @MainActor
    func makeBookListViewModel() -> BookListViewModel {
        return BookListViewModel()
    }
    
    @MainActor
    func makeBookDetailViewModel(book: Book) -> BookDetailViewModel {
        return BookDetailViewModel(book: book)
    }
    
    @MainActor
    func makeProfileViewModel() -> ProfileViewModel {
        return ProfileViewModel()
    }
    
    @MainActor
    func makeBookRegistrationViewModel() -> BookRegistrationViewModel {
        return BookRegistrationViewModel()
    }
    
    @MainActor
    func makeBookChatViewModel(book: Book) -> BookChatViewModel {
        return BookChatViewModel(book: book)
    }
    
    // Store accessors
    @MainActor
    func getBookStore() -> BookStore {
        return bookStore
    }
    
    // Repository accessors
    func getBookRepository() -> BookRepository {
        return bookRepository
    }
    
    func getBookChatRepository() -> BookChatRepository {
        return bookChatRepository
    }
    
    func getUserProfileRepository() -> UserProfileRepository {
        return userProfileRepository
    }
}

// MARK: - ViewModels (Placeholder for future implementation)
@MainActor
@Observable
class BookListViewModel: BaseViewModel {
    private let authService = AuthService.shared
    private let bookRepository = BookRepository.shared
    
    var books: [Book] = []
    
    func loadBooks() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            let booksList = try await self.bookRepository.getBooks()
            self.books = booksList.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}

@MainActor
@Observable
class BookDetailViewModel: BaseViewModel {
    private let authService = AuthService.shared
    private let bookRepository = BookRepository.shared
    private let bookChatRepository = BookChatRepository.shared
    
    var currentBook: Book
    
    init(book: Book) {
        self.currentBook = book
        super.init()
    }
    
    func updateBook(_ updatedBook: Book) {
        self.currentBook = updatedBook
    }
    
    func deleteBook() async -> Bool {
        var result = false
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            try await self.bookRepository.deleteBook(bookId: self.currentBook.id)
            result = true
        }
        return result
    }
}

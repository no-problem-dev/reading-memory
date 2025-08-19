import Foundation
import FirebaseFirestore

final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {}
    
    // Repositories
    private lazy var bookRepository = BookRepository.shared
    private lazy var userBookRepository = UserBookRepository.shared
    private lazy var bookChatRepository = BookChatRepository.shared
    private lazy var userProfileRepository = UserProfileRepository.shared
    
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
    func makeBookDetailViewModel(userBook: UserBook) -> BookDetailViewModel {
        return BookDetailViewModel(userBook: userBook)
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
    func makeBookChatViewModel(userBook: UserBook) -> BookChatViewModel {
        return BookChatViewModel(userBook: userBook)
    }
    
    // Repository accessors
    func getBookRepository() -> BookRepository {
        return bookRepository
    }
    
    func getUserBookRepository() -> UserBookRepository {
        return userBookRepository
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
    private let userBookRepository = UserBookRepository.shared
    
    var userBooks: [(userBook: UserBook, book: Book)] = []
    
    func loadUserBooks() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self,
                  let userId = self.authService.currentUser?.uid else {
                throw AppError.authenticationRequired
            }
            
            let userBooksList = try await self.userBookRepository.getUserBooks(for: userId)
            var booksData: [(UserBook, Book)] = []
            
            for userBook in userBooksList {
                if let bookId = userBook.bookId,
                   let book = try await self.bookRepository.getBook(by: bookId) {
                    booksData.append((userBook, book))
                }
            }
            
            self.userBooks = booksData.sorted { $0.0.updatedAt > $1.0.updatedAt }
        }
    }
}

@MainActor
@Observable
class BookDetailViewModel: BaseViewModel {
    private let authService = AuthService.shared
    private let userBookRepository = UserBookRepository.shared
    private let bookChatRepository = BookChatRepository.shared
    
    var currentUserBook: UserBook
    
    init(userBook: UserBook) {
        self.currentUserBook = userBook
        super.init()
    }
    
    func updateUserBook(_ updatedUserBook: UserBook) {
        self.currentUserBook = updatedUserBook
    }
    
    func deleteUserBook() async -> Bool {
        var result = false
        await withLoadingNoThrow { [weak self] in
            guard let self = self,
                  let userId = self.authService.currentUser?.uid else {
                throw AppError.authenticationRequired
            }
            
            try await self.userBookRepository.deleteUserBook(userId: userId, userBookId: self.currentUserBook.id)
            result = true
        }
        return result
    }
}

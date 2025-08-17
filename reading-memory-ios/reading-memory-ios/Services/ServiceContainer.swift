import Foundation
import FirebaseFirestore

@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {}
    
    // MARK: - Repositories
    lazy var bookRepository = BookRepository.shared
    lazy var userBookRepository = UserBookRepository.shared
    lazy var bookChatRepository = BookChatRepository.shared
    lazy var userProfileRepository = UserProfileRepository.shared
    
    // MARK: - ViewModels
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel()
    }
    
    func makeBookListViewModel() -> BookListViewModel {
        return BookListViewModel(
            bookRepository: bookRepository,
            userBookRepository: userBookRepository
        )
    }
    
    func makeBookDetailViewModel(userBookId: String) -> BookDetailViewModel {
        return BookDetailViewModel(
            userBookId: userBookId,
            userBookRepository: userBookRepository,
            bookChatRepository: bookChatRepository
        )
    }
    
    func makeProfileViewModel(userId: String) -> ProfileViewModel {
        return ProfileViewModel(
            userId: userId,
            userProfileRepository: userProfileRepository
        )
    }
}

// MARK: - ViewModels (Placeholder for future implementation)
@MainActor
@Observable
class BookListViewModel: BaseViewModel {
    private let bookRepository: BookRepository
    private let userBookRepository: UserBookRepository
    
    var userBooks: [UserBook] = []
    
    init(bookRepository: BookRepository, userBookRepository: UserBookRepository) {
        self.bookRepository = bookRepository
        self.userBookRepository = userBookRepository
        super.init()
    }
}

@MainActor
@Observable
class BookDetailViewModel: BaseViewModel {
    private let userBookId: String
    private let userBookRepository: UserBookRepository
    private let bookChatRepository: BookChatRepository
    
    var userBook: UserBook?
    var chats: [BookChat] = []
    
    init(userBookId: String, userBookRepository: UserBookRepository, bookChatRepository: BookChatRepository) {
        self.userBookId = userBookId
        self.userBookRepository = userBookRepository
        self.bookChatRepository = bookChatRepository
        super.init()
    }
}

@MainActor
@Observable
class ProfileViewModel: BaseViewModel {
    private let userId: String
    private let userProfileRepository: UserProfileRepository
    
    var userProfile: UserProfile?
    
    init(userId: String, userProfileRepository: UserProfileRepository) {
        self.userId = userId
        self.userProfileRepository = userProfileRepository
        super.init()
    }
}
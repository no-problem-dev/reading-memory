import Foundation
import FirebaseFirestore

@Observable
class BookShelfViewModel: BaseViewModel {
    private let userBookRepository: UserBookRepository
    private let bookRepository: BookRepository
    private let authService = AuthService.shared
    
    private(set) var allBooks: [UserBook] = []
    private(set) var filteredBooks: [UserBook] = []
    private var currentFilter: UserBook.ReadingStatus? = nil
    private var currentSort: BookShelfView.SortOption = .dateAdded
    
    override init() {
        self.userBookRepository = ServiceContainer.shared.getUserBookRepository()
        self.bookRepository = ServiceContainer.shared.getBookRepository()
        super.init()
    }
    
    @MainActor
    func loadBooks() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self,
                  let userId = self.authService.currentUser?.uid else {
                throw AppError.authenticationRequired
            }
            
            var userBooks = try await self.userBookRepository.getUserBooks(for: userId)
            
            // Fetch all associated books
            for i in 0..<userBooks.count {
                if let book = try await self.bookRepository.getBook(by: userBooks[i].bookId) {
                    userBooks[i] = UserBook(
                        id: userBooks[i].id,
                        userId: userBooks[i].userId,
                        bookId: userBooks[i].bookId,
                        book: book,
                        status: userBooks[i].status,
                        rating: userBooks[i].rating,
                        startDate: userBooks[i].startDate,
                        completedDate: userBooks[i].completedDate,
                        customCoverImageUrl: userBooks[i].customCoverImageUrl,
                        notes: userBooks[i].notes,
                        isPublic: userBooks[i].isPublic,
                        createdAt: userBooks[i].createdAt,
                        updatedAt: userBooks[i].updatedAt
                    )
                }
            }
            
            self.allBooks = userBooks.filter { $0.book != nil }
            self.applyFilterAndSort()
        }
    }
    
    func filterBooks(by status: UserBook.ReadingStatus?) {
        currentFilter = status
        applyFilterAndSort()
    }
    
    func sortBooks(by option: BookShelfView.SortOption) {
        currentSort = option
        applyFilterAndSort()
    }
    
    private func applyFilterAndSort() {
        // Apply filter
        var books = allBooks
        if let filter = currentFilter {
            books = books.filter { $0.status == filter }
        }
        
        // Apply sort
        switch currentSort {
        case .dateAdded:
            books.sort { $0.createdAt > $1.createdAt }
        case .title:
            books.sort { ($0.book?.title ?? "").localizedCompare($1.book?.title ?? "") == .orderedAscending }
        case .author:
            books.sort { ($0.book?.author ?? "").localizedCompare($1.book?.author ?? "") == .orderedAscending }
        case .rating:
            books.sort { 
                let rating0 = $0.rating ?? 0
                let rating1 = $1.rating ?? 0
                return rating0 > rating1
            }
        }
        
        filteredBooks = books
    }
}
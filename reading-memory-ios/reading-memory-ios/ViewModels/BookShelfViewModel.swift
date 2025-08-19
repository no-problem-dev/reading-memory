import Foundation
import FirebaseFirestore

@Observable
class BookShelfViewModel: BaseViewModel {
    private let userBookRepository: UserBookRepository
    private let bookRepository: BookRepository
    private let authService = AuthService.shared
    
    private(set) var allBooks: [UserBook] = []
    private(set) var filteredBooks: [UserBook] = []
    private var currentFilter: ReadingStatus? = nil
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
            
            let userBooks = try await self.userBookRepository.getUserBooks(for: userId)
            
            self.allBooks = userBooks
            self.applyFilterAndSort()
        }
    }
    
    func filterBooks(by status: ReadingStatus?) {
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
            books.sort { $0.bookTitle.localizedCompare($1.bookTitle) == .orderedAscending }
        case .author:
            books.sort { $0.bookAuthor.localizedCompare($1.bookAuthor) == .orderedAscending }
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
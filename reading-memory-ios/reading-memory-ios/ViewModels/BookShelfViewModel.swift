import Foundation
// TODO: Remove Firebase dependency
// import FirebaseFirestore

@Observable
class BookShelfViewModel: BaseViewModel {
    private let bookRepository: BookRepository
    private let authService = AuthService.shared
    
    private(set) var allBooks: [Book] = []
    private(set) var filteredBooks: [Book] = []
    private var currentFilter: ReadingStatus? = nil
    private var currentSort: BookShelfView.SortOption = .dateAdded
    
    override init() {
        self.bookRepository = ServiceContainer.shared.getBookRepository()
        super.init()
    }
    
    @MainActor
    func loadBooks() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            let books = try await self.bookRepository.getBooks()
            
            self.allBooks = books
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
            books.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:
            books.sort { $0.author.localizedCompare($1.author) == .orderedAscending }
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
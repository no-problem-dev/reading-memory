import Foundation
// TODO: Remove Firebase dependency
// import FirebaseFirestore

@Observable
class BookShelfViewModel: BaseViewModel {
    enum BookFilter: String, CaseIterable {
        case all = "すべて"
        case reading = "読書中"
        case completed = "読了"
        case dnf = "積読"
        case wantToRead = "読みたい"
        
        var status: ReadingStatus? {
            switch self {
            case .all:
                return nil
            case .reading:
                return .reading
            case .completed:
                return .completed
            case .dnf:
                return .dnf
            case .wantToRead:
                return .wantToRead
            }
        }
    }
    
    enum DisplayMode {
        case grid
        case list
    }
    
    private let bookRepository: BookRepository
    private let authService = AuthService.shared
    
    private(set) var allBooks: [Book] = []
    private(set) var filteredBooks: [Book] = []
    var currentFilter: BookFilter = .all
    var displayMode: DisplayMode = .grid
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
    
    func setFilter(_ filter: BookFilter) {
        currentFilter = filter
        applyFilterAndSort()
    }
    
    func setDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
    }
    
    func sortBooks(by option: BookShelfView.SortOption) {
        currentSort = option
        applyFilterAndSort()
    }
    
    private func applyFilterAndSort() {
        // Apply filter
        var books = allBooks
        if let status = currentFilter.status {
            books = books.filter { $0.status == status }
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
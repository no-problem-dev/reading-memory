import Foundation

@Observable
@MainActor
final class PublicBookshelfViewModel: BaseViewModel {
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    
    // 人気の本
    var popularBooks: [Book] = []
    
    // 新着の本
    var recentBooks: [Book] = []
    
    // 検索結果
    var searchResults: [Book] = []
    var isSearching = false
    
    func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadPopularBooks() }
            group.addTask { await self.loadRecentBooks() }
        }
    }
    
    func loadPopularBooks() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            do {
                self.popularBooks = try await self.bookRepository.getPopularBooks(limit: 30)
            } catch {
                self.handleError(error)
                self.popularBooks = []
            }
        }
    }
    
    func loadRecentBooks() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            do {
                self.recentBooks = try await self.bookRepository.getRecentlyAddedBooks(limit: 30)
            } catch {
                self.handleError(error)
                self.recentBooks = []
            }
        }
    }
    
    func searchPublicBooks(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            do {
                self.searchResults = try await self.bookRepository.searchPublicBooks(query: query, limit: 50)
            } catch {
                self.handleError(error)
                self.searchResults = []
            }
        }
        
        isSearching = false
    }
    
    func refreshData() async {
        await loadInitialData()
    }
}
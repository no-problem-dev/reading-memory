import Foundation

@Observable
@MainActor
final class BookRegistrationViewModel: BaseViewModel {
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    private let activityRepository = ActivityRepository.shared
    
    private(set) var monthlyBookCount = 0
    private(set) var canAddBook = true
    var showPaywall = false
    
    override init() {
        super.init()
        Task {
            await checkBookQuota()
        }
    }
    
    func checkBookQuota() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        // 今月の本登録数を取得
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        monthlyBookCount = await bookRepository.getBookCount(userId: userId, since: startOfMonth)
        
        // プレミアムチェック
        canAddBook = FeatureGate.canAddBook(currentMonthlyCount: monthlyBookCount)
    }
    
    func registerBook(_ book: Book) async -> Bool {
        // まず制限チェック
        await checkBookQuota()
        
        guard canAddBook else {
            showPaywall = true
            return false
        }
        
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
            
            // 登録後にカウントを更新
            await self.checkBookQuota()
            
            result = true
        }
        return result
    }
    
    func registerBookFromSearchResult(_ searchResult: BookSearchResult) async -> Bool {
        // まず制限チェック
        await checkBookQuota()
        
        guard canAddBook else {
            showPaywall = true
            return false
        }
        
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
            
            // 登録後にカウントを更新
            await self.checkBookQuota()
            
            result = true
        }
        return result
    }
}
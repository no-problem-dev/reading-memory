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
    
    // 環境オブジェクト用のプロパティ
    private var subscriptionStateStore: SubscriptionStateStore?
    
    // 処理中のISBNを記録して二重登録を防ぐ
    private var processingISBNs = Set<String>()
    
    override init() {
        super.init()
        Task {
            await checkBookQuota()
        }
    }
    
    func setSubscriptionStateStore(_ store: SubscriptionStateStore) {
        self.subscriptionStateStore = store
        Task {
            await checkBookQuota()
        }
    }
    
    func checkBookQuota() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        // 今月の本登録数を取得
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        monthlyBookCount = await bookRepository.getBookCount(userId: userId, since: startOfMonth)
        
        // 環境オブジェクトから購読状態を確認
        if let subscriptionStateStore = subscriptionStateStore {
            canAddBook = subscriptionStateStore.canAddBook()
        } else {
            // フォールバック（本来は起こらないはず）
            canAddBook = monthlyBookCount < 3
        }
    }
    
    func registerBook(_ book: Book) async -> (success: Bool, book: Book?) {
        // まず制限チェック
        await checkBookQuota()
        
        guard canAddBook else {
            showPaywall = true
            return (false, nil)
        }
        
        var result = false
        var createdBook: Book?
        
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
            createdBook = try await self.bookRepository.createBook(book)
            
            // アクティビティを記録（読みたいリストに追加）
            if book.status == .wantToRead {
                try? await self.activityRepository.recordBookRead()
            }
            
            // 登録後にカウントを更新
            await self.checkBookQuota()
            
            result = true
        }
        return (result, createdBook)
    }
    
    func registerBookFromSearchResult(_ searchResult: BookSearchResult, status: ReadingStatus = .wantToRead) async -> (success: Bool, book: Book?) {
        // ISBNがある場合は二重登録チェック
        if let isbn = searchResult.isbn {
            if processingISBNs.contains(isbn) {
                print("DEBUG: Already processing ISBN: \(isbn)")
                return (false, nil)
            }
            processingISBNs.insert(isbn)
        }
        
        // まず制限チェック
        await checkBookQuota()
        
        guard canAddBook else {
            showPaywall = true
            if let isbn = searchResult.isbn {
                processingISBNs.remove(isbn)
            }
            return (false, nil)
        }
        
        var result = false
        var createdBook: Book?
        
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
            createdBook = try await self.bookRepository.createBookFromSearchResult(searchResult, status: status)
            
            // アクティビティを記録（読みたいリストに追加）
            if createdBook?.status == .wantToRead {
                try? await self.activityRepository.recordBookRead()
            }
            
            // 登録後にカウントを更新
            await self.checkBookQuota()
            
            result = true
        }
        
        // 処理完了後はISBNを削除
        if let isbn = searchResult.isbn {
            processingISBNs.remove(isbn)
        }
        
        return (result, createdBook)
    }
}
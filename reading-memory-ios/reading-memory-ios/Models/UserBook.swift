import Foundation

// ユーザーの読書情報（個人データ）
// ドメインモデル - 外部依存なし
struct UserBook: Identifiable, Equatable {
    let id: String
    let userId: String
    let bookId: String?  // 公開本の場合のみ
    let manualBookData: ManualBookData?  // 手動入力本の場合のみ
    
    // 非正規化データ（検索・表示の高速化のため）
    let bookTitle: String
    let bookAuthor: String
    let bookCoverImageUrl: String?
    let bookIsbn: String?
    
    // ユーザー個別データ
    var status: ReadingStatus
    var rating: Double? // 0.5〜5.0（0.5刻み）
    var readingProgress: Double? // 0.0〜1.0
    var currentPage: Int?
    var startDate: Date?
    var completedDate: Date?
    var memo: String?
    var tags: [String]
    var isPrivate: Bool
    
    // AI関連
    var aiSummary: String?
    var summaryGeneratedAt: Date?
    
    // 読みたいリスト関連
    var priority: Int? // 0が最高優先度、nilの場合は優先度なし
    var plannedReadingDate: Date? // 読書予定日
    var reminderEnabled: Bool // リマインダー有効化
    var purchaseLinks: [PurchaseLink]? // 購入リンク
    var addedToWantListDate: Date? // リスト追加日
    
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String,
        userId: String,
        bookId: String? = nil,
        manualBookData: ManualBookData? = nil,
        bookTitle: String,
        bookAuthor: String,
        bookCoverImageUrl: String? = nil,
        bookIsbn: String? = nil,
        status: ReadingStatus = .wantToRead,
        rating: Double? = nil,
        readingProgress: Double? = nil,
        currentPage: Int? = nil,
        startDate: Date? = nil,
        completedDate: Date? = nil,
        memo: String? = nil,
        tags: [String] = [],
        isPrivate: Bool = false,
        aiSummary: String? = nil,
        summaryGeneratedAt: Date? = nil,
        priority: Int? = nil,
        plannedReadingDate: Date? = nil,
        reminderEnabled: Bool = false,
        purchaseLinks: [PurchaseLink]? = nil,
        addedToWantListDate: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.bookId = bookId
        self.manualBookData = manualBookData
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.bookCoverImageUrl = bookCoverImageUrl
        self.bookIsbn = bookIsbn
        self.status = status
        self.rating = rating
        self.readingProgress = readingProgress
        self.currentPage = currentPage
        self.startDate = startDate
        self.completedDate = completedDate
        self.memo = memo
        self.tags = tags
        self.isPrivate = isPrivate
        self.aiSummary = aiSummary
        self.summaryGeneratedAt = summaryGeneratedAt
        self.priority = priority
        self.plannedReadingDate = plannedReadingDate
        self.reminderEnabled = reminderEnabled
        self.purchaseLinks = purchaseLinks
        self.addedToWantListDate = addedToWantListDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 新規作成用のファクトリメソッド（公開本を参照する場合）
    static func new(
        userId: String,
        book: Book,
        status: ReadingStatus = .wantToRead
    ) -> UserBook {
        let now = Date()
        return UserBook(
            id: UUID().uuidString,
            userId: userId,
            bookId: book.id,
            manualBookData: nil,
            bookTitle: book.title,
            bookAuthor: book.author,
            bookCoverImageUrl: book.coverImageUrl,
            bookIsbn: book.isbn,
            status: status,
            rating: nil,
            readingProgress: nil,
            currentPage: nil,
            startDate: nil,
            completedDate: nil,
            memo: nil,
            tags: [],
            isPrivate: false,
            addedToWantListDate: status == .wantToRead ? now : nil,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // 新規作成用のファクトリメソッド（手動入力本の場合）
    static func newManual(
        userId: String,
        manualBookData: ManualBookData,
        status: ReadingStatus = .wantToRead
    ) -> UserBook {
        let now = Date()
        return UserBook(
            id: UUID().uuidString,
            userId: userId,
            bookId: nil,
            manualBookData: manualBookData,
            bookTitle: manualBookData.title,
            bookAuthor: manualBookData.author,
            bookCoverImageUrl: manualBookData.coverImageUrl,
            bookIsbn: manualBookData.isbn,
            status: status,
            rating: nil,
            readingProgress: nil,
            currentPage: nil,
            startDate: nil,
            completedDate: nil,
            memo: nil,
            tags: [],
            isPrivate: false,
            addedToWantListDate: status == .wantToRead ? now : nil,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // 更新用のメソッド
    func updated(
        status: ReadingStatus? = nil,
        rating: Double? = nil,
        readingProgress: Double? = nil,
        currentPage: Int? = nil,
        startDate: Date? = nil,
        completedDate: Date? = nil,
        memo: String? = nil,
        tags: [String]? = nil,
        isPrivate: Bool? = nil,
        aiSummary: String? = nil,
        summaryGeneratedAt: Date? = nil,
        priority: Int?? = nil,
        plannedReadingDate: Date?? = nil,
        reminderEnabled: Bool? = nil,
        purchaseLinks: [PurchaseLink]?? = nil
    ) -> UserBook {
        let newStatus = status ?? self.status
        let now = Date()
        
        return UserBook(
            id: self.id,
            userId: self.userId,
            bookId: self.bookId,
            manualBookData: self.manualBookData,
            bookTitle: self.bookTitle,
            bookAuthor: self.bookAuthor,
            bookCoverImageUrl: self.bookCoverImageUrl,
            bookIsbn: self.bookIsbn,
            status: newStatus,
            rating: rating ?? self.rating,
            readingProgress: readingProgress ?? self.readingProgress,
            currentPage: currentPage ?? self.currentPage,
            startDate: startDate ?? self.startDate,
            completedDate: completedDate ?? self.completedDate,
            memo: memo ?? self.memo,
            tags: tags ?? self.tags,
            isPrivate: isPrivate ?? self.isPrivate,
            aiSummary: aiSummary ?? self.aiSummary,
            summaryGeneratedAt: summaryGeneratedAt ?? self.summaryGeneratedAt,
            priority: priority ?? self.priority,
            plannedReadingDate: plannedReadingDate ?? self.plannedReadingDate,
            reminderEnabled: reminderEnabled ?? self.reminderEnabled,
            purchaseLinks: purchaseLinks ?? self.purchaseLinks,
            addedToWantListDate: self.addedToWantListDate ?? (newStatus == .wantToRead && self.status != .wantToRead ? now : nil),
            createdAt: self.createdAt,
            updatedAt: now
        )
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case wantToRead = "want_to_read"
    case reading = "reading"
    case completed = "completed"
    case dnf = "dnf" // Did Not Finish
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .wantToRead:
            return "読みたい"
        case .reading:
            return "読書中"
        case .completed:
            return "読み終えた"
        case .dnf:
            return "積読"
        }
    }
    
    var icon: String {
        switch self {
        case .wantToRead:
            return "bookmark"
        case .reading:
            return "book"
        case .completed:
            return "checkmark.circle"
        case .dnf:
            return "xmark.circle"
        }
    }
}
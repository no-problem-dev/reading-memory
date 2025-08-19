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
        isPrivate: Bool? = nil
    ) -> UserBook {
        return UserBook(
            id: self.id,
            userId: self.userId,
            bookId: self.bookId,
            manualBookData: self.manualBookData,
            bookTitle: self.bookTitle,
            bookAuthor: self.bookAuthor,
            bookCoverImageUrl: self.bookCoverImageUrl,
            bookIsbn: self.bookIsbn,
            status: status ?? self.status,
            rating: rating ?? self.rating,
            readingProgress: readingProgress ?? self.readingProgress,
            currentPage: currentPage ?? self.currentPage,
            startDate: startDate ?? self.startDate,
            completedDate: completedDate ?? self.completedDate,
            memo: memo ?? self.memo,
            tags: tags ?? self.tags,
            isPrivate: isPrivate ?? self.isPrivate,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }
}

enum ReadingStatus: String, Codable, CaseIterable {
    case wantToRead = "want_to_read"
    case reading = "reading"
    case completed = "completed"
    case dnf = "dnf" // Did Not Finish
    
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
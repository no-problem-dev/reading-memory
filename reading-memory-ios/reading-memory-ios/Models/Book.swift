import Foundation

struct Book: Identifiable, Equatable, Hashable, Codable {
    // 識別子
    let id: String
    
    // 書籍基本情報
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: Date?
    let pageCount: Int?
    let description: String?
    let coverImageId: String?
    let dataSource: BookDataSource
    
    // 読書ステータス
    let status: ReadingStatus
    let rating: Double?
    let readingProgress: Double?
    let currentPage: Int?
    
    // 日付
    let addedDate: Date
    let startDate: Date?
    let completedDate: Date?
    let lastReadDate: Date?
    
    // 読みたいリスト
    let priority: Int?
    let plannedReadingDate: Date?
    let reminderEnabled: Bool
    let purchaseLinks: [PurchaseLink]?
    
    // メモとタグ
    let memo: String?
    let tags: [String]
    
    // AI要約
    let aiSummary: String?
    let summaryGeneratedAt: Date?
    
    // メタデータ
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String,
        isbn: String? = nil,
        title: String,
        author: String,
        publisher: String? = nil,
        publishedDate: Date? = nil,
        pageCount: Int? = nil,
        description: String? = nil,
        coverImageId: String? = nil,
        dataSource: BookDataSource,
        status: ReadingStatus,
        rating: Double? = nil,
        readingProgress: Double? = nil,
        currentPage: Int? = nil,
        addedDate: Date,
        startDate: Date? = nil,
        completedDate: Date? = nil,
        lastReadDate: Date? = nil,
        priority: Int? = nil,
        plannedReadingDate: Date? = nil,
        reminderEnabled: Bool = false,
        purchaseLinks: [PurchaseLink]? = nil,
        memo: String? = nil,
        tags: [String] = [],
        aiSummary: String? = nil,
        summaryGeneratedAt: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.pageCount = pageCount
        self.description = description
        self.coverImageId = coverImageId
        self.dataSource = dataSource
        self.status = status
        self.rating = rating
        self.readingProgress = readingProgress
        self.currentPage = currentPage
        self.addedDate = addedDate
        self.startDate = startDate
        self.completedDate = completedDate
        self.lastReadDate = lastReadDate
        self.priority = priority
        self.plannedReadingDate = plannedReadingDate
        self.reminderEnabled = reminderEnabled
        self.purchaseLinks = purchaseLinks
        self.memo = memo
        self.tags = tags
        self.aiSummary = aiSummary
        self.summaryGeneratedAt = summaryGeneratedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 新規作成用ファクトリメソッド
    static func new(
        isbn: String? = nil,
        title: String,
        author: String,
        publisher: String? = nil,
        publishedDate: Date? = nil,
        pageCount: Int? = nil,
        description: String? = nil,
        coverImageId: String? = nil,
        dataSource: BookDataSource,
        status: ReadingStatus = .wantToRead
    ) -> Book {
        let now = Date()
        return Book(
            id: UUID().uuidString,
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedDate: publishedDate,
            pageCount: pageCount,
            description: description,
            coverImageId: coverImageId,
            dataSource: dataSource,
            status: status,
            addedDate: now,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // 更新用メソッド
    func updated(
        status: ReadingStatus? = nil,
        rating: Double? = nil,
        readingProgress: Double? = nil,
        currentPage: Int? = nil,
        startDate: Date? = nil,
        completedDate: Date? = nil,
        priority: Int? = nil,
        plannedReadingDate: Date? = nil,
        reminderEnabled: Bool? = nil,
        purchaseLinks: [PurchaseLink]? = nil,
        memo: String? = nil,
        tags: [String]? = nil,
        aiSummary: String? = nil,
        summaryGeneratedAt: Date? = nil
    ) -> Book {
        return Book(
            id: self.id,
            isbn: self.isbn,
            title: self.title,
            author: self.author,
            publisher: self.publisher,
            publishedDate: self.publishedDate,
            pageCount: self.pageCount,
            description: self.description,
            coverImageId: self.coverImageId,
            dataSource: self.dataSource,
            status: status ?? self.status,
            rating: rating ?? self.rating,
            readingProgress: readingProgress ?? self.readingProgress,
            currentPage: currentPage ?? self.currentPage,
            addedDate: self.addedDate,
            startDate: startDate ?? self.startDate,
            completedDate: completedDate ?? self.completedDate,
            lastReadDate: Date(),
            priority: priority ?? self.priority,
            plannedReadingDate: plannedReadingDate ?? self.plannedReadingDate,
            reminderEnabled: reminderEnabled ?? self.reminderEnabled,
            purchaseLinks: purchaseLinks ?? self.purchaseLinks,
            memo: memo ?? self.memo,
            tags: tags ?? self.tags,
            aiSummary: aiSummary ?? self.aiSummary,
            summaryGeneratedAt: summaryGeneratedAt ?? self.summaryGeneratedAt,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }
    
    // 値を明示的に設定・クリアできる更新メソッド
    enum UpdateValue<T> {
        case set(T)
        case clear
        case keep
    }
    
    func updatedWithClear(
        status: ReadingStatus? = nil,
        rating: UpdateValue<Double> = .keep,
        readingProgress: UpdateValue<Double> = .keep,
        currentPage: UpdateValue<Int> = .keep,
        startDate: UpdateValue<Date> = .keep,
        completedDate: UpdateValue<Date> = .keep,
        priority: UpdateValue<Int> = .keep,
        plannedReadingDate: UpdateValue<Date> = .keep,
        reminderEnabled: Bool? = nil,
        purchaseLinks: UpdateValue<[PurchaseLink]> = .keep,
        memo: UpdateValue<String> = .keep,
        tags: UpdateValue<[String]> = .keep,
        aiSummary: UpdateValue<String> = .keep,
        summaryGeneratedAt: UpdateValue<Date> = .keep
    ) -> Book {
        return Book(
            id: self.id,
            isbn: self.isbn,
            title: self.title,
            author: self.author,
            publisher: self.publisher,
            publishedDate: self.publishedDate,
            pageCount: self.pageCount,
            description: self.description,
            coverImageId: self.coverImageId,
            dataSource: self.dataSource,
            status: status ?? self.status,
            rating: {
                switch rating {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.rating
                }
            }(),
            readingProgress: {
                switch readingProgress {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.readingProgress
                }
            }(),
            currentPage: {
                switch currentPage {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.currentPage
                }
            }(),
            addedDate: self.addedDate,
            startDate: {
                switch startDate {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.startDate
                }
            }(),
            completedDate: {
                switch completedDate {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.completedDate
                }
            }(),
            lastReadDate: Date(),
            priority: {
                switch priority {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.priority
                }
            }(),
            plannedReadingDate: {
                switch plannedReadingDate {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.plannedReadingDate
                }
            }(),
            reminderEnabled: reminderEnabled ?? self.reminderEnabled,
            purchaseLinks: {
                switch purchaseLinks {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.purchaseLinks
                }
            }(),
            memo: {
                switch memo {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.memo
                }
            }(),
            tags: {
                switch tags {
                case .set(let value): return value
                case .clear: return []
                case .keep: return self.tags
                }
            }(),
            aiSummary: {
                switch aiSummary {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.aiSummary
                }
            }(),
            summaryGeneratedAt: {
                switch summaryGeneratedAt {
                case .set(let value): return value
                case .clear: return nil
                case .keep: return self.summaryGeneratedAt
                }
            }(),
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Computed Properties
extension Book {
    var displayTitle: String {
        title.isEmpty ? "無題の本" : title
    }
    
    var displayAuthor: String {
        author.isEmpty ? "著者不明" : author
    }
    
    var progressPercentage: Int {
        Int(readingProgress ?? 0)
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var isReading: Bool {
        status == .reading
    }
    
    var isWantToRead: Bool {
        status == .wantToRead
    }
    
    var isDNF: Bool {
        status == .dnf
    }
    
    var hasRating: Bool {
        rating != nil && rating! > 0
    }
    
    var formattedRating: String {
        guard let rating = rating else { return "未評価" }
        return String(format: "%.1f", rating)
    }
}
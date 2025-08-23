import Foundation

struct BookDTO: Codable {
    let id: String?
    // 書籍基本情報
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: Date?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    let dataSource: String
    
    // 読書ステータス
    let status: String
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
    let purchaseLinks: [PurchaseLinkDTO]?
    
    // メモとタグ
    let memo: String?
    let tags: [String]
    
    // AI要約
    let aiSummary: String?
    let summaryGeneratedAt: Date?
    
    // メタデータ
    let createdAt: Date
    let updatedAt: Date
    
    init(from book: Book) {
        self.id = book.id
        self.isbn = book.isbn
        self.title = book.title
        self.author = book.author
        self.publisher = book.publisher
        self.publishedDate = book.publishedDate
        self.pageCount = book.pageCount
        self.description = book.description
        self.coverImageUrl = book.coverImageUrl
        self.dataSource = book.dataSource.rawValue
        self.status = book.status.rawValue
        self.rating = book.rating
        self.readingProgress = book.readingProgress
        self.currentPage = book.currentPage
        self.addedDate = book.addedDate
        self.startDate = book.startDate
        self.completedDate = book.completedDate
        self.lastReadDate = book.lastReadDate
        self.priority = book.priority
        self.plannedReadingDate = book.plannedReadingDate
        self.reminderEnabled = book.reminderEnabled
        self.purchaseLinks = book.purchaseLinks?.map { PurchaseLinkDTO(from: $0) }
        self.memo = book.memo
        self.tags = book.tags
        self.aiSummary = book.aiSummary
        self.summaryGeneratedAt = book.summaryGeneratedAt
        self.createdAt = book.createdAt
        self.updatedAt = book.updatedAt
    }
    
    func toDomain() -> Book {
        let bookStatus = ReadingStatus(rawValue: status) ?? .wantToRead
        
        return Book(
            id: id ?? UUID().uuidString,
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedDate: publishedDate,
            pageCount: pageCount,
            description: description,
            coverImageUrl: coverImageUrl,
            dataSource: BookDataSource(rawValue: dataSource) ?? .manual,
            status: bookStatus,
            rating: rating,
            readingProgress: readingProgress,
            currentPage: currentPage,
            addedDate: addedDate,
            startDate: startDate,
            completedDate: completedDate,
            lastReadDate: lastReadDate,
            priority: priority,
            plannedReadingDate: plannedReadingDate,
            reminderEnabled: reminderEnabled,
            purchaseLinks: purchaseLinks?.map { $0.toDomain() },
            memo: memo,
            tags: tags,
            aiSummary: aiSummary,
            summaryGeneratedAt: summaryGeneratedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - PurchaseLinkDTO
struct PurchaseLinkDTO: Codable {
    let title: String
    let url: String
    let price: Double?
    
    init(from purchaseLink: PurchaseLink) {
        self.title = purchaseLink.title
        self.url = purchaseLink.url
        self.price = purchaseLink.price
    }
    
    func toDomain() -> PurchaseLink {
        return PurchaseLink(title: title, url: url, price: price)
    }
}
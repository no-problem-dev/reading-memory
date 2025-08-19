import Foundation
import FirebaseFirestore

// Firestore用のDTO（Data Transfer Object）
struct UserBookDTO: Codable {
    let userId: String
    let bookId: String?
    let manualBookData: ManualBookDataDTO?
    
    // 非正規化データ
    let bookTitle: String
    let bookAuthor: String
    let bookCoverImageUrl: String?
    let bookIsbn: String?
    
    // ユーザー個別データ
    let status: String
    let rating: Double?
    let readingProgress: Double?
    let currentPage: Int?
    let startDate: Timestamp?
    let completedDate: Timestamp?
    let memo: String?
    let tags: [String]
    let isPrivate: Bool
    
    // AI関連
    let aiSummary: String?
    let summaryGeneratedAt: Timestamp?
    
    // 読みたいリスト関連
    let priority: Int?
    let plannedReadingDate: Timestamp?
    let reminderEnabled: Bool
    let purchaseLinks: [PurchaseLinkDTO]?
    let addedToWantListDate: Timestamp?
    
    let createdAt: Timestamp
    let updatedAt: Timestamp
    
    init(from userBook: UserBook) {
        self.userId = userBook.userId
        self.bookId = userBook.bookId
        self.manualBookData = userBook.manualBookData.map { ManualBookDataDTO(from: $0) }
        self.bookTitle = userBook.bookTitle
        self.bookAuthor = userBook.bookAuthor
        self.bookCoverImageUrl = userBook.bookCoverImageUrl
        self.bookIsbn = userBook.bookIsbn
        self.status = userBook.status.rawValue
        self.rating = userBook.rating
        self.readingProgress = userBook.readingProgress
        self.currentPage = userBook.currentPage
        self.startDate = userBook.startDate.map { Timestamp(date: $0) }
        self.completedDate = userBook.completedDate.map { Timestamp(date: $0) }
        self.memo = userBook.memo
        self.tags = userBook.tags
        self.isPrivate = userBook.isPrivate
        self.aiSummary = userBook.aiSummary
        self.summaryGeneratedAt = userBook.summaryGeneratedAt.map { Timestamp(date: $0) }
        self.priority = userBook.priority
        self.plannedReadingDate = userBook.plannedReadingDate.map { Timestamp(date: $0) }
        self.reminderEnabled = userBook.reminderEnabled
        self.purchaseLinks = userBook.purchaseLinks?.map { PurchaseLinkDTO(from: $0) }
        self.addedToWantListDate = userBook.addedToWantListDate.map { Timestamp(date: $0) }
        self.createdAt = Timestamp(date: userBook.createdAt)
        self.updatedAt = Timestamp(date: userBook.updatedAt)
    }
    
    func toDomain(id: String) -> UserBook? {
        guard let status = ReadingStatus(rawValue: status) else { return nil }
        
        return UserBook(
            id: id,
            userId: userId,
            bookId: bookId,
            manualBookData: manualBookData?.toDomain(),
            bookTitle: bookTitle,
            bookAuthor: bookAuthor,
            bookCoverImageUrl: bookCoverImageUrl,
            bookIsbn: bookIsbn,
            status: status,
            rating: rating,
            readingProgress: readingProgress,
            currentPage: currentPage,
            startDate: startDate?.dateValue(),
            completedDate: completedDate?.dateValue(),
            memo: memo,
            tags: tags,
            isPrivate: isPrivate,
            aiSummary: aiSummary,
            summaryGeneratedAt: summaryGeneratedAt?.dateValue(),
            priority: priority,
            plannedReadingDate: plannedReadingDate?.dateValue(),
            reminderEnabled: reminderEnabled,
            purchaseLinks: purchaseLinks?.map { $0.toDomain() },
            addedToWantListDate: addedToWantListDate?.dateValue(),
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}
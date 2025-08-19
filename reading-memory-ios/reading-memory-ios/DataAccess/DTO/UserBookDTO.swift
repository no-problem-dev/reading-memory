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
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}
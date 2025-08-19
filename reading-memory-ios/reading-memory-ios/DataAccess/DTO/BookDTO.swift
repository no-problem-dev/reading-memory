import Foundation
import FirebaseFirestore

// Firestore用のDTO（Data Transfer Object）
struct BookDTO: Codable {
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: Timestamp?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    let dataSource: String
    let visibility: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    
    init(from book: Book) {
        self.isbn = book.isbn
        self.title = book.title
        self.author = book.author
        self.publisher = book.publisher
        self.publishedDate = book.publishedDate.map { Timestamp(date: $0) }
        self.pageCount = book.pageCount
        self.description = book.description
        self.coverImageUrl = book.coverImageUrl
        self.dataSource = book.dataSource.rawValue
        self.visibility = book.visibility.rawValue
        self.createdAt = Timestamp(date: book.createdAt)
        self.updatedAt = Timestamp(date: book.updatedAt)
    }
    
    func toDomain(id: String) -> Book {
        return Book(
            id: id,
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedDate: publishedDate?.dateValue(),
            pageCount: pageCount,
            description: description,
            coverImageUrl: coverImageUrl,
            dataSource: BookDataSource(rawValue: dataSource) ?? .manual,
            visibility: BookVisibility(rawValue: visibility) ?? .private,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}
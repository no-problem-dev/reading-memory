import Foundation
import FirebaseFirestore

// 手動入力本情報のDTO
struct ManualBookDataDTO: Codable {
    let title: String
    let author: String
    let isbn: String?
    let publisher: String?
    let publishedDate: Timestamp?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    
    init(from manualBookData: ManualBookData) {
        self.title = manualBookData.title
        self.author = manualBookData.author
        self.isbn = manualBookData.isbn
        self.publisher = manualBookData.publisher
        self.publishedDate = manualBookData.publishedDate.map { Timestamp(date: $0) }
        self.pageCount = manualBookData.pageCount
        self.description = manualBookData.description
        self.coverImageUrl = manualBookData.coverImageUrl
    }
    
    func toDomain() -> ManualBookData {
        return ManualBookData(
            title: title,
            author: author,
            isbn: isbn,
            publisher: publisher,
            publishedDate: publishedDate?.dateValue(),
            pageCount: pageCount,
            description: description,
            coverImageUrl: coverImageUrl
        )
    }
}
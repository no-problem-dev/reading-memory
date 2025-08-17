import Foundation

struct Book: Identifiable, Codable {
    let id: String
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: Date?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case isbn
        case title
        case author
        case publisher
        case publishedDate
        case pageCount
        case description
        case coverImageUrl
        case createdAt
        case updatedAt
    }
    
    init(id: String = UUID().uuidString,
         isbn: String? = nil,
         title: String,
         author: String,
         publisher: String? = nil,
         publishedDate: Date? = nil,
         pageCount: Int? = nil,
         description: String? = nil,
         coverImageUrl: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.pageCount = pageCount
        self.description = description
        self.coverImageUrl = coverImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
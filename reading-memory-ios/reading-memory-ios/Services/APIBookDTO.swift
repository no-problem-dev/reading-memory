import Foundation

// REST API用のBookDTO
struct APIBookDTO: Decodable {
    let id: String?
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: String?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    let dataSource: String
    let visibility: String?
    let createdAt: Date?
    let updatedAt: Date?
}
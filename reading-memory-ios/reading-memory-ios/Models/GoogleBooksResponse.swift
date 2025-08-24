import Foundation

// Google Books API レスポンスモデル
struct GoogleBooksResponse: Codable {
    let kind: String?
    let totalItems: Int
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let industryIdentifiers: [IndustryIdentifier]?
    let pageCount: Int?
    let imageLinks: ImageLinks?
    let language: String?
    
    var isbn: String? {
        industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier ??
        industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier
    }
    
    var author: String {
        authors?.joined(separator: ", ") ?? ""
    }
    
    var coverImageUrl: String? {
        // HTTPSに変換
        imageLinks?.thumbnail?.replacingOccurrences(of: "http://", with: "https://")
    }
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    let small: String?
    let medium: String?
    let large: String?
    let extraLarge: String?
}

// Google Books API から Book モデルへの変換
extension GoogleBookItem {
    func toBook() -> Book {
        return Book.new(
            isbn: volumeInfo.isbn,
            title: volumeInfo.title,
            author: volumeInfo.author,
            publisher: volumeInfo.publisher,
            publishedDate: parseDate(volumeInfo.publishedDate),
            pageCount: volumeInfo.pageCount,
            description: volumeInfo.description,
            coverImageId: nil,  // Google Books APIから取得した画像はURLのまま使用
            dataSource: .googleBooks
        )
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatters = [
            DateFormatter.yyyyMMdd,
            DateFormatter.yyyyMM,
            DateFormatter.yyyy
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

// DateFormatter 拡張
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    static let yyyyMM: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    static let yyyy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
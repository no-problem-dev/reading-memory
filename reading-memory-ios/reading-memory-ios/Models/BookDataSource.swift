import Foundation

enum BookDataSource: String, Codable {
    case manual = "manual"          // 手動入力
    case googleBooks = "google_books"
    case openBD = "openbd"
    case rakutenBooks = "rakuten_books"
}
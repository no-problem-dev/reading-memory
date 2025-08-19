import Foundation

enum BookDataSource: String, Codable {
    case manual = "manual"          // 手動入力
    case googleBooks = "google_books"
    case openBD = "openbd"
    case rakutenBooks = "rakuten_books"
}

enum BookVisibility: String, Codable {
    case `public` = "public"        // 全ユーザー共有
    case `private` = "private"      // 個人専用
}
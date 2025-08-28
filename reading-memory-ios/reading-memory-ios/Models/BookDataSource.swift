import Foundation

enum BookDataSource: String, Codable {
    case manual = "manual"          // 手動入力
    case googleBooks = "googleBooks"
    case openBD = "openBD"
    case rakutenBooks = "rakutenBooks"
}
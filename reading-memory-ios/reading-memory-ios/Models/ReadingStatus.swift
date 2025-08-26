import Foundation

enum ReadingStatus: String, Codable, CaseIterable {
    case wantToRead = "want_to_read"   // 読みたい
    case reading = "reading"            // 読書中
    case completed = "completed"        // 完了
    case dnf = "dnf"                   // 途中断念（Did Not Finish）
    
    var displayName: String {
        switch self {
        case .wantToRead:
            return "読みたい"
        case .reading:
            return "読書中"
        case .completed:
            return "読了"
        case .dnf:
            return "途中で読むのをやめた"
        }
    }
    
    var icon: String {
        switch self {
        case .wantToRead:
            return "bookmark"
        case .reading:
            return "book"
        case .completed:
            return "checkmark.circle"
        case .dnf:
            return "xmark.circle"
        }
    }
}
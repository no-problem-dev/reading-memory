import Foundation

// 読みたいリストの優先度
enum WantToReadPriority: Int, CaseIterable, Codable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
    
    var displayName: String {
        switch self {
        case .none:
            return "なし"
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .high:
            return 0
        case .medium:
            return 1
        case .low:
            return 2
        case .none:
            return 3
        }
    }
}
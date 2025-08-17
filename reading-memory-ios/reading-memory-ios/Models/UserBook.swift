import Foundation

struct UserBook: Identifiable, Codable {
    let id: String
    let userId: String
    let bookId: String
    let book: Book?
    let status: ReadingStatus
    let rating: Double?
    let startDate: Date?
    let completedDate: Date?
    let customCoverImageUrl: String?
    let notes: String?
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum ReadingStatus: String, Codable, CaseIterable {
        case wantToRead = "want_to_read"
        case reading = "reading"
        case completed = "completed"
        case dnf = "dnf" // Did Not Finish
        
        var displayName: String {
            switch self {
            case .wantToRead:
                return "読みたい"
            case .reading:
                return "読書中"
            case .completed:
                return "完了"
            case .dnf:
                return "DNF"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case bookId
        case book
        case status
        case rating
        case startDate
        case completedDate
        case customCoverImageUrl
        case notes
        case isPublic
        case createdAt
        case updatedAt
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         bookId: String,
         book: Book? = nil,
         status: ReadingStatus = .wantToRead,
         rating: Double? = nil,
         startDate: Date? = nil,
         completedDate: Date? = nil,
         customCoverImageUrl: String? = nil,
         notes: String? = nil,
         isPublic: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.bookId = bookId
        self.book = book
        self.status = status
        self.rating = rating
        self.startDate = startDate
        self.completedDate = completedDate
        self.customCoverImageUrl = customCoverImageUrl
        self.notes = notes
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
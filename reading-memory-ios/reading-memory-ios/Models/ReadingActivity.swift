import Foundation
import FirebaseFirestore

struct ReadingActivity: Identifiable, Codable {
    let id: String
    let userId: String
    let date: Date
    var booksRead: Int
    var memosWritten: Int
    var pagesRead: Int?
    var readingMinutes: Int?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case booksRead
        case memosWritten
        case pagesRead
        case readingMinutes
        case createdAt
        case updatedAt
    }
    
    init(id: String? = nil,
         userId: String,
         date: Date,
         booksRead: Int = 0,
         memosWritten: Int = 0,
         pagesRead: Int? = nil,
         readingMinutes: Int? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        // 日付をキーとしたIDを生成
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        self.id = id ?? "\(userId)_\(dateString)"
        
        self.userId = userId
        self.date = Calendar.current.startOfDay(for: date)
        self.booksRead = booksRead
        self.memosWritten = memosWritten
        self.pagesRead = pagesRead
        self.readingMinutes = readingMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var hasActivity: Bool {
        booksRead > 0 || memosWritten > 0
    }
    
    mutating func recordBookRead() {
        self.booksRead += 1
        self.updatedAt = Date()
    }
    
    mutating func recordMemoWritten() {
        self.memosWritten += 1
        self.updatedAt = Date()
    }
    
    mutating func addPages(_ pages: Int) {
        self.pagesRead = (self.pagesRead ?? 0) + pages
        self.updatedAt = Date()
    }
    
    mutating func addReadingTime(_ minutes: Int) {
        self.readingMinutes = (self.readingMinutes ?? 0) + minutes
        self.updatedAt = Date()
    }
    
    static func createTodayActivity(userId: String) -> ReadingActivity {
        return ReadingActivity(
            userId: userId,
            date: Date()
        )
    }
}
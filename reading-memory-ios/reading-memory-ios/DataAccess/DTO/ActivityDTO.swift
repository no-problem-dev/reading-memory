import Foundation

struct ActivityDTO: Codable {
    let id: String
    let date: Date
    let booksRead: Int
    let memosWritten: Int
    let createdAt: Date
    let updatedAt: Date
    
    func toDomain() -> ReadingActivity {
        return ReadingActivity(
            id: id,
            date: date,
            booksRead: booksRead,
            memosWritten: memosWritten,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    init(from activity: ReadingActivity) {
        self.id = activity.id
        self.date = activity.date
        self.booksRead = activity.booksRead
        self.memosWritten = activity.memosWritten
        self.createdAt = activity.createdAt
        self.updatedAt = activity.updatedAt
    }
}
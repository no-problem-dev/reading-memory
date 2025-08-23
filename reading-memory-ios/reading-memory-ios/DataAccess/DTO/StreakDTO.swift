import Foundation

struct StreakDTO: Codable {
    let id: String
    let type: String
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: Date?
    let streakDates: [Date]
    let createdAt: Date
    let updatedAt: Date
    
    func toDomain() -> ReadingStreak {
        let streakType: ReadingStreak.StreakType
        switch type {
        case "reading":
            streakType = .reading
        case "chatMemo": 
            streakType = .chatMemo
        case "combined":
            streakType = .combined
        default:
            streakType = .reading
        }
        
        return ReadingStreak(
            id: id,
            type: streakType,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastActivityDate: lastActivityDate,
            streakDates: streakDates,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    init(from streak: ReadingStreak) {
        self.id = streak.id
        self.type = streak.type.rawValue
        self.currentStreak = streak.currentStreak
        self.longestStreak = streak.longestStreak
        self.lastActivityDate = streak.lastActivityDate
        self.streakDates = streak.streakDates
        self.createdAt = streak.createdAt
        self.updatedAt = streak.updatedAt
    }
}
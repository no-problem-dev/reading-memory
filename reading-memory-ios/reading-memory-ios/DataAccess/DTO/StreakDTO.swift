import Foundation

struct StreakDTO: Codable {
    let id: String
    let type: String?
    let currentStreak: Int
    let longestStreak: Int
    let lastReadDate: Date?
    let lastActivityDate: Date?
    let streakStartDate: Date?
    let streakDates: [Date]?
    let createdAt: Date
    let updatedAt: Date
    
    func toDomain() -> ReadingStreak {
        let streakType: ReadingStreak.StreakType
        if let type = type {
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
        } else {
            streakType = .reading
        }
        
        // Use lastActivityDate if available, otherwise fall back to lastReadDate
        let lastActivity = lastActivityDate ?? lastReadDate
        
        return ReadingStreak(
            id: id,
            type: streakType,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastActivityDate: lastActivity,
            streakDates: streakDates ?? [],
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
        self.lastReadDate = streak.lastActivityDate // For backward compatibility
        self.streakStartDate = nil
        self.streakDates = streak.streakDates
        self.createdAt = streak.createdAt
        self.updatedAt = streak.updatedAt
    }
}
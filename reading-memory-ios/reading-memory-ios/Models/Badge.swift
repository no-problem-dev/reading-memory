import Foundation
import FirebaseFirestore

struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let iconName: String // SF Symbol名
    let category: BadgeCategory
    let requirement: BadgeRequirement
    let tier: BadgeTier
    let sortOrder: Int
    
    enum BadgeCategory: String, Codable {
        case milestone = "milestone"
        case streak = "streak"
        case genre = "genre"
        case special = "special"
    }
    
    enum BadgeTier: String, Codable {
        case bronze = "bronze"
        case silver = "silver"
        case gold = "gold"
        case platinum = "platinum"
        
        var color: String {
            switch self {
            case .bronze:
                return "brown"
            case .silver:
                return "gray"
            case .gold:
                return "yellow"
            case .platinum:
                return "purple"
            }
        }
    }
    
    struct BadgeRequirement: Codable {
        let type: RequirementType
        let value: Int
        let genre: String?
        
        enum RequirementType: String, Codable {
            case booksRead = "booksRead"
            case streakDays = "streakDays"
            case genreBooks = "genreBooks"
            case yearlyGoal = "yearlyGoal"
            case reviews = "reviews"
            case memos = "memos"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case iconName
        case category
        case requirement
        case tier
        case sortOrder
    }
    
    init(id: String,
         name: String,
         description: String,
         iconName: String,
         category: BadgeCategory,
         requirement: BadgeRequirement,
         tier: BadgeTier,
         sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.tier = tier
        self.sortOrder = sortOrder
    }
    
    var displayDescription: String {
        switch requirement.type {
        case .booksRead:
            return "\(requirement.value)冊の本を読んで獲得"
        case .streakDays:
            return "\(requirement.value)日連続で読書して獲得"
        case .genreBooks:
            let genreName = requirement.genre ?? "特定ジャンル"
            return "\(genreName)の本を\(requirement.value)冊読んで獲得"
        case .yearlyGoal:
            return "年間読書目標を達成して獲得"
        case .reviews:
            return "\(requirement.value)件のレビューを書いて獲得"
        case .memos:
            return "\(requirement.value)件のメモを書いて獲得"
        }
    }
}

// MARK: - Default Badges
extension Badge {
    static let defaultBadges: [Badge] = [
        // Milestone Badges
        Badge(
            id: "first_book",
            name: "読書デビュー",
            description: "初めての本を登録",
            iconName: "book.fill",
            category: .milestone,
            requirement: BadgeRequirement(type: .booksRead, value: 1, genre: nil),
            tier: .bronze,
            sortOrder: 1
        ),
        Badge(
            id: "books_10",
            name: "本の虫",
            description: "10冊の本を読了",
            iconName: "books.vertical.fill",
            category: .milestone,
            requirement: BadgeRequirement(type: .booksRead, value: 10, genre: nil),
            tier: .bronze,
            sortOrder: 2
        ),
        Badge(
            id: "books_50",
            name: "読書家",
            description: "50冊の本を読了",
            iconName: "book.pages.fill",
            category: .milestone,
            requirement: BadgeRequirement(type: .booksRead, value: 50, genre: nil),
            tier: .silver,
            sortOrder: 3
        ),
        Badge(
            id: "books_100",
            name: "読書マスター",
            description: "100冊の本を読了",
            iconName: "crown.fill",
            category: .milestone,
            requirement: BadgeRequirement(type: .booksRead, value: 100, genre: nil),
            tier: .gold,
            sortOrder: 4
        ),
        
        // Streak Badges
        Badge(
            id: "streak_7",
            name: "読書習慣",
            description: "7日連続で読書",
            iconName: "flame.fill",
            category: .streak,
            requirement: BadgeRequirement(type: .streakDays, value: 7, genre: nil),
            tier: .bronze,
            sortOrder: 10
        ),
        Badge(
            id: "streak_30",
            name: "読書の達人",
            description: "30日連続で読書",
            iconName: "flame.circle.fill",
            category: .streak,
            requirement: BadgeRequirement(type: .streakDays, value: 30, genre: nil),
            tier: .silver,
            sortOrder: 11
        ),
        Badge(
            id: "streak_100",
            name: "読書の鬼",
            description: "100日連続で読書",
            iconName: "star.circle.fill",
            category: .streak,
            requirement: BadgeRequirement(type: .streakDays, value: 100, genre: nil),
            tier: .gold,
            sortOrder: 12
        ),
        
        // Special Badges
        Badge(
            id: "yearly_goal",
            name: "目標達成",
            description: "年間読書目標を達成",
            iconName: "target",
            category: .special,
            requirement: BadgeRequirement(type: .yearlyGoal, value: 1, genre: nil),
            tier: .gold,
            sortOrder: 20
        ),
        Badge(
            id: "memo_master",
            name: "メモ魔",
            description: "100件のメモを記録",
            iconName: "note.text",
            category: .special,
            requirement: BadgeRequirement(type: .memos, value: 100, genre: nil),
            tier: .silver,
            sortOrder: 21
        )
    ]
}
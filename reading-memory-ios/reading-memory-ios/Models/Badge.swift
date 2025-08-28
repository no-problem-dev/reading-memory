import Foundation

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
        ),
        
        // Genre badges - Fiction
        Badge(
            id: "literature_lover",
            name: "純文学愛好家",
            description: "純文学の本を10冊読了",
            iconName: "book.pages.fill",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.literature.rawValue),
            tier: .bronze,
            sortOrder: 30
        ),
        Badge(
            id: "mystery_lover",
            name: "ミステリー愛好家",
            description: "ミステリー・推理の本を10冊読了",
            iconName: "magnifyingglass",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.mystery.rawValue),
            tier: .bronze,
            sortOrder: 31
        ),
        Badge(
            id: "sf_enthusiast",
            name: "SF愛読者",
            description: "SF・ファンタジーの本を10冊読了",
            iconName: "sparkles",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.scienceFiction.rawValue),
            tier: .bronze,
            sortOrder: 32
        ),
        Badge(
            id: "historical_fiction_lover",
            name: "歴史小説愛好家",
            description: "歴史小説の本を10冊読了",
            iconName: "clock.arrow.circlepath",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.historicalFiction.rawValue),
            tier: .bronze,
            sortOrder: 33
        ),
        Badge(
            id: "romance_reader",
            name: "ロマンス読者",
            description: "ロマンス・恋愛小説の本を10冊読了",
            iconName: "heart.fill",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.romance.rawValue),
            tier: .bronze,
            sortOrder: 34
        ),
        Badge(
            id: "essay_reader",
            name: "エッセイ読者",
            description: "エッセイ・随筆の本を10冊読了",
            iconName: "quote.bubble.fill",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.essay.rawValue),
            tier: .bronze,
            sortOrder: 35
        ),
        Badge(
            id: "poetry_lover",
            name: "詩歌愛好家",
            description: "詩・短歌・俳句の本を10冊読了",
            iconName: "text.alignleft",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.poetry.rawValue),
            tier: .bronze,
            sortOrder: 36
        ),
        Badge(
            id: "biography_enthusiast",
            name: "伝記ファン",
            description: "伝記・自伝の本を10冊読了",
            iconName: "person.text.rectangle.fill",
            category: .genre,  
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.biography.rawValue),
            tier: .bronze,
            sortOrder: 37
        ),
        
        // Genre badges - Business & Self-Improvement
        Badge(
            id: "business_expert",
            name: "ビジネスエキスパート",
            description: "ビジネス・経済の本を15冊読了",
            iconName: "briefcase.fill",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 15, genre: BookGenre.business.rawValue),
            tier: .silver,
            sortOrder: 38
        ),
        Badge(
            id: "self_help_master",
            name: "自己啓発マスター",
            description: "自己啓発の本を15冊読了",
            iconName: "person.fill.checkmark",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 15, genre: BookGenre.selfHelp.rawValue),
            tier: .silver,
            sortOrder: 39
        ),
        Badge(
            id: "psychology_student",
            name: "心理学研究者",
            description: "心理学の本を10冊読了",
            iconName: "brain",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.psychology.rawValue),
            tier: .bronze,
            sortOrder: 40
        ),
        Badge(
            id: "philosophy_thinker",
            name: "哲学思想家",
            description: "哲学・思想の本を10冊読了",
            iconName: "lightbulb.fill",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.philosophy.rawValue),
            tier: .bronze,
            sortOrder: 41
        ),
        
        // Genre badges - Academic
        Badge(
            id: "science_explorer",
            name: "科学探究者",
            description: "科学・数学の本を15冊読了",
            iconName: "atom",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 15, genre: BookGenre.science.rawValue),
            tier: .silver,
            sortOrder: 42
        ),
        Badge(
            id: "tech_guru",
            name: "技術書の達人",
            description: "技術書・ITの本を20冊読了",
            iconName: "desktopcomputer",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 20, genre: BookGenre.technology.rawValue),
            tier: .silver,
            sortOrder: 43
        ),
        Badge(
            id: "art_connoisseur",
            name: "芸術鑑賞家",
            description: "アート・デザインの本を10冊読了",
            iconName: "paintpalette.fill",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.artDesign.rawValue),
            tier: .bronze,
            sortOrder: 44
        ),
        Badge(
            id: "social_science_observer",
            name: "社会観察者",
            description: "社会・政治の本を10冊読了",
            iconName: "person.3.fill",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.socialScience.rawValue),
            tier: .bronze,
            sortOrder: 45
        ),
        
        // Genre badges - Lifestyle  
        Badge(
            id: "health_conscious",
            name: "健康意識高い系",
            description: "健康・ライフスタイルの本を10冊読了",
            iconName: "heart.text.square.fill",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.health.rawValue),
            tier: .bronze,
            sortOrder: 46
        ),
        Badge(
            id: "travel_explorer",
            name: "旅行探検家",
            description: "旅行・地理の本を10冊読了",
            iconName: "airplane",
            category: .genre,
            requirement: BadgeRequirement(type: .genreBooks, value: 10, genre: BookGenre.travel.rawValue),
            tier: .bronze,
            sortOrder: 47
        ),
        
        // Genre diversity badges
        Badge(
            id: "genre_explorer",
            name: "ジャンル探検家",
            description: "5つの異なるジャンルで本を読了",
            iconName: "square.grid.3x3.fill",
            category: .special,
            requirement: BadgeRequirement(type: .booksRead, value: 5, genre: nil),
            tier: .bronze,
            sortOrder: 48
        ),
        Badge(
            id: "genre_master",
            name: "ジャンルマスター",
            description: "10つの異なるジャンルで本を読了",
            iconName: "square.grid.4x3.fill",
            category: .special,
            requirement: BadgeRequirement(type: .booksRead, value: 10, genre: nil),
            tier: .silver,
            sortOrder: 49
        ),
        Badge(
            id: "genre_omnivore",
            name: "全ジャンル制覇",
            description: "15つ以上の異なるジャンルで本を読了",
            iconName: "infinity.circle.fill",
            category: .special,
            requirement: BadgeRequirement(type: .booksRead, value: 15, genre: nil),
            tier: .gold,
            sortOrder: 50
        )
    ]
}
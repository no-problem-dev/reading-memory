import Foundation

enum BookGenre: String, Codable, CaseIterable {
    // 小説・文学
    case literature = "literature"          // 文学・純文学
    case mystery = "mystery"                // ミステリー・推理
    case scienceFiction = "science_fiction" // SF・ファンタジー
    case romance = "romance"                // ロマンス・恋愛
    case historicalFiction = "historical_fiction" // 歴史小説
    
    // ビジネス・実用
    case business = "business"              // ビジネス・経済
    case selfHelp = "self_help"             // 自己啓発
    case psychology = "psychology"          // 心理学
    case philosophy = "philosophy"          // 哲学・思想
    
    // 専門書
    case technology = "technology"          // 技術書・コンピューター
    case science = "science"                // 科学・数学
    case socialScience = "social_science"   // 社会・政治
    
    // その他
    case essay = "essay"                    // エッセイ・随筆
    case poetry = "poetry"                  // 詩・短歌・俳句
    case artDesign = "art_design"           // アート・デザイン
    case health = "health"                  // 健康・ライフスタイル
    case biography = "biography"            // 伝記・自伝
    case travel = "travel"                  // 旅行・地理
    
    var displayName: String {
        switch self {
        case .literature:
            return "文学・純文学"
        case .mystery:
            return "ミステリー・推理"
        case .scienceFiction:
            return "SF・ファンタジー"
        case .romance:
            return "ロマンス・恋愛"
        case .historicalFiction:
            return "歴史小説"
        case .business:
            return "ビジネス・経済"
        case .selfHelp:
            return "自己啓発"
        case .psychology:
            return "心理学"
        case .philosophy:
            return "哲学・思想"
        case .technology:
            return "技術書・IT"
        case .science:
            return "科学・数学"
        case .socialScience:
            return "社会・政治"
        case .essay:
            return "エッセイ・随筆"
        case .poetry:
            return "詩・短歌・俳句"
        case .artDesign:
            return "アート・デザイン"
        case .health:
            return "健康・ライフスタイル"
        case .biography:
            return "伝記・自伝"
        case .travel:
            return "旅行・地理"
        }
    }
    
    var icon: String {
        switch self {
        case .literature:
            return "book.fill"
        case .mystery:
            return "magnifyingglass"
        case .scienceFiction:
            return "sparkles"
        case .romance:
            return "heart.fill"
        case .historicalFiction:
            return "clock.fill"
        case .business:
            return "briefcase.fill"
        case .selfHelp:
            return "person.fill.checkmark"
        case .psychology:
            return "brain"
        case .philosophy:
            return "lightbulb.fill"
        case .technology:
            return "desktopcomputer"
        case .science:
            return "atom"
        case .socialScience:
            return "person.3.fill"
        case .essay:
            return "text.quote"
        case .poetry:
            return "text.alignleft"
        case .artDesign:
            return "paintpalette.fill"
        case .health:
            return "heart.circle.fill"
        case .biography:
            return "person.text.rectangle.fill"
        case .travel:
            return "map.fill"
        }
    }
    
    var category: GenreCategory {
        switch self {
        case .literature, .mystery, .scienceFiction, .romance, .historicalFiction:
            return .fiction
        case .business, .selfHelp, .psychology, .philosophy:
            return .businessAndSelfImprovement
        case .technology, .science, .socialScience:
            return .academic
        case .essay, .poetry, .artDesign, .health, .biography, .travel:
            return .lifestyle
        }
    }
    
    enum GenreCategory: String, CaseIterable {
        case fiction = "fiction"
        case businessAndSelfImprovement = "business_and_self_improvement"
        case academic = "academic"
        case lifestyle = "lifestyle"
        
        var displayName: String {
            switch self {
            case .fiction:
                return "小説・文学"
            case .businessAndSelfImprovement:
                return "ビジネス・自己啓発"
            case .academic:
                return "専門書・学術"
            case .lifestyle:
                return "ライフスタイル"
            }
        }
    }
    
    // グループ化されたジャンルを取得
    static var groupedGenres: [GenreCategory: [BookGenre]] {
        Dictionary(grouping: BookGenre.allCases) { $0.category }
    }
}
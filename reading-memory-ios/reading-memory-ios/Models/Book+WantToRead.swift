import Foundation

// 読みたいリスト関連の拡張
extension Book {
    // 読みたいリスト関連のプロパティ（プロパティラッパーを使わない計算プロパティとして実装）
    var wantToReadPriority: WantToReadPriority {
        guard let priority = priority else { return .none }
        switch priority {
        case 1, 2:
            return .high
        case 3, 4:
            return .medium
        case 5:
            return .low
        default:
            return .none
        }
    }
    
    var wantToReadDate: Date? {
        // 読みたいリストに追加された日付（plannedReadingDateがなければaddedDate）
        return plannedReadingDate ?? (status == .wantToRead ? addedDate : nil)
    }
    
    var wantToReadMemo: String? {
        // メモがある場合はそれを使用
        return memo
    }
    
    // プレビュー用データ（通常版）
    static var preview: Book {
        Book(
            id: UUID().uuidString,
            isbn: "9784167158057",
            title: "キッチン",
            author: "吉本ばなな",
            publisher: "文藝春秋",
            publishedDate: Date(),
            pageCount: 226,
            description: "祖母を亡くした大学生みかげの再生の物語",
            coverImageId: nil,
            dataSource: .manual,
            purchaseUrl: nil,
            status: .reading,
            rating: nil,
            readingProgress: nil,
            currentPage: nil,
            addedDate: Date(),
            startDate: Date(),
            completedDate: nil,
            lastReadDate: Date(),
            priority: nil,
            plannedReadingDate: nil,
            reminderEnabled: false,
            purchaseLinks: nil,
            memo: nil,
            tags: [],
            genre: .literature,
            aiSummary: nil,
            summaryGeneratedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // 読みたいリストのプレビュー用データ
    static var previewWantToRead: Book {
        Book(
            id: UUID().uuidString,
            isbn: "9784101010137",
            title: "ノルウェイの森",
            author: "村上春樹",
            publisher: "新潮社",
            publishedDate: Date(),
            pageCount: 492,
            description: "限りない喪失と再生を描く究極の恋愛小説",
            coverImageId: nil,
            dataSource: .manual,
            purchaseUrl: nil,
            status: .wantToRead,
            rating: nil,
            readingProgress: nil,
            currentPage: nil,
            addedDate: Date(),
            startDate: nil,
            completedDate: nil,
            lastReadDate: nil,
            priority: 1, // 高優先度
            plannedReadingDate: Date().addingTimeInterval(60 * 60 * 24 * 7), // 1週間後
            reminderEnabled: true,
            purchaseLinks: nil,
            memo: "友人から強く薦められた。恋愛小説の金字塔らしい",
            tags: ["恋愛", "村上春樹"],
            genre: .romance,
            aiSummary: nil,
            summaryGeneratedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
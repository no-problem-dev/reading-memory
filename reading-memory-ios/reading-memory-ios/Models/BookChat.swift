import Foundation

// チャット形式の読書メモ
// ドメインモデル - 外部依存なし
struct BookChat: Identifiable, Equatable {
    let id: String
    let userBookId: String
    let userId: String
    let message: String
    let imageUrl: String?
    let chapterOrSection: String?
    let pageNumber: Int?
    let isAI: Bool // AIからの返信かユーザーのメモか
    let createdAt: Date
    
    init(
        id: String,
        userBookId: String,
        userId: String,
        message: String,
        imageUrl: String? = nil,
        chapterOrSection: String? = nil,
        pageNumber: Int? = nil,
        isAI: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.userBookId = userBookId
        self.userId = userId
        self.message = message
        self.imageUrl = imageUrl
        self.chapterOrSection = chapterOrSection
        self.pageNumber = pageNumber
        self.isAI = isAI
        self.createdAt = createdAt
    }
    
    // 新規作成用のファクトリメソッド
    static func new(
        userBookId: String,
        userId: String,
        message: String,
        imageUrl: String? = nil,
        chapterOrSection: String? = nil,
        pageNumber: Int? = nil,
        isAI: Bool = false
    ) -> BookChat {
        return BookChat(
            id: UUID().uuidString,
            userBookId: userBookId,
            userId: userId,
            message: message,
            imageUrl: imageUrl,
            chapterOrSection: chapterOrSection,
            pageNumber: pageNumber,
            isAI: isAI,
            createdAt: Date()
        )
    }
}
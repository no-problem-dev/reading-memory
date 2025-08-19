import Foundation
import FirebaseFirestore

// Firestore用のDTO（Data Transfer Object）
struct BookChatDTO: Codable {
    let userBookId: String
    let userId: String
    let message: String
    let imageUrl: String?
    let chapterOrSection: String?
    let pageNumber: Int?
    let isAI: Bool
    let createdAt: Timestamp
    
    init(from bookChat: BookChat) {
        self.userBookId = bookChat.userBookId
        self.userId = bookChat.userId
        self.message = bookChat.message
        self.imageUrl = bookChat.imageUrl
        self.chapterOrSection = bookChat.chapterOrSection
        self.pageNumber = bookChat.pageNumber
        self.isAI = bookChat.isAI
        self.createdAt = Timestamp(date: bookChat.createdAt)
    }
    
    func toDomain(id: String) -> BookChat {
        return BookChat(
            id: id,
            userBookId: userBookId,
            userId: userId,
            message: message,
            imageUrl: imageUrl,
            chapterOrSection: chapterOrSection,
            pageNumber: pageNumber,
            isAI: isAI,
            createdAt: createdAt.dateValue()
        )
    }
}
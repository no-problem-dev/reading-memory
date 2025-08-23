import Foundation

/// AI関連サービス
final class AIService {
    static let shared = AIService()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    /// AI応答を生成
    func generateAIResponse(bookId: String, message: String) async throws -> String {
        let result = try await apiClient.generateAIResponse(
            bookId: bookId,
            message: message
        )
        
        guard result.success else {
            throw AppError.custom("AI応答の生成に失敗しました")
        }
        
        return result.message
    }
    
    /// 読書メモの要約を生成
    func generateBookSummary(bookId: String) async throws -> String {
        let result = try await apiClient.generateBookSummary(
            bookId: bookId
        )
        
        guard result.success else {
            throw AppError.custom("要約の生成に失敗しました")
        }
        
        return result.summary
    }
}
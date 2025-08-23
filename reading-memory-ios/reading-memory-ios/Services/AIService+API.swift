import Foundation

// AIServiceをAPIClientを使うように拡張
extension AIService {
    
    /// AI応答を生成 (REST API版)
    func generateAIResponseAPI(userId: String, userBookId: String, message: String) async throws -> String {
        let result = try await APIClient.shared.generateAIResponse(
            userId: userId,
            userBookId: userBookId,
            message: message
        )
        
        guard result.success else {
            throw AppError.custom("AI応答の生成に失敗しました")
        }
        
        return result.message
    }
    
    /// 読書メモの要約を生成 (REST API版)
    func generateBookSummaryAPI(userId: String, userBookId: String) async throws -> String {
        let result = try await APIClient.shared.generateBookSummary(
            userId: userId,
            userBookId: userBookId
        )
        
        guard result.success else {
            throw AppError.custom("要約の生成に失敗しました")
        }
        
        return result.summary
    }
}
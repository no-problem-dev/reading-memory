import Foundation

// AIServiceをAPIClientを使うように拡張
extension AIService {
    
    /// AI応答を生成 (REST API版)
    func generateAIResponseAPI(bookId: String, message: String) async throws -> String {
        let result = try await APIClient.shared.generateAIResponse(
            bookId: bookId,
            message: message
        )
        
        guard result.success else {
            throw AppError.custom("AI応答の生成に失敗しました")
        }
        
        return result.message
    }
    
    /// 読書メモの要約を生成 (REST API版)
    func generateBookSummaryAPI(bookId: String) async throws -> String {
        let result = try await APIClient.shared.generateBookSummary(
            bookId: bookId
        )
        
        guard result.success else {
            // エラーメッセージがある場合はそれを使用
            let errorMessage = result.message ?? "要約の生成に失敗しました"
            throw AppError.custom(errorMessage)
        }
        
        return result.summary
    }
}
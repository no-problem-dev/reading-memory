import Foundation
import FirebaseFunctions

final class AIService {
    static let shared = AIService()
    
    private let functions = Functions.functions(region: "asia-northeast1")
    
    private init() {}
    
    /// AI応答を生成
    func generateAIResponse(userId: String, userBookId: String, message: String) async throws -> String {
        let data: [String: Any] = [
            "userId": userId,
            "userBookId": userBookId,
            "message": message
        ]
        
        do {
            let result = try await functions.httpsCallable("generateAIResponse").call(data)
            
            guard let response = result.data as? [String: Any],
                  let success = response["success"] as? Bool,
                  success,
                  let aiMessage = response["message"] as? String else {
                throw AppError.custom("無効なレスポンスデータです")
            }
            
            return aiMessage
        } catch {
            if let nsError = error as NSError?, nsError.domain == "com.firebase.functions" {
                let code = FunctionsErrorCode(rawValue: nsError.code)
                switch code {
                case .unauthenticated:
                    throw AppError.authenticationRequired
                case .notFound:
                    throw AppError.dataNotFound
                case .permissionDenied:
                    throw AppError.permissionDenied
                default:
                    throw AppError.custom("サーバーエラーが発生しました")
                }
            }
            throw AppError.custom("サーバーエラーが発生しました")
        }
    }
    
    /// 読書メモの要約を生成
    func generateBookSummary(userId: String, userBookId: String) async throws -> String {
        let data: [String: Any] = [
            "userId": userId,
            "userBookId": userBookId
        ]
        
        do {
            let result = try await functions.httpsCallable("generateBookSummary").call(data)
            
            guard let response = result.data as? [String: Any],
                  let success = response["success"] as? Bool,
                  success,
                  let summary = response["summary"] as? String else {
                throw AppError.custom("無効なレスポンスデータです")
            }
            
            return summary
        } catch {
            if let nsError = error as NSError?, nsError.domain == "com.firebase.functions" {
                let code = FunctionsErrorCode(rawValue: nsError.code)
                switch code {
                case .unauthenticated:
                    throw AppError.authenticationRequired
                case .notFound:
                    throw AppError.dataNotFound
                case .permissionDenied:
                    throw AppError.permissionDenied
                default:
                    throw AppError.custom("サーバーエラーが発生しました")
                }
            }
            throw AppError.custom("サーバーエラーが発生しました")
        }
    }
}
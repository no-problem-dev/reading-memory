import Foundation

enum AppError: LocalizedError {
    // MARK: - Authentication Errors
    case authenticationFailed(String)
    case userNotFound
    case sessionExpired
    case invalidCredentials
    
    // MARK: - Network Errors
    case networkError(String)
    case serverError(Int)
    case noInternetConnection
    case requestTimeout
    
    // MARK: - Database Errors
    case databaseError(String)
    case dataNotFound
    case saveFailed
    case deleteFailed
    
    // MARK: - Validation Errors
    case validationError(String)
    case invalidInput(field: String, reason: String)
    case missingRequiredField(String)
    
    // MARK: - Permission Errors
    case permissionDenied
    case unauthorized
    
    // MARK: - General Errors
    case unknown
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let message):
            return "認証に失敗しました: \(message)"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .sessionExpired:
            return "セッションの有効期限が切れました。再度ログインしてください"
        case .invalidCredentials:
            return "認証情報が無効です"
            
        // Network
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .serverError(let code):
            return "サーバーエラー (コード: \(code))"
        case .noInternetConnection:
            return "インターネット接続がありません"
        case .requestTimeout:
            return "リクエストがタイムアウトしました"
            
        // Database
        case .databaseError(let message):
            return "データベースエラー: \(message)"
        case .dataNotFound:
            return "データが見つかりません"
        case .saveFailed:
            return "保存に失敗しました"
        case .deleteFailed:
            return "削除に失敗しました"
            
        // Validation
        case .validationError(let message):
            return "入力エラー: \(message)"
        case .invalidInput(let field, let reason):
            return "\(field): \(reason)"
        case .missingRequiredField(let field):
            return "\(field)は必須項目です"
            
        // Permission
        case .permissionDenied:
            return "アクセス権限がありません"
        case .unauthorized:
            return "認証が必要です"
            
        // General
        case .unknown:
            return "不明なエラーが発生しました"
        case .custom(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .sessionExpired:
            return "アプリを再起動してログインし直してください"
        case .noInternetConnection:
            return "ネットワーク接続を確認してください"
        case .requestTimeout:
            return "しばらく待ってから再度お試しください"
        case .permissionDenied, .unauthorized:
            return "ログイン状態を確認してください"
        default:
            return nil
        }
    }
}

// MARK: - Error Conversion
extension AppError {
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        let nsError = error as NSError
        
        // Firebase errors
        if nsError.domain == "FIRAuthErrorDomain" {
            switch nsError.code {
            case 17011: return .userNotFound
            case 17009: return .invalidCredentials
            case 17020: return .networkError("ネットワーク接続を確認してください")
            default: return .authenticationFailed(nsError.localizedDescription)
            }
        }
        
        // Network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return .noInternetConnection
            case NSURLErrorTimedOut:
                return .requestTimeout
            default:
                return .networkError(nsError.localizedDescription)
            }
        }
        
        return .custom(error.localizedDescription)
    }
}
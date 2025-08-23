import Foundation

/// アプリケーション設定
struct Config {
    static let shared = Config()
    
    private init() {}
    
    /// REST API のベースURL
    var apiBaseURL: String {
        #if DEBUG
        // 開発環境
        // 環境変数でオーバーライド可能
        if let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"] {
            return envURL
        }
        // デフォルトはCloud Run API（開発環境でもCloud Runを使用）
        return "https://reading-memory-api-ehel5nxm2q-an.a.run.app"
        #else
        // 本番環境
        return "https://reading-memory-api-ehel5nxm2q-an.a.run.app"
        #endif
    }
}
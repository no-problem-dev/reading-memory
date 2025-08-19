import Foundation

struct AppConfig {
    static let shared = AppConfig()
    
    private init() {}
    
    // APIキーは Cloud Functions 側で管理されるため、iOS側では不要になりました
    // Cloud Functions が Secret Manager から自動的に取得します
    
    // 開発環境の判定
    static var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
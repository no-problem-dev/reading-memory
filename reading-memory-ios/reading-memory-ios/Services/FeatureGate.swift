import Foundation

/// プレミアム機能へのアクセス制御
public struct FeatureGate {
    // プレミアムプランかどうか
    public static var isPremium: Bool {
        SubscriptionStore.shared.isSubscribed
    }
    
    // 本の登録制限
    private static let freeMonthlyBookLimit = 10
    
    /// 本を追加できるかどうか
    public static func canAddBook(currentMonthlyCount: Int) -> Bool {
        isPremium || currentMonthlyCount < freeMonthlyBookLimit
    }
    
    /// 今月の本登録の残り枠
    public static func remainingBookQuota(currentMonthlyCount: Int) -> Int? {
        guard !isPremium else { return nil }
        return max(0, freeMonthlyBookLimit - currentMonthlyCount)
    }
    
    // AI機能
    public static var canUseAI: Bool { isPremium }
    
    // 写真機能
    public static var canAttachPhotos: Bool { isPremium }
    
    // バーコードスキャン
    public static var canScanBarcode: Bool { isPremium }
    
    // 統計機能
    public static var canViewFullStatistics: Bool { isPremium }
    public static var statisticsMonthsLimit: Int { isPremium ? .max : 3 }
    
    // 読書目標
    public static var canSetYearlyGoals: Bool { isPremium }
    
    // アチーブメント
    public static var canUnlockPremiumBadges: Bool { isPremium }
    
    // 公開本棚
    public static var maxPublicShelfBooks: Int { isPremium ? .max : 5 }
    
    // 機能名を取得（ペイウォール表示用）
    public enum Feature: String, CaseIterable {
        case unlimitedBooks = "無制限の本登録"
        case aiChat = "AI対話・要約機能"
        case photoAttachment = "写真付きメモ"
        case barcodeScanning = "バーコードスキャン"
        case fullStatistics = "全期間の統計分析"
        case yearlyGoals = "年間読書目標"
        case premiumBadges = "プレミアムバッジ"
        case unlimitedPublicShelf = "無制限の公開本棚"
        
        public var icon: String {
            switch self {
            case .unlimitedBooks: return "infinity"
            case .aiChat: return "sparkles"
            case .photoAttachment: return "photo"
            case .barcodeScanning: return "barcode"
            case .fullStatistics: return "chart.line.uptrend.xyaxis"
            case .yearlyGoals: return "calendar"
            case .premiumBadges: return "medal"
            case .unlimitedPublicShelf: return "books.vertical"
            }
        }
    }
}
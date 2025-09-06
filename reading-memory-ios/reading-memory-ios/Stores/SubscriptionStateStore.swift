import Foundation
import SwiftUI

/// アプリ全体の購読状態を管理する環境オブジェクト
/// 購読状態と機能制限の判定のみを責務とする
@MainActor
@Observable
public final class SubscriptionStateStore {
    // MARK: - Properties
    
    /// 購読状態
    private(set) var isSubscribed = false
    
    /// 今月の本登録数
    private(set) var currentMonthBookCount: Int = 0
    
    /// ローディング状態
    private(set) var isLoading = false
    
    /// エラー
    private(set) var error: Error?
    
    // MARK: - Constants
    
    /// 無料ユーザーの月間本登録制限
    private let freeMonthlyBookLimit = 10
    
    // MARK: - Dependencies
    
    private let subscriptionService: SubscriptionService
    private let bookRepository: BookRepository
    
    // MARK: - Initialization
    
    init(
        subscriptionService: SubscriptionService = SubscriptionService.shared,
        bookRepository: BookRepository = BookRepository.shared
    ) {
        self.subscriptionService = subscriptionService
        self.bookRepository = bookRepository
        
        // 購読状態の変更を監視
        setupSubscriptionObserver()
    }
    
    // MARK: - Public Methods
    
    /// 初期化（認証後に呼び出し）
    func initialize() async {
        // 購読状態をチェック
        await checkSubscriptionStatus()
        
        // 月間本登録数を更新
        await updateMonthlyBookCount()
    }
    
    /// 購読状態を再チェック
    func refreshStatus() async {
        await checkSubscriptionStatus()
    }
    
    /// 月間本登録数を更新
    func updateMonthlyBookCount() async {
        do {
            let books = try await bookRepository.getBooks()
            let calendar = Calendar.current
            let now = Date()
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            
            currentMonthBookCount = books.filter { book in
                let bookMonth = calendar.component(.month, from: book.addedDate)
                let bookYear = calendar.component(.year, from: book.addedDate)
                return bookMonth == currentMonth && bookYear == currentYear
            }.count
        } catch {
            print("Error counting monthly books: \(error)")
            currentMonthBookCount = 0
        }
    }
    
    // MARK: - Feature Access Methods
    
    /// プレミアムプランかどうか
    var isPremium: Bool { isSubscribed }
    
    /// 本を追加できるかどうか
    func canAddBook() -> Bool {
        isPremium || currentMonthBookCount < freeMonthlyBookLimit
    }
    
    /// 今月の本登録の残り枠
    func remainingBookQuota() -> Int? {
        guard !isPremium else { return nil }
        return max(0, freeMonthlyBookLimit - currentMonthBookCount)
    }
    
    /// AI機能を使用できるか
    var canUseAI: Bool { isPremium }
    
    /// 写真を添付できるか
    var canAttachPhotos: Bool { isPremium }
    
    /// バーコードスキャンできるか
    var canScanBarcode: Bool { isPremium }
    
    /// 全期間の統計を見られるか
    var canViewFullStatistics: Bool { isPremium }
    
    /// 統計表示の月数制限
    var statisticsMonthsLimit: Int { isPremium ? .max : 3 }
    
    /// 年間目標を設定できるか
    var canSetYearlyGoals: Bool { isPremium }
    
    /// プレミアムバッジを獲得できるか
    var canUnlockPremiumBadges: Bool { isPremium }
    
    /// 公開本棚の最大数
    var maxPublicShelfBooks: Int { isPremium ? .max : 5 }
    
    // MARK: - Private Methods
    
    /// 購読状態をチェック
    private func checkSubscriptionStatus() async {
        isLoading = true
        error = nil
        
        do {
            isSubscribed = try await subscriptionService.checkSubscriptionStatus()
        } catch {
            self.error = error
            isSubscribed = false
        }
        
        isLoading = false
    }
    
    /// 購読状態変更の監視設定
    private func setupSubscriptionObserver() {
        // SubscriptionServiceからの通知を監視
        NotificationCenter.default.addObserver(
            forName: SubscriptionService.subscriptionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let isSubscribed = notification.userInfo?["isSubscribed"] as? Bool {
                self.isSubscribed = isSubscribed
            }
        }
    }
}

// MARK: - Premium Features

extension SubscriptionStateStore {
    /// プレミアム機能の種類（UI表示用）
    public enum PremiumFeature: String, CaseIterable {
        case unlimitedBooks = "無制限の本登録"
        case aiChat = "AI対話・要約機能"
        case photoAttachment = "写真付きメモ"
        case barcodeScanning = "バーコードスキャン"
//        case fullStatistics = "全期間の統計分析"
//        case yearlyGoals = "年間読書目標"
//        case premiumBadges = "プレミアムバッジ"
//        case unlimitedPublicShelf = "無制限の公開本棚"
        
        public var icon: String {
            switch self {
            case .unlimitedBooks: return "infinity"
            case .aiChat: return "sparkles"
            case .photoAttachment: return "photo"
            case .barcodeScanning: return "barcode"
//            case .fullStatistics: return "chart.line.uptrend.xyaxis"
//            case .yearlyGoals: return "calendar"
//            case .premiumBadges: return "medal"
//            case .unlimitedPublicShelf: return "books.vertical"
            }
        }
        
        public var description: String {
            switch self {
            case .unlimitedBooks: return "月10冊の制限なく、好きなだけ本を登録"
            case .aiChat: return "AIと本について対話し、要約を生成"
            case .photoAttachment: return "メモに写真を添付して記録"
            case .barcodeScanning: return "バーコードで簡単に本を登録"
//            case .fullStatistics: return "全期間の読書統計を分析"
//            case .yearlyGoals: return "年間読書目標を設定して進捗管理"
//            case .premiumBadges: return "特別なアチーブメントバッジを獲得"
//            case .unlimitedPublicShelf: return "公開本棚に無制限で本を追加"
            }
        }
    }
}
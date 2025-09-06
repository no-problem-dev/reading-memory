import Foundation
import RevenueCat
import FirebaseAuth

/// 購読の購入・管理を行うサービス層
/// RevenueCatとの通信と購入処理を責務とする
@MainActor
public final class SubscriptionService {
    // MARK: - Singleton
    
    public static let shared = SubscriptionService()
    
    // MARK: - Notifications
    
    /// 購読状態変更通知
    public static let subscriptionStatusDidChangeNotification = Notification.Name("SubscriptionStatusDidChange")
    
    // MARK: - Properties
    
    /// RevenueCatのオファリング情報
    private(set) var offerings: Offerings?
    
    /// 顧客情報
    private(set) var customerInfo: CustomerInfo?
    
    /// RevenueCat API Key
    private let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String ?? ""
    
    /// Delegate Handler
    private var delegateHandler: PurchasesDelegateHandler?
    
    // MARK: - Initialization
    
    private init() {
        setupRevenueCat()
    }
    
    // MARK: - Setup
    
    /// RevenueCatの初期設定
    private func setupRevenueCat() {
        guard !apiKey.isEmpty else {
            print("⚠️ RevenueCat API Key not found in Info.plist")
            return
        }
        
        Purchases.configure(withAPIKey: apiKey)
        
        // Delegate設定
        delegateHandler = PurchasesDelegateHandler { [weak self] customerInfo in
            self?.handleCustomerInfoUpdate(customerInfo)
        }
        Purchases.shared.delegate = delegateHandler
        
        // Firebase Auth連携
        setupAuthSync()
    }
    
    /// Firebase Authとの同期設定
    private func setupAuthSync() {
        if let userId = Auth.auth().currentUser?.uid {
            Task {
                await syncWithUser(userId: userId)
            }
        }
        
        // Auth状態変更の監視
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let userId = user?.uid {
                    await self?.syncWithUser(userId: userId)
                } else {
                    await self?.logOut()
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 購読状態をチェック
    public func checkSubscriptionStatus() async throws -> Bool {
        customerInfo = try await Purchases.shared.customerInfo()
        let isSubscribed = customerInfo?.entitlements["premium"]?.isActive ?? false
        print("✅ Subscription status: \(isSubscribed ? "Active" : "Inactive")")
        return isSubscribed
    }
    
    /// オファリング（商品情報）を読み込み
    public func loadOfferings() async throws -> Offerings? {
        offerings = try await Purchases.shared.offerings()
        print("✅ Loaded offerings: \(offerings?.current?.availablePackages.count ?? 0) packages")
        return offerings
    }
    
    /// 購入処理
    public func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        customerInfo = result.customerInfo
        let isSubscribed = customerInfo?.entitlements["premium"]?.isActive ?? false
        
        if !result.userCancelled && isSubscribed {
            print("✅ Purchase successful")
            notifySubscriptionChange(isSubscribed: true)
        }
        
        return isSubscribed
    }
    
    /// 購入の復元
    public func restore() async throws -> Bool {
        customerInfo = try await Purchases.shared.restorePurchases()
        let isSubscribed = customerInfo?.entitlements["premium"]?.isActive ?? false
        print("✅ Restore completed: \(isSubscribed ? "Active subscription found" : "No active subscription")")
        
        if isSubscribed {
            notifySubscriptionChange(isSubscribed: true)
        }
        
        return isSubscribed
    }
    
    // MARK: - Private Methods
    
    /// ユーザーIDとの同期
    private func syncWithUser(userId: String) async {
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            self.customerInfo = customerInfo
            
            let isSubscribed = customerInfo.entitlements["premium"]?.isActive ?? false
            notifySubscriptionChange(isSubscribed: isSubscribed)
        } catch {
            print("Error syncing with user: \(error)")
        }
    }
    
    /// ログアウト処理
    private func logOut() async {
        do {
            _ = try await Purchases.shared.logOut()
            notifySubscriptionChange(isSubscribed: false)
        } catch {
            print("Error logging out: \(error)")
        }
    }
    
    /// 顧客情報更新の処理
    private func handleCustomerInfoUpdate(_ customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        let isSubscribed = customerInfo.entitlements["premium"]?.isActive ?? false
        print("📱 Subscription status updated: \(isSubscribed ? "Active" : "Inactive")")
        notifySubscriptionChange(isSubscribed: isSubscribed)
    }
    
    /// 購読状態変更を通知
    private func notifySubscriptionChange(isSubscribed: Bool) {
        NotificationCenter.default.post(
            name: Self.subscriptionStatusDidChangeNotification,
            object: nil,
            userInfo: ["isSubscribed": isSubscribed]
        )
    }
}

// MARK: - PurchasesDelegate Handler

/// RevenueCat Delegateを処理するためのNSObject継承クラス
private final class PurchasesDelegateHandler: NSObject, PurchasesDelegate {
    private let onCustomerInfoUpdate: (CustomerInfo) -> Void
    
    init(onCustomerInfoUpdate: @escaping (CustomerInfo) -> Void) {
        self.onCustomerInfoUpdate = onCustomerInfoUpdate
        super.init()
    }
    
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            onCustomerInfoUpdate(customerInfo)
        }
    }
}
import Foundation
import RevenueCat
import FirebaseAuth

@Observable
public final class SubscriptionStore: NSObject {
    public static let shared = SubscriptionStore()
    
    // 状態
    public private(set) var isSubscribed = false
    public private(set) var offerings: Offerings?
    public private(set) var customerInfo: CustomerInfo?
    
    // RevenueCat API Key (Info.plistから読み込み)
    private let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String ?? ""
    
    private override init() {
        super.init()
    }
    
    // RevenueCat初期化
    public func initialize() {
        guard !apiKey.isEmpty else {
            print("⚠️ RevenueCat API Key not found in Info.plist")
            return
        }
        
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        
        // Firebase AuthのユーザーIDと同期
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let userId = user?.uid {
                Purchases.shared.logIn(userId) { _, _, _ in
                    Task {
                        await self?.checkSubscriptionStatus()
                    }
                }
            } else {
                Purchases.shared.logOut { _, _ in
                    self?.isSubscribed = false
                }
            }
        }
    }
    
    // サブスクリプション状態をチェック
    @MainActor
    public func checkSubscriptionStatus() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
            isSubscribed = customerInfo?.entitlements["premium"]?.isActive ?? false
            print("✅ Subscription status: \(isSubscribed ? "Active" : "Inactive")")
        } catch {
            print("❌ Error checking subscription status: \(error)")
            isSubscribed = false
        }
    }
    
    // オファリング（商品情報）を読み込み
    @MainActor
    public func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
            print("✅ Loaded offerings: \(offerings?.current?.availablePackages.count ?? 0) packages")
        } catch {
            print("❌ Error loading offerings: \(error)")
            offerings = nil
        }
    }
    
    // 購入処理
    @MainActor
    public func purchase(_ package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        customerInfo = result.customerInfo
        isSubscribed = customerInfo?.entitlements["premium"]?.isActive ?? false
        
        if !result.userCancelled && isSubscribed {
            print("✅ Purchase successful")
        }
    }
    
    // 購入の復元
    @MainActor
    public func restore() async throws {
        customerInfo = try await Purchases.shared.restorePurchases()
        isSubscribed = customerInfo?.entitlements["premium"]?.isActive ?? false
        print("✅ Restore completed: \(isSubscribed ? "Active subscription found" : "No active subscription")")
    }
}

// MARK: - PurchasesDelegate
extension SubscriptionStore: PurchasesDelegate {
    public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isSubscribed = customerInfo.entitlements["premium"]?.isActive ?? false
            print("📱 Subscription status updated: \(isSubscribed ? "Active" : "Inactive")")
        }
    }
}
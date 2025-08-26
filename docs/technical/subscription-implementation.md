# サブスクリプション実装方針（RevenueCat版）

## 概要

読書メモリーのサブスクリプション機能は、RevenueCat SDKを使用して実装します。すべての課金状態管理をRevenueCatに委譲することで、シンプルかつ信頼性の高い実装を実現します。

## アーキテクチャ

### システム構成（超シンプル）

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   iOS App   │────▶│  RevenueCat  │────▶│  App Store  │
│    (SDK)    │     │   Backend    │     │             │
└─────────────┘     └──────────────┘     └─────────────┘
```

**重要**: Firestoreへの課金情報の保存は一切行いません。すべてRevenueCatが管理します。

## RevenueCat設定

### 1. Dashboard設定

#### Entitlement
- ID: `premium`
- Description: メモリープラス

#### Products
- `com.readingmemory.premium.monthly` - 月額プラン（¥600）
- `com.readingmemory.premium.yearly` - 年額プラン（¥6,000）

#### Offering
- Default Offering
  - Monthly Package
  - Yearly Package（推奨表示）

### 2. API Keys
- Public SDK Key: `appl_xxxxxxxxxxxx`（iOS アプリに埋め込み）
- Secret API Key: 管理画面でのみ使用

## iOS実装

### 1. SDK導入

```swift
// Swift Package Manager
// https://github.com/RevenueCat/purchases-ios.git
// Version: 4.0.0 < 5.0.0
```

### 2. 初期化（AppDelegate）

```swift
import RevenueCat
import FirebaseAuth

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // RevenueCat初期化
    Purchases.configure(withAPIKey: "appl_xxxxxxxxxxxx")
    
    // Firebase AuthユーザーIDと同期
    Auth.auth().addStateDidChangeListener { _, user in
        if let userId = user?.uid {
            Purchases.shared.logIn(userId) { _, _, _ in }
        } else {
            Purchases.shared.logOut { _, _ in }
        }
    }
    
    return true
}
```

### 3. サブスクリプション状態管理

```swift
// SubscriptionStore.swift
import Foundation
import RevenueCat

@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()
    
    // 状態
    private(set) var isSubscribed = false
    private(set) var offerings: Offerings?
    
    init() {
        // CustomerInfoの変更を監視
        Purchases.shared.delegate = self
        Task { await checkSubscriptionStatus() }
    }
    
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isSubscribed = customerInfo.entitlements["premium"]?.isActive ?? false
        } catch {
            isSubscribed = false
        }
    }
    
    func loadOfferings() async {
        offerings = try? await Purchases.shared.offerings()
    }
    
    func purchase(_ package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        isSubscribed = result.customerInfo.entitlements["premium"]?.isActive ?? false
    }
    
    func restore() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        isSubscribed = customerInfo.entitlements["premium"]?.isActive ?? false
    }
}

// Delegate実装
extension SubscriptionStore: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        isSubscribed = customerInfo.entitlements["premium"]?.isActive ?? false
    }
}
```

### 4. 機能ゲート

```swift
// FeatureGate.swift
struct FeatureGate {
    static var isPremium: Bool {
        SubscriptionStore.shared.isSubscribed
    }
    
    static func canAddBook(currentCount: Int) -> Bool {
        isPremium || currentCount < 10
    }
    
    static var canUseAI: Bool { isPremium }
    static var canAttachPhotos: Bool { isPremium }
    static var canScanBarcode: Bool { isPremium }
    static var canViewFullStatistics: Bool { isPremium }
    static var canSetYearlyGoals: Bool { isPremium }
    static var maxPublicShelfBooks: Int { isPremium ? .max : 5 }
}
```

### 5. ペイウォール表示

```swift
// 使用例
struct AddBookView: View {
    @State private var bookCount = 0
    @State private var showPaywall = false
    
    var body: some View {
        Button("本を追加") {
            if FeatureGate.canAddBook(currentCount: bookCount) {
                // 本を追加
            } else {
                showPaywall = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
```

## 実装チェックリスト

### Phase 1: 基本実装（1日）
- [ ] RevenueCat SDK導入
- [ ] RevenueCat Dashboard設定
- [ ] SubscriptionStore実装
- [ ] FeatureGate実装

### Phase 2: UI実装（2日）
- [ ] PaywallView作成
- [ ] 設定画面のサブスクリプション管理
- [ ] 各機能への制限適用

### Phase 3: テスト（1日）
- [ ] Sandboxテスト
- [ ] 購入フロー確認
- [ ] 復元フロー確認

## エラーハンドリング

RevenueCatが自動的に以下を処理：
- ネットワークエラーのリトライ
- レシート検証
- サブスクリプション状態の同期
- 返金・キャンセルの検知

アプリ側では単純に成功/失敗のみ処理すればOK。

## テスト

### StoreKit Configuration File
1. Xcodeでプロダクト定義
2. RevenueCat Dashboardと同じProduct IDを使用
3. ローカルテストで動作確認

### Sandbox環境
1. RevenueCat DashboardでSandbox API Keyを使用
2. TestFlightでの動作確認

## 監視

RevenueCat Dashboardで自動的に以下を確認可能：
- リアルタイムの売上
- サブスクリプション継続率
- チャーン率
- コホート分析
- A/Bテスト結果

## セキュリティ

- Public API Keyのみアプリに埋め込み（漏洩しても問題なし）
- すべての検証はRevenueCatサーバー側で実施
- 不正な購入は自動的にブロック

## まとめ

RevenueCatを使用することで：
- ✅ 実装が1-2日で完了
- ✅ バックエンド開発不要
- ✅ 複雑な検証ロジック不要
- ✅ 自動的な状態管理
- ✅ 充実した分析機能

開発者はUI/UXに集中でき、課金まわりの複雑さから解放されます。
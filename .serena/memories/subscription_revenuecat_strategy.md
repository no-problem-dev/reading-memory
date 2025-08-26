# 読書メモリー サブスクリプション戦略（RevenueCat版）

## 概要
RevenueCat SDKを使用したシンプルなサブスクリプション実装。課金状態管理はすべてRevenueCatに委譲し、Firestoreには課金情報を一切保存しない。

## アーキテクチャ
```
iOS App (SDK) → RevenueCat Backend → App Store
```

## フリーミアムモデル

### 無料プラン
- 本の登録：月10冊まで
- 手動登録のみ
- テキストチャットメモ
- 基本統計（過去3ヶ月）
- 月間目標のみ
- 基本バッジのみ
- 公開本棚：5冊まで

### プレミアムプラン「メモリープラス」
**価格**: 月額600円 / 年額6,000円

**機能**:
- 無制限の本登録
- バーコード/ISBN検索
- AI対話・要約機能
- 写真付きチャットメモ
- 全期間の統計・分析
- 高度な読書目標設定（年間目標）
- 全アチーブメント解放
- 公開本棚無制限

## RevenueCat設定

### Product IDs
- `com.readingmemory.premium.monthly`
- `com.readingmemory.premium.yearly`

### Entitlement
- ID: `premium`

## 実装のポイント

### 1. 完全な分離
- 課金状態はRevenueCatのみが管理
- FirestoreにはユーザーIDとの紐付けのみ（RevenueCat.logIn）
- 課金情報の永続化は不要

### 2. シンプルな状態管理
```swift
@Observable
final class SubscriptionStore {
    private(set) var isSubscribed = false
    private(set) var offerings: Offerings?
}
```

### 3. 機能ゲート
```swift
struct FeatureGate {
    static var isPremium: Bool { SubscriptionStore.shared.isSubscribed }
    static func canAddBook(currentCount: Int) -> Bool { isPremium || currentCount < 10 }
    static var canUseAI: Bool { isPremium }
    // etc...
}
```

### 4. 実装期間
- Phase 1: 基本実装（1日）
- Phase 2: UI実装（2日）
- Phase 3: テスト（1日）
- **合計: 4日**

## メリット
- ✅ バックエンド開発不要
- ✅ 複雑な検証ロジック不要
- ✅ 自動的なサブスクリプション管理
- ✅ 充実した分析ダッシュボード
- ✅ A/Bテスト機能
- ✅ セキュリティはRevenueCat側で担保

## 注意点
- RevenueCat障害時の対策を検討（キャッシュ等）
- アプリ起動時の状態取得を高速化
- オフライン時の動作確認
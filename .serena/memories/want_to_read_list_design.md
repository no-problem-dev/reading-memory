# 読みたいリスト機能設計

## 実装日
2025年1月19日

## 機能要件
1. **リスト管理UI**
   - 専用の読みたいリストビュー
   - ドラッグ&ドロップで優先順位変更
   - スワイプアクション（読書開始、削除）

2. **優先順位設定**
   - 並び替え可能なリスト
   - 優先度インジケーター（高/中/低）
   - カスタム並び順の保存

3. **リマインダー機能**
   - 読書開始予定日の設定
   - プッシュ通知（後続フェーズで実装）
   - リマインダー一覧表示

4. **購入リンク管理**
   - 購入先URL登録（Amazon、楽天など）
   - 複数リンク対応
   - ワンタップで購入ページへ

## データモデル設計

### UserBookモデル拡張
```swift
// 既存のUserBookに追加
var priority: Int? // 0が最高優先度
var plannedReadingDate: Date? // 読書予定日
var reminderEnabled: Bool // リマインダー有効化
var purchaseLinks: [PurchaseLink]? // 購入リンク
var addedToWantListDate: Date? // リスト追加日
```

### 新規モデル: PurchaseLink
```swift
struct PurchaseLink: Codable, Identifiable {
    let id: String
    let title: String // "Amazon", "楽天ブックス"など
    let url: String
    let price: Double?
    let createdAt: Date
}
```

## View設計

### WantToReadListView（メインビュー）
- NavigationStackで表示
- ツールバー：並び替え、フィルター
- リスト表示（優先度順/追加日順/予定日順）
- 統計情報ヘッダー（総数、今月追加数など）

### WantToReadRowView（行ビュー）
- 本の基本情報表示
- 優先度インジケーター
- 予定日バッジ
- スワイプアクション

### WantToReadDetailView（詳細編集）
- 優先度設定（スライダーor選択）
- 読書予定日設定
- リマインダー設定
- 購入リンク管理

## ViewModel設計

### WantToReadListViewModel
```swift
@Observable
class WantToReadListViewModel {
    private(set) var books: [UserBook] = []
    private(set) var isLoading = false
    var sortOption: SortOption = .priority
    
    func loadWantToReadBooks()
    func updatePriority(bookId: String, priority: Int)
    func reorderBooks(from: IndexSet, to: Int)
    func startReading(bookId: String)
}
```

## 実装優先順位
1. 基本的なリスト表示UI
2. 優先順位の設定と並び替え
3. 読書予定日とリマインダー基盤
4. 購入リンク管理

## UI/UXガイドライン
- 優先度は視覚的にわかりやすく（色/アイコン）
- ドラッグ&ドロップは直感的に
- 空状態は行動を促すデザイン
- 読書開始への導線を明確に
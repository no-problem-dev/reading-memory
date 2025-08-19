# 読みたいリスト機能実装完了

## 実装日
2025年1月19日

## 実装内容

### データモデル拡張
1. **UserBookモデル**
   - priority: Int? - 優先度（0が最高）
   - plannedReadingDate: Date? - 読書予定日
   - reminderEnabled: Bool - リマインダー有効化
   - purchaseLinks: [PurchaseLink]? - 購入リンク
   - addedToWantListDate: Date? - リスト追加日

2. **PurchaseLinkモデル** (新規)
   - 購入先情報を管理
   - Amazon、楽天ブックスなどのプリセット

### View実装
1. **WantToReadListView**
   - メインの読みたいリスト画面
   - 統計ヘッダー表示
   - スワイプアクション（読書開始/削除）
   - ドラッグで並び替え

2. **WantToReadRowView**
   - リストの行表示
   - 優先度インジケーター
   - 予定日バッジ
   - リマインダー/購入リンクアイコン

3. **WantToReadDetailView**
   - 詳細設定画面
   - 優先度スライダー
   - 読書予定日設定
   - 購入リンク管理

### ViewModel
- **WantToReadListViewModel**
  - ソート機能（優先度/追加日/予定日/タイトル）
  - 並び替え機能
  - CRUD操作

### Repository更新
- UserBookDTO/UserBookRepositoryを新フィールドに対応
- UserBookRepositoryProtocol作成

### UI統合
- MainTabViewに「読みたい」タブ追加
- bookmark.fillアイコン使用

## 技術的な特徴
- @Observableパターン使用
- SwiftUI最新機能活用
- リアルタイムFirestore同期
- 直感的なドラッグ&ドロップ

## 次のステップ
- プッシュ通知実装（Phase 4）
- 読書目標・習慣機能
- ウィジェット対応
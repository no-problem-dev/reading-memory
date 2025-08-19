# Phase 4: 読みたいリスト機能実装完了

## 実装日
2025年1月19日

## PR情報
- ブランチ: feature/want-to-read-list
- PR: https://github.com/no-problem-dev/reading-memory/pull/2

## 実装内容

### データモデル拡張
1. **UserBookモデル**
   - priority: Int? - 優先度（0が最高）
   - plannedReadingDate: Date? - 読書予定日
   - reminderEnabled: Bool - リマインダー有効化
   - purchaseLinks: [PurchaseLink]? - 購入リンク
   - addedToWantListDate: Date? - リスト追加日

2. **PurchaseLinkモデル** (新規)
   - id: String
   - title: String（Amazon、楽天ブックスなど）
   - url: String
   - price: Double?
   - createdAt: Date

### View実装
1. **WantToReadListView**
   - MainTabViewに「読みたい」タブ追加
   - 統計ヘッダー表示
   - ドラッグ&ドロップで並び替え
   - スワイプアクション

2. **WantToReadRowView**
   - 優先度インジケーター
   - 予定日バッジ
   - 各種アイコン表示

3. **WantToReadDetailView**
   - 優先度スライダー（0-9）
   - 読書予定日設定
   - リマインダー設定
   - 購入リンク管理（追加/編集/削除）

### ViewModel
- **WantToReadListViewModel**
  - ソート機能（4種類）
  - 並び替え機能
  - CRUD操作
  - AuthService.shared使用

### Repository更新
- UserBookDTO/UserBookRepositoryを新フィールドに対応
- UserBookRepositoryProtocol作成
- PurchaseLinkDTO作成

### UI改善
- BookCoverViewをパラメータ化
  - サイズ指定可能（width/height）
  - タイトル/評価の表示制御
  - BookCoverPlaceholderも動的サイズ対応

## 技術的な特徴
- @Observableパターン使用
- SwiftUI最新機能活用（iOS 17.0+）
- リアルタイムFirestore同期
- 既存のアーキテクチャに準拠（MVVM + Repository）

## 次のステップ（Phase 4残り）
- 読書目標・習慣機能
- 通知機能（プッシュ通知）
- ウィジェット実装
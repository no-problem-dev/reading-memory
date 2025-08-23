# 読書メモリー: 公開機能削除と非公開化の実装方針

## 概要
読書メモリーアプリから公開機能を削除し、完全にプライベートな読書管理アプリに変更する。

## 現状分析

### 公開機能の実装箇所
1. **iOS側**
   - PublicBookshelfView / PublicBookshelfViewModel: みんなの本棚画面
   - BookRegistrationViewModel: API経由の本は常に public として登録
   - BookSearchViewModel: searchPublicBooks メソッド
   - BookRepository: searchPublicBooks メソッド
   - APIClient: getPopularBooks, getRecentBooks, searchPublicBooks メソッド
   
2. **API側**
   - public.routes.ts: /api/v1/public/books/* エンドポイント
   - public.controller.ts: 公開本の検索・取得処理
   
3. **データモデル**
   - Book.visibility: BookVisibility (.public/.private)
   - Firestore booksコレクション: 公開本のマスターテーブル

## 実装方針

### Phase 1: iOS側の修正
1. BookRegistrationViewModel の修正
   - API経由の本登録時、visibility を .private に変更
   - books コレクションへの登録を廃止（userBooks のみに登録）

2. 公開画面の削除
   - PublicBookshelfView.swift を削除
   - PublicBookshelfViewModel.swift を削除
   - BookShelfView から PublicBookshelfView への遷移を削除

3. 公開関連メソッドの削除
   - BookSearchViewModel: searchPublicBooks, loadPublicBooks を削除
   - BookRepository: searchPublicBooks を削除
   - APIClient: getPopularBooks, getRecentBooks, searchPublicBooks を削除

### Phase 2: API側の修正
1. エンドポイントの削除
   - public.routes.ts を削除
   - public.controller.ts を削除
   - app.ts から public routes の登録を削除

### Phase 3: データベース構造の簡素化
1. Firestore構造
   - books コレクションは将来的に削除（既存データは残す）
   - 新規登録はすべて userBooks のみに保存

2. BookVisibility の扱い
   - 既存コードへの影響を最小限にするため、enum は残す
   - デフォルト値を .private に固定

### Phase 4: UI/UXの調整
1. プロフィール画面
   - isPublic プロパティの編集UI削除（内部的には false 固定）

2. 検索機能
   - Firestore内の公開本検索を削除
   - API（Google Books等）からの検索のみに限定

## 実装順序
1. BookRegistrationViewModel の visibility 変更
2. 公開画面（PublicBookshelfView）の削除
3. 公開関連メソッドの削除
4. API側のエンドポイント削除
5. UIの調整とテスト

## 注意事項
- 既存の books コレクションのデータは削除しない（過去データ保持）
- userBooks コレクションの構造は変更しない
- Book モデルの visibility プロパティは残す（将来の拡張性のため）
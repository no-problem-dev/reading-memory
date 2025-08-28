# ジャンル管理システムの再設計 (2025年1月)

## 概要
読書メモリーアプリのジャンル管理を文字列ベースから型安全なEnum管理に全面的に再設計しました。

## 主な変更点

### 1. BookGenre Enumの作成
- 本好きとビジネス向けに特化した18種類のジャンルを定義
- 4つのカテゴリーに分類（小説・文学、ビジネス・自己啓発、専門書・学術、ライフスタイル）
- 各ジャンルにアイコンと表示名を設定

### 2. データモデルの更新
- Book: `tags: [String]` に加えて `genre: BookGenre?` プロパティを追加
- UserProfile: `favoriteGenres: [String]` を `favoriteGenres: [BookGenre]` に変更
- BookDTO: String型でFirestoreとの変換処理を実装

### 3. UI/UXの改善
- オンボーディング画面: BookGenre.allCasesを使用した選択UI
- プロフィール編集画面: タグ入力からBookGenre選択式に変更
- 統計画面: 実際のBook.genreデータを使用したジャンル分布表示

### 4. 機能の拡張
- ジャンル別バッジ機能: ミステリー愛好家、ビジネスエキスパート等のバッジを追加
- AchievementRepository: Book.genreを参照するよう修正
- GoalRepository: ジャンル数カウントでBook.genreを使用

## 実装されたBookGenreの一覧
- 小説・文学: literature, mystery, scienceFiction, romance, historicalFiction
- ビジネス・自己啓発: business, selfHelp, psychology, philosophy
- 専門書・学術: technology, science, socialScience
- ライフスタイル: essay, poetry, artDesign, health, biography, travel

## 未実装タスク
1. 本の編集画面にジャンル選択UIを追加
2. APIとFirebaseルールの更新（genreフィールド追加）

## メリット
- 型安全性の向上
- ジャンルの一貫性確保
- 拡張性の向上（新ジャンル追加が容易）
- アイコンやカテゴリー等のメタデータ管理の簡潔化
# みんなの本棚機能の実装ガイド

## 概要
「みんなの本棚」は、ユーザーが登録した公開本を共有できる機能です。API経由で取得した本は自動的に公開本として登録され、他のユーザーも閲覧・登録できます。

## 動作フロー

### 1. 本の検索と登録
1. ユーザーがバーコードスキャンまたはキーワード検索で本を検索
2. Cloud Functions経由でOpenBD/Google Books APIから書籍情報を取得
3. 検索結果から本を選択して登録
4. API経由の本は自動的に `visibility: public` として保存

### 2. 公開本の共有
1. API経由の本はFirestoreの `books` コレクションに保存
2. ISBNによる重複チェックで、同じ本は1つのマスターデータとして管理
3. 各ユーザーは `books` コレクションで公開本への参照を保持

### 3. みんなの本棚での閲覧
1. 本棚画面の地球アイコンから「みんなの本棚」にアクセス
2. 3つのタブで公開本を表示：
   - **人気**: 登録ユーザー数が多い本（現在は新着順）
   - **新着**: 最近追加された公開本
   - **検索**: タイトル・著者で公開本を検索

### 4. 公開本の登録
1. みんなの本棚から本を選択
2. 「本棚に追加」ボタンで自分の本棚に登録
3. 既に存在する公開本への参照として `books` に保存

## 技術実装

### Cloud Functions
- `searchBookByISBN`: ISBN検索（OpenBD → Google Books）
- `searchBooksByQuery`: キーワード検索
- `getPopularBooks`: 人気の本を取得
- `getRecentBooks`: 新着の本を取得
- `searchPublicBooks`: 公開本を検索

### データモデル
```swift
// 本のデータソース
enum BookDataSource {
    case manual      // 手動入力
    case googleBooks // Google Books API
    case openBD      // OpenBD API
    case rakutenBooks // 楽天Books API
}

// 本の公開設定
enum BookVisibility {
    case public   // 公開（API経由は自動的にこれ）
    case private  // 非公開（手動入力のみ）
}
```

### セキュリティ
- APIキーはFirebase Secret Managerで管理
- クライアント側にAPIキーは露出しない
- 認証済みユーザーのみがCloud Functionsを呼び出し可能

## 今後の拡張予定
1. 人気順の実装（登録ユーザー数でソート）
2. レビュー・評価の共有
3. 読書コミュニティ機能
4. おすすめ本の提案
# Cloud Functions for 読書メモリー

## セットアップ

### 1. 依存関係のインストール
```bash
npm install
```

### 2. Firebase Emulatorのセットアップ
```bash
firebase emulators:start
```

### 3. Secret Managerの設定

#### Google Books API Key
```bash
firebase functions:secrets:set GOOGLE_BOOKS_API_KEY
```

#### Claude API Key
```bash
firebase functions:secrets:set CLAUDE_API_KEY
```

### 4. デプロイ
```bash
firebase deploy --only functions
```

## 関数一覧

### 書籍検索関連
- `searchBookByISBN` - ISBN検索
- `searchBooksByQuery` - キーワード検索
- `getPopularBooks` - 人気の本を取得
- `getRecentBooks` - 新着の本を取得
- `searchPublicBooks` - 公開本を検索

### AI関連
- `generateAIResponse` - チャットのAI応答を生成
- `generateBookSummary` - 読書メモの要約を生成

## 開発ガイド

### ローカル開発
```bash
npm run serve
```

### ログ確認
```bash
firebase functions:log
```

### 型チェック
```bash
npm run build
```

## 環境変数

以下の環境変数が必要です：

- `GOOGLE_BOOKS_API_KEY` - Google Books API のAPIキー
- `CLAUDE_API_KEY` - Anthropic Claude API のAPIキー

これらはFirebase Secret Managerで管理されます。
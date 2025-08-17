# Cloud Functions デプロイメントガイド

## 前提条件
1. Firebase CLIがインストールされていること
2. Firebase プロジェクトにログインしていること
3. 適切な権限（Cloud Functions Admin）を持っていること

## デプロイ手順

### 1. Firebase にログイン
```bash
firebase login
```

### 2. プロジェクトを選択
```bash
firebase use reading-memory
```

### 3. 依存関係のインストール
```bash
make install
```

### 4. ビルドとリント
```bash
make lint
make build
```

### 5. デプロイ
```bash
make deploy
```

または、すべてを一度に実行:
```bash
make safe-deploy
```

## デプロイ後の確認

### 1. Firebase Console で確認
1. [Firebase Console](https://console.firebase.google.com) にアクセス
2. プロジェクトを選択
3. Functions セクションで `searchBookByISBN` が表示されることを確認

### 2. ログの確認
```bash
make functions-logs
```

### 3. ローカルテスト（エミュレータ）
```bash
make functions-serve
```

## トラブルシューティング

### 権限エラーが出る場合
```bash
firebase login --reauth
```

### デプロイが失敗する場合
1. Node.js バージョンを確認（v20が必要）
2. Firebase CLI を最新版に更新
```bash
npm install -g firebase-tools@latest
```

### リージョンエラー
Functions は `asia-northeast1` にデプロイされます。
プロジェクトの設定でこのリージョンが有効になっていることを確認してください。

## 環境変数（必要な場合）
現在の実装では環境変数は不要ですが、将来的に必要になった場合:
```bash
firebase functions:config:set someservice.key="THE_API_KEY"
```
# Cloud Run デプロイ手順

## 前提条件
1. Google Cloud SDK (gcloud) がインストールされていること
2. 適切なGCPプロジェクトへのアクセス権限があること
3. Secret Managerに必要なシークレットが設定されていること

## 手動デプロイ手順

### 1. GCPリソースのセットアップ (初回のみ)
```bash
./setup-gcp.sh
```

このスクリプトで以下が実行されます：
- サービスアカウントの作成
- 必要なIAMロールの付与
- Secret Managerへのシークレット登録

### 2. Cloud Runへのデプロイ
```bash
./deploy.sh
```

このスクリプトで以下が実行されます：
- Dockerイメージのビルド
- Container Registryへのプッシュ
- Cloud Runへのデプロイ

## 自動デプロイ (CI/CD)

`cloudbuild.yaml`が用意されているため、GitHubへのプッシュ時に自動的にデプロイすることも可能です。

### Cloud Buildトリガーの設定
1. GCP ConsoleでCloud Buildトリガーを作成
2. GitHubリポジトリと連携
3. `api/cloudbuild.yaml`を使用するよう設定

## 環境変数とシークレット

### 環境変数
- `NODE_ENV`: production
- `GCP_PROJECT_ID`: プロジェクトID

### Secret Manager
以下のシークレットが必要です：
- `GOOGLE_BOOKS_API_KEY`: Google Books APIキー
- `CLAUDE_API_KEY`: Claude APIキー

## エンドポイント

デプロイ後、以下のエンドポイントが利用可能になります：

- Health Check: `GET /health`
- AI応答生成: `POST /api/v1/users/:userId/books/:userBookId/ai-response`
- 要約生成: `POST /api/v1/users/:userId/books/:userBookId/summary`
- ISBN検索: `GET /api/v1/books/search/isbn/:isbn`
- キーワード検索: `GET /api/v1/books/search?q=:query`
- 人気の本: `GET /api/v1/public/books/popular`
- 新着の本: `GET /api/v1/public/books/recent`
- 公開本検索: `GET /api/v1/public/books/search?q=:query`
- アカウント削除: `DELETE /api/v1/users/me`

## トラブルシューティング

### ログの確認
```bash
gcloud run logs read --service reading-memory-api --region asia-northeast1
```

### サービスの状態確認
```bash
gcloud run services describe reading-memory-api --region asia-northeast1
```

### 手動でのDockerイメージビルドとプッシュ
```bash
# ビルド
docker build -t gcr.io/reading-memory-429401/reading-memory-api .

# プッシュ
docker push gcr.io/reading-memory-429401/reading-memory-api
```
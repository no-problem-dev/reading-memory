# Reading Memory API

読書メモリーアプリのREST APIサーバー（Cloud Run）

## 概要

このAPIは、読書メモリーアプリのバックエンドサービスです。Firebase Cloud Functionsから移行し、Cloud Run上で動作するDockerコンテナとして実装されています。

## 主な機能

- **認証**: Firebase IDトークンによる認証
- **AI応答生成**: Claude APIを使用した読書メモへのAI応答
- **書籍検索**: Google Books APIを使用した書籍検索
- **公開本管理**: 公開された本の検索・取得
- **アカウント管理**: ユーザーアカウントの削除

## エンドポイント

### AI関連
- `POST /api/v1/users/:userId/books/:userBookId/ai-response` - AI応答生成
- `POST /api/v1/users/:userId/books/:userBookId/summary` - 要約生成

### 書籍検索
- `GET /api/v1/books/search/isbn/:isbn` - ISBN検索
- `GET /api/v1/books/search?q=:query` - キーワード検索

### 公開本
- `GET /api/v1/public/books/popular` - 人気の本
- `GET /api/v1/public/books/recent` - 新着の本
- `GET /api/v1/public/books/search?q=:query` - 公開本検索

### ユーザー管理
- `DELETE /api/v1/users/me` - アカウント削除

## 開発環境のセットアップ

```bash
# 依存関係のインストール
cd api
npm install

# 環境変数の設定
cp .env.example .env
# .envファイルを編集して必要な環境変数を設定

# 開発サーバーの起動
npm run dev
```

## ビルドとデプロイ

```bash
# TypeScriptのビルド
npm run build

# Dockerイメージのビルド（ローカル）
docker build -t reading-memory-api .

# Cloud Runへのデプロイ
./deploy.sh
```

## 環境変数

- `NODE_ENV`: 実行環境（development/production）
- `PORT`: サーバーポート（デフォルト: 8080）
- `GOOGLE_BOOKS_API_KEY`: Google Books APIキー
- `CLAUDE_API_KEY`: Claude APIキー
- `GCP_PROJECT_ID`: GCPプロジェクトID
- `FIREBASE_SERVICE_ACCOUNT_KEY`: Firebaseサービスアカウントキー（開発環境のみ）

## 認証

全てのAPIエンドポイント（公開本関連を除く）は、Firebase IDトークンによる認証が必要です。

```
Authorization: Bearer {idToken}
```

## エラーレスポンス

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ"
  }
}
```

## モニタリング

```bash
# ログの確認
gcloud run logs read --service reading-memory-api --region asia-northeast1

# メトリクスの確認
gcloud run services describe reading-memory-api --region asia-northeast1
```
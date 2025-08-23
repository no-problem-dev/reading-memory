# Cloud Functions to REST API Migration

## 完了日
2025-08-23

## 概要
Firebase Cloud FunctionsからGoogle Cloud Run上のREST APIへの全面移行を完了しました。

## 主な変更点

### 1. バックエンドAPI実装
- **技術スタック**: Express.js + TypeScript
- **認証方式**: Firebase ID Token認証
- **デプロイ先**: Google Cloud Run
- **コンテナ化**: Docker multi-stage build
- **APIベースURL**: https://reading-memory-api-ehel5nxm2q-an.a.run.app

### 2. 実装されたエンドポイント

#### AI関連
- `POST /api/v1/users/:userId/books/:userBookId/ai-response` - AI応答生成
- `POST /api/v1/users/:userId/books/:userBookId/summary` - 要約生成

#### 書籍検索
- `GET /api/v1/books/search/isbn/:isbn` - ISBN検索
- `GET /api/v1/books/search?q=:query` - キーワード検索

#### 公開本棚
- `GET /api/v1/public/books/popular` - 人気の本
- `GET /api/v1/public/books/recent` - 最近の本
- `GET /api/v1/public/books/search?q=:query` - 公開本検索

#### アカウント管理
- `DELETE /api/v1/users/me` - アカウント削除

### 3. iOS クライアント変更
- 新しい`APIClient`クラスを実装
- 全てのCloud Functions呼び出しをREST API呼び出しに置き換え
- `CloudFunctionsService`を完全に削除
- エラーハンドリングの改善

### 4. インフラストラクチャ設定

#### Docker設定
```dockerfile
# Multi-stage build for optimized production image
FROM node:20-alpine AS builder
# ... build stage
FROM node:20-alpine
# ... production stage with security best practices
```

#### Cloud Run設定
- サービス名: `reading-memory-api`
- リージョン: `asia-northeast1`
- メモリ: 512Mi
- 最小インスタンス: 0
- 最大インスタンス: 100

#### IAMロール
サービスアカウント `reading-memory-api-sa@reading-memory.iam.gserviceaccount.com` に付与：
- `roles/datastore.user`
- `roles/secretmanager.secretAccessor`
- `roles/storage.objectViewer`
- `roles/storage.objectCreator`
- `roles/firebase.auth.admin`
- `roles/serviceusage.serviceUsageConsumer`

### 5. セキュリティ設定
- Firebase Security Rulesは維持
- API側でFirebase ID Token検証を実装
- Helmetによるセキュリティヘッダー設定
- CORS設定でオリジン制限

### 6. 削除されたもの
- `/functions/src/functions/` 内の全Cloud Functions実装
- `/functions/src/index.ts` のエクスポート
- iOS側の `CloudFunctionsService.swift`
- デプロイ済みのCloud Functions

### 7. ローカル開発設定
- `API_BASE_URL`環境変数でローカル/本番切り替え可能
- ローカル: `http://localhost:8080`
- 本番: `https://reading-memory-api-ehel5nxm2q-an.a.run.app`

## 注意点
1. Cloud Functionsは完全に削除されたため、以前のエンドポイントは利用不可
2. 新しいREST APIは認証が必須（Firebase ID Token）
3. エラーレスポンスフォーマットが統一された

## Pull Request
https://github.com/no-problem-dev/reading-memory/pull/5

## 今後の推奨事項
1. Cloud Monitoringでのパフォーマンス監視設定
2. Error Reportingでのエラー追跡設定
3. CI/CDパイプラインの更新（Cloud Build）
4. 負荷テストの実施
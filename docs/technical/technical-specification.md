# 技術仕様書

> ミニマムで堅牢な技術アーキテクチャ

## システム構成

```
iOS App (SwiftUI + Firebase SDK)
    ↓
Firebase Services
├── Authentication (Google/Apple)
├── Firestore
├── Cloud Storage
└── Cloud Functions (TypeScript)
    └── Secret Manager (API Keys)
```

## 技術スタック

### フロントエンド
- **プラットフォーム**: iOS 17.0+
- **言語**: Swift 5.9+
- **フレームワーク**: SwiftUI
- **アーキテクチャ**: @Observable + DDD

### バックエンド
- **データベース**: Firebase Firestore
- **認証**: Firebase Authentication
- **ストレージ**: Cloud Storage
- **サーバーレス**: Cloud Functions (Node.js 20, TypeScript 5.0+)
- **AI**: Vertex AI / Gemini API

## アーキテクチャ設計

### クライアントアーキテクチャ（iOS）

```
Presentation Layer (SwiftUI Views)
    ↓
Application Layer (@Observable ViewModels)
    ↓
Domain Layer (Models, Business Logic)
    ↓
Infrastructure Layer (Firebase SDK)
```

### サーバーアーキテクチャ

```
Cloud Functions (TypeScript)
├── API Layer (HTTP Triggers)
├── Service Layer (Business Logic)
├── Repository Layer (Firestore Access)
└── External Services (Gemini API, Google Books API)
```

## 主要機能と実装方針

### 認証機能
- Firebase Authentication使用
- Google/Apple Sign-In対応
- 自動的なセッション管理
- リフレッシュトークンの自動更新

### データ同期
- Firestore のリアルタイム同期
- オフライン対応（標準キャッシュ機能）
- 楽観的更新によるUX向上

### 画像処理
- iOS側で圧縮（JPEG 80%品質）
- Cloud Storageへの直接アップロード
- サムネイルはCloud Functionsで生成

### AI機能
- Gemini API統合
- プロンプトエンジニアリング
- コンテキスト管理（本の情報含む）

## セキュリティ設計

### 認証・認可
- Firebase Security Rules による厳密なアクセス制御
- ユーザーごとのデータ分離
- APIキーはSecret Manager管理

### データ保護
- HTTPS通信のみ
- 個人情報の最小化
- 適切なCORS設定

### プライバシー
- ユーザーデータの分離
- 削除リクエストへの対応
- GDPRコンプライアンス考慮

## パフォーマンス最適化

### Firestore
- 複合インデックスの事前定義
- ページネーション（20件ずつ）
- リアルタイムリスナーの最小化

### 画像
- 遅延読み込み
- キャッシュ戦略（URLCache）
- 適切なサイズでの配信

### ネットワーク
- バッチ処理の活用
- 不要な通信の削減
- エラー時のリトライ戦略

## エラーハンドリング

### クライアント側
- Firebase SDKの標準エラー活用
- ユーザーフレンドリーなメッセージ
- オフライン時の適切な処理

### サーバー側
- 構造化ログ出力
- エラーの分類と通知
- 自動リトライメカニズム

## 監視とログ

### 監視ツール
- Firebase Crashlytics（クラッシュ）
- Firebase Analytics（ユーザー行動）
- Firebase Performance（パフォーマンス）
- Cloud Logging（サーバーログ）

### アラート設定
- エラー率の急増
- レスポンスタイムの劣化
- コスト超過警告

## 開発環境

### 必要なツール
- Xcode 15.0+
- Node.js 20+
- Firebase CLI
- TypeScript 5.0+

### 環境変数管理
- 開発/本番環境の分離
- Secret Managerの活用
- ローカル開発用の設定ファイル

## デプロイメント

### iOS アプリ
- TestFlight でのベータ配信
- App Store Connect での管理
- 段階的リリース戦略

### Cloud Functions
- Firebase CLI でのデプロイ
- 環境別のデプロイ設定
- ロールバック手順の確立

## スケーラビリティ

### 想定負荷
- 初年度: 50,000ユーザー
- 同時接続: 1,000ユーザー
- 月間API呼び出し: 500万回

### スケーリング戦略
- Cloud Functions の自動スケーリング
- Firestore の自動スケーリング
- CDN活用による静的コンテンツ配信

## コスト管理

### 無料枠の活用
- Firestore: 50,000読み取り/日
- Storage: 5GB保存
- Functions: 200万呼び出し/月

### コスト最適化
- 効率的なデータ構造
- キャッシュの積極活用
- 不要なデータの定期削除

## 技術的制約

### 制約事項
- Swift側はFirebase SDKのみ使用
- サードパーティライブラリ最小限
- ネイティブ機能の活用

### 将来の拡張性
- マイクロサービス化の準備
- API設計の標準化
- データ移行の考慮

## リスクと対策

### 技術的リスク
- **Firebase依存**: マルチクラウド対応の準備
- **API制限**: レート制限の実装
- **データ損失**: 定期バックアップ

### 運用リスク
- **スケーリング**: 自動スケーリングの活用
- **セキュリティ**: 定期的な監査
- **コスト超過**: アラートと制限設定
# 読書メモリー (Reading Memory) - Claude AI アシスタントガイド

## プロジェクト概要

**読書メモリー**は、本との出会いと対話を美しく記録し、読書体験を特別な思い出として残すiOSアプリです。

### ビジョン
「読んだ本すべてが、あなたの思い出になる」

### ミッション
本を愛する人々に、読書をもっと豊かで意味のある体験に変える

## 技術スタック

### フロントエンド
- **プラットフォーム**: iOS 17.0+
- **言語**: Swift 5.9+
- **UI フレームワーク**: SwiftUI
- **アーキテクチャ**: MVVM + Repository パターン
- **状態管理**: @Observable

### バックエンド
- **BaaS**: Firebase
  - Authentication (Google/Apple Sign-In)
  - Firestore (NoSQL データベース)
  - Cloud Storage (画像保存)

### API (Cloud Run)
- **言語**: TypeScript 5.0+
- **ランタイム**: Node.js 20+
- **フレームワーク**: Express.js
- **デプロイ**: Docker コンテナ on Cloud Run

### AI/外部API
- **AI**: Vertex AI / Gemini API
- **書籍情報**: Google Books API

## プロジェクト構造

```
reading-memory/
├── docs/                    # ドキュメント
│   ├── overview/           # プロジェクト概要
│   ├── technical/          # 技術仕様
│   ├── development/        # 開発ガイド
│   └── business/           # ビジネス関連
├── reading-memory-ios/      # iOS アプリ (SwiftUI)
│   ├── reading-memory-ios/  # メインアプリ
│   │   ├── Models/         # データモデル
│   │   ├── Views/          # SwiftUI ビュー
│   │   ├── ViewModels/     # ビューモデル
│   │   ├── Repositories/   # データアクセス層
│   │   ├── Services/       # ビジネスロジック
│   │   ├── DataAccess/     # DTO (Data Transfer Objects)
│   │   │   └── DTO/        # Firestore用データ変換
│   │   └── Utils/          # ユーティリティ
│   └── reading-memory-ios.xcodeproj
├── api/                    # REST API (Cloud Run)
│   ├── src/               # TypeScript ソース
│   │   ├── routes/        # APIルート定義
│   │   ├── services/      # サービス層
│   │   └── index.ts       # エントリーポイント
│   ├── package.json       # 依存関係
│   └── tsconfig.json      # TypeScript 設定
├── ci_scripts/            # CI/CD スクリプト
├── firestore.rules        # Firestore セキュリティルール
├── storage.rules          # Storage セキュリティルール
├── firebase.json          # Firebase 設定
├── firestore.indexes.json # Firestore インデックス
├── task-sheet.md          # タスク管理シート
├── CLAUDE.md              # このファイル
└── README.md              # プロジェクト概要
```

## 主要機能

### 実装済み機能
1. **本とおしゃべり** - チャット形式で気づきを記録（AI応答機能付き）
2. **メモリーシェルフ** - 美しいビジュアルで本棚を再現
3. **読書記録管理** - ステータス管理（読みたい/読書中/完了/DNF）
4. **読みたいリスト** - 優先度設定、読書予定日、リマインダー機能
5. **読書目標と習慣** - 月間/年間目標、読書ストリーク追跡
6. **アチーブメント** - バッジ獲得システム、実績管理
7. **書籍検索** - Google Books API/OpenBD統合検索、バーコードスキャン
8. **AI要約** - Claude APIによる読書メモの要約生成
9. **公開本棚** - 読書記録の選択的共有機能
10. **プロフィール** - ユーザープロフィール管理

### 将来機能
- 複数の本の知識を横断検索（RAG）
- 読書コミュニティ機能
- 読書分析の高度化

## コーディング規約

### Swift
```swift
// クラス・構造体: UpperCamelCase
struct BookMemory { }

// プロパティ・メソッド: lowerCamelCase
let bookTitle: String
func updateStatus(to newStatus: ReadingStatus) { }

// 列挙型: UpperCamelCase、ケース: lowerCamelCase
enum ReadingStatus {
    case wantToRead
    case reading
    case completed
    case dnf
}
```

### TypeScript
```typescript
// インターフェース: PascalCase
interface BookData { }

// 関数: camelCase
export const searchBooks = async () => { }

// 定数: UPPER_SNAKE_CASE
const MAX_SEARCH_RESULTS = 20;
```

## 開発ガイドライン

### 基本方針
1. **ミニマムスタート** - MVP から始めて段階的に機能追加
2. **ユーザー中心設計** - 読書体験の向上を最優先
3. **品質重視** - バグの少ない安定したアプリ

### コミットメッセージ
```
feat: 新機能追加
fix: バグ修正
docs: ドキュメント更新
refactor: リファクタリング
test: テスト追加・修正
style: コードスタイル修正
chore: ビルド設定など
```

### ブランチ戦略
- `main`: 本番環境
- `develop`: 開発環境
- `feature/*`: 機能開発
- `bugfix/*`: バグ修正
- `release/*`: リリース準備

## データモデル

### Firestore コレクション
- `users/{userId}` - ユーザー基本情報
- `userProfiles/{userId}` - プロフィール情報
- `books/{bookId}` - 本のマスターデータ（共有本のみ）
- `users/{userId}/books/{bookId}` - ユーザーごとの本
- `users/{userId}/books/{bookId}/chats/{chatId}` - チャットメモ
- `users/{userId}/goals/{goalId}` - 読書目標
- `users/{userId}/activities/{activityId}` - 読書活動記録
- `users/{userId}/achievements/{achievementId}` - 獲得アチーブメント
- `users/{userId}/streaks/{streakId}` - 読書ストリーク

## 重要な制約・仕様

### セキュリティ
- Firebase Security Rules で厳密なアクセス制御
- ユーザーは自分のデータのみアクセス可能
- APIキーは Secret Manager で管理

### パフォーマンス
- Firestore クエリは 20 件ずつページネーション
- 画像は JPEG 80% 品質で圧縮
- オフライン対応（Firestore キャッシュ）

### UI/UX
- チャット形式のメモは時系列で表示
- 評価は 0.5 刻み（0.5〜5.0）
- ステータス: 読みたい/読書中/完了/DNF

## よく使うコマンド

### iOS 開発
```bash
# プロジェクトを開く
cd reading-memory-ios
open reading-memory-ios.xcodeproj

# クリーンビルド
# Xcode で Cmd+Shift+K

# ビルド
# Xcode で Cmd+B

# 実行
# Xcode で Cmd+R
```

### REST API (Cloud Run)
```bash
cd api

# 依存関係インストール
npm install

# ローカルで実行
npm run dev

# Dockerビルド
docker build -t reading-memory-api .

# Cloud Runへデプロイ
gcloud run deploy reading-memory-api \
  --image asia-northeast1-docker.pkg.dev/reading-memory/reading-memory-api/reading-memory-api \
  --region asia-northeast1

# ログ確認
gcloud logging read "resource.type=cloud_run_revision"
```

### Firebase
```bash
# エミュレータ起動
firebase emulators:start

# Firestore ルールデプロイ
firebase deploy --only firestore:rules

# インデックスデプロイ
firebase deploy --only firestore:indexes
```

## トラブルシューティング

### よくある問題
1. **Firebase 認証エラー**: GoogleService-Info.plist の配置確認
2. **ビルドエラー**: Xcode のクリーンビルド（Cmd+Shift+K）
3. **API エラー**: 環境変数とSecret Managerの設定確認

## AI アシスタントへの指示

このプロジェクトで作業する際は、以下の点に注意してください：

1. **SwiftUI と @Observable パターンを使用**
   - iOS 17.0+ の最新機能を活用
   - Combine は使わず @Observable を使用

2. **Firebase SDK の直接使用**
   - サードパーティライブラリは最小限に
   - Firebase の標準機能を最大限活用

3. **エラーハンドリング**
   - ユーザーフレンドリーなメッセージ
   - 適切なローカライズ（日本語）

4. **テスト**
   - 新機能には必ずテストを追加
   - UI テストも重要視

5. **パフォーマンス**
   - 不要な再レンダリング回避
   - 適切なキャッシュ戦略

## 現在のフェーズ

**Phase 4: 読書目標・習慣機能完了**
- MVP開発は完了
- 基本的な読書記録機能：実装済み
- チャットメモ機能：実装済み（AI応答対応）
- 読みたいリスト機能：実装済み
- 読書目標・習慣トラッキング：実装済み
- アチーブメント機能：実装済み
- 詳細は task-sheet.md とメモリーファイルを参照

## 次のステップ

1. task-sheet.md のタスクを順次実装
2. 定期的にユーザーフィードバックを収集
3. 継続的な改善とイテレーション

## 連絡先・リソース

- プロジェクトオーナー: [あなたの名前]
- ドキュメント: `/docs` ディレクトリ
- タスク管理: `task-sheet.md`

---

*このドキュメントは Claude AI が効率的にプロジェクトを理解し、適切な支援を提供するためのガイドです。*
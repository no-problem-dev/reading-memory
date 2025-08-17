# セットアップ手順

## 前提条件

### 必要なツール
- macOS 13.0以上
- Xcode 15.0以上
- Node.js 20以上
- npm または yarn
- Firebase CLI
- Git

### アカウント
- Apple Developer アカウント
- Google Cloud Platform アカウント
- Firebase プロジェクト

## 1. リポジトリのクローン

```bash
git clone https://github.com/[your-username]/reading-memory.git
cd reading-memory
```

## 2. Firebase プロジェクトのセットアップ

### Firebase Console での作業

1. [Firebase Console](https://console.firebase.google.com) にアクセス
2. 新しいプロジェクトを作成
3. プロジェクト名: `reading-memory-[environment]` (例: reading-memory-dev)

### 有効化するサービス

- **Authentication**
  - Sign-in providers:
    - Google
    - Apple (要Apple Developer設定)
  
- **Firestore Database**
  - リージョン: asia-northeast1 (東京)
  - セキュリティルール: 開発中は一時的にテストモード

- **Storage**
  - リージョン: asia-northeast1
  - セキュリティルール: 認証ユーザーのみ

- **Functions**
  - リージョン: asia-northeast1
  - Node.js 20

## 3. iOS アプリのセットアップ

### Firebase設定ファイルの配置

1. Firebase Console > プロジェクト設定 > アプリを追加 > iOS
2. バンドルID: `com.readingmemory.app`
3. `GoogleService-Info.plist` をダウンロード
4. `ios/ReadingMemory/` に配置

### Xcodeでの設定

```bash
cd ios
open ReadingMemory.xcodeproj
```

1. **Bundle Identifier** の設定
2. **Signing & Capabilities** の設定
   - Team を選択
   - Sign in with Apple を追加

### 依存関係のインストール

Xcode で自動的に Swift Package Manager が動作します。

必要なパッケージ:
- Firebase iOS SDK

## 4. Cloud Functions のセットアップ

### 初期設定

```bash
cd functions
npm install
```

### 環境変数の設定

`.env.local` ファイルを作成:

```env
# Google Books API
GOOGLE_BOOKS_API_KEY=your_api_key_here

# Gemini API
GEMINI_API_KEY=your_api_key_here
```

### Firebase CLI の設定

```bash
# Firebase CLI のインストール（未インストールの場合）
npm install -g firebase-tools

# ログイン
firebase login

# プロジェクトの初期化
firebase use --add
# プロジェクトを選択してエイリアスを設定（例: dev）
```

## 5. 開発環境の起動

### Firebase Emulator の起動

```bash
# functions ディレクトリで
npm run serve
```

エミュレータが起動するポート:
- Firestore: http://localhost:8080
- Functions: http://localhost:5001
- Auth: http://localhost:9099

### iOS アプリの起動

1. Xcode でターゲットデバイスを選択
2. ⌘ + R で実行

開発中は自動的にエミュレータに接続されます。

## 6. データベースの初期設定

### セキュリティルールの適用

`firestore.rules`:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false;
    }
    
    match /userProfiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /books/{bookId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /userBooks/{userId}/books/{bookId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /chats/{chatId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

適用コマンド:
```bash
firebase deploy --only firestore:rules
```

### インデックスの作成

`firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "books",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "books",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "rating", "order": "DESCENDING" }
      ]
    }
  ]
}
```

適用コマンド:
```bash
firebase deploy --only firestore:indexes
```

## 7. 動作確認

### チェックリスト

- [ ] Google認証でログインできる
- [ ] プロフィール編集ができる
- [ ] 本の手動登録ができる
- [ ] チャットメモが保存される
- [ ] オフラインでも基本機能が動作する

## トラブルシューティング

### よくある問題

#### Firebase認証エラー
- `GoogleService-Info.plist` が正しく配置されているか確認
- Bundle IDが一致しているか確認

#### ビルドエラー
- Xcode のクリーンビルド: ⌘ + Shift + K
- Derived Data の削除

#### Functions のエラー
- Node.js のバージョン確認（20以上）
- 環境変数が正しく設定されているか確認

### デバッグ方法

#### iOS
- Xcode のコンソールログを確認
- ブレークポイントの活用

#### Cloud Functions
```bash
# ログの確認
firebase functions:log

# エミュレータのログ
# http://localhost:4000/logs
```

## 次のステップ

1. [開発ガイドライン](development-guide.md) を読む
2. 機能開発を開始
3. テストを書く
4. プルリクエストを作成
# データモデル設計

## Firestore コレクション構造

### users/{userId}
認証後に自動作成・基本変更なし

```typescript
interface User {
  id: string                    // Firebase Auth UID
  email: string
  provider: 'google' | 'apple'
  createdAt: Timestamp
  lastLoginAt: Timestamp
}
```

### userProfiles/{userId}
ユーザーが編集可能なプロフィール

```typescript
interface UserProfile {
  userId: string               // Firebase Auth UID
  displayName: string
  bio?: string                 // 自己紹介（最大200文字）
  photoUrl?: string           // Cloud Storage URL
  updatedAt: Timestamp
}
```

### books/{bookId}
本のマスターデータ（全ユーザー共通）

```typescript
interface Book {
  id: string
  isbn?: string
  title: string
  author: string
  publisher?: string
  publishedDate?: string
  defaultCoverUrl?: string    // Google Books API等から取得
  createdAt: Timestamp
}
```

### userBooks/{userId}/books/{userBookId}
ユーザーごとの本の記録

```typescript
interface UserBook {
  id: string
  userId: string
  bookId: string              // booksコレクションへの参照
  status: 'want_to_read' | 'reading' | 'completed' | 'dnf'
  rating?: number             // 0.5-5.0（0.5刻み）
  customCoverUrl?: string     // ユーザーがアップロードした表紙
  startedAt?: Timestamp
  completedAt?: Timestamp
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

### userBooks/{userId}/books/{userBookId}/chats/{chatId}
本に対するチャットメモ（サブコレクション）

```typescript
interface BookChat {
  id: string
  message: string
  type: 'text' | 'photo' | 'ai_response'
  photoUrl?: string           // 写真メッセージの場合
  createdAt: Timestamp
}
```

## Cloud Storage 構造

```
/users/{userId}/
  ├── profile.jpg              // プロフィール画像
  └── books/{userBookId}/
      ├── cover.jpg            // カスタム表紙
      └── photos/{photoId}.jpg // チャット添付写真
```

## データ設計の原則

### 1. 正規化 vs 非正規化
- **正規化**: 本のマスターデータ（books）
- **非正規化**: ユーザー固有のデータ（userBooks）
- パフォーマンスを考慮した適切なバランス

### 2. セキュリティ
- ユーザーごとのデータ分離
- Security Rules による厳密なアクセス制御
- 個人情報の最小化

### 3. スケーラビリティ
- サブコレクションによる効率的なクエリ
- 適切なインデックス設計
- ドキュメントサイズの制限考慮（1MB）

## インデックス設計

### 複合インデックス（必須）

```
Collection: userBooks/{userId}/books
- status ASC, createdAt DESC
- status ASC, rating DESC
- status ASC, updatedAt DESC
```

### 単一フィールドインデックス（自動）
- createdAt
- updatedAt
- status
- rating

## データ操作パターン

### 本の登録フロー
1. booksコレクションを検索
2. 存在しない場合は新規作成
3. userBooksにユーザー固有のデータを作成

### チャットメモの追加
1. userBooks/{userId}/books/{userBookId}の存在確認
2. chatsサブコレクションに追加
3. 親ドキュメントのupdatedAtを更新

### 統計情報の取得
1. userBooksコレクションをstatus別に集計
2. 必要に応じてCloud Functionsでキャッシュ
3. リアルタイム更新は最小限に

## データ移行戦略

### バージョン管理
- スキーマバージョンフィールドの追加
- 後方互換性の維持
- 段階的な移行プロセス

### バックアップ
- 日次自動バックアップ
- ポイントインタイムリカバリ
- エクスポート機能の提供

## パフォーマンス考慮事項

### 読み取り最適化
- 頻繁にアクセスされるデータのキャッシュ
- 適切なページネーション（20件ずつ）
- 不要なリアルタイムリスナーの回避

### 書き込み最適化
- バッチ書き込みの活用
- トランザクションの適切な使用
- 楽観的更新によるUX向上

## データ分析用の設計

### 集計データ
- 日次/月次の読書統計
- ジャンル別の分析
- 読書ペースの追跡

### プライバシー配慮
- 個人を特定できない形での集計
- オプトアウトの提供
- データ保持期間の明確化
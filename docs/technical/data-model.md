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
  avatarUrl?: string          // Cloud Storage URL
  isPublic: boolean           // プロフィールの公開設定
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

### books/{bookId}
本のマスターデータ（公開本のみ、全ユーザー共通）

```typescript
interface Book {
  id: string
  isbn?: string
  title: string
  author: string
  publisher?: string
  publishedDate?: Date
  pageCount?: number
  description?: string
  coverImageUrl?: string      // Google Books API等から取得
  dataSource: 'google' | 'openbd' | 'manual'
  visibility: 'public' | 'private'
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

### users/{userId}/books/{bookId}
ユーザーごとの本の記録

```typescript
interface Book {
  id: string
  userId: string
  bookId?: string              // 公開本の場合のみ（booksコレクションへの参照）
  manualBookData?: ManualBookData  // 手動入力本の場合のみ
  
  // 非正規化データ（検索・表示の高速化）
  bookTitle: string
  bookAuthor: string
  bookCoverImageUrl?: string
  bookIsbn?: string
  
  // ユーザー個別データ
  status: 'want_to_read' | 'reading' | 'completed' | 'dnf'
  rating?: number             // 0.5-5.0（0.5刻み）
  readingProgress?: number    // 0.0-1.0
  currentPage?: number
  startDate?: Timestamp
  completedDate?: Timestamp
  memo?: string
  tags: string[]
  isPrivate: boolean
  
  // AI関連
  aiSummary?: string
  summaryGeneratedAt?: Timestamp
  
  // 読みたいリスト関連
  priority?: number           // 0が最高優先度
  plannedReadingDate?: Timestamp
  reminderEnabled: boolean
  purchaseLinks?: PurchaseLink[]
  addedToWantListDate?: Timestamp
  
  createdAt: Timestamp
  updatedAt: Timestamp
}

interface ManualBookData {
  title: string
  author: string
  isbn?: string
  publisher?: string
  publishedDate?: Date
  pageCount?: number
  description?: string
  coverImageUrl?: string
}

interface PurchaseLink {
  storeName: string
  url: string
}
```

### users/{userId}/books/{bookId}/chats/{chatId}
本に対するチャットメモ（サブコレクション）

```typescript
interface BookChat {
  id: string
  bookId: string
  userId: string
  message: string
  imageUrl?: string           // 添付画像
  chapterOrSection?: string   // 章・セクション
  pageNumber?: number         // ページ番号
  isAI: boolean              // AI応答かユーザーメモか
  createdAt: Timestamp
}
```

### users/{userId}/goals/{goalId}
読書目標

```typescript
interface ReadingGoal {
  id: string
  userId: string
  type: 'monthly' | 'yearly'
  targetBooks: number
  targetDate: Date
  completedBooks: number
  isActive: boolean
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

### users/{userId}/activities/{activityId}
読書活動記録

```typescript
interface ReadingActivity {
  id: string
  userId: string
  bookId: string
  activityType: 'started' | 'completed' | 'progress' | 'memo'
  date: Date
  details?: {
    progress?: number
    pagesRead?: number
    memoCount?: number
  }
  createdAt: Timestamp
}
```

### users/{userId}/achievements/{achievementId}
獲得アチーブメント

```typescript
interface Achievement {
  id: string
  userId: string
  badgeId: string
  unlockedAt: Date
  progress: number
  isCompleted: boolean
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

### users/{userId}/streaks/{streakId}
読書ストリーク

```typescript
interface ReadingStreak {
  id: string
  userId: string
  currentStreak: number
  longestStreak: number
  lastActivityDate: Date
  streakStartDate: Date
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

## Cloud Storage 構造

```
/users/{userId}/
  ├── profile.jpg              // プロフィール画像
  └── books/{bookId}/
      ├── cover.jpg            // カスタム表紙
      └── photos/{photoId}.jpg // チャット添付写真
```

## データ設計の原則

### 1. 正規化 vs 非正規化
- **正規化**: 本のマスターデータ（books）
- **非正規化**: ユーザー固有のデータ（books）
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
Collection: users/{userId}/books
- status ASC, createdAt DESC
- status ASC, rating DESC
- status ASC, updatedAt DESC
- status ASC, priority ASC
- status ASC, plannedReadingDate ASC
- isPrivate ASC, createdAt DESC

Collection: users/{userId}/books/{bookId}/chats
- createdAt DESC

Collection: users/{userId}/goals
- type ASC, isActive DESC
- isActive DESC, targetDate ASC

Collection: users/{userId}/activities
- date DESC
- bookId ASC, date DESC

Collection: users/{userId}/achievements
- isCompleted DESC, unlockedAt DESC
```

### 単一フィールドインデックス（自動）
- createdAt
- updatedAt
- status
- rating
- priority
- isPrivate

## データ操作パターン

### 本の登録フロー
1. Google Books API/OpenBDで書籍情報を検索
2. 公開本の場合:
   - booksコレクションを検索
   - 存在しない場合は新規作成（visibility: public）
3. 手動入力本の場合:
   - manualBookDataに情報を格納
4. users/{userId}/booksにユーザー固有のデータを作成

### チャットメモの追加
1. users/{userId}/books/{bookId}の存在確認
2. chatsサブコレクションに追加
3. 親ドキュメントのupdatedAtを更新
4. AI応答の場合はCloud Functions経由で処理

### 読書活動の記録
1. ステータス変更時にactivityを記録
2. ストリーク情報を更新
3. 目標の進捗を更新
4. アチーブメントの条件確認と解除

### 統計情報の取得
1. booksコレクションをstatus別に集計
2. activitiesから読書履歴を取得
3. goalsから目標進捗を取得
4. キャッシュの活用で高速化

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
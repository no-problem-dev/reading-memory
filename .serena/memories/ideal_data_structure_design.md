# 読書メモリー: 理想的なデータ構造設計（後方互換性を考慮しない場合）

## 設計原則
1. **単一責任原則**: 各コレクションは明確な責任を持つ
2. **非正規化の活用**: Firestoreの特性を活かし、読み取りパフォーマンスを優先
3. **シンプルさ**: 不要な抽象化を避ける
4. **スケーラビリティ**: ユーザー数が増えても問題ない構造

## 理想的なコレクション構造

### 1. users/{userId}/books/{bookId}
ユーザーの本棚（全ての書籍情報と読書記録を統合）

```typescript
interface UserBook {
  // 書籍基本情報（完全に非正規化）
  isbn?: string
  title: string
  author: string
  publisher?: string
  publishedDate?: Date
  pageCount?: number
  description?: string
  coverImageUrl?: string
  dataSource: 'manual' | 'google_books' | 'openbd' | 'rakuten_books'
  
  // 読書ステータス
  status: 'want_to_read' | 'reading' | 'completed' | 'dnf'
  rating?: number // 0.5-5.0
  readingProgress?: number // 0-100
  currentPage?: number
  
  // 読書日付
  addedDate: Date // 本棚に追加した日
  startDate?: Date
  completedDate?: Date
  lastReadDate?: Date
  
  // 読みたいリスト専用
  priority?: 1 | 2 | 3 | 4 | 5
  plannedReadingDate?: Date
  reminderEnabled: boolean
  purchaseLinks?: PurchaseLink[]
  
  // メモ・タグ
  memo?: string
  tags: string[]
  
  // AI要約
  aiSummary?: string
  summaryGeneratedAt?: Date
  
  // メタデータ
  createdAt: Date
  updatedAt: Date
}
```

### 2. users/{userId}/books/{bookId}/notes/{noteId}
読書メモ（チャット形式の記録）

```typescript
interface ReadingNote {
  type: 'user' | 'ai'
  content: string
  
  // オプション（将来の拡張用）
  pageNumber?: number
  chapter?: string
  quotedText?: string
  
  createdAt: Date
}
```

### 3. users/{userId}/reading_sessions/{sessionId}
読書セッション記録（読書習慣トラッキング用）

```typescript
interface ReadingSession {
  bookId: string
  bookTitle: string // 非正規化
  startTime: Date
  endTime: Date
  pagesRead: number
  
  // セッション中のメモ
  notes?: string[]
}
```

### 4. users/{userId}/goals/{goalId}
読書目標

```typescript
interface ReadingGoal {
  type: 'monthly' | 'yearly'
  year: number
  month?: number
  targetBooks: number
  targetPages: number
  
  // 進捗（定期的に更新）
  completedBooks: number
  completedPages: number
  
  createdAt: Date
  updatedAt: Date
}
```

### 5. users/{userId}/stats
統計情報（事前計算された集計データ）

```typescript
interface UserStats {
  // 全期間統計
  totalBooks: number
  totalPages: number
  averageRating: number
  
  // ジャンル別統計
  genreStats: Map<string, GenreStats>
  
  // 月別統計
  monthlyStats: Map<string, MonthlyStats>
  
  // ストリーク
  currentStreak: number
  longestStreak: number
  lastReadDate: Date
  
  // アチーブメント
  achievements: Achievement[]
  
  updatedAt: Date
}
```

## 削除されるコレクション
- `books` (共有本マスター) → 削除
- `userProfiles` の `isPublic` → 削除
- 複雑な参照関係 → 削除

## メリット

### 1. シンプルさ
- 1ユーザーの全データが `/users/{userId}` 配下に集約
- 参照なしで必要な情報に直接アクセス可能
- bookIdやmanualBookDataのような条件分岐が不要

### 2. パフォーマンス
- 書籍一覧表示で追加のクエリ不要
- 全ての情報が非正規化されているため高速
- インデックスも単純化

### 3. 開発効率
- モデルがシンプルになり、バグが減る
- 新機能追加時の影響範囲が明確
- テストが書きやすい

### 4. スケーラビリティ
- ユーザー間でデータが完全に独立
- 水平分割が容易
- 読み取り/書き込みの競合なし

## 移行戦略

### Phase 1: 新規登録を新構造に
1. 新しいUserBookモデルを作成
2. 新規登録は新構造のみに保存
3. 既存データは旧構造のまま

### Phase 2: 既存データの移行
1. バッチ処理で既存のUserBook + Bookを新構造に変換
2. 移行フラグで管理
3. 両構造を並行稼働

### Phase 3: 旧構造の削除
1. 全データ移行確認
2. 旧コード削除
3. Firestoreから旧コレクション削除

## セキュリティルール（シンプル化）

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## まとめ
この設計により、読書メモリーは真にパーソナルな読書管理アプリとなり、複雑な共有機能や参照関係から解放されます。データ構造がシンプルになることで、開発速度と品質の両方が向上します。
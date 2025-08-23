# 読書メモリー: 理想的データ構造への移行実装方針

## 現状分析結果

### 依存関係マップ
1. **BookRepository**
   - booksコレクションへのCRUD操作
   - searchPublicBooks, getPopularBooks等の公開機能

2. **UserBookRepository**
   - userBooksコレクションへのCRUD操作
   - bookIdでBookを参照（正規化構造）
   - manualBookDataで手動登録本の情報保持

3. **BookChatRepository**
   - users/{userId}/userBooks/{userBookId}/chats への操作

4. **依存するViewModel/View**
   - BookRegistrationViewModel: Book作成 → UserBook作成の2段階
   - BookSearchViewModel: 公開本検索機能
   - BookShelfViewModel: UserBook取得のみ
   - PublicBookshelfView/ViewModel: 公開本閲覧機能

### API構造
- `/api/v1/books/*`: 外部API検索（Google Books等）
- `/api/v1/public/*`: 公開本の検索・取得
- `/api/v1/users/*`: ユーザー関連（AI応答、アカウント管理）

## 移行実装方針

### Phase 1: 新UserBookモデルの実装（後方互換性維持）

#### 1.1 新しいUserBookV2モデル作成
```swift
struct UserBookV2: Codable, Identifiable {
    // 基本識別子
    let id: String
    let userId: String
    
    // 書籍情報（完全非正規化）
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: Date?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    let dataSource: BookDataSource
    
    // 読書ステータス
    let status: ReadingStatus
    let rating: Double?
    let readingProgress: Double?
    let currentPage: Int?
    
    // 日付管理
    let addedDate: Date // 本棚追加日
    let startDate: Date?
    let completedDate: Date?
    let lastReadDate: Date?
    
    // 読みたいリスト機能
    let priority: Int?
    let plannedReadingDate: Date?
    let reminderEnabled: Bool
    let purchaseLinks: [PurchaseLink]?
    
    // メモ・タグ
    let memo: String?
    let tags: [String]
    
    // AI要約
    let aiSummary: String?
    let summaryGeneratedAt: Date?
    
    // メタデータ
    let createdAt: Date
    let updatedAt: Date
    
    // 移行フラグ
    let version: Int = 2
    let migratedFromBookId: String? // 旧構造からの移行時に設定
}
```

#### 1.2 新しいUserBookRepositoryV2作成
- 新構造への読み書き
- 旧構造からの透過的な読み取り（移行期間中）

### Phase 2: ViewModelの段階的更新

#### 2.1 BookRegistrationViewModel改修
```swift
// 新実装
func registerBook(_ book: Book, status: ReadingStatus) async throws {
    // UserBookV2として直接保存（Bookコレクションは使わない）
    let userBookV2 = UserBookV2.from(book: book, userId: userId, status: status)
    try await userBookRepositoryV2.create(userBookV2)
}
```

#### 2.2 既存ViewModelのRepository切り替え
- Feature Flagで新旧切り替え可能に
- 段階的にUserBookRepositoryV2へ移行

### Phase 3: 公開機能の削除

#### 3.1 iOS側
1. PublicBookshelfView/ViewModel削除
2. BookShelfViewから公開本棚への遷移削除
3. BookSearchViewModelの公開検索メソッド削除
4. APIClientの公開系メソッド削除

#### 3.2 API側
1. public.routes.ts削除
2. public.controller.ts削除
3. app.tsから公開ルート削除

### Phase 4: データ移行

#### 4.1 バッチ移行スクリプト
```typescript
async function migrateUserBooks() {
  const users = await getUsers();
  
  for (const user of users) {
    const userBooks = await getUserBooks(user.uid);
    
    for (const userBook of userBooks) {
      if (userBook.version === 2) continue; // 既に移行済み
      
      let bookData;
      if (userBook.bookId) {
        // Bookコレクションから情報取得
        bookData = await getBook(userBook.bookId);
      } else if (userBook.manualBookData) {
        // 手動登録データから変換
        bookData = userBook.manualBookData;
      }
      
      // UserBookV2形式に変換
      const userBookV2 = convertToV2(userBook, bookData);
      await saveUserBookV2(user.uid, userBookV2);
    }
  }
}
```

### Phase 5: クリーンアップ

1. 旧モデル・リポジトリの削除
2. Bookコレクション関連コードの削除
3. Firestoreルールの簡素化

## 実装順序とタイムライン

### Week 1-2: 準備フェーズ
- [ ] UserBookV2モデル設計・実装
- [ ] UserBookRepositoryV2実装
- [ ] Feature Flag設定

### Week 3-4: 新規登録の切り替え
- [ ] BookRegistrationViewModelを新構造対応
- [ ] 新規登録はすべてV2形式で保存

### Week 5-6: 公開機能削除
- [ ] iOS側の公開画面・機能削除
- [ ] API側の公開エンドポイント削除

### Week 7-8: 既存データ移行
- [ ] 移行スクリプト実装・テスト
- [ ] 段階的なユーザーデータ移行

### Week 9-10: クリーンアップ
- [ ] 旧コード削除
- [ ] ドキュメント更新
- [ ] パフォーマンステスト

## リスクと対策

### リスク1: データ不整合
- 対策: 移行フラグとバージョン管理で二重移行防止

### リスク2: パフォーマンス低下
- 対策: 非正規化によりクエリ数は減少、インデックス最適化

### リスク3: アプリクラッシュ
- 対策: Feature Flagで段階的ロールアウト

## 成功指標

1. **技術指標**
   - クエリ数: 50%削減
   - 画面表示速度: 30%向上
   - コード行数: 20%削減

2. **品質指標**
   - クラッシュ率: 0.1%以下維持
   - エラー率: 増加なし

3. **開発効率**
   - 新機能開発速度: 向上
   - バグ修正時間: 短縮
# 開発ガイドライン

## 開発理念

### ミニマムスタート
- 必要最小限の機能から開始
- 早期リリースとフィードバック重視
- 段階的な機能追加

### 品質重視
- バグの少ない安定したアプリ
- 快適なユーザー体験
- 継続的な改善

## コーディング規約

### Swift（iOS）

#### 命名規則
```swift
// クラス・構造体: UpperCamelCase
struct BookMemory {
    // プロパティ・メソッド: lowerCamelCase
    let bookTitle: String
    var readingStatus: ReadingStatus
    
    func updateStatus(to newStatus: ReadingStatus) {
        // ...
    }
}

// 列挙型: UpperCamelCase
enum ReadingStatus {
    case wantToRead
    case reading
    case completed
    case dnf
}
```

#### SwiftUIビューの構成
```swift
struct BookDetailView: View {
    @Observable var viewModel: BookDetailViewModel
    
    var body: some View {
        VStack {
            headerSection
            chatSection
            actionButtons
        }
    }
    
    // セクションごとに分割
    private var headerSection: some View {
        // ...
    }
}
```

### TypeScript（Cloud Functions）

#### 命名規則
```typescript
// インターフェース: PascalCase with 'I' prefix
interface IBookData {
    id: string;
    title: string;
    author: string;
}

// 関数: camelCase
export const searchBooks = functions.https.onCall(async (data, context) => {
    // ...
});

// 定数: UPPER_SNAKE_CASE
const MAX_SEARCH_RESULTS = 20;
```

## アーキテクチャパターン

### iOS: MVVM + Repository

```swift
// View
struct BookListView: View {
    @StateObject private var viewModel = BookListViewModel()
}

// ViewModel
@Observable
class BookListViewModel {
    private let repository: BookRepository
    var books: [Book] = []
    
    func loadBooks() async {
        books = await repository.fetchBooks()
    }
}

// Repository
protocol BookRepository {
    func fetchBooks() async -> [Book]
}

class FirebaseBookRepository: BookRepository {
    func fetchBooks() async -> [Book] {
        // Firestore access
    }
}
```

### Cloud Functions: レイヤードアーキテクチャ

```typescript
// Controller Layer
export const searchBooks = functions.https.onCall(async (data, context) => {
    const service = new BookSearchService();
    return await service.search(data.query);
});

// Service Layer
class BookSearchService {
    private repository: BookRepository;
    
    async search(query: string): Promise<Book[]> {
        // Business logic
    }
}

// Repository Layer
class BookRepository {
    async findByQuery(query: string): Promise<Book[]> {
        // Firestore access
    }
}
```

## エラーハンドリング

### iOS
```swift
enum BookError: LocalizedError {
    case networkError
    case notFound
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .notFound:
            return "本が見つかりませんでした"
        case .unauthorized:
            return "認証が必要です"
        }
    }
}

// 使用例
do {
    let books = try await repository.fetchBooks()
} catch {
    // エラー表示
    showError(error)
}
```

### Cloud Functions
```typescript
import { HttpsError } from 'firebase-functions/v2/https';

// エラーをスロー
throw new HttpsError('not-found', '本が見つかりませんでした');

// エラーハンドリング
try {
    const result = await bookService.search(query);
    return { success: true, data: result };
} catch (error) {
    console.error('Search error:', error);
    throw new HttpsError('internal', 'エラーが発生しました');
}
```

## テスト方針

### ユニットテスト
- ビジネスロジックのテスト
- ViewModelのテスト
- Repositoryのモックを使用

### 統合テスト
- Firebase Emulatorを使用
- エンドツーエンドのフロー確認

### UIテスト
- 主要な画面遷移
- 重要な機能の動作確認

## Git運用

### ブランチ戦略
```
main
├── develop
│   ├── feature/add-chat-function
│   ├── feature/implement-search
│   └── bugfix/fix-login-error
└── release/v1.0.0
```

### コミットメッセージ
```
feat: チャット機能を追加
fix: ログインエラーを修正
docs: READMEを更新
refactor: BookRepositoryをリファクタリング
test: BookViewModelのテストを追加
```

## セキュリティベストプラクティス

### 認証・認可
- Firebase Authenticationの適切な使用
- Security Rulesの厳密な設定
- トークンの適切な管理

### データ保護
- 個人情報の最小化
- 適切な暗号化
- セキュアな通信

### APIキー管理
- Secret Managerの使用
- 環境変数での管理
- ハードコーディング禁止

## パフォーマンス最適化

### iOS
- 画像の遅延読み込み
- 不要な再レンダリングの回避
- メモリリークの防止

### Cloud Functions
- コールドスタートの最小化
- 効率的なクエリ
- 適切なインデックス設計

## デバッグとログ

### iOS
```swift
// Debug時のみ出力
#if DEBUG
print("Debug: \(books.count) books loaded")
#endif

// Crashlyticsログ
Crashlytics.crashlytics().log("User action: opened book detail")
```

### Cloud Functions
```typescript
// 構造化ログ
console.log({
    severity: 'INFO',
    message: 'Book search completed',
    query: query,
    resultCount: results.length
});
```

## リリースプロセス

### 1. 機能開発完了
- コードレビュー
- テスト実行
- ドキュメント更新

### 2. リリース準備
- バージョン番号更新
- リリースノート作成
- 最終動作確認

### 3. デプロイ
- TestFlightでのベータ配信
- フィードバック収集
- App Store申請

## 継続的改善

### 監視項目
- クラッシュ率
- パフォーマンス指標
- ユーザーフィードバック

### 定期レビュー
- 週次でのバグ対応
- 月次での機能改善
- 四半期でのロードマップ見直し
# 読書メモリー アナリティクス設計

## 概要

読書メモリーアプリのユーザー行動分析とサービス改善のため、Firebase Analyticsを使用したアナリティクス基盤を構築します。

## 設計原則

1. **プライバシーファースト**: ユーザーの個人情報保護を最優先
2. **目的志向**: 意味のあるデータのみを収集
3. **パフォーマンス重視**: アプリのパフォーマンスに影響を与えない
4. **拡張性**: 将来の分析ニーズに対応できる設計

## アーキテクチャ

### 層構造

```
┌─────────────────────────────────────────┐
│          Views / ViewModels             │
├─────────────────────────────────────────┤
│        AnalyticsService (DI)            │
├─────────────────────────────────────────┤
│      Firebase Analytics SDK             │
└─────────────────────────────────────────┘
```

### AnalyticsService設計

```swift
// Analytics/AnalyticsEvent.swift
enum AnalyticsEvent {
    // スクリーン表示
    case screenView(screen: ScreenName)
    
    // ユーザーアクション
    case userAction(action: UserAction)
    
    // 書籍関連
    case bookEvent(event: BookEvent)
    
    // エラー
    case error(type: ErrorType, message: String)
}

enum ScreenName: String {
    case bookShelf = "book_shelf"
    case bookDetail = "book_detail"
    case bookChat = "book_chat"
    case discovery = "discovery"
    case searchBooks = "search_books"
    case wantToReadList = "want_to_read_list"
    case profile = "profile"
    case settings = "settings"
}

enum UserAction {
    case login(method: String)
    case logout
    case search(query: String, resultCount: Int)
    case filterApplied(filterType: String)
    case sortChanged(sortType: String)
}

enum BookEvent {
    case added(bookId: String, method: String)
    case statusChanged(bookId: String, from: String, to: String)
    case ratingChanged(bookId: String, rating: Double)
    case chatMessageSent(bookId: String, messageLength: Int)
    case summaryGenerated(bookId: String)
    case bookDeleted(bookId: String)
}

enum ErrorType: String {
    case network = "network_error"
    case authentication = "auth_error"
    case dataFetch = "data_fetch_error"
    case unknown = "unknown_error"
}
```

### AnalyticsService実装

```swift
// Analytics/AnalyticsService.swift
import FirebaseAnalytics
import FirebaseAuth
import FirebaseAnalyticsSwift

@MainActor
final class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private init() {
        // Firebase Analyticsの初期設定
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // SwiftUIでは自動screen_view収集が機能しないため、
        // 手動で管理することを明示
        #if DEBUG
        print("📊 Analytics: Manual screen tracking enabled for SwiftUI")
        #endif
    }
    
    // ユーザーIDの設定（ログイン時に呼び出し）
    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }
    
    // ユーザープロパティの設定
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    // イベントのトラッキング
    func track(_ event: AnalyticsEvent) {
        switch event {
        case .screenView(let screen):
            trackScreenView(screen)
        case .userAction(let action):
            trackUserAction(action)
        case .bookEvent(let bookEvent):
            trackBookEvent(bookEvent)
        case .error(let type, let message):
            trackError(type: type, message: message)
        }
    }
    
    private func trackScreenView(_ screen: ScreenName) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screen.rawValue,
            AnalyticsParameterScreenClass: "\(screen.rawValue)_view"
        ])
    }
    
    private func trackUserAction(_ action: UserAction) {
        switch action {
        case .login(let method):
            Analytics.logEvent(AnalyticsEventLogin, parameters: [
                AnalyticsParameterMethod: method
            ])
        case .logout:
            Analytics.logEvent("logout", parameters: nil)
        case .search(let query, let resultCount):
            Analytics.logEvent(AnalyticsEventSearch, parameters: [
                AnalyticsParameterSearchTerm: query,
                "result_count": resultCount
            ])
        case .filterApplied(let filterType):
            Analytics.logEvent("filter_applied", parameters: [
                "filter_type": filterType
            ])
        case .sortChanged(let sortType):
            Analytics.logEvent("sort_changed", parameters: [
                "sort_type": sortType
            ])
        }
    }
    
    private func trackBookEvent(_ event: BookEvent) {
        switch event {
        case .added(let bookId, let method):
            Analytics.logEvent("book_added", parameters: [
                "book_id": bookId,
                "method": method
            ])
        case .statusChanged(let bookId, let from, let to):
            Analytics.logEvent("book_status_changed", parameters: [
                "book_id": bookId,
                "from_status": from,
                "to_status": to
            ])
        case .ratingChanged(let bookId, let rating):
            Analytics.logEvent("book_rating_changed", parameters: [
                "book_id": bookId,
                "rating": rating
            ])
        case .chatMessageSent(let bookId, let messageLength):
            Analytics.logEvent("chat_message_sent", parameters: [
                "book_id": bookId,
                "message_length": messageLength
            ])
        case .summaryGenerated(let bookId):
            Analytics.logEvent("summary_generated", parameters: [
                "book_id": bookId
            ])
        case .bookDeleted(let bookId):
            Analytics.logEvent("book_deleted", parameters: [
                "book_id": bookId
            ])
        }
    }
    
    private func trackError(type: ErrorType, message: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_type": type.rawValue,
            "error_message": message
        ])
    }
}
```

### ServiceContainerへの統合

```swift
// ServiceContainer.swift に追加
@MainActor
private lazy var analyticsService = AnalyticsService.shared

@MainActor
func getAnalyticsService() -> AnalyticsService {
    return analyticsService
}
```

### 環境オブジェクトとしての配布

```swift
// MainTabView.swift で
@State private var analyticsService = ServiceContainer.shared.getAnalyticsService()

// body内で
.environment(analyticsService)
```

## SwiftUIとFirebase Analyticsの統合

### 自動収集の制限事項

Firebase AnalyticsはUIKitアプリケーションではscreen_viewイベントを自動収集しますが、SwiftUIでは以下の制限があります：

1. **Method Swizzlingの制限**: SwiftUIのビュー構造では自動収集が正しく機能しない
2. **ビューコントローラーの認識**: `NotifyingMulticolumnSplitViewController`のような内部クラスのみが認識される
3. **実際のビュー名の欠落**: SwiftUIビューの実際の名前が記録されない

### 推奨される実装方法

#### 1. `.analyticsScreen`モディファイアの使用（推奨）

```swift
struct BookShelfHomeView: View {
    var body: some View {
        NavigationView {
            // ビューの内容
        }
        .analyticsScreen(
            name: "book_shelf",
            class: "BookShelfHomeView"
        )
    }
}
```

#### 2. 手動ログ送信（既存アプローチ）

```swift
struct BookShelfHomeView: View {
    @Environment(AnalyticsService.self) private var analytics
    
    var body: some View {
        NavigationView {
            // ビューの内容
        }
        .onAppear {
            analytics.track(.screenView(screen: .bookShelf))
        }
    }
}
```

### 自動収集の無効化（オプション）

完全に手動管理したい場合は、`Info.plist`に以下を追加：

```xml
<key>FirebaseAutomaticScreenReportingEnabled</key>
<false/>
```

## 初期化フロー

1. **アプリ起動時**
   - Firebase Analytics SDK の初期化（App.swift）
   - AnalyticsServiceのインスタンス生成
   - 自動収集の設定確認

2. **ログイン成功時**
   - Firebase Auth UIDを使用してユーザーIDを設定
   - ユーザープロパティの設定（プレミアムステータスなど）

3. **ログアウト時**
   - ユーザーIDをクリア
   - ユーザープロパティをリセット

## プライバシーとセキュリティ

1. **収集しないデータ**
   - 個人を特定できる情報（メールアドレス、氏名）
   - 書籍の具体的な内容（チャットメッセージの本文）
   - 位置情報

2. **匿名化**
   - 書籍IDはFirestore上のIDを使用（ISBNは送信しない）
   - 検索クエリは集計目的のみ

3. **ユーザーコントロール**
   - 設定画面でアナリティクスのオプトアウト機能を提供（将来実装）

## テストとデバッグ

1. **デバッグモード**
   ```swift
   #if DEBUG
   Analytics.setAnalyticsCollectionEnabled(false) // デバッグ時は無効化も可能
   #endif
   ```

2. **DebugViewの使用**
   - Xcodeのスキーム設定で `-FIRDebugEnabled` を追加
   - Firebase ConsoleのDebugViewでリアルタイム確認

3. **screen_viewイベントの確認**
   - 自動収集と手動送信の両方が記録される場合がある
   - DebugViewで実際に送信されているイベントを確認
   - 重複がある場合は自動収集を無効化することを検討

## 今後の拡張性

1. **カスタムユーザープロパティ**
   - 読書傾向（ジャンル嗜好）
   - アクティビティレベル
   - 機能の利用頻度

2. **コンバージョンイベント**
   - プレミアムプランへのアップグレード
   - 特定機能の初回利用

3. **A/Bテスト**
   - Firebase Remote Configとの連携
   - UI/UXの最適化
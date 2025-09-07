# 読書メモリー アナリティクスイベント仕様書

## 概要

このドキュメントは、読書メモリーアプリの各画面と機能で送信されるアナリティクスイベントの仕様を定義します。

## イベント一覧

### 1. 本棚関連

#### BookShelfHomeView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "book_shelf" | 本棚画面の表示 |
| filter_applied | フィルター適用時 | filter_type: "all" / "reading" / "wantToRead" / "completed" / "dnf" | 読書ステータスフィルター |
| sort_changed | 並び替え変更時 | sort_type: "lastReadDate" / "registrationDate" / "title" / "author" | 並び替え方法の変更 |
| book_selected | 本選択時 | book_id: String, from_screen: "book_shelf" | 本棚から本を選択 |

#### BookDetailView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "book_detail", book_id: String | 本の詳細画面表示 |
| book_status_changed | ステータス変更時 | book_id: String, from_status: String, to_status: String | 読書ステータスの変更 |
| book_rating_changed | 評価変更時 | book_id: String, rating: Double, previous_rating: Double | 星評価の変更 |
| chat_opened | チャット開始時 | book_id: String | 「本とおしゃべり」へ遷移 |
| book_deleted | 本削除時 | book_id: String | 本の削除 |

#### BookChatView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "book_chat", book_id: String | チャット画面表示 |
| chat_message_sent | メッセージ送信時 | book_id: String, message_length: Int, has_ai_response: Bool | チャットメッセージ送信 |
| summary_generated | 要約生成時 | book_id: String, chat_count: Int | AI要約の生成 |
| chat_message_deleted | メッセージ削除時 | book_id: String, message_id: String | チャットメッセージ削除 |

### 2. 発見関連

#### DiscoveryView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "discovery" | 発見画面の表示 |
| tab_selected | タブ切り替え時 | tab_name: "want_to_read" / "search" | タブの選択 |

#### WantToReadListView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "want_to_read_list" | 読みたいリスト表示 |
| filter_applied | フィルター適用時 | filter_type: "high_priority" / "has_reminder" | フィルター適用 |
| book_selected | 本選択時 | book_id: String, from_screen: "want_to_read_list" | リストから本を選択 |
| priority_changed | 優先度変更時 | book_id: String, priority: "high" / "normal" / "low" | 優先度の変更 |
| reminder_set | リマインダー設定時 | book_id: String, reminder_date: String | リマインダー設定 |

#### SearchBooksView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "search_books" | 書籍検索画面表示 |
| search | 検索実行時 | search_term: String, result_count: Int, search_type: "manual" / "barcode" | 書籍検索 |
| book_added | 本追加時 | book_id: String, method: "manual_search" / "barcode_scan", source: "google_books" / "openbd" | 検索から本を追加 |
| barcode_scan | バーコードスキャン時 | success: Bool, isbn: String? | バーコードスキャン |

### 3. 設定関連

#### ProfileTabView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "profile" | プロフィール画面表示 |
| section_tapped | セクションタップ時 | section: "edit_profile" / "settings" / "subscription" / "help" / "feedback" | セクション選択 |
| logout | ログアウト時 | - | ログアウト |

#### EditProfileView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "edit_profile" | プロフィール編集画面 |
| profile_updated | 保存時 | has_display_name: Bool, has_bio: Bool, has_avatar: Bool | プロフィール更新 |
| avatar_changed | アバター変更時 | source: "camera" / "library" | アバター変更 |

#### SettingsView

| イベント名 | タイミング | パラメータ | 説明 |
|----------|---------|----------|-------|
| screen_view | 画面表示時 | screen_name: "settings" | 設定画面表示 |
| setting_changed | 設定変更時 | setting_name: String, value: Any | 設定変更 |
| export_data | データエクスポート時 | format: "csv" / "json" | データエクスポート |
| delete_account | アカウント削除時 | - | アカウント削除 |

### 4. エラーイベント

| イベント名 | タイミング | 僕の戦略として検索動線は結構重要だと考えてます。今多分検索した時とか本を追加した時とか、その辺で多分ログを出してないんではないかなと思います。なんでそのあたり実装してくださいちゃんとこのドキュメントさっき作ってもらったログ戦略アナリティクスイベント仕様書とちゃんと一緒になるようにログ作れてるかちゃんと確認してみてくださいパラメータ | 説明 |
|----------|---------|----------|-------|
| app_error | エラー発生時 | error_type: String, error_message: String, screen_name: String | アプリエラー |

## ユーザープロパティ

ログイン時に設定されるユーザープロパティ：

| プロパティ名 | 値 | 説明 |
|-------------|-----|-------|
| user_type | "free" / "premium" | ユーザータイプ |
| book_count | Int | 登録書籍数 |
| active_days | Int | アプリ利用日数 |
| has_profile | Bool | プロフィール設定有無 |

## 実装例

### 本棚画面での実装

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
        .onChange(of: selectedFilter) { _, newFilter in
            analytics.track(.userAction(.filterApplied(filterType: newFilter.rawValue)))
        }
    }
}
```

### 本追加時の実装

```swift
func addBook(bookInfo: BookInfo, method: String) async {
    do {
        let book = try await bookRepository.createBook(from: bookInfo)
        
        analytics.track(.bookEvent(.added(
            bookId: book.id,
            method: method
        )))
    } catch {
        analytics.track(.error(
            type: .dataFetch,
            message: "Failed to add book: \(error.localizedDescription)"
        ))
    }
}
```

## 送信タイミングのガイドライン

1. **画面表示**: `onAppear` モディファイアで送信
2. **ユーザーアクション**: アクション完了後すぐに送信
3. **エラー**: `catch` ブロック内で送信

## 注意事項

1. **SwiftUIでのscreen_view**:
   - Firebaseの自動screen_view収集はSwiftUIでは機能しない
   - 手動送信が必須（上述の`onAppear`または`.analyticsScreen`使用）
   - 自動収集と手動送信は別々に記録される（上書きではない）

2. **重複送信の回避**: 
   - 同一セッションでの重複送信を避ける
   - `onAppear`は状態変更時にも呼ばれるため注意

3. **パフォーマンス**: メインスレッドをブロックしない

4. **プライバシー**: 個人情報を含まない

5. **デバッグ**: 
   - 開発時はDebugViewで確認
   - 自動収集と手動送信の両方が表示される場合がある

## 更新履歴

- 2024-12-XX: 初版作成

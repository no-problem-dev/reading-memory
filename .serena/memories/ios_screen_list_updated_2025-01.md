# iOS画面一覧（2025年1月更新版）

## メイン画面
1. **MainTabView** - タブバー付きメインコンテナ
   - BookShelfHomeView（本棚タブ）
   - RecordsHubView（記録タブ）
   - DiscoveryView（発見タブ）
   - ProfileTabView（プロフィールタブ）

## 認証・オンボーディング
2. **AuthView** - 認証画面
3. **OnboardingView** - オンボーディングコンテナ
   - ProfileSetupStep - プロフィール設定
   - FirstBookStep - 最初の本登録
   - OnboardingBookSearchView - 本の検索
   - ChatExperienceStep - チャット体験
   - PreferencesStep - 設定

## 本棚関連
4. **BookShelfHomeView** - 本棚ホーム（リファクタリング済み）
   - Components/BookShelf/CurrentlyReadingSection
   - Components/BookShelf/CurrentReadingCard
   - Components/BookShelf/EmptyReadingCard
   - Components/BookShelf/MemoryShelfSection
   - Components/BookShelf/MemoryBookCover
5. **BookShelfView** - 本棚表示
6. **BookCoverView** - 本の表紙表示
7. **BookDetailView** - 本の詳細（リファクタリング済み）
   - Components/BookDetail/RatingSelector
   - Components/BookDetail/BookDetailHeroSection
   - Components/BookDetail/BookDetailActionButtons
   - Components/BookDetail/BookDetailStatusSection
   - Components/BookDetail/BookDetailAISummarySection
   - Components/BookDetail/BookDetailNotesSection
   - Components/BookDetail/BookDetailAdditionalInfo
8. **BookMemoryTabView** - 読書メモタブビュー（チャット/通常メモ）
9. **BookChatView** - 本とのチャット画面
10. **ChatContentView** - チャットコンテンツ表示
11. **ChatImageView** - チャット内画像表示
12. **BookNoteView** - 通常の読書メモ画面
13. **BookNoteContentView** - 読書メモコンテンツ表示
14. **BookRegistrationView** - 本の登録
15. **EditBookView** - 本の編集
16. **BookSearchView** - 本の検索（リファクタリング済み）
    - Components/BookSearch/BookSearchResultRow
    - Components/BookSearch/BookSearchBar
    - Components/BookSearch/BookSearchEmptyState
    - Components/BookSearch/BookSearchNoResults
    - Components/BookSearch/BookSearchLoadingView
17. **BookAdditionFlowView** - 本追加フロー
18. **BarcodeScannerView** - バーコードスキャナー

## 記録関連
19. **RecordsHubView** - 記録ハブ
20. **StatisticsView** - 統計画面
21. **GoalDashboardView** - 目標ダッシュボード
22. **GoalSettingView** - 目標設定
23. **AchievementGalleryView** - アチーブメントギャラリー
24. **BadgeDetailView** - バッジ詳細表示

## 発見関連
25. **DiscoveryView** - 発見画面
26. **WantToReadListView** - 読みたいリスト
27. **WantToReadDetailView** - 読みたい本の詳細
28. **WantToReadRowView** - 読みたい本の行表示

## プロフィール関連
29. **ProfileTabView** - プロフィールタブビュー
30. **ProfileView** - プロフィール表示
31. **ProfileEditView** - プロフィール編集
32. **ProfileSetupView** - プロフィール設定
33. **ProfileImageView** - プロフィール画像表示

## AI/要約関連
34. **SummaryView** - AI要約画面

## サブスクリプション関連
35. **PaywallView** - 課金画面

## コンポーネント
### 共通コンポーネント
- **RemoteImage** - リモート画像表示
- **CachedAsyncImage** - キャッシュ付き非同期画像
- **LoadingOverlay** - ローディングオーバーレイ
- **FlowLayout** - フローレイアウト
- **SplashScreenView** - スプラッシュ画面
- **FloatingActionButton** - フローティングアクションボタン

### チャット関連コンポーネント
- Components/Chat/（チャット関連コンポーネント）

### リファクタリング済みコンポーネント（2025年1月）
- Components/BookShelf/（5ファイル）
- Components/BookSearch/（5ファイル）
- Components/BookDetail/（7ファイル）

## 備考
- 2025年1月31日時点の情報
- BookShelfHomeView、BookSearchView、BookDetailViewを適切な粒度でコンポーネント分割済み
- BookCoverPlaceholderの重複を解消し、BookCoverView.swiftに統一
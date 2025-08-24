# iOS画面一覧

## メイン画面
1. **MainTabView** - タブバー付きメインコンテナ
   - BookShelfHomeView（本棚タブ）
   - RecordsHubView（記録タブ）
   - DiscoveryView（発見タブ）

## 認証・オンボーディング
2. **AuthView** - 認証画面
3. **OnboardingView** - オンボーディングコンテナ
   - ProfileSetupStep - プロフィール設定
   - FirstBookStep - 最初の本登録
   - OnboardingBookSearchView - 本の検索
   - ChatExperienceStep - チャット体験
   - PreferencesStep - 設定

## 本棚関連
4. **BookShelfHomeView** - 本棚ホーム
5. **BookShelfView** - 本棚表示
6. **BookCoverView** - 本の表紙表示
7. **BookDetailView** - 本の詳細
8. **BookChatView** - 本とのチャット画面
9. **BookRegistrationView** - 本の登録
10. **EditBookView** - 本の編集
11. **BookSearchView** - 本の検索
12. **BarcodeScannerView** - バーコードスキャナー

## 記録関連
13. **RecordsHubView** - 記録ハブ
14. **StatisticsView** - 統計画面
15. **GoalDashboardView** - 目標ダッシュボード
16. **GoalSettingView** - 目標設定
17. **AchievementGalleryView** - アチーブメントギャラリー

## 発見関連
18. **DiscoveryView** - 発見画面
19. **WantToReadListView** - 読みたいリスト
20. **WantToReadDetailView** - 読みたい本の詳細
21. **WantToReadRowView** - 読みたい本の行表示

## プロフィール関連
22. **ProfileNavigationView** - プロフィールナビゲーション
23. **ProfileView** - プロフィール表示
24. **ProfileEditView** - プロフィール編集
25. **ProfileSetupView** - プロフィール設定

## その他
26. **SettingsView** - 設定画面

## コンポーネント
- CachedAsyncImage - キャッシュ付き非同期画像
- ProfileIconView（MainTabView内で参照）
- FloatingActionButton（MainTabView内で参照）
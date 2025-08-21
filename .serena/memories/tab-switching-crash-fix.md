# タブ高速切り替え時のクラッシュ修正

## 問題
下タブを高速で切り替えると以下のエラーでクラッシュ:
```
Thread 33Thread 34 Queue : RPAC issue generation workloop (serial)
#0    0x00000001949801f8 in _CFRelease.cold.1 ()
```

## 原因
GoalViewModelで`loadGoals()` → `updateGoalProgress()` → `loadGoals()`の無限ループが発生し、複数スレッドで並行実行されてメモリ競合状態になっていた。

## 修正内容

### 1. BaseViewModelの拡張
```swift
// データ読み込み管理
private(set) var hasLoadedInitialData = false
private var loadTask: Task<Void, Never>?
private var lastDataFetch: Date?

// キャッシュ有効期限（デフォルト5分）
var cacheValidityDuration: TimeInterval = 300

func shouldRefreshData() -> Bool
func markDataAsFetched()
func executeLoadTask(_ action: @escaping () async -> Void) async
func forceRefresh()
```

### 2. GoalViewModelの修正
- 無限ループを解消（updateGoalProgressIfNeededメソッドを新設）
- タスクキャンセレーション対応
- ローカル更新で再取得を回避

### 3. 各ViewModelの最適化
- StatisticsViewModel: 期間変更時は再計算のみ
- ProfileViewModel: メモ数の遅延読み込み
- StreakViewModel: キャッシュ期間1分
- AchievementViewModel: キャッシュ期間10分

### 4. Viewの修正パターン
```swift
.task {
    // 初回のみデータを読み込む
    if !viewModel.hasLoadedInitialData {
        await viewModel.loadData()
    }
}
.refreshable {
    // プルリフレッシュ時は強制的に再取得
    viewModel.forceRefresh()
    await viewModel.loadData()
}
.onAppear {
    // タブ表示時はキャッシュ有効期限を確認
    if viewModel.hasLoadedInitialData && viewModel.shouldRefreshData() {
        Task {
            await viewModel.loadData()
        }
    }
}
```

## 結果
- クラッシュが解消
- パフォーマンスが大幅に向上
- 不要なデータ再取得を削減

## 関連PR
- https://github.com/no-problem-dev/reading-memory/pull/4
# Phase 4: 読書目標・習慣機能 基盤実装完了

## 実装日
2025年1月19日

## ブランチ
feature/reading-goals-habits

## 実装内容

### データモデル (5モデル)
1. **ReadingGoal**
   - 読書目標管理（年間/月間/四半期/カスタム）
   - 進捗計算、達成判定
   - createYearlyGoal/createMonthlyGoalヘルパー

2. **ReadingStreak**
   - ストリーク追跡（読書/メモ/複合）
   - 週間アクティビティ取得
   - ストリーク継続判定ロジック

3. **Achievement**
   - バッジ達成記録
   - 進捗管理（0.0-1.0）
   - 解除日時記録

4. **Badge**
   - バッジマスターデータ
   - カテゴリー（マイルストーン/ストリーク/ジャンル/特別）
   - デフォルトバッジ定義（9種類）

5. **ReadingActivity**
   - 日次アクティビティ記録
   - 本の読了数、メモ作成数
   - 日付ベースのID生成

### Repository層 (4リポジトリ)
- GoalRepository: 目標CRUD、進捗計算
- StreakRepository: ストリーク記録、UserProfile連携
- AchievementRepository: バッジ進捗チェック
- ActivityRepository: 日次記録、ストリーク自動更新

### ViewModel層 (3VM)
- GoalViewModel: 目標管理、推奨値計算
- StreakViewModel: ストリーク表示、アクティビティ統計
- AchievementViewModel: バッジ管理、カテゴリー分類

### UI実装 (2画面)
1. **GoalSettingView**
   - 年間/月間目標設定
   - スライダーでの直感的設定
   - 推奨値表示
   - 目標削除機能

2. **GoalDashboardView**
   - ストリーク表示（炎アイコン）
   - 目標進捗カード
   - 週間アクティビティ
   - 次に獲得可能なバッジ
   - 月間統計

### UserProfile拡張
- monthlyGoal: 月間目標
- streakStartDate: ストリーク開始日
- longestStreak: 最長ストリーク
- currentStreak: 現在のストリーク
- lastActivityDate: 最終活動日

## 技術的特徴
- @Observable パターン使用
- Firestore サブコレクション設計
- 非同期処理（async/await）
- リアルタイム進捗計算

## 残りのタスク
1. **既存機能との統合**
   - 本登録時のアクティビティ記録
   - チャットメモ作成時の記録
   - 統計画面への統合

2. **UI追加実装**
   - AchievementGalleryView（バッジギャラリー）
   - MainTabViewへの「目標」タブ追加
   - ProfileViewからの目標設定リンク

3. **ロジック実装**
   - バッジ判定の自動実行
   - 通知機能（ストリーク警告等）

## Firestore構造
```
/users/{userId}/
  - goals/{goalId}
  - streaks/{streakId}
  - achievements/{achievementId}
  - activities/{activityId}
/badges/{badgeId} // マスターデータ
```

## コミット
2376c75 - feat: 読書目標・習慣機能の基盤実装
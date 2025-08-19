# 読書目標・習慣機能設計 - Phase 4

## 実装日
2025年1月19日〜

## 設計概要
読書習慣形成とエンゲージメント向上を目的とした包括的な目標・習慣機能

## 主要機能
1. **読書目標設定**
   - 年間/月間目標
   - ジャンル別目標
   - カスタム期間目標

2. **ストリーク追跡**
   - 読書ストリーク（連続読書日数）
   - チャットメモストリーク
   - 週間アクティビティ表示

3. **達成バッジ**
   - マイルストーンバッジ
   - ストリークバッジ
   - ジャンルマスターバッジ
   - 特別イベントバッジ

4. **進捗可視化**
   - 目標達成率表示
   - 進捗グラフ
   - 月次/年次レポート

## データモデル
- ReadingGoal: 目標管理
- ReadingStreak: ストリーク管理
- Achievement: バッジ達成記録
- Badge: バッジマスターデータ
- ReadingActivity: 日次アクティビティ記録

## 実装計画
1. Phase 1: 基盤実装（2日）- データモデル、Repository
2. Phase 2: UI実装（3日）- 各種View
3. Phase 3: ロジック実装（2日）- 計算・判定処理
4. Phase 4: 統合とテスト（1日）

## 技術的特徴
- 既存のUserProfile.readingGoalを拡張
- StatisticsViewModelのストリーク計算を活用
- パフォーマンスを考慮した非同期処理
- 無料版/有料版の差別化

## Firestore構造
```
/users/{userId}/
  - goals/{goalId}
  - streaks/{streakId}
  - achievements/{achievementId}
  - activities/{activityId}
/badges/{badgeId}
```

## 成功指標
- DAU/MAU 10%向上
- 30日以上ストリーク達成者 20%
- 有料転換率 1%向上
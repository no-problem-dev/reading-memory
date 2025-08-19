# 読書目標・習慣機能 設計書

## 概要
読書メモリーのPhase 4における「目標・習慣機能」の設計と実装方針を定義します。本機能は、ユーザーの読書習慣形成と継続を支援し、エンゲージメントを高めることを目的とします。

## 機能要件

### 1. 読書目標設定機能
- 年間読書目標（冊数）
- 月間読書目標（冊数）
- ジャンル別目標
- カスタム期間目標（四半期、特定期間）

### 2. ストリーク追跡機能
- 読書ストリーク（連続読書日数）
- チャットメモストリーク（連続記録日数）
- 週間アクティビティ表示
- ストリーク通知とリマインダー

### 3. 達成バッジ機能
- マイルストーンバッジ（10冊、50冊、100冊等）
- ストリークバッジ（7日、30日、100日連続等）
- ジャンルマスターバッジ（特定ジャンル5冊以上等）
- 特別イベントバッジ（年間目標達成等）

### 4. 進捗可視化機能
- 目標達成率の視覚的表示
- 進捗グラフとトレンド
- 月次/年次レポート
- モチベーション維持のための予測機能

## データモデル設計

### 1. 拡張するモデル

#### UserProfile（既存モデルの拡張）
```swift
struct UserProfile {
    // 既存フィールド
    let readingGoal: Int? // 年間目標冊数
    
    // 新規追加フィールド
    let monthlyGoal: Int? // 月間目標冊数
    let genreGoals: [GenreGoal]? // ジャンル別目標
    let customGoals: [CustomGoal]? // カスタム目標
    let streakStartDate: Date? // ストリーク開始日
    let longestStreak: Int // 最長ストリーク記録
    let currentStreak: Int // 現在のストリーク
    let lastActivityDate: Date? // 最終アクティビティ日
}
```

### 2. 新規モデル

#### ReadingGoal
```swift
struct ReadingGoal: Identifiable, Codable {
    let id: String
    let userId: String
    let type: GoalType
    let targetValue: Int
    let currentValue: Int
    let period: GoalPeriod
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum GoalType: String, Codable {
        case bookCount = "bookCount"
        case readingDays = "readingDays"
        case genreCount = "genreCount"
        case custom = "custom"
    }
    
    enum GoalPeriod: String, Codable {
        case yearly = "yearly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case custom = "custom"
    }
}
```

#### ReadingStreak
```swift
struct ReadingStreak: Identifiable, Codable {
    let id: String
    let userId: String
    let type: StreakType
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: Date
    let streakDates: [Date] // 活動した日付の記録
    let createdAt: Date
    let updatedAt: Date
    
    enum StreakType: String, Codable {
        case reading = "reading" // 読書した日
        case chatMemo = "chatMemo" // メモを書いた日
        case combined = "combined" // いずれかの活動
    }
}
```

#### Achievement（達成バッジ）
```swift
struct Achievement: Identifiable, Codable {
    let id: String
    let badgeId: String
    let userId: String
    let unlockedAt: Date
    let progress: Double // 0.0-1.0
    let isUnlocked: Bool
}

struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let iconName: String // SF Symbol名
    let category: BadgeCategory
    let requirement: BadgeRequirement
    let tier: BadgeTier // bronze, silver, gold
    
    enum BadgeCategory: String, Codable {
        case milestone = "milestone"
        case streak = "streak"
        case genre = "genre"
        case special = "special"
    }
    
    enum BadgeTier: String, Codable {
        case bronze = "bronze"
        case silver = "silver"
        case gold = "gold"
        case platinum = "platinum"
    }
}
```

#### ReadingActivity（日次アクティビティ記録）
```swift
struct ReadingActivity: Identifiable, Codable {
    let id: String
    let userId: String
    let date: Date
    let booksRead: Int // その日に読んだ本の数
    let memosWritten: Int // その日に書いたメモの数
    let pagesRead: Int? // その日に読んだページ数
    let readingMinutes: Int? // 読書時間（分）
    let createdAt: Date
}
```

## UI/UX設計

### 1. 目標設定画面（GoalSettingView）
- プロフィール画面からアクセス
- 年間/月間目標の設定
- スライダーでの直感的な数値設定
- 推奨目標の提案（過去の読書ペースから）

### 2. ダッシュボード（GoalDashboardView）
- 新規タブ「目標」を追加（または既存の統計タブに統合）
- 現在の進捗を大きく表示
- ストリーク表示（炎のアイコンで視覚化）
- 今月の目標達成状況
- 獲得バッジの表示

### 3. バッジギャラリー（AchievementGalleryView）
- 獲得済み/未獲得バッジの一覧
- バッジのカテゴリー別表示
- 進捗状況の表示（例: 「あと2冊で獲得！」）
- シェア機能（SNS投稿用の画像生成）

### 4. ストリーク通知
- 毎日の読書リマインダー
- ストリークが途切れそうな時の警告
- マイルストーン達成時のお祝い通知

## 実装方針

### Phase 1: 基盤実装（2日）
1. データモデルの実装
   - ReadingGoal, ReadingStreak, Achievement モデル
   - Repository層の実装
   - Firestore構造の設計

2. 基本的なViewModel実装
   - GoalViewModel
   - StreakViewModel
   - AchievementViewModel

### Phase 2: UI実装（3日）
1. 目標設定画面
   - GoalSettingView
   - 目標編集機能

2. ダッシュボード画面
   - GoalDashboardView
   - 進捗表示コンポーネント

3. バッジギャラリー
   - AchievementGalleryView
   - バッジ詳細表示

### Phase 3: ロジック実装（2日）
1. ストリーク計算ロジック
   - 日次アクティビティの記録
   - ストリーク更新処理
   - バックグラウンド処理

2. バッジ判定ロジック
   - 達成条件のチェック
   - バッジ解放処理
   - 通知連携

### Phase 4: 統合とテスト（1日）
1. 既存機能との統合
   - 本の登録時のアクティビティ記録
   - チャットメモ作成時の記録
   - 統計画面への統合

2. テストとデバッグ

## 技術的な考慮事項

### 1. パフォーマンス
- ストリーク計算は日次バッチで実行
- アクティビティ記録は非同期で処理
- バッジ判定は必要な時のみ実行

### 2. データ整合性
- トランザクションを使用した更新
- 楽観的UIでのUX向上
- エラーハンドリングの徹底

### 3. 拡張性
- バッジの追加が容易な設計
- 新しい目標タイプの追加を考慮
- 国際化対応（将来的な多言語対応）

### 4. 無料版/有料版の差別化
- 無料版：基本的な年間目標とストリーク機能
- 有料版：詳細な目標設定、全バッジ機能、カスタム目標

## Firestore構造

```
/users/{userId}/
  - goals/
    - {goalId}
  - streaks/
    - {streakId}
  - achievements/
    - {achievementId}
  - activities/
    - {activityId} // date-based ID

/badges/
  - {badgeId} // マスターデータ
```

## 実装優先順位

1. **高優先度**
   - 年間読書目標（既存のreadingGoalを活用）
   - 基本的なストリーク機能
   - シンプルなダッシュボード

2. **中優先度**
   - 月間目標
   - バッジ機能（基本的なマイルストーン）
   - 進捗グラフ

3. **低優先度**
   - カスタム目標
   - 高度なバッジ
   - SNSシェア機能

## 成功指標

1. **エンゲージメント向上**
   - DAU/MAUの10%向上
   - 平均セッション時間の15%増加

2. **習慣形成**
   - 30日以上のストリーク達成者が全体の20%
   - 目標設定ユーザーの60%が目標達成

3. **有料転換**
   - 高度な目標機能による有料転換率1%向上

## まとめ

この設計は既存の実装を最大限活用しながら、ユーザーの読書習慣形成を支援する包括的な機能を提供します。段階的な実装により、リスクを最小限に抑えながら価値を提供していきます。
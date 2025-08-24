# 読書メモリー デザインシステム仕様

## コンセプト
「本と過ごした時間を、ずっと大切に」という温かみのあるビジュアル体験

## カラーパレット

### プライマリカラー
- **Memory Blue**: 記憶の深さを表す落ち着いた青
  - Light: #5B8DEE
  - Base: #3B6BCE
  - Dark: #2C4F9C
  
### セカンダリカラー
- **Warm Coral**: 思い出の温かさを表すコーラル
  - Light: #FF9B9B
  - Base: #FF7B7B
  - Dark: #E55B5B

### アクセントカラー
- **Golden Memory**: 特別な思い出を表すゴールド
  - Light: #FFD700
  - Base: #FFC107
  - Dark: #FFB300

### ニュートラルカラー
- **Ink Black**: 本のインクを表す黒
  - 900: #1A1A1A
  - 700: #3A3A3A
  - 500: #6A6A6A
  - 300: #9A9A9A
  - 100: #E5E5E5
  - 50: #F5F5F5

### セマンティックカラー
- Success: #4CAF50
- Warning: #FF9800
- Error: #F44336
- Info: #2196F3

### 背景色
- **Light Mode**:
  - Primary Background: #FFFFFF
  - Secondary Background: #FAFAFA
  - Card Background: #FFFFFF
  - Overlay: rgba(0, 0, 0, 0.5)

- **Dark Mode**:
  - Primary Background: #1C1C1E
  - Secondary Background: #2C2C2E
  - Card Background: #3A3A3C
  - Overlay: rgba(0, 0, 0, 0.7)

## タイポグラフィ

### フォントファミリー
- 日本語: "Hiragino Sans", "Yu Gothic"
- 英語: SF Pro Display (iOS System Font)

### フォントサイズとウェイト
- **Hero**: 34pt, Bold (大見出し)
- **Title1**: 28pt, Bold (画面タイトル)
- **Title2**: 22pt, Semibold (セクションタイトル)
- **Title3**: 20pt, Semibold (カードタイトル)
- **Headline**: 17pt, Semibold (強調テキスト)
- **Body**: 17pt, Regular (本文)
- **Callout**: 16pt, Regular (説明文)
- **Subheadline**: 15pt, Regular (サブテキスト)
- **Footnote**: 13pt, Regular (補足)
- **Caption**: 12pt, Regular (キャプション)

## スペーシング

### 基本単位: 4pt
- xxs: 4pt
- xs: 8pt
- sm: 12pt
- md: 16pt
- lg: 24pt
- xl: 32pt
- xxl: 48pt
- xxxl: 64pt

## コーナーラジアス
- small: 8pt (ボタン、小要素)
- medium: 12pt (カード、入力フィールド)
- large: 16pt (モーダル、大きなカード)
- full: 完全な円形 (アバター、FAB)

## シャドウ
- **Soft Shadow** (カード): 
  - Light: shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
  - Dark: shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)

- **Medium Shadow** (FAB、ポップアップ):
  - Light: shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
  - Dark: shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)

- **Strong Shadow** (モーダル):
  - Light: shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
  - Dark: shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)

## アニメーション
- **Duration**:
  - Fast: 0.2s (マイクロインタラクション)
  - Normal: 0.3s (標準的な遷移)
  - Slow: 0.5s (複雑なアニメーション)

- **Easing**:
  - Standard: easeInOut
  - Enter: easeOut
  - Exit: easeIn

## コンポーネント

### ボタン
1. **Primary Button**: 主要アクション
   - Background: Memory Blue
   - Text: White
   - Height: 50pt
   - Corner Radius: 25pt

2. **Secondary Button**: 補助アクション
   - Background: Memory Blue.opacity(0.1)
   - Text: Memory Blue
   - Border: Memory Blue (1pt)

3. **Text Button**: テキストのみ
   - Text: Memory Blue
   - No background

### カード
- Background: Card Background Color
- Corner Radius: large (16pt)
- Padding: md (16pt)
- Shadow: Soft Shadow

### 入力フィールド
- Height: 50pt
- Background: Neutral 50 (Light) / Neutral 700 (Dark)
- Corner Radius: medium (12pt)
- Padding: horizontal md (16pt)

### ナビゲーションバー
- Background: Blur effect with primary background
- Height: Standard iOS (44pt + safe area)

### タブバー
- Background: Primary Background with blur
- Height: Standard iOS (49pt + safe area)
- Active Color: Memory Blue
- Inactive Color: Neutral 500

## アクセシビリティ
- 最小タップ領域: 44pt x 44pt
- カラーコントラスト: WCAG AA準拠 (4.5:1以上)
- Dynamic Type対応
- VoiceOver最適化
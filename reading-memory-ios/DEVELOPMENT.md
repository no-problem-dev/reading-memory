# 読書メモリー iOS 開発ガイド

## 🚀 セットアップ

### 1. 必要環境

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- CocoaPodsまたはSwift Package Manager

### 2. Firebase設定

1. `GoogleService-Info.plist`をプロジェクトルートに配置
2. Firebase Consoleでプロジェクトを設定

### 3. Xcodeプロジェクトを開く

```bash
cd reading-memory-ios
open reading-memory-ios.xcodeproj
```

## 🔧 ビルドとデバッグ

### Makefileコマンド

```bash
# ビルド
make build

# エラーチェック
make errors

# クリーンビルド
make clean

# シミュレーター一覧
make simulators
```

## 🔍 Firebase Analytics DebugView

### Xcodeでの設定手順

1. **Product > Scheme > Edit Scheme...** を選択
2. 左メニューから **Run** を選択
3. **Arguments** タブを開く
4. **Arguments Passed On Launch** に以下を追加：
   ```
   -FIRDebugEnabled
   ```

### Firebase Consoleでの確認

1. [Firebase Console](https://console.firebase.google.com/)にログイン
2. **Analytics > DebugView** を選択
3. アプリを起動するとリアルタイムでイベントが確認できます

### iOS 18対応

iOS 18でDebugViewが動作しない場合は、AppDelegate.swiftに以下のコードが自動的に追加されています：

```swift
#if DEBUG
UserDefaults.standard.set(true, forKey: "/google/firebase/debug_mode")
UserDefaults.standard.set(true, forKey: "/google/measurement/debug_mode")
#endif
```

ℹ️ **注意**: プロダクションビルドではDebugViewを必ず無効にしてください。

## 📋 アナリティクス

### イベント仕様

- [アナリティクス設計](/docs/technical/analytics-design.md)
- [イベント仕様書](/docs/technical/analytics-event-specification.md)
- [DebugView設定ガイド](/docs/development/firebase-analytics-debug-setup.md)

## 🎯 開発ガイドライン

### コーディング規約

```swift
// クラス・構造体: UpperCamelCase
struct BookMemory { }

// プロパティ・メソッド: lowerCamelCase
let bookTitle: String
func updateStatus(to newStatus: ReadingStatus) { }

// 列挙型: UpperCamelCase、ケース: lowerCamelCase
enum ReadingStatus {
    case wantToRead
    case reading
    case completed
    case dnf
}
```

### アーキテクチャ

- **MVVM + Repositoryパターン**
- **@Observable** を使用した状態管理
- **ServiceContainer** によるDI
- **環境オブジェクト** でStoreを配布

### テスト

```bash
# テスト実行
make test
```

## 🔒 セキュリティ

- APIキーは`Config.swift`で管理
- Firebase Security Rulesでアクセス制御
- ユーザーデータの完全な分離

## 🌐 リソース

- [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer](https://developer.apple.com/)
- [Claude.md](/CLAUDE.md) - AIアシスタントガイド
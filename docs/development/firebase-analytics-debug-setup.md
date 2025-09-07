# Firebase Analytics DebugView設定ガイド

## 概要

Firebase AnalyticsのDebugViewを使用すると、アプリから送信されたイベントをリアルタイムで確認できます。
このドキュメントでは、iOSアプリでDebugViewを有効にする方法を説明します。

## Xcodeでの設定手順

### 1. Schemeの編集

1. Xcodeでプロジェクトを開きます
2. メニューバーから **Product > Scheme > Edit Scheme...** を選択
3. 左側のメニューから **Run** を選択
4. **Arguments** タブをクリック

### 2. デバッグフラグの追加

**Arguments Passed On Launch** セクションに以下のフラグを追加：

```
-FIRDebugEnabled
```

![Xcode Scheme Arguments](https://firebase.google.com/static/docs/analytics/images/xcode-arguments.png)

### 3. デバッグビルドでのみ有効化

Debug構成でのみ有効にしたい場合は、以下のように設定します：

1. **Arguments Passed On Launch** で追加した `-FIRDebugEnabled` の左側のチェックボックスがオンになっていることを確認
2. Run Configuration が **Debug** になっていることを確認

## Firebase Consoleでの確認

1. [Firebase Console](https://console.firebase.google.com/) にログイン
2. プロジェクトを選択
3. 左側のメニューから **Analytics > DebugView** を選択
4. アプリを起動すると、デバイスがリストに表示されます

## デバッグモードの無効化

デバッグモードを無効にするには、以下のフラグを追加します：

```
-FIRDebugDisabled
```

## トラブルシューティング

### DebugViewにデバイスが表示されない場合

1. **フラグの確認**: `-FIRDebugEnabled` が正しく追加されているか確認
2. **アプリの再起動**: Xcodeからアプリを停止し、再度実行
3. **Firebaseの初期化**: `FirebaseApp.configure()` が呼ばれているか確認
4. **ネットワーク接続**: デバイスがインターネットに接続されているか確認

### iOS 18での問題

iOS 18.1ではDebugViewが正常に動作しない場合が報告されています。
この場合は、以下の代替方法を試してください：

```swift
// AppDelegate.swiftまたはApp.swiftに追加
#if DEBUG
UserDefaults.standard.set(true, forKey: "/google/firebase/debug_mode")
UserDefaults.standard.set(true, forKey: "/google/measurement/debug_mode")
#endif
```

## プロダクションへの注意

**重要**: `-FIRDebugEnabled` フラグは開発時のみ使用してください。
プロダクションビルドでは必ず無効にしてください。

## 参考リンク

- [Firebase Analytics DebugView 公式ドキュメント](https://firebase.google.com/docs/analytics/debugview)
- [読書メモリー アナリティクス設計](/docs/technical/analytics-design.md)
- [読書メモリー アナリティクスイベント仕様書](/docs/technical/analytics-event-specification.md)
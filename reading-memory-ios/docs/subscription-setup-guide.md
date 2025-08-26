# 読書メモリー サブスクリプション設定ガイド

## 1. App Store Connect 設定

### 1.1 アプリ内課金の有効化
1. **App Store Connect** にログイン
2. **マイApp** → **読書メモリー** を選択
3. **一般** → **App情報** で以下を確認:
   - Bundle ID: `com.readingmemory`
   - プライマリ言語: 日本語

### 1.2 契約・税金・口座情報
1. **契約/税金/口座情報** に移動
2. **有料App** の契約が有効であることを確認
3. 必要に応じて銀行口座情報を登録

### 1.3 サブスクリプショングループの作成
1. **App内課金** → **管理** → **サブスクリプショングループを作成**
2. グループ設定:
   ```
   参照名: メモリープラス
   サブスクリプショングループ表示名: メモリープラス
   ```

### 1.4 サブスクリプション商品の作成

#### 月額プラン
1. **サブスクリプショングループ** → **サブスクリプションを作成**
2. 基本情報:
   ```
   参照名: メモリープラス月額
   製品ID: com.readingmemory.premium.monthly
   ```
3. サブスクリプション価格:
   ```
   価格: ¥600
   ```
4. サブスクリプション期間:
   ```
   期間: 1か月
   ```
5. ローカリゼーション情報（日本語）:
   ```
   表示名: メモリープラス月額プラン
   説明: すべての機能を無制限でご利用いただけます
   ```

#### 年額プラン
1. **サブスクリプショングループ** → **サブスクリプションを作成**
2. 基本情報:
   ```
   参照名: メモリープラス年額
   製品ID: com.readingmemory.premium.yearly
   ```
3. サブスクリプション価格:
   ```
   価格: ¥6,000
   ```
4. サブスクリプション期間:
   ```
   期間: 1年
   ```
5. ローカリゼーション情報（日本語）:
   ```
   表示名: メモリープラス年額プラン
   説明: すべての機能を無制限でご利用いただけます（2ヶ月分お得）
   ```

### 1.5 サブスクリプショングループの追加設定

#### グループローカリゼーション
1. **サブスクリプショングループ** → **ローカリゼーション** → **日本語を追加**
   ```
   サブスクリプショングループ表示名: メモリープラス
   カスタムアプリ名（オプション）: 読書メモリー
   ```

#### App Storeプロモーション（オプション）
1. **サブスクリプショングループ** → **App Storeプロモーション**
   ```
   プロモーション画像: 1024x1024px
   プロモーション説明: 読書体験をもっと豊かに
   ```

### 1.6 レビュー情報
1. **App内課金** → **レビュー情報**
   ```
   レビューに関するメモ: 
   - RevenueCat SDKを使用
   - サブスクリプションはアプリ内で管理
   - テスト用のSandboxアカウントは不要
   
   スクリーンショット: PaywallViewのスクリーンショットをアップロード
   ```

## 2. RevenueCat Dashboard 設定

### 2.1 アカウント作成とプロジェクト設定
1. [RevenueCat](https://app.revenuecat.com) にサインアップ
2. **Create New Project**
   ```
   Project Name: 読書メモリー
   ```

### 2.2 アプリ設定
1. **Project Settings** → **Apps** → **+ New**
2. アプリ情報:
   ```
   App Name: 読書メモリー iOS
   Platform: App Store
   Bundle ID: com.readingmemory
   ```

### 2.3 App Store Connect 連携
1. **Apps** → **読書メモリー iOS** → **App Store Connect**
2. **App Store Connect API Key** を設定:
   - **Issuer ID**: App Store Connectから取得
   - **Vendor Number**: App Store Connectから取得
   - **Key ID**: App Store Connectから取得
   - **Private Key**: .p8ファイルの内容をペースト

### 2.4 商品設定
1. **Products** → **+ New**
2. 月額プラン:
   ```
   Identifier: com.readingmemory.premium.monthly
   App Store Product ID: com.readingmemory.premium.monthly
   Type: Auto-Renewable Subscription
   Duration: 1 month
   ```
3. 年額プラン:
   ```
   Identifier: com.readingmemory.premium.yearly
   App Store Product ID: com.readingmemory.premium.yearly
   Type: Auto-Renewable Subscription
   Duration: 1 year
   ```

### 2.5 Entitlements設定
1. **Entitlements** → **+ New**
   ```
   Identifier: premium
   Description: プレミアムメンバーシップ
   ```
2. **Attach Products** で両方の商品を選択

### 2.6 Offerings設定
1. **Offerings** → **+ New**
   ```
   Identifier: default
   Description: デフォルト価格
   Is Current: ✓
   ```
2. **Packages** を追加:
   - Monthly Package:
     ```
     Identifier: $rc_monthly
     Products: com.readingmemory.premium.monthly
     ```
   - Annual Package:
     ```
     Identifier: $rc_annual  
     Products: com.readingmemory.premium.yearly
     ```

### 2.7 API Keys
1. **Project Settings** → **API Keys**
2. **Public App-Specific API Keys** からiOS用のキーをコピー
   ```
   例: appl_ABCDEFGHIJKLMNOPQRSTUVWXYZabc
   ```

### 2.8 Webhook設定（オプション）
1. **Integrations** → **Webhooks** → **Add Webhook**
   ```
   URL: https://api.readingmemory.com/webhook/revenuecat
   Events: 
   - [x] Initial Purchase
   - [x] Renewal
   - [x] Cancellation
   - [x] Uncancellation
   - [x] Non Renewing Purchase
   - [x] Expiration
   ```

### 2.9 サンドボックステスト設定
1. **Apps** → **読書メモリー iOS** → **Sandbox Behavior**
   ```
   Renewal Rate: Real-time (1 month = 5 minutes)
   Introductory Price Eligibility: Standard behavior
   ```

## 3. テスト手順

### 3.1 Sandboxテスターの作成（App Store Connect）
1. **ユーザーとアクセス** → **Sandboxテスター**
2. **+** ボタンで新規作成:
   ```
   メール: test@example.com
   パスワード: TestPassword123!
   名: Test
   姓: User
   地域: 日本
   ```

### 3.2 デバイスでのテスト
1. デバイスの設定 → **App Store** → **サンドボックスアカウント**でログイン
2. アプリを起動してPaywallを表示
3. 購入フローをテスト

## 4. 本番環境への移行チェックリスト

- [ ] App Store Connectで全商品が「送信準備完了」状態
- [ ] RevenueCatのProduction環境設定完了
- [ ] APIキーを本番用に更新
- [ ] プライバシーポリシーにサブスクリプション条項を追加
- [ ] 利用規約に自動更新と解約方法を明記
- [ ] App Store審査用のレビューノートを準備
- [ ] スクリーンショットにPaywall画面を含める

## 5. トラブルシューティング

### よくある問題
1. **商品が取得できない**
   - Bundle IDの確認
   - 商品IDの完全一致を確認
   - App Store Connectで商品が有効か確認

2. **購入が完了しない**
   - Sandboxアカウントの地域設定
   - 契約・税金・口座情報の完了状態

3. **RevenueCatで商品が表示されない**
   - App Store Connect API連携の再設定
   - 商品の同期待ち（最大24時間）

## 6. 参考リンク

- [RevenueCat Documentation](https://www.revenuecat.com/docs)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
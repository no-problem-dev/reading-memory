# 読書メモリー フリーミアム・サブスクリプション戦略

## 概要
読書メモリーのマネタイズ戦略として、フリーミアムモデルを採用。StoreKit2を使用したiOSネイティブのサブスクリプション実装。

## フリーミアムモデル

### 無料プラン「メモリースターター」
- 本の登録：月10冊まで
- 手動登録のみ（バーコード/検索は制限）
- テキストチャットメモ（AI応答なし）
- 基本統計（過去3ヶ月分）
- 月間目標のみ
- 基本バッジのみ
- 公開本棚：5冊まで

### プレミアムプラン「メモリープラス」
**価格**: 月額600円 / 年額6,000円（2ヶ月分お得）

**機能**:
- 無制限の本登録
- バーコード/ISBN検索
- AI対話・要約機能
- 写真付きチャットメモ
- 全期間の統計・分析
- 高度な読書目標設定
- 全アチーブメント解放
- 公開本棚無制限
- 優先サポート

## 技術実装

### Product IDs
- `com.readingmemory.premium.monthly` - 月額プラン
- `com.readingmemory.premium.yearly` - 年額プラン

### 主要コンポーネント（Manager排除）
1. **SubscriptionStore**: StoreKit2との統合、購入・復元処理
2. **FeatureGate**: 機能アクセス制御
3. **ReceiptValidator**: レシート検証
4. **UsageTracker**: 使用量追跡

### Firebase Auth統合
- Firebase AuthのUIDとStoreKitのoriginalTransactionIdを紐付け
- Firestoreでユーザーごとのサブスクリプション状態を管理
- Cloud FunctionsでApp Store Server Notificationsを受信

### 検証フロー
1. **ローカル検証**: StoreKit2の自動検証機能
2. **サーバー検証**: Firebase Functions経由（重要な機能のみ）
3. **Server Notifications**: 自動更新・キャンセルの即時反映

## KPI目標
- 無料→有料転換率：3%（初年度）
- 年額プラン比率：40%
- 30日リテンション：15%
- LTV：7,200円
- CAC：2,000円以下

## 転換率向上施策
1. **オンボーディング最適化**
   - Day 3: AI機能の1回お試し
   - Day 7: 制限到達通知
   - Day 14: 初月半額オファー

2. **アップグレードトリガー**
   - 月10冊制限到達
   - 写真添付したい瞬間
   - AI要約を見たいとき
   - 年間目標設定時

3. **価値の可視化**
   - 月末統計でプレミアム機能プレビュー
   - ロックされたバッジの表示
   - AI応答のサンプル表示

## 実装方針
詳細な実装方針は `/docs/technical/subscription-implementation.md` を参照。

## 将来の拡張
- Phase 2（6ヶ月後）：ファミリープラン（月額1,000円）、学生プラン（月額300円）
- Phase 3（1年後）：プロプラン（月額1,500円、API アクセス等）
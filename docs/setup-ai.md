# AI機能のセットアップ

## 1. Claude APIキーの取得

1. [Anthropic Console](https://console.anthropic.com/) にアクセス
2. アカウントを作成またはログイン
3. API Keys セクションで新しいAPIキーを作成
4. キーをコピー（一度しか表示されません）

## 2. Firebase Secret Managerの設定

```bash
# Claude APIキーをSecret Managerに設定
firebase functions:secrets:set CLAUDE_API_KEY

# プロンプトが表示されたらAPIキーを貼り付け
```

## 3. Cloud Functionsのデプロイ

```bash
# 関数をデプロイ
firebase deploy --only functions:generateAIResponse,functions:generateBookSummary
```

## 4. 動作確認

### iOSアプリでの確認
1. 本の詳細画面からチャットメモを開く
2. 右上のAIボタンをタップして有効化
3. メッセージを送信すると、AIからの返答が表示される
4. 本の詳細画面で「AI要約」をタップすると、読書メモの要約が生成される

## トラブルシューティング

### エラー: "CLAUDE_API_KEY is not set"
Secret Managerが正しく設定されていません。上記の手順2を再度実行してください。

### エラー: "AI応答の生成に失敗しました"
1. Cloud Functionsのログを確認
   ```bash
   firebase functions:log
   ```
2. Claude APIキーが有効か確認
3. APIの利用制限に達していないか確認

### エラー: "要約の生成に失敗しました"
読書メモが存在しない可能性があります。チャットメモを追加してから再度試してください。

## 料金について

Claude APIの料金：
- Claude 3 Sonnet: $3 / 1M input tokens, $15 / 1M output tokens
- 平均的な使用で1回のチャット応答: 約$0.001-0.002
- 要約生成: 約$0.003-0.005

Firebase Secret Manager：
- 基本的に無料（6つのアクティブなシークレットまで）
- アクセス回数: 10,000回/月まで無料
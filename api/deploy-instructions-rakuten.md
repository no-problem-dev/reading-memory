# 楽天ブックスAPI設定完了

## 完了した設定

1. **Secret Manager に楽天APIキーを登録**
   - `rakuten-application-id`: 1020295651766009342
   - `rakuten-affiliate-id`: 3b12dd83.1a9403fd.3b12dd84.d5ffb4c2

2. **Cloud Run サービスアカウントに権限付与**
   - サービスアカウント: `reading-memory-api@reading-memory.iam.gserviceaccount.com`
   - 両シークレットへの `secretmanager.secretAccessor` 権限を付与済み

3. **deploy.sh を更新**
   - 楽天API関連の環境変数が自動的にSecret Managerから読み込まれるように設定

## 次回のデプロイ時

```bash
# apiディレクトリから実行
./deploy.sh
```

これで楽天ブックスAPIが本番環境で自動的に有効になります。

## ローカル開発環境

開発時は `.env` ファイルを作成：

```env
RAKUTEN_APPLICATION_ID=1020295651766009342
RAKUTEN_AFFILIATE_ID=3b12dd83.1a9403fd.3b12dd84.d5ffb4c2
```

**注意**: `.env` ファイルは絶対にGitにコミットしないでください。

## APIの動作

- ISBN検索: 楽天 → OpenBD → Google Books の優先順位
- キーワード検索: 楽天 → Google Books の優先順位
- 楽天で見つかった場合はアフィリエイトURLも含まれます
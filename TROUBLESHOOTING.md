# Cloud Functions トラブルシューティング

## デプロイエラーの解決方法

### エラー: Access to bucket denied

```
Build failed: Access to bucket gcf-sources-969134479773-asia-northeast1 denied. 
You must grant Storage Object Viewer permission to 969134479773-compute@developer.gserviceaccount.com.
```

#### 解決手順:

1. **Google Cloud Console にアクセス**
   - https://console.cloud.google.com
   - プロジェクト `reading-memory` を選択

2. **IAM & Admin → IAM に移動**
   - 左側メニューから「IAM & Admin」→「IAM」を選択

3. **サービスアカウントに権限を付与**
   - `969134479773-compute@developer.gserviceaccount.com` を見つける
   - 「編集」をクリック
   - 以下のロールを追加:
     - `Storage Object Viewer`
     - `Cloud Functions Developer`
     - `Service Account User`

4. **別の方法: gcloud CLI を使用**
   ```bash
   gcloud projects add-iam-policy-binding reading-memory \
     --member="serviceAccount:969134479773-compute@developer.gserviceaccount.com" \
     --role="roles/storage.objectViewer"
   ```

### エラー: API が有効になっていない

必要な API を有効化:
```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### エラー: リージョンがサポートされていない

`asia-northeast1` (東京) がサポートされているか確認:
```bash
gcloud functions regions list
```

### クリーンアップポリシーの設定

警告を解消するには:
```bash
firebase functions:artifacts:setpolicy
```

または、強制的にデプロイ:
```bash
firebase deploy --only functions --force
```

## よくある問題

### 1. 認証エラー
```bash
firebase login --reauth
gcloud auth login
```

### 2. プロジェクトの確認
```bash
firebase projects:list
gcloud config get-value project
```

### 3. ビリングアカウント
Cloud Functions を使用するには、プロジェクトにビリングアカウントが設定されている必要があります。

### 4. Firebase Blaze プラン
Cloud Functions を使用するには、Firebase の Blaze プラン（従量課金）が必要です。

## デバッグ方法

### ローカルでテスト
```bash
make functions-serve
```

### ログの確認
```bash
make functions-logs
```

### 直接実行
```bash
cd functions
npm run shell
```

## 再デプロイ手順

問題を解決した後:
```bash
make clean
make safe-deploy
```
# ローカルテスト方法

## iOS アプリからローカルAPIサーバーに接続する方法

### 1. ローカルAPIサーバーを起動

```bash
cd api
npm run dev
```

### 2. XcodeでSchemeの環境変数を設定

1. Xcode で Product > Scheme > Edit Scheme を開く
2. Run > Arguments > Environment Variables に追加：
   - Name: `API_BASE_URL`
   - Value: `http://localhost:8080`

### 3. アプリを実行

これで、iOSアプリがローカルのAPIサーバーに接続されます。

### 注意事項

- iOS SimulatorからlocalhostにアクセスするにはHTTP通信を許可する必要があります
- Info.plistに以下を追加（開発環境のみ）：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### Cloud Run APIを使用する場合

環境変数を設定しない、または以下のように設定：

- Name: `API_BASE_URL`
- Value: `https://reading-memory-api-ehel5nxm2q-an.a.run.app`
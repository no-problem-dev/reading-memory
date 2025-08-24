# 画像管理システム設計

## 概要
画像を独立したエンティティとして管理し、各ドメインが画像IDを参照する設計。

## データ構造

### Firestore コレクション

#### `images/{imageId}`
```typescript
interface Image {
  id: string;              // 画像ID（UUID）
  uploadedBy: string;      // アップロードしたユーザーID
  storagePath: string;     // Firebase Storage上のパス
  url: string;             // アクセスURL
  contentType: string;     // MIMEタイプ (image/jpeg, image/png)
  size: number;            // ファイルサイズ（バイト）
  metadata: {
    width?: number;        // 画像の幅
    height?: number;       // 画像の高さ
  };
  createdAt: Date;
  updatedAt: Date;
}
```

### 各ドメインでの参照

#### ユーザープロフィール
```typescript
interface UserProfile {
  // ... 他のフィールド
  avatarImageId?: string;  // images/{imageId} への参照
}
```

#### 本（UserBook）
```typescript
interface UserBook {
  // ... 他のフィールド
  coverImageId?: string;   // images/{imageId} への参照
}
```

#### チャット
```typescript
interface BookChat {
  // ... 他のフィールド
  imageId?: string;        // images/{imageId} への参照
}
```

## Firebase Storage 構造
```
images/
  ├── {imageId}.jpg      // 実際の画像ファイル
  └── {imageId}_thumb.jpg // サムネイル（将来実装）
```

## API エンドポイント

### 画像アップロード
```
POST /api/v1/images
Content-Type: multipart/form-data

Response:
{
  "imageId": "123e4567-e89b-12d3-a456-426614174000",
  "url": "https://firebasestorage.googleapis.com/..."
}
```

### 画像情報取得
```
GET /api/v1/images/{imageId}

Response:
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "url": "https://firebasestorage.googleapis.com/...",
  "contentType": "image/jpeg",
  "size": 1048576,
  "metadata": {
    "width": 1024,
    "height": 768
  }
}
```

### 画像削除
```
DELETE /api/v1/images/{imageId}
```

## セキュリティルール

### Firestore
```javascript
// images コレクション
match /images/{imageId} {
  // 読み取り：アップロードしたユーザーのみ
  allow read: if request.auth != null && 
    request.auth.uid == resource.data.uploadedBy;
  
  // 作成：認証されたユーザー
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.uploadedBy;
  
  // 削除：アップロードしたユーザーのみ
  allow delete: if request.auth != null && 
    request.auth.uid == resource.data.uploadedBy;
}
```

### Storage
```javascript
match /images/{imageId} {
  // APIサーバー経由でのみアクセス可能
  allow read: if false;
  allow write: if false;
}
```

## 利点

1. **シンプルな権限管理**: 画像の所有者情報はFirestoreで一元管理
2. **柔軟な参照**: 任意のドメインから画像IDで参照可能
3. **効率的**: userIdをパスに含めないため、画像表示時にuserIdが不要
4. **スケーラブル**: 画像管理が独立しているため、将来の拡張が容易

## 実装の流れ

1. Firestoreに`images`コレクションを追加
2. APIに画像管理エンドポイントを実装
3. 既存のドメイン（本、チャット、プロフィール）を画像ID参照方式に変更
4. iOSクライアントを新APIに対応

## 移行計画

1. 新しいAPIエンドポイントを並行して実装
2. 既存データの画像URLから画像IDへの移行スクリプトを作成
3. クライアントを段階的に新方式に移行
4. 旧エンドポイントを廃止
# ISBN Barcode Scanning Implementation

## Overview
Implemented ISBN barcode scanning feature using OpenBD API for Japanese book data retrieval.

## Implementation Details

### Cloud Function (Firebase Functions v1)
- **Function Name**: `searchBookByISBN`
- **Region**: `asia-northeast1`
- **Runtime**: Node.js 20
- **Type**: Callable function with authentication
- **Location**: `/functions/src/index.ts`

### Key Features
1. **Barcode Scanning**: Uses AVFoundation to scan ISBN barcodes (EAN-13)
2. **Manual Entry**: Fallback option for manual ISBN input
3. **OpenBD API Integration**: Fetches Japanese book data
4. **Authentication**: Requires authenticated users
5. **Data Storage**: Saves book master data to Firestore

### iOS Implementation
- **Scanner View**: `BarcodeScannerView.swift`
- **Camera Integration**: Custom `CameraViewController` with AVCaptureSession
- **Manual Entry**: `ManualISBNEntryView` for fallback input
- **Book Registration**: Updated to accept prefilled book data

### Important Configuration
1. **IAM Policy**: Must allow `allUsers` to invoke the function
   ```bash
   gcloud functions add-iam-policy-binding searchBookByISBN \
     --region=asia-northeast1 \
     --member="allUsers" \
     --role="roles/cloudfunctions.invoker"
   ```

2. **Info.plist**: Added camera usage description
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>カメラを使用して本のバーコードをスキャンします</string>
   ```

### Troubleshooting
- **UNAUTHENTICATED Error**: Ensure IAM policy allows allUsers to invoke
- **403 Forbidden**: Function needs public invoker permissions
- **Build Failures**: Check organization policies and service account permissions

### Data Flow
1. User taps "バーコードでスキャン" in BookShelfView
2. Camera opens and scans ISBN barcode
3. Calls Cloud Function with ISBN
4. Function queries OpenBD API
5. Returns book data to iOS app
6. Pre-fills BookRegistrationView with data
7. User can edit and save the book

### OpenBD API Response Mapping
- Title: `summary.title` or `onix.DescriptiveDetail.TitleDetail`
- Author: `summary.author` or `onix.DescriptiveDetail.Contributor`
- Publisher: `summary.publisher` or `onix.PublishingDetail.Imprint`
- Cover Image: `summary.cover`
- Page Count: `onix.DescriptiveDetail.Extent` (type 11)
- Description: `onix.CollateralDetail.TextContent` (type 03)

Last updated: 2025-08-17
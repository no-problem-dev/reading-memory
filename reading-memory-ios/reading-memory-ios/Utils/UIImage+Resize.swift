import UIKit

extension UIImage {
    /// 画像を指定サイズ以下にリサイズ（アスペクト比を維持）
    /// - Parameters:
    ///   - maxSize: 最大サイズ（幅・高さの上限）
    ///   - maxFileSizeKB: 最大ファイルサイズ（KB単位）
    /// - Returns: リサイズされた画像
    public func resizedToFit(maxSize: CGSize, maxFileSizeKB: Int = 500) -> UIImage {
        // まず指定サイズに収まるようにリサイズ
        let resizedImage = self.resizedMaintainingAspectRatioToFit(targetSize: maxSize)
        
        // ファイルサイズが大きい場合は圧縮
        if let compressedData = resizedImage.compressedJPEGData(maxFileSizeKB: maxFileSizeKB),
           let finalImage = UIImage(data: compressedData) {
            return finalImage
        }
        
        return resizedImage
    }
    
    /// 画像を指定サイズに収まるようにリサイズ（アスペクト比を維持）
    /// - Parameter targetSize: 目標サイズ（この範囲内に収まるようにリサイズ）
    /// - Returns: リサイズされた画像
    public func resizedMaintainingAspectRatioToFit(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / self.size.width
        let heightRatio = targetSize.height / self.size.height
        let ratio = min(widthRatio, heightRatio)
        
        // 既に目標サイズ以下の場合はそのまま返す
        if ratio >= 1.0 {
            return self
        }
        
        let newSize = CGSize(
            width: self.size.width * ratio,
            height: self.size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// 画像を再帰的に圧縮してファイルサイズを削減
    /// - Parameters:
    ///   - currentSize: 現在のサイズ（初回はオリジナルサイズ）
    ///   - maxFileSizeKB: 最大ファイルサイズ（KB単位）
    ///   - quality: 圧縮品質（0.0〜1.0）
    /// - Returns: 圧縮された画像データ
    public func compressedRecursively(currentSize: CGSize? = nil, maxFileSizeKB: Int = 500, quality: CGFloat = 0.8) -> Data? {
        let maxFileSize = maxFileSizeKB * 1024 // KBをバイトに変換
        let imageToCompress = currentSize != nil ? self.resizedMaintainingAspectRatioToFit(targetSize: currentSize!) : self
        
        // 現在の品質で圧縮を試みる
        if let data = imageToCompress.jpegData(compressionQuality: quality) {
            if data.count <= maxFileSize {
                return data
            }
            
            // ファイルサイズがまだ大きい場合
            if quality > 0.1 {
                // 品質を下げて再試行
                return imageToCompress.compressedRecursively(
                    currentSize: currentSize,
                    maxFileSizeKB: maxFileSizeKB,
                    quality: max(quality - 0.1, 0.1)
                )
            } else if let currentSize = currentSize {
                // 品質が最低でもまだ大きい場合は、サイズを縮小
                let newSize = CGSize(
                    width: currentSize.width * 0.8,
                    height: currentSize.height * 0.8
                )
                return self.compressedRecursively(
                    currentSize: newSize,
                    maxFileSizeKB: maxFileSizeKB,
                    quality: 0.8
                )
            } else {
                // 初回でサイズ指定なしの場合は、80%のサイズから始める
                let newSize = CGSize(
                    width: self.size.width * 0.8,
                    height: self.size.height * 0.8
                )
                return self.compressedRecursively(
                    currentSize: newSize,
                    maxFileSizeKB: maxFileSizeKB,
                    quality: 0.8
                )
            }
        }
        
        return nil
    }
}
import UIKit

extension UIImage {
    /// 画像を正方形にクロップ（中央を基準）
    /// - Parameter targetSize: 目標サイズ（正方形の一辺の長さ）
    /// - Returns: クロップされた正方形の画像
    func croppedToSquare(targetSize: CGFloat = 800) -> UIImage {
        let originalWidth = self.size.width
        let originalHeight = self.size.height
        
        // 既に正方形の場合は、リサイズのみ行う
        if originalWidth == originalHeight {
            return self.resizedMaintainingAspectRatio(targetSize: CGSize(width: targetSize, height: targetSize))
        }
        
        // 正方形にクロップする範囲を計算（短い辺に合わせる）
        let cropSize = min(originalWidth, originalHeight)
        let cropX = (originalWidth - cropSize) / 2
        let cropY = (originalHeight - cropSize) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: cropSize, height: cropSize)
        
        // CGImageに変換してクロップ
        guard let cgImage = self.cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return self
        }
        
        // UIImageに戻す（元の画像の向きを保持）
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: self.scale, orientation: self.imageOrientation)
        
        // 目標サイズにリサイズ
        return croppedImage.resizedMaintainingAspectRatio(targetSize: CGSize(width: targetSize, height: targetSize))
    }
    
    /// アスペクト比を維持しながらリサイズ
    /// - Parameter targetSize: 目標サイズ
    /// - Returns: リサイズされた画像
    private func resizedMaintainingAspectRatio(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / self.size.width
        let heightRatio = targetSize.height / self.size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: self.size.width * ratio,
            height: self.size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// プロフィール画像用に最適化された処理
    /// 正方形にクロップし、適切なサイズに圧縮
    /// - Parameters:
    ///   - targetSize: 正方形の一辺のサイズ（デフォルト: 800）
    ///   - maxFileSizeKB: 最大ファイルサイズ（KB単位、デフォルト: 500）
    /// - Returns: 処理された画像
    func preparedForProfileImage(targetSize: CGFloat = 800, maxFileSizeKB: Int = 500) -> UIImage {
        // まず正方形にクロップ
        let squareImage = self.croppedToSquare(targetSize: targetSize)
        
        // そのままでも画質を保ちながら圧縮
        // compressedJPEGDataは既にUIImage+Compression.swiftで定義済み
        if let compressedData = squareImage.compressedJPEGData(maxFileSizeKB: maxFileSizeKB),
           let finalImage = UIImage(data: compressedData) {
            return finalImage
        }
        
        return squareImage
    }
}
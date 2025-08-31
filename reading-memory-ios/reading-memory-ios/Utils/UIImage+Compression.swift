import UIKit

extension UIImage {
    /// 指定されたファイルサイズ以下になるまで画像を圧縮
    /// - Parameters:
    ///   - maxFileSizeKB: 最大ファイルサイズ（KB単位）
    ///   - initialQuality: 初期圧縮品質（0.0〜1.0）
    /// - Returns: 圧縮されたJPEGデータ
    func compressedJPEGData(maxFileSizeKB: Int = 500, initialQuality: CGFloat = 0.8) -> Data? {
        let maxFileSize = maxFileSizeKB * 1024 // KBをバイトに変換
        
        // 最初に指定品質で圧縮を試みる
        if let data = self.jpegData(compressionQuality: initialQuality),
           data.count <= maxFileSize {
            return data
        }
        
        // 品質を段階的に下げる
        let qualities: [CGFloat] = [0.7, 0.5, 0.3, 0.2, 0.1]
        for quality in qualities {
            if let data = self.jpegData(compressionQuality: quality),
               data.count <= maxFileSize {
                return data
            }
        }
        
        // それでも大きい場合は、画像サイズを縮小してから圧縮
        let scales: [(CGFloat, CGFloat)] = [(0.8, 0.5), (0.6, 0.4), (0.4, 0.3), (0.3, 0.2)]
        for (scale, quality) in scales {
            let scaledImage = self.scaled(by: scale)
            if let data = scaledImage.jpegData(compressionQuality: quality),
               data.count <= maxFileSize {
                return data
            }
        }
        
        // 最終手段: 非常に小さいサイズまで縮小
        let finalImage = self.scaled(by: 0.2)
        return finalImage.jpegData(compressionQuality: 0.1)
    }
    
    /// 画像を指定された倍率でスケールする
    /// - Parameter scale: スケール倍率（0.0〜1.0）
    /// - Returns: スケールされた画像
    private func scaled(by scale: CGFloat) -> UIImage {
        let newSize = CGSize(
            width: self.size.width * scale,
            height: self.size.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
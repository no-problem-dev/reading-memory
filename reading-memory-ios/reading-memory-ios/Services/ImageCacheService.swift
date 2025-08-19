import Foundation
import UIKit

final class ImageCacheService {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // キャッシュディレクトリの設定
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // ディレクトリが存在しない場合は作成
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // メモリキャッシュの設定
        cache.countLimit = 100 // 最大100枚
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    func loadImage(from url: URL) async -> UIImage? {
        // メモリキャッシュをチェック
        if let cachedImage = cache.object(forKey: url as NSURL) {
            return cachedImage
        }
        
        // ディスクキャッシュをチェック
        let fileName = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        if let diskImage = UIImage(contentsOfFile: fileURL.path) {
            // メモリキャッシュに追加
            cache.setObject(diskImage, forKey: url as NSURL)
            return diskImage
        }
        
        // ネットワークから取得
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // キャッシュに保存
            await saveToCache(image: image, url: url)
            
            return image
        } catch {
            print("Failed to load image from \(url): \(error)")
            return nil
        }
    }
    
    private func saveToCache(image: UIImage, url: URL) async {
        // メモリキャッシュに保存
        cache.setObject(image, forKey: url as NSURL)
        
        // ディスクキャッシュに保存
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileName = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("Failed to save image to disk cache: \(error)")
        }
    }
    
    func clearCache() {
        // メモリキャッシュをクリア
        cache.removeAllObjects()
        
        // ディスクキャッシュをクリア
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getCacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for file in files {
            if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
}
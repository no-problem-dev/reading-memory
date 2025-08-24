import Foundation
import UIKit

final class ImageEntityEntityRepository {
    static let shared = ImageEntityEntityRepository()
    
    private let apiClient = APIClient.shared
    private var imageCache: [String: ImageEntity] = [:]
    
    private init() {}
    
    /// 画像をアップロード
    func uploadImage(_ uiImage: UIImage, compressionQuality: CGFloat = 0.8) async throws -> ImageEntity {
        guard let imageData = uiImage.jpegData(compressionQuality: compressionQuality) else {
            throw AppError.custom("画像の変換に失敗しました")
        }
        
        let (imageId, url) = try await apiClient.uploadImage(imageData: imageData)
        
        let image = ImageEntity(
            id: imageId,
            url: url,
            contentType: "image/jpeg",
            size: imageData.count,
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // キャッシュに保存
        imageCache[imageId] = image
        
        return image
    }
    
    /// 画像情報を取得
    func getImage(id: String) async throws -> ImageEntity {
        // キャッシュから取得
        if let cachedImageEntity = imageCache[id] {
            return cachedImageEntity
        }
        
        // APIから取得
        let image = try await apiClient.getImage(id: id)
        
        // キャッシュに保存
        imageCache[id] = image
        
        return image
    }
    
    /// 画像を削除
    func deleteImage(id: String) async throws {
        try await apiClient.deleteImage(id: id)
        
        // キャッシュからも削除
        imageCache.removeValue(forKey: id)
    }
    
    /// キャッシュをクリア
    func clearCache() {
        imageCache.removeAll()
    }
}
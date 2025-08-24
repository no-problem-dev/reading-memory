import Foundation
import UIKit

/// 新しい画像管理システムのラッパーサービス
/// ImageEntityRepositoryへの移行を簡単にするためのファサード
final class StorageService {
    static let shared = StorageService()
    
    private let imageRepository = ImageEntityRepository.shared
    
    private init() {}
    
    /// 画像をアップロード（新システム）
    /// - Returns: 画像ID
    func uploadImage(_ image: UIImage, compressionQuality: CGFloat = 0.8) async throws -> String {
        let uploadedImage = try await imageRepository.uploadImage(image, compressionQuality: compressionQuality)
        return uploadedImage.id
    }
    
    /// 画像情報を取得
    func getImage(id: String) async throws -> ImageEntity {
        return try await imageRepository.getImage(id: id)
    }
    
    /// 画像URLを取得（便利メソッド）
    func getImageUrl(id: String) async throws -> String {
        let image = try await imageRepository.getImage(id: id)
        return image.url
    }
    
    /// 画像を削除
    func deleteImage(id: String) async throws {
        try await imageRepository.deleteImage(id: id)
    }
}
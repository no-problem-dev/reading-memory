import Foundation
import UIKit

/// 新しい画像管理システムのラッパーサービス
/// ImageEntityRepositoryへの移行を簡単にするためのファサード
final class StorageService {
    static let shared = StorageService()
    
    private let imageRepository = ImageEntityRepository.shared
    
    private init() {}
    
    /// 画像をアップロード（新システム）
    /// - Parameters:
    ///   - image: アップロードする画像
    ///   - maxFileSizeKB: 最大ファイルサイズ（KB単位、デフォルト500KB）
    /// - Returns: 画像ID
    func uploadImage(_ image: UIImage, maxFileSizeKB: Int = 500) async throws -> String {
        // 確実に指定サイズ以下に圧縮
        guard let compressedData = image.compressedJPEGData(maxFileSizeKB: maxFileSizeKB) else {
            throw AppError.custom("画像の圧縮に失敗しました")
        }
        
        guard let compressedImage = UIImage(data: compressedData) else {
            throw AppError.custom("圧縮データから画像を作成できませんでした")
        }
        
        let uploadedImage = try await imageRepository.uploadImage(compressedImage, compressionQuality: 1.0)
        return uploadedImage.id
    }
    
    /// プロフィール画像をアップロード
    /// 正方形にクロップして最適化
    /// - Parameters:
    ///   - image: アップロードする画像
    ///   - targetSize: 正方形の一辺のサイズ（デフォルト: 800）
    ///   - maxFileSizeKB: 最大ファイルサイズ（KB単位、デフォルト: 500）
    /// - Returns: 画像ID
    func uploadProfileImage(_ image: UIImage, targetSize: CGFloat = 800, maxFileSizeKB: Int = 500) async throws -> String {
        // プロフィール画像用に最適化（正方形クロップ + 圧縮）
        let preparedImage = image.preparedForProfileImage(targetSize: targetSize, maxFileSizeKB: maxFileSizeKB)
        
        let uploadedImage = try await imageRepository.uploadImage(preparedImage, compressionQuality: 1.0)
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
import Foundation
import UIKit

final class StorageService {
    static let shared = StorageService()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    enum StoragePath {
        case profileImage(userId: String)
        case bookCover(userId: String, bookId: String)
        case chatPhoto(bookId: String, photoId: String)
        
        var path: String {
            switch self {
            case .profileImage(let userId):
                return "users/\(userId)/profile/\(UUID().uuidString).jpg"
            case .bookCover(let userId, let bookId):
                return "users/\(userId)/books/\(bookId)/cover.jpg"
            case .chatPhoto(let bookId, let photoId):
                return "books/\(bookId)/photos/\(photoId).jpg"
            }
        }
    }
    
    /// 画像をアップロード
    func uploadImage(_ image: UIImage, path: StoragePath, compressionQuality: CGFloat = 0.8) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw AppError.custom("画像の変換に失敗しました")
        }
        
        switch path {
        case .profileImage:
            return try await apiClient.uploadProfileImage(imageData: imageData)
        case .bookCover(_, let bookId):
            return try await apiClient.uploadBookCover(bookId: bookId, imageData: imageData)
        case .chatPhoto(let bookId, _):
            return try await apiClient.uploadChatPhoto(bookId: bookId, imageData: imageData)
        }
    }
    
    /// データをアップロード
    func uploadData(_ data: Data, path: String) async throws -> String {
        // 現在は画像アップロードのみ対応
        throw AppError.custom("データアップロードは未実装です")
    }
    
    /// 画像を削除
    func deleteImage(at url: String) async throws {
        try await apiClient.deleteImage(url: url)
    }
}
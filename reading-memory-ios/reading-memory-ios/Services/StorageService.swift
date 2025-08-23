import Foundation
import UIKit

final class StorageService {
    static let shared = StorageService()
    
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
        // TODO: 実際のアップロード処理を実装
        // 現在はダミーURLを返す
        return "https://example.com/\(path.path)"
    }
    
    /// データをアップロード
    func uploadData(_ data: Data, path: String) async throws -> String {
        // TODO: 実際のアップロード処理を実装
        // 現在はダミーURLを返す
        return "https://example.com/\(path)"
    }
    
    /// 画像を削除
    func deleteImage(at url: String) async throws {
        // TODO: 実際の削除処理を実装
        // 現在は何もしない
    }
}
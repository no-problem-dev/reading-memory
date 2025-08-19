import Foundation
import FirebaseStorage
import UIKit

final class StorageService {
    static let shared = StorageService()
    
    private let storage = Storage.storage()
    
    private init() {}
    
    enum StoragePath {
        case profileImage(userId: String)
        case bookCover(userId: String, bookId: String)
        case chatPhoto(userId: String, bookId: String, photoId: String)
        
        var path: String {
            switch self {
            case .profileImage(let userId):
                return "users/\(userId)/profile/\(UUID().uuidString).jpg"
            case .bookCover(let userId, let bookId):
                return "users/\(userId)/books/\(bookId)/cover.jpg"
            case .chatPhoto(let userId, let bookId, let photoId):
                return "users/\(userId)/books/\(bookId)/photos/\(photoId).jpg"
            }
        }
    }
    
    /// 画像をアップロード
    func uploadImage(_ image: UIImage, path: StoragePath, compressionQuality: CGFloat = 0.8) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw AppError.custom("画像データの変換に失敗しました")
        }
        
        return try await uploadData(imageData, path: path.path)
    }
    
    /// データをアップロード
    func uploadData(_ data: Data, path: String) async throws -> String {
        let storageRef = storage.reference().child(path)
        
        // アップロード
        _ = try await storageRef.putDataAsync(data)
        
        // ダウンロードURL取得
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    /// 画像を削除
    func deleteImage(at path: String) async throws {
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
    }
    
    /// URLから画像を削除
    func deleteImage(url: String) async throws {
        // URLからパスを抽出
        guard let storageUrl = URL(string: url),
              let path = extractPath(from: storageUrl) else {
            throw AppError.custom("無効な画像URLです")
        }
        
        try await deleteImage(at: path)
    }
    
    private func extractPath(from url: URL) -> String? {
        // Firebase Storage URLからパスを抽出
        // 例: https://firebasestorage.googleapis.com/v0/b/PROJECT_ID.appspot.com/o/PATH%2Ffile.jpg?alt=media&token=TOKEN
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let pathComponent = components.path.split(separator: "/").last else {
            return nil
        }
        
        // URLデコード
        return String(pathComponent).removingPercentEncoding
    }
}
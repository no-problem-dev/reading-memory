import Foundation
import SwiftUI
import UIKit

/// 画像IDからURL取得やAsyncImage用のヘルパー機能を提供
final class ImageService {
    static let shared = ImageService()
    
    private let imageRepository = ImageEntityRepository.shared
    private let cache = NSCache<NSString, CachedImage>()
    
    private init() {
        cache.countLimit = 100  // 最大100枚をキャッシュ
    }
    
    /// 画像IDからURLを取得（キャッシュ付き）
    func getImageUrl(id: String?) async -> URL? {
        guard let id = id, !id.isEmpty else { return nil }
        
        // キャッシュを確認
        if let cached = cache.object(forKey: id as NSString) {
            return URL(string: cached.url)
        }
        
        do {
            let image = try await imageRepository.getImage(id: id)
            
            // キャッシュに保存
            let cached = CachedImage(id: image.id, url: image.url)
            cache.setObject(cached, forKey: id as NSString)
            
            return URL(string: image.url)
        } catch {
            print("Failed to get image URL for id: \(id), error: \(error)")
            return nil
        }
    }
}

private class CachedImage {
    let id: String
    let url: String
    
    init(id: String, url: String) {
        self.id = id
        self.url = url
    }
}

/// 画像IDからAsyncImageを表示するView
struct RemoteImage: View {
    let imageId: String?
    let contentMode: ContentMode
    
    @State private var imageUrl: URL?
    
    init(imageId: String?, contentMode: ContentMode = .fit) {
        self.imageId = imageId
        self.contentMode = contentMode
    }
    
    var body: some View {
        AsyncImage(url: imageUrl) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure(_):
                SwiftUI.Image(systemName: "photo")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            @unknown default:
                EmptyView()
            }
        }
        .task {
            imageUrl = await ImageService.shared.getImageUrl(id: imageId)
        }
    }
}
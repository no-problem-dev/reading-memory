import Foundation

/// 画像メタデータのエンティティ
struct ImageEntity: Identifiable, Codable {
    let id: String
    let url: String
    let contentType: String
    let size: Int
    let metadata: ImageMetadata?
    let createdAt: Date
    let updatedAt: Date
    
    struct ImageMetadata: Codable {
        let width: Int?
        let height: Int?
    }
}

extension ImageEntity {
    static func mock() -> ImageEntity {
        ImageEntity(
            id: UUID().uuidString,
            url: "https://example.com/image.jpg",
            contentType: "image/jpeg",
            size: 1024 * 1024,
            metadata: ImageMetadata(width: 1024, height: 768),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
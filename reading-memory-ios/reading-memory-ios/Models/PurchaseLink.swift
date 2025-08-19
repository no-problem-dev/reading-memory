import Foundation

struct PurchaseLink: Codable, Identifiable, Equatable {
    let id: String
    let title: String // "Amazon", "楽天ブックス"など
    let url: String
    let price: Double?
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        url: String,
        price: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.price = price
        self.createdAt = createdAt
    }
    
    // 一般的な購入先のプリセット
    static func amazon(url: String, price: Double? = nil) -> PurchaseLink {
        return PurchaseLink(
            title: "Amazon",
            url: url,
            price: price
        )
    }
    
    static func rakuten(url: String, price: Double? = nil) -> PurchaseLink {
        return PurchaseLink(
            title: "楽天ブックス",
            url: url,
            price: price
        )
    }
    
    static func kinokuniya(url: String, price: Double? = nil) -> PurchaseLink {
        return PurchaseLink(
            title: "紀伊國屋書店",
            url: url,
            price: price
        )
    }
}
import Foundation
import FirebaseFirestore

struct PurchaseLinkDTO: Codable {
    let id: String
    let title: String
    let url: String
    let price: Double?
    let createdAt: Timestamp
    
    init(from purchaseLink: PurchaseLink) {
        self.id = purchaseLink.id
        self.title = purchaseLink.title
        self.url = purchaseLink.url
        self.price = purchaseLink.price
        self.createdAt = Timestamp(date: purchaseLink.createdAt)
    }
    
    func toDomain() -> PurchaseLink {
        return PurchaseLink(
            id: id,
            title: title,
            url: url,
            price: price,
            createdAt: createdAt.dateValue()
        )
    }
}
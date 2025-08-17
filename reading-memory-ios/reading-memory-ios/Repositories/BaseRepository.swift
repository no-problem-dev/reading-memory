import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol BaseRepository {
    associatedtype T: Codable
    var collectionName: String { get }
    var db: Firestore { get }
}

extension BaseRepository {
    var db: Firestore {
        return Firestore.firestore()
    }
    
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    func documentToModel(_ document: DocumentSnapshot) throws -> T? {
        return try document.data(as: T.self)
    }
    
    func modelToData(_ model: T) throws -> [String: Any] {
        let encoder = Firestore.Encoder()
        return try encoder.encode(model)
    }
}
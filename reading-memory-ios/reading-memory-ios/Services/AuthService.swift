import Foundation
import FirebaseAuth

@MainActor
final class AuthService {
    static let shared = AuthService()
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    var currentUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    private init() {}
    
    func startAuthStateListener(_ handler: @escaping (FirebaseAuth.User?) -> Void) {
        authStateListener = Auth.auth().addStateDidChangeListener { _, user in
            handler(user)
        }
    }
    
    func stopAuthStateListener() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
            authStateListener = nil
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
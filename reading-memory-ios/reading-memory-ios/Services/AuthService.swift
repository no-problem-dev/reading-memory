import Foundation
import FirebaseAuth

enum DeleteAccountError: Error, LocalizedError {
    case authenticationRequired
    case permissionDenied
    case serverError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "認証が必要です。"
        case .permissionDenied:
            return "権限がありません。"
        case .serverError:
            return "サーバーエラーが発生しました。"
        case .invalidResponse:
            return "サーバーからの応答が不正です。"
        }
    }
}

// Firebase AuthUserを抽象化
class AuthUser {
    private let firebaseUser: FirebaseAuth.User
    
    init(firebaseUser: FirebaseAuth.User) {
        self.firebaseUser = firebaseUser
    }
    
    var uid: String {
        firebaseUser.uid
    }
    
    var email: String? {
        firebaseUser.email
    }
    
    var displayName: String? {
        firebaseUser.displayName
    }
    
    var photoURL: URL? {
        firebaseUser.photoURL
    }
    
    var isAnonymous: Bool {
        firebaseUser.isAnonymous
    }
    
    func getIDToken() async throws -> String {
        return try await firebaseUser.getIDToken()
    }
    
    func reload() async throws {
        try await firebaseUser.reload()
    }
    
    func delete() async throws {
        try await firebaseUser.delete()
    }
}

@MainActor
final class AuthService {
    static let shared = AuthService()
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var _currentUser: AuthUser?
    
    var currentUser: AuthUser? {
        return _currentUser
    }
    
    private init() {
        // 初期化時に現在のFirebaseユーザーをチェック
        if let firebaseUser = Auth.auth().currentUser {
            _currentUser = AuthUser(firebaseUser: firebaseUser)
        }
    }
    
    func startAuthStateListener(_ handler: @escaping (AuthUser?) -> Void) {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                let authUser = AuthUser(firebaseUser: user)
                self?._currentUser = authUser
                handler(authUser)
            } else {
                self?._currentUser = nil
                handler(nil)
            }
        }
        
        // 即座に現在のユーザーを通知
        handler(_currentUser)
    }
    
    func stopAuthStateListener() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        _currentUser = nil
    }
    
    func deleteAccount() async throws {
        let apiClient = APIClient.shared
        _ = try await apiClient.deleteAccount()
        
        // Firebase上のユーザーも削除
        try await Auth.auth().currentUser?.delete()
        _currentUser = nil
    }
}
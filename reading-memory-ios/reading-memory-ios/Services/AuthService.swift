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
        guard let firebaseUser = Auth.auth().currentUser else {
            throw DeleteAccountError.authenticationRequired
        }
        
        // 最近のログインを確認するため、ユーザー情報をリロード
        do {
            try await firebaseUser.reload()
        } catch {
            print("DEBUG: Failed to reload user, but continuing: \(error)")
        }
        
        // APIサーバー側でデータを削除
        let apiClient = APIClient.shared
        let result = try await apiClient.deleteAccount()
        
        // エラーがある場合は、部分的な削除の可能性を警告
        if !result.errors.isEmpty {
            print("WARNING: Account deletion had errors: \(result.errors)")
        }
        
        // クライアント側でFirebase Authアカウントを削除
        // API側でも削除を試みているが、権限の問題で失敗する可能性があるため、
        // クライアント側でも削除を実行
        do {
            try await firebaseUser.delete()
            print("INFO: Successfully deleted Firebase Auth account from client")
        } catch {
            // API側で既に削除されている可能性もあるため、エラーはログに記録するが続行
            print("ERROR: Failed to delete Firebase Auth account from client: \(error)")
            // ユーザーが既に削除されている場合は成功として扱う
            if (error as NSError).code == 17011 { // FIRAuthErrorCodeUserNotFound
                print("INFO: User already deleted, treating as success")
            } else {
                throw error
            }
        }
        
        _currentUser = nil
    }
}
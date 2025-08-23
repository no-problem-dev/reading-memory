import Foundation

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

// ダミーのAuthUser型
class AuthUser {
    let uid: String = "dummy-user-id"
    let email: String? = "user@example.com"
    let displayName: String? = "Test User"
    let photoURL: URL? = nil
    let isAnonymous: Bool = false
    
    func getIDToken() -> String {
        // ダミーのIDトークンを返す
        return "dummy-id-token"
    }
    
    func reload() async throws {
        // 何もしない
    }
    
    func delete() async throws {
        // 何もしない
    }
}

@MainActor
final class AuthService {
    static let shared = AuthService()
    
    private var _currentUser: AuthUser? = AuthUser() // デフォルトでログイン状態
    
    var currentUser: AuthUser? {
        return _currentUser
    }
    
    private init() {}
    
    func startAuthStateListener(_ handler: @escaping (AuthUser?) -> Void) {
        // 即座に現在のユーザーを返す
        handler(_currentUser)
    }
    
    func stopAuthStateListener() {
        // 何もしない
    }
    
    func signOut() throws {
        _currentUser = nil
    }
    
    func deleteAccount() async throws {
        let apiClient = APIClient.shared
        _ = try await apiClient.deleteAccount()
        _currentUser = nil
    }
}
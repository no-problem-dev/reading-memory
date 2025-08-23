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
    
    func deleteAccount() async throws -> DeleteAccountResult {
        do {
            let result = try await APIClient.shared.deleteAccount()
            return DeleteAccountResult(
                success: result.success,
                deletedCollections: result.deletedCollections,
                errors: result.errors
            )
        } catch let error as AppError {
            // AppErrorをDeleteAccountErrorに変換
            switch error {
            case .authenticationRequired:
                throw DeleteAccountError.authenticationRequired
            case .permissionDenied:
                throw DeleteAccountError.permissionDenied
            case .custom(let message):
                if message.contains("認証") {
                    throw DeleteAccountError.authenticationRequired
                } else {
                    throw DeleteAccountError.serverError
                }
            default:
                throw DeleteAccountError.serverError
            }
        } catch {
            throw DeleteAccountError.serverError
        }
    }
}
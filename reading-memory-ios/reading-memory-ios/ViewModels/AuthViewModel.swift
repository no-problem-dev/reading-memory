import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit

@MainActor
@Observable
final class AuthViewModel: BaseViewModel {
    private let authService = AuthService.shared
    var currentUser: User?
    
    private var currentNonce: String?
    
    override init() {
        super.init()
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authService.startAuthStateListener { [weak self] authUser in
            if let authUser = authUser {
                self?.currentUser = User(
                    id: authUser.uid,
                    email: authUser.email ?? "",
                    displayName: authUser.displayName ?? "",
                    photoURL: nil,
                    provider: .email,
                    createdAt: Date(),
                    lastLoginAt: Date()
                )
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    func cleanupAuthListener() {
        authService.stopAuthStateListener()
    }
    
    func signInWithGoogle() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            // ダミー実装：Google認証成功をシミュレート
            self.currentUser = User(
                id: "dummy-google-user",
                email: "user@gmail.com",
                displayName: "Google User",
                photoURL: nil,
                provider: .google,
                createdAt: Date(),
                lastLoginAt: Date()
            )
        }
    }
    
    func signOut() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            try authService.signOut()
            currentUser = nil
        }
    }
    
    func startSignInWithAppleFlow() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }
    
    func signInWithApple(authorization: ASAuthorization) async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Apple認証情報の取得に失敗しました"])
            }
            
            var displayName = ""
            if let fullName = appleIDCredential.fullName {
                let firstName = fullName.givenName ?? ""
                let lastName = fullName.familyName ?? ""
                displayName = "\(lastName) \(firstName)".trimmingCharacters(in: .whitespaces)
            }
            
            // ダミー実装：Apple認証成功をシミュレート
            self.currentUser = User(
                id: "dummy-apple-user",
                email: appleIDCredential.email ?? "user@icloud.com",
                displayName: displayName.isEmpty ? "Apple User" : displayName,
                photoURL: nil,
                provider: .apple,
                createdAt: Date(),
                lastLoginAt: Date()
            )
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}
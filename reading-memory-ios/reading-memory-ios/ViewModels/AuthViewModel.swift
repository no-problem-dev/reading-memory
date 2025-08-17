import Foundation
import SwiftUI
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

@MainActor
@Observable
final class AuthViewModel: BaseViewModel {
    var currentUser: User?
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    
    override init() {
        super.init()
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                let provider = firebaseUser.providerData.first?.providerID ?? "password"
                self?.currentUser = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName ?? "",
                    photoURL: firebaseUser.photoURL?.absoluteString,
                    provider: User.AuthProvider(providerId: provider),
                    createdAt: firebaseUser.metadata.creationDate ?? Date(),
                    lastLoginAt: firebaseUser.metadata.lastSignInDate ?? Date()
                )
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    func cleanupAuthListener() {
        if let authStateHandler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(authStateHandler)
            self.authStateHandler = nil
        }
    }
    
    func signInWithGoogle() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "ルートビューコントローラーが見つかりません"])
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "IDトークンの取得に失敗しました"])
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            self.currentUser = User(
                id: authResult.user.uid,
                email: authResult.user.email ?? "",
                displayName: authResult.user.displayName ?? "",
                photoURL: authResult.user.photoURL?.absoluteString,
                provider: .google,
                createdAt: authResult.user.metadata.creationDate ?? Date(),
                lastLoginAt: authResult.user.metadata.lastSignInDate ?? Date()
            )
        }
    }
    
    func signOut() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
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
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Apple認証情報の取得に失敗しました"])
            }
            
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            var displayName = authResult.user.displayName ?? ""
            if displayName.isEmpty,
               let fullName = appleIDCredential.fullName {
                let firstName = fullName.givenName ?? ""
                let lastName = fullName.familyName ?? ""
                displayName = "\(lastName) \(firstName)".trimmingCharacters(in: .whitespaces)
            }
            
            self.currentUser = User(
                id: authResult.user.uid,
                email: authResult.user.email ?? appleIDCredential.email ?? "",
                displayName: displayName,
                photoURL: authResult.user.photoURL?.absoluteString,
                provider: .apple,
                createdAt: authResult.user.metadata.creationDate ?? Date(),
                lastLoginAt: authResult.user.metadata.lastSignInDate ?? Date()
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
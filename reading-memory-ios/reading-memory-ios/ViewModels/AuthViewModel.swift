import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

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
            guard self != nil else { return }
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presentingViewController = windowScene.windows.first?.rootViewController else {
                throw AppError.custom("画面の取得に失敗しました")
            }
            
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AppError.custom("Google Sign-In設定が見つかりません")
            }
            
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AppError.custom("IDトークンの取得に失敗しました")
            }
            
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            _ = try await Auth.auth().signIn(with: credential)
            // AuthService の AuthStateListener が自動的に currentUser を更新する
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
            
            guard let nonce = self.currentNonce else {
                throw AppError.custom("無効なnonce値です")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                throw AppError.custom("Apple IDトークンが取得できませんでした")
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AppError.custom("Apple IDトークンの変換に失敗しました")
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                         rawNonce: nonce,
                                                         fullName: appleIDCredential.fullName)
            
            _ = try await Auth.auth().signIn(with: credential)
            // AuthService の AuthStateListener が自動的に currentUser を更新する
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
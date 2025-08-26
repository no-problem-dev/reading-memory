import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    private let hasLaunchedBeforeKey = "com.readingmemory.hasLaunchedBefore"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase初期化
        FirebaseApp.configure()
        
        // RevenueCat初期化
        SubscriptionStore.shared.initialize()
        
        // 初回起動チェック
        checkFirstLaunchAndSignOut()
        
        // 開発中は毎回キャッシュをクリア（問題が解決したら削除）
        #if DEBUG
        ImageCacheService.shared.clearCache()
        print("Image cache cleared on launch (DEBUG mode)")
        #endif
        
        return true
    }
    
    private func checkFirstLaunchAndSignOut() {
        let userDefaults = UserDefaults.standard
        let hasLaunchedBefore = userDefaults.bool(forKey: hasLaunchedBeforeKey)
        
        if !hasLaunchedBefore {
            // 初回起動の場合、Firebase Authからサインアウト
            do {
                try Auth.auth().signOut()
                print("First launch detected: Signed out from Firebase Auth")
            } catch {
                print("Error signing out on first launch: \(error)")
            }
            
            // 初回起動フラグを設定
            userDefaults.set(true, forKey: hasLaunchedBeforeKey)
        }
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
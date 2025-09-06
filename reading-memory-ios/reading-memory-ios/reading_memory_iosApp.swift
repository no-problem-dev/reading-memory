import SwiftUI
// import FirebaseCore

@main
struct reading_memory_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }
}

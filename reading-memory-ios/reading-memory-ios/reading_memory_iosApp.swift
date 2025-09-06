import SwiftUI
// import FirebaseCore

@main
struct reading_memory_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @MainActor
    @State private var bookStore = ServiceContainer.shared.getBookStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(bookStore)
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }
}

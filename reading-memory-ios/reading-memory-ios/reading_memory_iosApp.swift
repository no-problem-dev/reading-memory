import SwiftUI
import FirebaseCore

@main
struct reading_memory_iosApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

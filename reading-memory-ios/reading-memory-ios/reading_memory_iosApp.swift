//
//  reading_memory_iosApp.swift
//  reading-memory-ios
//
//  Created by 谷口恭一 on 2025/08/17.
//

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

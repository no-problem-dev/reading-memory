import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var needsOnboarding = false
    @State private var isCheckingProfile = true
    @State private var isInitializing = false
    @State private var showSplash = true
    @State private var isDataReady = false
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                if !isDataReady {
                    // Show nothing while data is loading
                    Color.clear
                } else if authViewModel.currentUser == nil {
                    AuthView()
                        .environment(authViewModel)
                } else if needsOnboarding {
                    OnboardingView {
                        needsOnboarding = false
                    }
                    .environment(authViewModel)
                } else {
                    MainTabView()
                        .environment(authViewModel)
                }
            }
            
            // Splash screen overlay
            if showSplash {
                SplashScreenView {
                    // Splash animation completed
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            }
        }
        .task {
            // Start initialization immediately when splash appears
            await initializeUserIfNeeded()
        }
        .onChange(of: authViewModel.currentUser) { oldUser, newUser in
            if oldUser != newUser {
                // ユーザーがnilになった場合（ログアウト・削除）、即座にデータをリセット
                if newUser == nil {
                    isDataReady = false
                    needsOnboarding = false
                    isCheckingProfile = false
                    // 少し待ってからisDataReadyをtrueに設定して画面を更新
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                        isDataReady = true
                    }
                } else {
                    // ログインした場合
                    Task {
                        await initializeUserIfNeeded()
                    }
                }
            }
        }
    }
    
    @MainActor
    private func initializeUserIfNeeded() async {
        guard authViewModel.currentUser != nil else {
            isCheckingProfile = false
            needsOnboarding = false
            isDataReady = true
            return
        }
        
        isInitializing = true
        
        do {
            // Step 1: Initialize user (creates user document if needed)
            let apiClient = APIClient.shared
            _ = try await apiClient.initializeUser()
            
            // Step 2: Check onboarding status
            let status = try await apiClient.getOnboardingStatus()
            
            needsOnboarding = status.needsOnboarding
            isCheckingProfile = false
            isInitializing = false
            
            // Wait a bit to ensure smooth transition from splash
            if showSplash {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            isDataReady = true
            
        } catch {
            print("Error initializing user: \(error)")
            // If there's an error, assume onboarding is needed
            needsOnboarding = true
            isCheckingProfile = false
            isInitializing = false
            isDataReady = true
        }
    }
}


#Preview {
    ContentView()
}

import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var needsOnboarding = false
    @State private var isCheckingProfile = true
    @State private var isInitializing = false
    
    var body: some View {
        Group {
            if isCheckingProfile {
                // Loading state while checking profile
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("読み込み中...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
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
        .task {
            await initializeUserIfNeeded()
        }
        .onChange(of: authViewModel.currentUser) { oldUser, newUser in
            if oldUser != newUser {
                Task {
                    await initializeUserIfNeeded()
                }
            }
        }
    }
    
    @MainActor
    private func initializeUserIfNeeded() async {
        guard authViewModel.currentUser != nil else {
            isCheckingProfile = false
            needsOnboarding = false
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
            
        } catch {
            print("Error initializing user: \(error)")
            // If there's an error, assume onboarding is needed
            needsOnboarding = true
            isCheckingProfile = false
            isInitializing = false
        }
    }
}


#Preview {
    ContentView()
}

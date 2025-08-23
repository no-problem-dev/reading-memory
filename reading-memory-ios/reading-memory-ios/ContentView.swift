import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var needsOnboarding = false
    @State private var isCheckingProfile = true
    
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
            await checkUserProfile()
        }
        .onChange(of: authViewModel.currentUser) { oldUser, newUser in
            if oldUser != newUser {
                Task {
                    await checkUserProfile()
                }
            }
        }
    }
    
    @MainActor
    private func checkUserProfile() async {
        guard let currentUser = authViewModel.currentUser else {
            isCheckingProfile = false
            needsOnboarding = false
            return
        }
        
        do {
            let userProfileRepository = UserProfileRepository.shared
            let profile = try await userProfileRepository.getUserProfile()
            
            needsOnboarding = (profile == nil)
            isCheckingProfile = false
            
        } catch {
            // If there's an error checking profile, assume onboarding is needed
            needsOnboarding = true
            isCheckingProfile = false
        }
    }
}

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        TabView {
            BookShelfView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("本棚")
                }
            
            WantToReadListView()
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("読みたい")
                }
            
            GoalDashboardView()
                .tabItem {
                    Image(systemName: "target")
                    Text("目標")
                }
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("プロフィール")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
        }
    }
}

#Preview {
    ContentView()
}

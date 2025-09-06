import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab = 0
    @State private var bookStore = ServiceContainer.shared.getBookStore()
    @State private var userProfileStore = ServiceContainer.shared.getUserProfileStore()
    @State private var subscriptionStateStore = ServiceContainer.shared.getSubscriptionStateStore()
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Main Content
            TabView(selection: $selectedTab) {
                // 本棚
                BookShelfHomeView()
                    .tabItem {
                        Label {
                            Text("本棚")
                        } icon: {
                            Image(systemName: selectedTab == 0 ? "books.vertical.fill" : "books.vertical")
                        }
                    }
                    .tag(0)
                
                // 記録（統計・目標・アチーブメント）
//                RecordsHubView()
//                    .tabItem {
//                        Label {
//                            Text("記録")
//                        } icon: {
//                            Image(systemName: selectedTab == 1 ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
//                        }
//                    }
//                    .tag(1)
                
                // 発見（読みたいリスト・検索）
                DiscoveryView()
                    .tabItem {
                        Label {
                            Text("発見")
                        } icon: {
                            Image(systemName: selectedTab == 2 ? "sparkle.magnifyingglass" : "magnifyingglass")
                        }
                    }
                    .tag(2)
                
                // 設定
                ProfileTabView()
                    .tabItem {
                        Label {
                            Text("設定")
                        } icon: {
                            // カスタムアイコンまたはシステムアイコン
                            if selectedTab == 3 {
                                Image(systemName: "gearshape.fill")
                            } else {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                    .tag(3)
            }
            .tint(MemoryTheme.Colors.primaryBlue)
        }
        .environment(bookStore)
        .environment(userProfileStore)
        .environment(subscriptionStateStore)
        .task {
            // プロフィールを初回ロード
            await userProfileStore.loadProfile()
            // 購読状態を初回ロード
            await subscriptionStateStore.initialize()
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthViewModel())
        .environment(ServiceContainer.shared.getBookStore())
        .environment(ServiceContainer.shared.getUserProfileStore())
}
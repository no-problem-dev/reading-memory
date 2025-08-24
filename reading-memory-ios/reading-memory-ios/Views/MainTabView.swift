import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab = 0
    @State private var showAddBook = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Main Content
            TabView(selection: $selectedTab) {
                // 本棚（ホーム）
                BookShelfHomeView(showAddBook: $showAddBook)
                    .tabItem {
                        Label {
                            Text("メモリー")
                        } icon: {
                            Image(systemName: selectedTab == 0 ? "books.vertical.fill" : "books.vertical")
                        }
                    }
                    .tag(0)
                
                // 記録（統計・目標・アチーブメント）
                RecordsHubView()
                    .tabItem {
                        Label {
                            Text("記録")
                        } icon: {
                            Image(systemName: selectedTab == 1 ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
                        }
                    }
                    .tag(1)
                
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
                
                // プロフィール
                ProfileTabView()
                    .tabItem {
                        Label {
                            Text("プロフィール")
                        } icon: {
                            // カスタムアイコンまたはシステムアイコン
                            if selectedTab == 3 {
                                Image(systemName: "person.crop.circle.fill")
                            } else {
                                Image(systemName: "person.crop.circle")
                            }
                        }
                    }
                    .tag(3)
            }
            .tint(MemoryTheme.Colors.primaryBlue)
            
            // FAB for adding books (only show on home tab)
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MemoryFloatingActionButton {
                            showAddBook = true
                        }
                        .padding(.bottom, 100) // Increased to avoid tab bar
                        .padding(.trailing, MemorySpacing.lg)
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: selectedTab)
            }
        }
        .sheet(isPresented: $showAddBook) {
            BookAdditionFlowView()
        }
    }
}

// Memory Floating Action Button wrapper
struct MemoryFloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        FloatingActionButton(action: action, icon: "plus")
    }
}


#Preview {
    MainTabView()
        .environment(AuthViewModel())
}
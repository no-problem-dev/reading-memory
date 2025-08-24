import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var showAddBook = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // 本棚（ホーム）
                BookShelfHomeView(showAddBook: $showAddBook)
                    .tabItem {
                        Image(systemName: "books.vertical.fill")
                        Text("本棚")
                    }
                    .tag(0)
                
                // 記録（統計・目標・アチーブメント）
                RecordsHubView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("記録")
                    }
                    .tag(1)
                
                // 発見（読みたいリスト・検索）
                DiscoveryView()
                    .tabItem {
                        Image(systemName: "sparkle.magnifyingglass")
                        Text("発見")
                    }
                    .tag(2)
            }
            .overlay(alignment: .topTrailing) {
                // プロフィールアイコン
                Button {
                    showProfile = true
                } label: {
                    ProfileIconView()
                        .padding()
                }
            }
            
            // FAB for adding books (only show on home tab)
            if selectedTab == 0 {
                FloatingActionButton {
                    showAddBook = true
                }
                .padding(.bottom, 80)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileNavigationView()
        }
        .sheet(isPresented: $showAddBook) {
            BookRegistrationView()
        }
    }
}

// Floating Action Button
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

// Profile Icon View
struct ProfileIconView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        if let photoURL = authViewModel.currentUser?.photoURL,
           let url = URL(string: photoURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.title)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .frame(width: 32, height: 32)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthViewModel())
}
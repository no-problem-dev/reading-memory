import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    
    var body: some View {
        if authViewModel.currentUser != nil {
            MainTabView()
                .environment(authViewModel)
        } else {
            AuthView()
                .environment(authViewModel)
        }
    }
}

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        TabView {
            BookListView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("本棚")
                }
            
            Text("読書中")
                .tabItem {
                    Image(systemName: "book")
                    Text("読書中")
                }
            
            Text("統計")
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("統計")
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

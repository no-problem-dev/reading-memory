import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    
    var body: some View {
        if authViewModel.currentUser != nil {
            MainTabView()
                .environment(authViewModel)
        } else {
            AuthView()
        }
    }
}

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        TabView {
            Text("本棚")
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
            
            Text("設定")
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

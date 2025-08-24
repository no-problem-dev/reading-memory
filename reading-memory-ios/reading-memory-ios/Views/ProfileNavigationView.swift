import SwiftUI

struct ProfileNavigationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false
    @State private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // プロフィール情報
                ProfileHeaderView()
                    .padding()
                
                // メニューリスト
                List {
                    Section {
                        NavigationLink {
                            ProfileEditView(viewModel: profileViewModel)
                        } label: {
                            Label("プロフィールを編集", systemImage: "person.fill")
                        }
                        
                        NavigationLink {
                            PublicBookshelfSettingsView()
                        } label: {
                            Label("公開本棚の設定", systemImage: "books.vertical.circle")
                        }
                    }
                    
                    Section {
                        Button {
                            showSettings = true
                        } label: {
                            Label("設定", systemImage: "gear")
                                .foregroundStyle(.primary)
                        }
                        
                        NavigationLink {
                            AboutView()
                        } label: {
                            Label("このアプリについて", systemImage: "info.circle")
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

// プロフィールヘッダー
struct ProfileHeaderView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profile: UserProfile?
    
    var body: some View {
        VStack(spacing: 16) {
            // アバター
            if let photoURL = authViewModel.currentUser?.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
            }
            
            // 名前
            if let profile = profile {
                Text(profile.displayName)
                    .font(.title3)
                    .fontWeight(.medium)
                
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            // 統計サマリー
            HStack(spacing: 30) {
                ProfileStatItem(value: "0", label: "読了")
                ProfileStatItem(value: "0", label: "読書中")
                ProfileStatItem(value: "0", label: "読みたい")
            }
            .padding(.top, 8)
        }
        .task {
            await loadProfile()
        }
    }
    
    private func loadProfile() async {
        do {
            profile = try await APIClient.shared.getUserProfile()
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
}

struct ProfileStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// 公開本棚設定（プレースホルダー）
struct PublicBookshelfSettingsView: View {
    var body: some View {
        Text("公開本棚の設定")
            .navigationTitle("公開本棚")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// アプリについて（プレースホルダー）
struct AboutView: View {
    var body: some View {
        Text("読書メモリーについて")
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileNavigationView()
        .environment(AuthViewModel())
}
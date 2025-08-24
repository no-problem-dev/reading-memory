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
    @State private var statistics = ProfileViewModel.ProfileStatistics()
    
    var body: some View {
        VStack(spacing: MemorySpacing.md) {
            // アバター
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlueLight.opacity(0.3),
                                MemoryTheme.Colors.primaryBlue.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .memoryShadow(.soft)
                
                if let photoURL = authViewModel.currentUser?.photoURL,
                   let url = URL(string: photoURL) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                }
            }
            
            // 名前
            if let profile = profile {
                VStack(spacing: MemorySpacing.xs) {
                    Text(profile.displayName)
                        .font(MemoryTheme.Fonts.headline())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                    
                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(MemoryTheme.Fonts.footnote())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
            
            // 統計サマリー
            HStack(spacing: MemorySpacing.lg) {
                ProfileStatItem(
                    value: "\(statistics.completedBooks)",
                    label: "読了"
                )
                Divider()
                    .frame(height: 30)
                    .foregroundColor(MemoryTheme.Colors.inkPale)
                ProfileStatItem(
                    value: "\(statistics.readingBooks)",
                    label: "読書中"
                )
                Divider()
                    .frame(height: 30)
                    .foregroundColor(MemoryTheme.Colors.inkPale)
                ProfileStatItem(
                    value: "\(statistics.wantToReadBooks)",
                    label: "読みたい"
                )
            }
            .padding(.horizontal, MemorySpacing.lg)
            .padding(.vertical, MemorySpacing.sm)
            .background(MemoryTheme.Colors.cardBackground)
            .cornerRadius(MemoryRadius.medium)
            .memoryShadow(.soft)
        }
        .task {
            await loadProfile()
            await loadStatistics()
        }
    }
    
    private func loadProfile() async {
        do {
            profile = try await APIClient.shared.getUserProfile()
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
    
    private func loadStatistics() async {
        let viewModel = ProfileViewModel()
        await viewModel.loadProfile()
        statistics = viewModel.statistics
    }
}

struct ProfileStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: MemorySpacing.xs) {
            Text(value)
                .font(MemoryTheme.Fonts.title3())
                .fontWeight(.bold)
                .foregroundColor(MemoryTheme.Colors.primaryBlue)
            Text(label)
                .font(MemoryTheme.Fonts.caption())
                .foregroundColor(MemoryTheme.Colors.inkGray)
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
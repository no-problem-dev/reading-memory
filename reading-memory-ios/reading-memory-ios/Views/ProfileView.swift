import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(UserProfileStore.self) private var profileStore
    @State private var showingEditView = false
    @State private var showingGoalSetting = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    if profileStore.isLoading {
                        ProgressView()
                            .tint(MemoryTheme.Colors.primaryBlue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if let profile = profileStore.userProfile {
                        VStack(spacing: 0) {
                            // Header section with gradient
                            profileHeaderSection(profile: profile)
                            
                            VStack(spacing: MemorySpacing.lg) {
                                // Statistics Cards
                                statisticsSection
                                    .padding(.horizontal, MemorySpacing.md)
                                
                                // Favorite Genres
                                if !profile.favoriteGenres.isEmpty {
                                    favoriteGenresSection(genres: profile.favoriteGenres)
                                        .padding(.horizontal, MemorySpacing.md)
                                }
                                
                                // Bio
                                if let bio = profile.bio, !bio.isEmpty {
                                    bioSection(bio: bio)
                                        .padding(.horizontal, MemorySpacing.md)
                                }
                            }
                            .padding(.vertical, MemorySpacing.lg)
                        }
                    } else {
                        VStack(spacing: MemorySpacing.md) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundColor(Color(.tertiaryLabel))
                            Text("プロフィールが見つかりません")
                                .font(.headline)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .padding(.top, 100)
                    }
                }
                .refreshable {
                    await profileStore.forceRefresh()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditView = true
                    } label: {
                        Text("編集")
                            .font(.subheadline)
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                }
            }
            .navigationDestination(isPresented: $showingEditView) {
                ProfileEditView()
            }
            .sheet(isPresented: $showingGoalSetting) {
                GoalSettingView()
            }
            .task {
                // 初回ロードはMainTabViewで実行済み
            }
            .onAppear {
                // 自動リフレッシュはUserProfileStoreが管理
            }
            .alert("エラー", isPresented: .constant(profileStore.error != nil)) {
                Button("OK") {
                    // エラーのクリアは必要に応じて実装
                }
            } message: {
                if let error = profileStore.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private func profileHeaderSection(profile: UserProfile) -> some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    MemoryTheme.Colors.primaryBlue.opacity(0.15),
                    MemoryTheme.Colors.primaryBlue.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)
            
            VStack(spacing: MemorySpacing.md) {
                // Profile Image
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
                        .frame(width: 120, height: 120)
                        .memoryShadow(.medium)
                    
                    if let imageId = profile.avatarImageId {
                        RemoteImage(imageId: imageId, contentMode: .fill)
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 77))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            .frame(width: 110, height: 110)
                    }
                }
                
                VStack(spacing: MemorySpacing.xs) {
                    // Display Name
                    Text(profile.displayName)
                        .font(.title2)
                        .foregroundColor(Color(.label))
                    
                    // Member Since
                    HStack(spacing: MemorySpacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                        Text("メンバー登録日: \(profile.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                .padding(.bottom, MemorySpacing.lg)
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(spacing: MemorySpacing.sm) {
            HStack(spacing: MemorySpacing.sm) {
                MemoryStatCard(
                    title: "総冊数",
                    value: "\(profileStore.statistics.totalBooks)",
                    icon: "books.vertical.fill",
                    color: MemoryTheme.Colors.primaryBlue
                )
                
                MemoryStatCard(
                    title: "読了",
                    value: "\(profileStore.statistics.completedBooks)",
                    icon: "checkmark.circle.fill",
                    color: Color(.systemGreen)
                )
            }
            
            HStack(spacing: MemorySpacing.sm) {
                MemoryStatCard(
                    title: "読書中",
                    value: "\(profileStore.statistics.readingBooks)",
                    icon: "book.fill",
                    color: MemoryTheme.Colors.goldenMemory
                )
                
                MemoryStatCard(
                    title: "読みたい",
                    value: "\(profileStore.statistics.wantToReadBooks)",
                    icon: "bookmark.fill",
                    color: MemoryTheme.Colors.goldenMemory
                )
            }
            
            HStack(spacing: MemorySpacing.sm) {
                MemoryStatCard(
                    title: "総メモ数",
                    value: "\(profileStore.statistics.totalMemos)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: MemoryTheme.Colors.primaryBlue
                )
                
                MemoryStatCard(
                    title: "平均評価",
                    value: profileStore.statistics.averageRating > 0 ? String(format: "%.1f", profileStore.statistics.averageRating) : "-",
                    icon: "star.fill",
                    color: MemoryTheme.Colors.goldenMemory
                )
            }
        }
    }
    
    private func favoriteGenresSection(genres: [BookGenre]) -> some View {
        MemoryCard(padding: MemorySpacing.md) {
            VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 18))
                        .foregroundColor(MemoryTheme.Colors.goldenMemory)
                    Text("お気に入りジャンル")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                FlowLayout(spacing: MemorySpacing.xs) {
                    ForEach(genres, id: \.self) { genre in
                        Text(genre.displayName)
                            .font(.caption)
                            .padding(.horizontal, MemorySpacing.md)
                            .padding(.vertical, MemorySpacing.xs)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.goldenMemoryLight.opacity(0.15),
                                        MemoryTheme.Colors.goldenMemory.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(MemoryTheme.Colors.goldenMemory)
                            .cornerRadius(MemoryRadius.full)
                    }
                }
            }
        }
    }
    
    private func bioSection(bio: String) -> some View {
        MemoryCard(padding: MemorySpacing.md) {
            VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 18))
                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    Text("自己紹介")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                Text(bio)
                    .font(.body)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MemoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MemorySpacing.xs) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.2),
                                color.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(.label))
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(MemorySpacing.md)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
    }
}

// Simple FlowLayout for genres

#Preview {
    ProfileView()
}
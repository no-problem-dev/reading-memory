import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
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
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(MemoryTheme.Colors.primaryBlue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if let profile = viewModel.userProfile {
                        VStack(spacing: 0) {
                            // Header section with gradient
                            profileHeaderSection(profile: profile)
                            
                            VStack(spacing: MemorySpacing.lg) {
                                // Statistics Cards
                                statisticsSection
                                    .padding(.horizontal, MemorySpacing.md)
                                
                                // Reading Goal Progress
                                if let goal = profile.readingGoal, goal > 0 {
                                    readingGoalProgress(goal: goal)
                                        .padding(.horizontal, MemorySpacing.md)
                                }
                                
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
                    viewModel.forceRefresh()
                    await viewModel.loadProfile()
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
            .sheet(isPresented: $showingEditView) {
                ProfileEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingGoalSetting) {
                GoalSettingView()
            }
            .task {
                if !viewModel.hasLoadedInitialData {
                    await viewModel.loadProfile()
                }
            }
            .onAppear {
                if viewModel.hasLoadedInitialData && viewModel.shouldRefreshData() {
                    Task {
                        await viewModel.loadProfile()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
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
                    
                    ProfileImageView(imageId: profile.avatarImageId, size: 110)
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
                    value: "\(viewModel.statistics.totalBooks)",
                    icon: "books.vertical.fill",
                    color: MemoryTheme.Colors.primaryBlue
                )
                
                MemoryStatCard(
                    title: "読了",
                    value: "\(viewModel.statistics.completedBooks)",
                    icon: "checkmark.circle.fill",
                    color: Color(.systemGreen)
                )
            }
            
            HStack(spacing: MemorySpacing.sm) {
                MemoryStatCard(
                    title: "読書中",
                    value: "\(viewModel.statistics.readingBooks)",
                    icon: "book.fill",
                    color: MemoryTheme.Colors.warmCoral
                )
                
                MemoryStatCard(
                    title: "読みたい",
                    value: "\(viewModel.statistics.wantToReadBooks)",
                    icon: "bookmark.fill",
                    color: MemoryTheme.Colors.goldenMemory
                )
            }
            
            HStack(spacing: MemorySpacing.sm) {
                MemoryStatCard(
                    title: "総メモ数",
                    value: "\(viewModel.statistics.totalMemos)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: MemoryTheme.Colors.primaryBlue
                )
                
                MemoryStatCard(
                    title: "平均評価",
                    value: viewModel.statistics.averageRating > 0 ? String(format: "%.1f", viewModel.statistics.averageRating) : "-",
                    icon: "star.fill",
                    color: MemoryTheme.Colors.goldenMemory
                )
            }
        }
    }
    
    private func readingGoalProgress(goal: Int) -> some View {
        MemoryCard(padding: MemorySpacing.md) {
            VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                HStack {
                    HStack(spacing: MemorySpacing.xs) {
                        Image(systemName: "target")
                            .font(.system(size: 18))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                        Text("年間読書目標")
                            .font(.headline)
                            .foregroundColor(Color(.label))
                    }
                    
                    Spacer()
                    
                    Button {
                        showingGoalSetting = true
                    } label: {
                        Text("設定")
                            .font(.caption)
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            .padding(.horizontal, MemorySpacing.sm)
                            .padding(.vertical, MemorySpacing.xs)
                            .background(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                            .cornerRadius(MemoryRadius.full)
                    }
                }
                
                HStack {
                    Text("\(viewModel.statistics.booksThisYear) / \(goal) 冊")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Color(.label))
                    
                    Spacer()
                    
                    Text("\(Int(Double(viewModel.statistics.booksThisYear) / Double(goal) * 100))%")
                        .font(.subheadline)
                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                }
                
                ProgressView(value: Double(viewModel.statistics.booksThisYear), total: Double(goal))
                    .tint(MemoryTheme.Colors.primaryBlue)
                    .background(MemoryTheme.Colors.inkPale)
                    .clipShape(Capsule())
            }
        }
    }
    
    private func favoriteGenresSection(genres: [String]) -> some View {
        MemoryCard(padding: MemorySpacing.md) {
            VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 18))
                        .foregroundColor(MemoryTheme.Colors.warmCoral)
                    Text("お気に入りジャンル")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                FlowLayout(spacing: MemorySpacing.xs) {
                    ForEach(genres, id: \.self) { genre in
                        Text(genre)
                            .font(.caption)
                            .padding(.horizontal, MemorySpacing.md)
                            .padding(.vertical, MemorySpacing.xs)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.warmCoralLight.opacity(0.15),
                                        MemoryTheme.Colors.warmCoral.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(MemoryTheme.Colors.warmCoral)
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
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + viewSize.width > maxWidth, currentX > 0 {
                    currentY += lineHeight + spacing
                    currentX = 0
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: viewSize))
                
                currentX += viewSize.width + spacing
                maxX = max(maxX, currentX)
                lineHeight = max(lineHeight, viewSize.height)
            }
            
            size = CGSize(width: maxX - spacing, height: currentY + lineHeight)
        }
    }
}

#Preview {
    ProfileView()
}
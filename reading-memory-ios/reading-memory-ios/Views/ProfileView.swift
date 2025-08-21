import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var showingEditView = false
    @State private var showingGoalSetting = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if let profile = viewModel.userProfile {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader(profile: profile)
                        
                        // Statistics Cards
                        statisticsSection
                        
                        // Reading Goal Progress
                        if let goal = profile.readingGoal, goal > 0 {
                            readingGoalProgress(goal: goal)
                        }
                        
                        // Favorite Genres
                        if !profile.favoriteGenres.isEmpty {
                            favoriteGenresSection(genres: profile.favoriteGenres)
                        }
                        
                        // Bio
                        if let bio = profile.bio, !bio.isEmpty {
                            bioSection(bio: bio)
                        }
                    }
                    .padding()
                } else {
                    Text("プロフィールが見つかりません")
                        .foregroundStyle(.secondary)
                        .padding(.top, 100)
                }
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("編集") {
                        showingEditView = true
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
                // 初回のみプロフィールを読み込む
                if !viewModel.hasLoadedInitialData {
                    await viewModel.loadProfile()
                }
            }
            .refreshable {
                // プルリフレッシュ時は強制的に再取得
                viewModel.forceRefresh()
                await viewModel.loadProfile()
            }
            .onAppear {
                // タブが表示されたときはキャッシュの有効期限を確認
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
    
    private func profileHeader(profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            // Profile Image
            if let imageUrl = profile.profileImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.gray)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.gray)
            }
            
            // Display Name
            Text(profile.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            // Member Since
            Text("メンバー登録日: \(profile.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    title: "総冊数",
                    value: "\(viewModel.statistics.totalBooks)",
                    icon: "books.vertical.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "読了",
                    value: "\(viewModel.statistics.completedBooks)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "読書中",
                    value: "\(viewModel.statistics.readingBooks)",
                    icon: "book.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "読みたい",
                    value: "\(viewModel.statistics.wantToReadBooks)",
                    icon: "bookmark.fill",
                    color: .purple
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "総メモ数",
                    value: "\(viewModel.statistics.totalMemos)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .indigo
                )
                
                StatCard(
                    title: "平均評価",
                    value: viewModel.statistics.averageRating > 0 ? String(format: "%.1f", viewModel.statistics.averageRating) : "-",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }
    
    private func readingGoalProgress(goal: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("年間読書目標")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingGoalSetting = true
                } label: {
                    Text("目標設定")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Text("\(viewModel.statistics.booksThisYear) / \(goal) 冊")
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(Int(Double(viewModel.statistics.booksThisYear) / Double(goal) * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: Double(viewModel.statistics.booksThisYear), total: Double(goal))
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func favoriteGenresSection(genres: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("お気に入りジャンル")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(15)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func bioSection(bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("自己紹介")
                .font(.headline)
            
            Text(bio)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
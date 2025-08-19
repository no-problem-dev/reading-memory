import SwiftUI

struct AchievementGalleryView: View {
    @State private var viewModel = AchievementViewModel()
    @State private var selectedCategory: Badge.BadgeCategory? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 達成率サマリー
                    achievementSummary
                    
                    // カテゴリー選択
                    categorySelector
                    
                    // バッジ一覧
                    badgeGrid
                }
                .padding()
            }
            .navigationTitle("バッジコレクション")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadAchievements()
            }
        }
    }
    
    private var achievementSummary: some View {
        VStack(spacing: 16) {
            Text("獲得バッジ")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 32) {
                VStack {
                    Text("\(viewModel.unlockedAchievements.count)")
                        .font(.system(size: 36, weight: .bold))
                    Text("獲得済み")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.badges.count)")
                        .font(.system(size: 36, weight: .bold))
                    Text("総バッジ数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(Int(viewModel.overallCompletionRate * 100))%")
                        .font(.system(size: 36, weight: .bold))
                    Text("達成率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 最近獲得したバッジ
            if !viewModel.getRecentlyUnlockedBadges(limit: 3).isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近獲得したバッジ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        ForEach(viewModel.getRecentlyUnlockedBadges(limit: 3), id: \.badge.id) { item in
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color(item.badge.tier.color))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: item.badge.iconName)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                Text(item.badge.name)
                                    .font(.caption2)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "すべて",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach([Badge.BadgeCategory.milestone, .streak, .genre, .special], id: \.self) { category in
                    CategoryChip(
                        title: categoryName(for: category),
                        isSelected: selectedCategory == category,
                        count: viewModel.getCategoryProgress(category: category).total,
                        unlockedCount: viewModel.getCategoryProgress(category: category).unlocked,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }
    
    private var badgeGrid: some View {
        let filteredBadges = selectedCategory == nil 
            ? viewModel.badges 
            : viewModel.badges.filter { $0.category == selectedCategory }
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            ForEach(filteredBadges) { badge in
                BadgeItem(
                    badge: badge,
                    achievement: viewModel.getAchievement(for: badge),
                    isUnlocked: viewModel.isUnlocked(badge: badge)
                )
            }
        }
    }
    
    private func categoryName(for category: Badge.BadgeCategory) -> String {
        switch category {
        case .milestone:
            return "マイルストーン"
        case .streak:
            return "ストリーク"
        case .genre:
            return "ジャンル"
        case .special:
            return "特別"
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    var count: Int? = nil
    var unlockedCount: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                
                if let count = count, let unlockedCount = unlockedCount {
                    Text("\(unlockedCount)/\(count)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct BadgeItem: View {
    let badge: Badge
    let achievement: Achievement?
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // バッジの背景
                Circle()
                    .fill(isUnlocked ? Color(badge.tier.color) : Color(.systemGray5))
                    .frame(width: 80, height: 80)
                
                // 進捗リング（未獲得の場合）
                if !isUnlocked, let achievement = achievement {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 6)
                        .frame(width: 86, height: 86)
                    
                    Circle()
                        .trim(from: 0, to: achievement.progress)
                        .stroke(Color(badge.tier.color), lineWidth: 6)
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(-90))
                }
                
                // バッジアイコン
                Image(systemName: badge.iconName)
                    .font(.title)
                    .foregroundColor(isUnlocked ? .white : .secondary)
                    .opacity(isUnlocked ? 1.0 : 0.5)
                
                // ロックアイコン（未獲得の場合）
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .background(Circle().fill(Color(.systemBackground)).frame(width: 20, height: 20))
                        .offset(x: 30, y: 30)
                }
            }
            
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                if isUnlocked, let achievement = achievement, let unlockedAt = achievement.unlockedAt {
                    Text(unlockedAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if let achievement = achievement {
                    Text("\(Int(achievement.progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("0%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AchievementGalleryView()
}
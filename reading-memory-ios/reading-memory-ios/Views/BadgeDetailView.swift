import SwiftUI

struct BadgeDetailView: View {
    let badge: Badge
    let achievement: Achievement?
    let isUnlocked: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var showConfetti = false
    @State private var scaleEffect: CGFloat = 1.0
    
    private var currentValue: Int {
        guard let achievement = achievement else { return 0 }
        return Int(Double(badge.requirement.value) * achievement.progress)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色を全画面に適用
                MemoryTheme.Colors.secondaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Badge Display
                        badgeDisplay
                            .padding(.top, 32)
                        
                        // Badge Info
                        badgeInfo
                        
                        // Progress Section
                        if !isUnlocked {
                            progressSection
                        }
                        
                        // Achievement History
                        if isUnlocked, let achievement = achievement {
                            achievementHistory(achievement: achievement)
                        }
                        
                        // Requirements
                        requirementsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("バッジ詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if isUnlocked && showConfetti {
                withAnimation(MemoryTheme.Animation.spring) {
                    scaleEffect = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(MemoryTheme.Animation.normal) {
                        scaleEffect = 1.0
                    }
                }
            }
        }
    }
    
    private var badgeDisplay: some View {
        VStack(spacing: 24) {
            ZStack {
                // 背景の装飾
                if isUnlocked {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(badge.tier.color).opacity(0.3),
                                    Color(badge.tier.color).opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                }
                
                // バッジ本体
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color(badge.tier.color) : MemoryTheme.Colors.inkPale)
                        .frame(width: 160, height: 160)
                        .memoryShadow(isUnlocked ? .medium : .soft)
                    
                    if !isUnlocked, let achievement = achievement {
                        // 進捗リング
                        Circle()
                            .stroke(MemoryTheme.Colors.inkPale, lineWidth: 8)
                            .frame(width: 170, height: 170)
                        
                        Circle()
                            .trim(from: 0, to: achievement.progress)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(badge.tier.color),
                                        Color(badge.tier.color).opacity(0.7)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 170, height: 170)
                            .rotationEffect(.degrees(-90))
                            .animation(MemoryTheme.Animation.normal, value: achievement.progress)
                    }
                    
                    Image(systemName: badge.iconName)
                        .font(.system(size: 60))
                        .foregroundColor(isUnlocked ? .white : MemoryTheme.Colors.inkGray)
                        .opacity(isUnlocked ? 1.0 : 0.5)
                    
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .background(
                                Circle()
                                    .fill(MemoryTheme.Colors.cardBackground)
                                    .frame(width: 40, height: 40)
                            )
                            .offset(x: 55, y: 55)
                    }
                }
                .scaleEffect(scaleEffect)
            }
            
            // Tier Label
            HStack {
                Image(systemName: tierIcon(for: badge.tier))
                    .font(.caption)
                Text(tierName(for: badge.tier))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(Color(badge.tier.color))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(badge.tier.color).opacity(0.1))
            .cornerRadius(MemoryRadius.full)
        }
    }
    
    private var badgeInfo: some View {
        VStack(spacing: 16) {
            Text(badge.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(MemoryTheme.Colors.inkBlack)
            
            Text(badge.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(MemoryTheme.Colors.inkGray)
                .padding(.horizontal, 24)
        }
    }
    
    private var progressSection: some View {
        Group {
            if let achievement = achievement {
                VStack(spacing: 20) {
                    // Progress Bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("進捗状況")
                                .font(.subheadline)
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            
                            Spacer()
                            
                            Text("\(Int(achievement.progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: MemoryRadius.small)
                                    .fill(MemoryTheme.Colors.inkPale.opacity(0.3))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: MemoryRadius.small)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(badge.tier.color),
                                                Color(badge.tier.color).opacity(0.7)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * achievement.progress, height: 12)
                            }
                        }
                        .frame(height: 12)
                    }
                    
                    // Current Status
                    currentStatusInfo(achievement: achievement)
                }
                .padding(24)
                .background(MemoryTheme.Colors.cardBackground)
                .cornerRadius(MemoryRadius.large)
                .memoryShadow(.soft)
            }
        }
    }
    
    private func currentStatusInfo(achievement: Achievement) -> some View {
        Group {
            switch badge.requirement.type {
            case .booksRead:
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .font(.title3)
                        .foregroundColor(Color(badge.tier.color))
                    VStack(alignment: .leading) {
                        Text("読了した本")
                            .font(.caption)
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        Text("\(currentValue) / \(badge.requirement.value) 冊")
                            .font(.headline)
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                    }
                    Spacer()
                }
                
            case .streakDays:
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundColor(Color(badge.tier.color))
                    VStack(alignment: .leading) {
                        Text("連続読書日数")
                            .font(.caption)
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        Text("\(currentValue) / \(badge.requirement.value) 日")
                            .font(.headline)
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                    }
                    Spacer()
                }
                
            case .genreBooks:
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.title3)
                        .foregroundColor(Color(badge.tier.color))
                    VStack(alignment: .leading) {
                        Text("\(badge.requirement.genre ?? "")の本")
                            .font(.caption)
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        Text("\(currentValue) / \(badge.requirement.value) 冊")
                            .font(.headline)
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                    }
                    Spacer()
                }
                
            case .memos:
                HStack {
                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundColor(Color(badge.tier.color))
                    VStack(alignment: .leading) {
                        Text("作成したメモ")
                            .font(.caption)
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        Text("\(currentValue) / \(badge.requirement.value) 件")
                            .font(.headline)
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                    }
                    Spacer()
                }
                
            default:
                EmptyView()
            }
        }
        .padding(.top, 8)
    }
    
    private func achievementHistory(achievement: Achievement) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title3)
                    .foregroundColor(MemoryTheme.Colors.goldenMemory)
                Text("獲得記録")
                    .font(.headline)
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                if let unlockedAt = achievement.unlockedAt {
                    HStack {
                        Text("獲得日")
                            .font(.subheadline)
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        Spacer()
                        Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                    }
                }
                
                HStack {
                    Text("達成値")
                        .font(.subheadline)
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                    Spacer()
                    Text(formatAchievementValue(currentValue, type: badge.requirement.type))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                }
            }
        }
        .padding(24)
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
    }
    
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                Text("獲得条件")
                    .font(.headline)
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
            }
            
            Text(badge.displayDescription)
                .font(.body)
                .foregroundColor(MemoryTheme.Colors.inkGray)
                .fixedSize(horizontal: false, vertical: true)
            
            // Tips
            if !isUnlocked {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ヒント")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(MemoryTheme.Colors.warmCoral)
                    
                    Text(getTips(for: badge))
                        .font(.caption)
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(MemoryTheme.Colors.warmCoral.opacity(0.1))
                .cornerRadius(MemoryRadius.medium)
            }
        }
        .padding(24)
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
    }
    
    // Helper Functions
    private func tierIcon(for tier: Badge.BadgeTier) -> String {
        switch tier {
        case .bronze:
            return "medal"
        case .silver:
            return "medal.fill"
        case .gold:
            return "crown"
        case .platinum:
            return "crown.fill"
        }
    }
    
    private func tierName(for tier: Badge.BadgeTier) -> String {
        switch tier {
        case .bronze:
            return "ブロンズ"
        case .silver:
            return "シルバー"
        case .gold:
            return "ゴールド"
        case .platinum:
            return "プラチナ"
        }
    }
    
    private func formatAchievementValue(_ value: Int, type: Badge.BadgeRequirement.RequirementType) -> String {
        switch type {
        case .booksRead, .genreBooks:
            return "\(value) 冊"
        case .streakDays:
            return "\(value) 日間"
        case .memos, .reviews:
            return "\(value) 件"
        case .yearlyGoal:
            return "達成"
        }
    }
    
    private func getTips(for badge: Badge) -> String {
        switch badge.requirement.type {
        case .booksRead:
            return "本を読み終えたら「完了」ステータスに変更しましょう。読書を継続することが達成への近道です。"
        case .streakDays:
            return "毎日少しでも読書をして、連続記録を伸ばしましょう。読書メモを残すと記録されます。"
        case .genreBooks:
            return "\(badge.requirement.genre ?? "特定のジャンル")の本を探して読んでみましょう。さまざまなジャンルに挑戦するのも楽しいですよ。"
        case .memos:
            return "読書中の気づきや感想をメモに残しましょう。後で見返すと新たな発見があるかもしれません。"
        case .yearlyGoal:
            return "年間読書目標を設定して、計画的に読書を進めましょう。"
        case .reviews:
            return "読み終えた本の感想や評価を記録しましょう。"
        }
    }
}

#Preview {
    BadgeDetailView(
        badge: Badge.defaultBadges[0],
        achievement: Achievement(
            id: "test",
            badgeId: Badge.defaultBadges[0].id,
            progress: 0.7
        ),
        isUnlocked: false
    )
}
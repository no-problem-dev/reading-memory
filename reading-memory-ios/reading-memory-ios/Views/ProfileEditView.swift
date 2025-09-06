import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss
    
    // Edit form state
    @State private var editDisplayName = ""
    @State private var editBio = ""
    @State private var editFavoriteGenres: [BookGenre] = []
    @State private var editReadingGoal: String = ""
    @State private var editMonthlyGoal: String = ""
    @State private var editIsPublic = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        MemoryTheme.Colors.background,
                        MemoryTheme.Colors.secondaryBackground
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Profile image header
                            profileImageSection
                                .padding(.bottom, MemorySpacing.lg)
                            
                            VStack(spacing: MemorySpacing.lg) {
                                // Basic Information
                                basicInfoSection
                                
                                // Reading Goal
                                readingGoalSection
                                
                                // Favorite Genres
                                genresSection
                                
                                // Privacy Settings
                                privacySection
                            }
                            .padding(.horizontal, MemorySpacing.md)
                            .padding(.bottom, MemorySpacing.lg)
                        }
                    }
                    
                    // Bottom save button
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button {
                            Task {
                                await saveProfile()
                            }
                        } label: {
                            Text("変更を保存")
                                .font(MemoryTheme.Fonts.headline())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: 
                                                    editDisplayName.isEmpty 
                                                    ? [MemoryTheme.Colors.inkLightGray, MemoryTheme.Colors.inkLightGray]
                                                    : [MemoryTheme.Colors.primaryBlue, MemoryTheme.Colors.primaryBlueDark]
                                                ),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        .disabled(isLoading || editDisplayName.isEmpty)
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, MemorySpacing.md)
                    }
                    .background(MemoryTheme.Colors.cardBackground)
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .memoryLoading(isLoading: isLoading, message: "保存中...")
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                loadInitialValues()
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    await loadImage(from: newValue)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var profileImageSection: some View {
        VStack(spacing: MemorySpacing.md) {
            // Profile image with gradient overlay
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        MemoryTheme.Colors.primaryBlue.opacity(0.2),
                        MemoryTheme.Colors.primaryBlueDark.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
                
                VStack(spacing: MemorySpacing.sm) {
                    // Profile image
                    ZStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(MemoryTheme.Colors.cardBackground, lineWidth: 4)
                                )
                        } else {
                            ProfileImageView(imageId: profileStore.userProfile?.avatarImageId, size: 120)
                        }
                        
                        // Camera overlay
                        PhotosPicker(selection: $selectedPhoto) {
                            ZStack {
                                Circle()
                                    .fill(MemoryTheme.Colors.primaryBlue.opacity(0.9))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(x: 40, y: 40)
                    }
                    
                    Text("プロフィール画像を変更")
                        .font(MemoryTheme.Fonts.caption())
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        MemoryCard {
            VStack(spacing: MemorySpacing.md) {
                sectionHeader(icon: "person.fill", title: "基本情報", color: MemoryTheme.Colors.primaryBlue)
                
                VStack(spacing: MemorySpacing.md) {
                    MemoryTextField(
                        placeholder: "表示名",
                        text: $editDisplayName,
                        icon: "person.circle",
                        isRequired: true
                    )
                    
                    VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                        HStack(spacing: MemorySpacing.xs) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 16))
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            Text("自己紹介")
                                .font(MemoryTheme.Fonts.subheadline())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                        }
                        
                        MemoryTextEditor(
                            placeholder: "自己紹介を入力（任意）",
                            text: $editBio,
                            minHeight: 100
                        )
                    }
                }
            }
        }
    }
    
    private var readingGoalSection: some View {
        MemoryCard {
            VStack(spacing: MemorySpacing.md) {
                sectionHeader(icon: "target", title: "読書目標", color: MemoryTheme.Colors.goldenMemory)
                
                VStack(spacing: MemorySpacing.md) {
                    HStack(spacing: MemorySpacing.sm) {
                        MemoryTextField(
                            placeholder: "年間目標",
                            text: $editReadingGoal,
                            icon: "calendar",
                            keyboardType: .numberPad
                        )
                        Text("冊")
                            .font(MemoryTheme.Fonts.body())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                    
                    HStack(spacing: MemorySpacing.sm) {
                        MemoryTextField(
                            placeholder: "月間目標",
                            text: $editMonthlyGoal,
                            icon: "calendar.badge.clock",
                            keyboardType: .numberPad
                        )
                        Text("冊")
                            .font(MemoryTheme.Fonts.body())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                }
            }
        }
    }
    
    private var genresSection: some View {
        MemoryCard {
            VStack(spacing: MemorySpacing.md) {
                sectionHeader(icon: "sparkles", title: "お気に入りジャンル", color: MemoryTheme.Colors.primaryBlue)
                
                // Selected genres
                if !editFavoriteGenres.isEmpty {
                    FlowLayout(spacing: MemorySpacing.sm) {
                        ForEach(editFavoriteGenres, id: \.self) { genre in
                            genreChip(genre: genre, isSelected: true)
                        }
                    }
                    .padding(.bottom, MemorySpacing.sm)
                }
                
                // Available genres
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MemorySpacing.sm) {
                        ForEach(BookGenre.allCases, id: \.self) { genre in
                            if !editFavoriteGenres.contains(genre) {
                                genreChip(genre: genre, isSelected: false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var privacySection: some View {
        MemoryCard {
            VStack(spacing: MemorySpacing.md) {
                sectionHeader(icon: "lock.fill", title: "プライバシー設定", color: MemoryTheme.Colors.inkGray)
                
                Toggle(isOn: $editIsPublic) {
                    VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                        Text("プロフィールを公開")
                            .font(MemoryTheme.Fonts.body())
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                        Text("他のユーザーがあなたのプロフィールを閲覧できるようになります")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                }
                .tint(MemoryTheme.Colors.primaryBlue)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: MemorySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(title)
                .font(MemoryTheme.Fonts.headline())
                .foregroundColor(MemoryTheme.Colors.inkBlack)
            Spacer()
        }
    }
    
    private func genreChip(genre: BookGenre, isSelected: Bool) -> some View {
        Button {
            if isSelected {
                editFavoriteGenres.removeAll { $0 == genre }
            } else {
                editFavoriteGenres.append(genre)
            }
        } label: {
            HStack(spacing: MemorySpacing.xs) {
                Text(genre.rawValue)
                    .font(MemoryTheme.Fonts.caption())
                    .foregroundColor(isSelected ? .white : MemoryTheme.Colors.inkBlack)
                
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, MemorySpacing.sm)
            .padding(.vertical, MemorySpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.full)
                    .fill(isSelected ? MemoryTheme.Colors.primaryBlue : MemoryTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MemoryRadius.full)
                            .stroke(isSelected ? Color.clear : MemoryTheme.Colors.inkPale, lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialValues() {
        guard let profile = profileStore.userProfile else { return }
        
        editDisplayName = profile.displayName
        editBio = profile.bio ?? ""
        editFavoriteGenres = profile.favoriteGenres
        editReadingGoal = profile.readingGoal != nil ? String(profile.readingGoal!) : ""
        editMonthlyGoal = profile.monthlyGoal != nil ? String(profile.monthlyGoal!) : ""
        editIsPublic = profile.isPublic
    }
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                profileImage = UIImage(data: data)
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
    
    private func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let profile = profileStore.userProfile else {
                throw AppError.dataNotFound
            }
            
            // Upload profile image if selected
            var avatarImageId = profile.avatarImageId
            if let selectedPhoto = selectedPhoto,
               let data = try await selectedPhoto.loadTransferable(type: Data.self) {
                avatarImageId = try await profileStore.updateProfileImage(data)
            }
            
            // Create updated profile
            let updatedProfile = UserProfile(
                id: profile.id,
                displayName: editDisplayName.isEmpty ? profile.displayName : editDisplayName,
                avatarImageId: avatarImageId,
                bio: editBio.isEmpty ? nil : editBio,
                favoriteGenres: editFavoriteGenres,
                readingGoal: Int(editReadingGoal),
                monthlyGoal: Int(editMonthlyGoal),
                streakStartDate: profile.streakStartDate,
                longestStreak: profile.longestStreak,
                currentStreak: profile.currentStreak,
                lastActivityDate: profile.lastActivityDate,
                isPublic: editIsPublic,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )
            
            try await profileStore.updateProfile(updatedProfile)
            
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    ProfileEditView()
        .environment(ServiceContainer.shared.getUserProfileStore())
}
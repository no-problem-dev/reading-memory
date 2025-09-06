import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hasChanges = false
    
    var body: some View {
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
                            await viewModel.saveProfile()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
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
                                                viewModel.editDisplayName.isEmpty 
                                                ? [MemoryTheme.Colors.inkLightGray, MemoryTheme.Colors.inkLightGray]
                                                : [MemoryTheme.Colors.primaryBlue, MemoryTheme.Colors.primaryBlueDark]
                                            ),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .disabled(viewModel.isLoading || viewModel.editDisplayName.isEmpty)
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.vertical, MemorySpacing.md)
                }
                .background(MemoryTheme.Colors.cardBackground)
            }
        }
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .memoryLoading(isLoading: viewModel.isLoading, message: "保存中...")
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Components
    
    private var profileImageSection: some View {
        VStack(spacing: MemorySpacing.md) {
            // Gradient background for profile section
            LinearGradient(
                gradient: Gradient(colors: [
                    MemoryTheme.Colors.primaryBlue.opacity(0.15),
                    MemoryTheme.Colors.primaryBlue.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .overlay(
                VStack(spacing: MemorySpacing.md) {
                    PhotosPicker(selection: $viewModel.selectedPhoto,
                               matching: .images,
                               photoLibrary: .shared()) {
                        VStack(spacing: MemorySpacing.sm) {
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
                                
                                if let profileImage = viewModel.profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                } else {
                                    ProfileImageView(imageId: viewModel.userProfile?.avatarImageId, size: 110)
                                }
                                
                                // Camera overlay
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 110, height: 110)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    )
                                    .opacity(0)
                            }
                            
                            Text("写真を変更")
                                .font(MemoryTheme.Fonts.caption())
                                .foregroundColor(.white)
                                .padding(.horizontal, MemorySpacing.md)
                                .padding(.vertical, MemorySpacing.xs)
                                .background(MemoryTheme.Colors.primaryBlue.opacity(0.8))
                                .cornerRadius(MemoryRadius.full)
                        }
                    }
                    .onChange(of: viewModel.selectedPhoto) { _, newItem in
                        Task {
                            await viewModel.loadImage(from: newItem)
                        }
                    }
                }
            )
        }
    }
    
    private var basicInfoSection: some View {
        MemoryCard {
            VStack(spacing: MemorySpacing.lg) {
                sectionHeader(
                    icon: "person.text.rectangle",
                    title: "基本情報",
                    color: MemoryTheme.Colors.primaryBlue
                )
                
                VStack(spacing: MemorySpacing.md) {
                    MemoryTextField(
                        placeholder: "表示名",
                        text: $viewModel.editDisplayName,
                        icon: "person.fill",
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
                            placeholder: "あなたについて教えてください",
                            text: $viewModel.editBio,
                            minHeight: 100
                        )
                    }
                }
            }
        }
    }
    
    private var readingGoalSection: some View {
        MemoryCard {
            VStack(spacing: MemorySpacing.lg) {
                sectionHeader(
                    icon: "target",
                    title: "読書目標",
                    color: MemoryTheme.Colors.goldenMemory
                )
                
                HStack(spacing: MemorySpacing.md) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(MemoryTheme.Colors.goldenMemory.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                        Text("年間読書目標")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        
                        HStack(alignment: .bottom, spacing: MemorySpacing.xs) {
                            TextField("0", text: $viewModel.editReadingGoal)
                                .font(MemoryTheme.Fonts.title())
                                .fontWeight(.bold)
                                .foregroundColor(MemoryTheme.Colors.goldenMemory)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                            
                            Text("冊")
                                .font(MemoryTheme.Fonts.headline())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                                .padding(.bottom, 4)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var genresSection: some View {
        MemoryCard {
            VStack(spacing: MemorySpacing.lg) {
                sectionHeader(
                    icon: "tag.fill",
                    title: "お気に入りジャンル",
                    color: MemoryTheme.Colors.goldenMemory
                )
                
                // Selected genres
                if !viewModel.editFavoriteGenres.isEmpty {
                    FlowLayout(spacing: MemorySpacing.sm) {
                        ForEach(viewModel.editFavoriteGenres, id: \.self) { genre in
                            HStack(spacing: MemorySpacing.xs) {
                                Text(genre.displayName)
                                    .font(MemoryTheme.Fonts.caption())
                                
                                Button {
                                    withAnimation(MemoryTheme.Animation.fast) {
                                        viewModel.removeGenre(genre)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, MemorySpacing.md)
                            .padding(.vertical, MemorySpacing.sm)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.goldenMemory,
                                        MemoryTheme.Colors.goldenMemoryDark
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(MemoryRadius.full)
                            .memoryShadow(.soft)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, MemorySpacing.sm)
                }
                
                // Available genres
                VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                    if !viewModel.editFavoriteGenres.isEmpty {
                        Text("ジャンルを追加")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                    
                    FlowLayout(spacing: MemorySpacing.sm) {
                        ForEach(BookGenre.allCases.filter { !viewModel.editFavoriteGenres.contains($0) }, id: \.self) { genre in
                            Button {
                                withAnimation(MemoryTheme.Animation.spring) {
                                    viewModel.addGenre(genre)
                                }
                            } label: {
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                    Text(genre.displayName)
                                        .font(MemoryTheme.Fonts.caption())
                                }
                                .padding(.horizontal, MemorySpacing.md)
                                .padding(.vertical, MemorySpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: MemoryRadius.full)
                                        .fill(MemoryTheme.Colors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: MemoryRadius.full)
                                                .stroke(MemoryTheme.Colors.inkPale, lineWidth: 1)
                                        )
                                )
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    private var privacySection: some View {
        MemoryCard {
            VStack(spacing: MemorySpacing.lg) {
                sectionHeader(
                    icon: "lock.shield.fill",
                    title: "プライバシー設定",
                    color: MemoryTheme.Colors.primaryBlue
                )
                
                VStack(spacing: MemorySpacing.md) {
                    Toggle(isOn: $viewModel.editIsPublic) {
                        HStack(spacing: MemorySpacing.sm) {
                            Image(systemName: viewModel.editIsPublic ? "globe" : "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.editIsPublic ? MemoryTheme.Colors.primaryBlue : MemoryTheme.Colors.inkGray)
                            
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Text("プロフィールを公開")
                                    .font(MemoryTheme.Fonts.subheadline())
                                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                                
                                if viewModel.editIsPublic {
                                    Text("他のユーザーがあなたのプロフィールを閲覧できます")
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(MemoryTheme.Colors.inkGray)
                                }
                            }
                        }
                    }
                    .tint(MemoryTheme.Colors.primaryBlue)
                    
                    if viewModel.editIsPublic {
                        HStack(spacing: MemorySpacing.sm) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(MemoryTheme.Colors.primaryBlue.opacity(0.6))
                            
                            Text("公開プロフィールには、表示名、自己紹介、読書統計が含まれます")
                                .font(MemoryTheme.Fonts.caption())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(MemorySpacing.sm)
                        .background(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                        .cornerRadius(MemoryRadius.small)
                    }
                }
            }
        }
    }
    
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
}

#Preview {
    NavigationStack {
        ProfileEditView(viewModel: ProfileViewModel())
    }
}
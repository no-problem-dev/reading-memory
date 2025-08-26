import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var firstChatMessage = ""
    @State private var isShowingBookSearch = false
    @State private var viewModel: OnboardingViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    let onComplete: () -> Void
    
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        self._viewModel = State(initialValue: OnboardingViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    MemoryTheme.Colors.primaryBlue.opacity(0.03),
                    MemoryTheme.Colors.warmCoral.opacity(0.02),
                    MemoryTheme.Colors.background
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                MemoryProgressBar(currentStep: currentStep, totalSteps: 4)
                    .padding(.horizontal, MemorySpacing.lg)
                    .padding(.top, MemorySpacing.lg)
                    .padding(.bottom, MemorySpacing.md)
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    ProfileSetupStep(
                        displayName: $viewModel.displayName,
                        selectedPhoto: $selectedPhoto,
                        profileImage: $viewModel.profileImage
                    )
                    .tag(1)
                    
                    PreferencesStep(
                        selectedGenres: $viewModel.selectedGenres,
                        monthlyGoal: $viewModel.monthlyGoal
                    )
                    .tag(2)
                    
                    FirstBookStep(
                        selectedBook: $viewModel.firstBook,
                        isShowingBookSearch: $isShowingBookSearch
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(MemoryTheme.Animation.normal, value: currentStep)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button {
                            withAnimation(MemoryTheme.Animation.fast) {
                                currentStep -= 1
                            }
                        } label: {
                            HStack(spacing: MemorySpacing.xs) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14))
                                Text("戻る")
                                    .font(MemoryTheme.Fonts.callout())
                            }
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: handleNext) {
                        Group {
                            if currentStep == 3 {
                                HStack(spacing: MemorySpacing.xs) {
                                    Text("読書を始める")
                                        .font(MemoryTheme.Fonts.headline())
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, MemorySpacing.lg)
                                .padding(.vertical, MemorySpacing.md)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            MemoryTheme.Colors.primaryBlue,
                                            MemoryTheme.Colors.primaryBlueDark
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(MemoryRadius.full)
                                .memoryShadow(.medium)
                            } else if currentStep == 3 && viewModel.firstBook == nil {
                                Text("スキップ")
                                    .font(MemoryTheme.Fonts.callout())
                                    .foregroundColor(MemoryTheme.Colors.inkGray)
                            } else {
                                HStack(spacing: MemorySpacing.xs) {
                                    Text("次へ")
                                        .font(MemoryTheme.Fonts.headline())
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, MemorySpacing.lg)
                                .padding(.vertical, MemorySpacing.md)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            MemoryTheme.Colors.primaryBlue,
                                            MemoryTheme.Colors.primaryBlueDark
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(MemoryRadius.full)
                                .memoryShadow(.medium)
                            }
                        }
                    }
                    .disabled(!canProceed)
                    .opacity(canProceed ? 1 : 0.6)
                }
                .padding(.horizontal, MemorySpacing.lg)
                .padding(.vertical, MemorySpacing.lg)
            }
        }
        .sheet(isPresented: $isShowingBookSearch) {
            OnboardingBookSearchView(onBookSelected: { searchResult in
                viewModel.firstBookSearchResult = searchResult
                viewModel.firstBook = searchResult.toBook()  // 表示用にBookオブジェクトも作成
                isShowingBookSearch = false
            })
                    }
        .onAppear {
            viewModel = OnboardingViewModel(authViewModel: authViewModel)
        }
            }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return !viewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !viewModel.selectedGenres.isEmpty && viewModel.monthlyGoal > 0
        default:
            // ステップ0, 3, 4では常に進める
            return true
        }
    }
    
    private func handleNext() {
        if currentStep < 3 {
            withAnimation {
                currentStep += 1
            }
        } else {
            Task {
                await completeOnboarding()
            }
        }
    }
    
    @MainActor
    private func completeOnboarding() async {
        viewModel.authViewModel = authViewModel
        let success = await viewModel.completeOnboarding()
        
        if success {
            onComplete()
        } else {
            // Handle error - show alert
            print("Onboarding failed: \(viewModel.errorMessage ?? "Unknown error")")
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStep: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: MemorySpacing.xl) {
            Spacer()
            
            // Animated logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlueLight.opacity(0.2),
                                MemoryTheme.Colors.primaryBlue.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlue,
                                MemoryTheme.Colors.primaryBlueDark
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .onAppear { isAnimating = true }
            .padding(.bottom, MemorySpacing.md)
            
            VStack(spacing: MemorySpacing.md) {
                Text("読書メモリーへようこそ")
                    .font(MemoryTheme.Fonts.hero())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                    .multilineTextAlignment(.center)
                
                Text("本と過ごした時間を、\nずっと大切に")
                    .font(MemoryTheme.Fonts.title3())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
            }
            
            // Feature highlights
            VStack(spacing: MemorySpacing.md) {
                MemoryFeatureRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "読書メモ",
                    description: "読みながら気づきを記録",
                    color: MemoryTheme.Colors.primaryBlue
                )
                
                MemoryFeatureRow(
                    icon: "sparkles",
                    title: "記憶に定着",
                    description: "AIが要約を生成し、理解を深める",
                    color: MemoryTheme.Colors.warmCoral
                )
                
                MemoryFeatureRow(
                    icon: "heart.circle.fill",
                    title: "思い出になる",
                    description: "本との出会いが大切な記憶に",
                    color: MemoryTheme.Colors.goldenMemory
                )
            }
            .padding(.horizontal, MemorySpacing.md)
            
            Spacer()
            Spacer()
        }
        .padding(MemorySpacing.lg)
    }
}

// MARK: - Memory Feature Row
struct MemoryFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: MemorySpacing.md) {
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
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                Text(title)
                    .font(MemoryTheme.Fonts.headline())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                Text(description)
                    .font(MemoryTheme.Fonts.caption())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
            }
            
            Spacer()
        }
    }
}

// MARK: - Memory Progress Bar
struct MemoryProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var progress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(MemoryTheme.Colors.inkPale)
                    .frame(height: 8)
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlueLight,
                                MemoryTheme.Colors.primaryBlue
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(MemoryTheme.Animation.spring, value: progress)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
    .environment(AuthViewModel())
}
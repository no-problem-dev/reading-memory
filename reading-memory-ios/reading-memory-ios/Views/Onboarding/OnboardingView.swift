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
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Progress indicator
                ProgressBar(currentStep: currentStep, totalSteps: 5)
                    .padding(.horizontal)
                    .padding(.top)
                
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
                    
                    ChatExperienceStep(
                        book: viewModel.firstBook,
                        firstMessage: $firstChatMessage
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("戻る") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: handleNext) {
                        if currentStep == 4 {
                            Text("読書を始める")
                                .fontWeight(.semibold)
                        } else if currentStep == 3 && viewModel.firstBook == nil {
                            Text("スキップ")
                                .foregroundColor(.secondary)
                        } else {
                            Text("次へ")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canProceed)
                }
                .padding()
            }
        }
        .sheet(isPresented: $isShowingBookSearch) {
            OnboardingBookSearchView(onBookSelected: { book in
                viewModel.firstBook = book
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
        case 4:
            return viewModel.firstBook != nil || !firstChatMessage.isEmpty
        default:
            return true
        }
    }
    
    private func handleNext() {
        if currentStep < 4 {
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
        VStack(spacing: 40) {
            Spacer()
            
            // Animated logo
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear { isAnimating = true }
            
            VStack(spacing: 20) {
                Text("読書メモリーへようこそ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("本と過ごした時間を、\nずっと大切に")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Feature highlights
            VStack(spacing: 24) {
                FeatureRow(
                    icon: "bubble.left.and.bubble.right",
                    title: "本とおしゃべり",
                    description: "チャット形式で気づきを記録"
                )
                
                FeatureRow(
                    icon: "brain",
                    title: "記憶に定着",
                    description: "AIが要約を生成し、理解を深める"
                )
                
                FeatureRow(
                    icon: "heart.circle",
                    title: "思い出になる",
                    description: "本との出会いが大切な記憶に"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var progress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.gradient)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.spring(), value: progress)
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
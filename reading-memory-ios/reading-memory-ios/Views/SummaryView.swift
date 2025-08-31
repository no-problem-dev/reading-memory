import SwiftUI

struct SummaryView: View {
    // MARK: - Properties
    let book: Book
    @State private var viewModel: SummaryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    
    // Animation States
    @State private var sparkleAnimation = false
    @State private var pulseAnimation = false
    
    // MARK: - Initialization
    init(book: Book) {
        self.book = book
        self._viewModel = State(initialValue: SummaryViewModel(
            bookId: book.id,
            bookTitle: book.title,
            bookAuthor: book.author,
            existingSummary: book.aiSummary
        ))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.top, MemorySpacing.lg)
                            .padding(.horizontal, MemorySpacing.md)
                        
                        // Main Content
                        switch viewModel.viewState {
                        case .loading:
                            loadingView
                                .padding(.top, 60)
                        case .loaded(let summary):
                            summaryContentView(summary: summary)
                                .padding(.top, MemorySpacing.xl)
                        case .error(let message):
                            errorView(message: message)
                                .padding(.top, 60)
                        }
                    }
                    .padding(.bottom, MemorySpacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .task {
                // 既存の要約がない場合は自動生成
                if viewModel.existingSummary == nil {
                    // プレミアムチェック
                    guard FeatureGate.canUseAI else {
                        showPaywall = true
                        return
                    }
                    
                    await viewModel.generateSummary()
                } else {
                    // 既存の要約を表示
                    viewModel.viewState = .loaded(summary: viewModel.existingSummary!)
                }
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: MemorySpacing.sm) {
            // Book Info
            VStack(spacing: MemorySpacing.xs) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            
            Divider()
                .padding(.top, MemorySpacing.sm)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: MemorySpacing.lg) {
            // Animated Icon
            ZStack {
                // Pulse Background
                Circle()
                    .fill(MemoryTheme.Colors.warmCoral.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.3 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                // Main Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(MemoryTheme.Colors.warmCoral)
                    .rotationEffect(.degrees(sparkleAnimation ? 10 : -10))
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: sparkleAnimation
                    )
            }
            
            VStack(spacing: MemorySpacing.xs) {
                Text("要約を生成中...")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                
                Text("あなたの読書メモを分析しています")
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            // Progress Indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MemoryTheme.Colors.warmCoral))
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, MemorySpacing.lg)
    }
    
    // MARK: - Summary Content View
    private func summaryContentView(summary: String) -> some View {
        VStack(spacing: MemorySpacing.lg) {
            // Title with Icon
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(MemoryTheme.Colors.warmCoral)
                
                Text("AI要約")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
            }
            
            // Summary Content
            VStack(alignment: .leading, spacing: MemorySpacing.md) {
                Text(summary)
                    .font(.body)
                    .foregroundColor(Color(.label))
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(MemorySpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.large)
                    .fill(Color(.secondarySystemBackground))
            )
            .memoryShadow(.soft)
            
            // Actions
            if viewModel.existingSummary != nil {
                regenerateButton
            }
            
            // Footer Note
            Text("この要約は、あなたの読書メモをもとにAIが生成しました")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.top, MemorySpacing.sm)
        }
        .padding(.horizontal, MemorySpacing.md)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: MemorySpacing.lg) {
            // Error Icon
            ZStack {
                Circle()
                    .fill(Color(.systemRed).opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: MemorySpacing.xs) {
                Text("生成エラー")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MemorySpacing.lg)
            }
            
            // Retry Button
            Button {
                Task {
                    // プレミアムチェック
                    guard FeatureGate.canUseAI else {
                        showPaywall = true
                        return
                    }
                    
                    await viewModel.retry()
                }
            } label: {
                Label("もう一度試す", systemImage: "arrow.clockwise")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, MemorySpacing.lg)
                    .padding(.vertical, MemorySpacing.sm)
                    .background(MemoryTheme.Colors.warmCoral)
                    .cornerRadius(MemoryRadius.full)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, MemorySpacing.lg)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Regenerate Button
    private var regenerateButton: some View {
        Button {
            Task {
                // プレミアムチェック
                guard FeatureGate.canUseAI else {
                    showPaywall = true
                    return
                }
                
                await viewModel.generateSummary()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
                
                Text("要約を再生成")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .foregroundColor(MemoryTheme.Colors.warmCoral)
            .padding(.horizontal, MemorySpacing.md)
            .padding(.vertical, MemorySpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.full)
                    .stroke(MemoryTheme.Colors.warmCoral, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isGenerating)
        .opacity(viewModel.isGenerating ? 0.5 : 1.0)
    }
    
    // MARK: - Helper Methods
    private func startAnimations() {
        sparkleAnimation = true
        pulseAnimation = true
    }
}
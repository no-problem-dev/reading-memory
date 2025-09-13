import SwiftUI

struct BookAdditionFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionStateStore.self) private var subscriptionState
    @State private var selectedOption: AdditionOption? = nil
    @State private var showPaywall = false
    
    enum AdditionOption: String, CaseIterable, Identifiable {
        case search = "search"
        case barcode = "barcode"
        case manual = "manual"
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .search:
                return "タイトル・著者名で検索"
            case .barcode:
                return "バーコードをスキャン"
            case .manual:
                return "手動で登録"
            }
        }
        
        var subtitle: String {
            switch self {
            case .search:
                return "本のタイトルや著者名から探す"
            case .barcode:
                return "カメラで本のバーコードを読み取る"
            case .manual:
                return "書籍情報を直接入力する"
            }
        }
        
        var icon: String {
            switch self {
            case .search:
                return "magnifyingglass"
            case .barcode:
                return "barcode.viewfinder"
            case .manual:
                return "pencil"
            }
        }
        
        var isRecommended: Bool {
            self == .search
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        MemoryTheme.Colors.primaryBlue.opacity(0.03),
                        MemoryTheme.Colors.goldenMemory.opacity(0.02),
                        MemoryTheme.Colors.background
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header illustration
                    headerSection
                    
                    // Options
                    ScrollView {
                        VStack(spacing: MemorySpacing.md) {
                            // Header text moved here for better proximity
                            VStack(spacing: MemorySpacing.xs) {
                                Text("本の登録方法を選択")
                                    .font(MemoryTheme.Fonts.title3())
                                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                                
                                Text("お好みの方法で本を追加できます")
                                    .font(MemoryTheme.Fonts.subheadline())
                                    .foregroundColor(MemoryTheme.Colors.inkGray)
                            }
                            .padding(.bottom, MemorySpacing.lg)
                            
                            ForEach(AdditionOption.allCases, id: \.self) { option in
                                optionCard(for: option)
                                    .padding(.horizontal, MemorySpacing.md)
                            }
                        }
                        .padding(.top, MemorySpacing.md)
                        .padding(.bottom, MemorySpacing.xl)
                    }
                }
            }
            .navigationTitle("本を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .frame(width: 30, height: 30)
                            .background(MemoryTheme.Colors.cardBackground)
                            .clipShape(Circle())
                            .memoryShadow(.soft)
                    }
                }
            }
            .sheet(item: $selectedOption) { option in
                switch option {
                case .search:
                    BookSearchView(defaultStatus: .reading)
                case .barcode:
                    BarcodeScannerView(defaultStatus: .reading)
                case .manual:
                    BookRegistrationView(defaultStatus: .reading)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // 本棚に本を追加するイメージのアイコン構成
            ZStack {
                // 背景の薄い円
                Circle()
                    .fill(MemoryTheme.Colors.inkPale.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                // 本のアイコン（装飾的で押せないことが明確）
                Image(systemName: "books.vertical")
                    .font(.system(size: 28))
                    .foregroundColor(MemoryTheme.Colors.inkGray.opacity(0.7))
            }
            .padding(.top, MemorySpacing.lg)
            .padding(.bottom, MemorySpacing.md)
        }
    }
    
    private func optionCard(for option: AdditionOption) -> some View {
        Button {
            if option == .barcode {
                guard subscriptionState.canScanBarcode else {
                    showPaywall = true
                    return
                }
            }
            selectedOption = option
        } label: {
            HStack(spacing: MemorySpacing.md) {
                // Larger, more prominent icon
                ZStack {
                    RoundedRectangle(cornerRadius: MemoryRadius.medium)
                        .fill(iconBackground(for: option))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 28))
                        .foregroundColor(iconColor(for: option))
                }
                
                // Text
                VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                    HStack(spacing: MemorySpacing.xs) {
                        Text(option.title)
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                        
                        if option.isRecommended {
                            Text("おすすめ")
                                .font(MemoryTheme.Fonts.caption())
                                .foregroundColor(.white)
                                .padding(.horizontal, MemorySpacing.sm)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            MemoryTheme.Colors.primaryBlue,
                                            MemoryTheme.Colors.primaryBlueDark
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(MemoryRadius.full)
                        }
                    }
                    
                    Text(option.subtitle)
                        .font(MemoryTheme.Fonts.subheadline())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Larger arrow for better tap indication
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
            }
            .padding(MemorySpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.large)
                    .fill(MemoryTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MemoryRadius.large)
                            .stroke(
                                option.isRecommended 
                                    ? MemoryTheme.Colors.primaryBlue.opacity(0.5) 
                                    : MemoryTheme.Colors.inkPale.opacity(0.3),
                                lineWidth: option.isRecommended ? 2 : 1
                            )
                    )
            )
            .memoryShadow(option.isRecommended ? .strong : .medium)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedOption)
    }
    
    private func iconBackground(for option: AdditionOption) -> LinearGradient {
        let colors: [Color]
        switch option {
        case .search:
            colors = [
                MemoryTheme.Colors.primaryBlueLight.opacity(0.2),
                MemoryTheme.Colors.primaryBlue.opacity(0.1)
            ]
        case .barcode:
            colors = [
                MemoryTheme.Colors.goldenMemoryLight.opacity(0.2),
                MemoryTheme.Colors.goldenMemory.opacity(0.1)
            ]
        case .manual:
            colors = [
                MemoryTheme.Colors.inkPale.opacity(0.5),
                MemoryTheme.Colors.inkPale.opacity(0.3)
            ]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func iconColor(for option: AdditionOption) -> Color {
        switch option {
        case .search:
            return MemoryTheme.Colors.primaryBlue
        case .barcode:
            return MemoryTheme.Colors.goldenMemory
        case .manual:
            return MemoryTheme.Colors.inkGray
        }
    }
}

#Preview {
    BookAdditionFlowView()
        }
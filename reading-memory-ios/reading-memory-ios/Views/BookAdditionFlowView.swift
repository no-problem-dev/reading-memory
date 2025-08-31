import SwiftUI

struct BookAdditionFlowView: View {
    @Environment(\.dismiss) private var dismiss
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
                        MemoryTheme.Colors.warmCoral.opacity(0.02),
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
                            ForEach(AdditionOption.allCases, id: \.self) { option in
                                optionCard(for: option)
                                    .padding(.horizontal, MemorySpacing.md)
                            }
                        }
                        .padding(.vertical, MemorySpacing.lg)
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
        VStack(spacing: MemorySpacing.md) {
            // Icon
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
                    .frame(width: 80, height: 80)
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
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
            
            // Text
            VStack(spacing: MemorySpacing.xs) {
                Text("どのように本を追加しますか？")
                    .font(MemoryTheme.Fonts.title3())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("最適な方法を選択してください")
                    .font(MemoryTheme.Fonts.subheadline())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
            }
        }
        .padding(.vertical, MemorySpacing.xl)
    }
    
    private func optionCard(for option: AdditionOption) -> some View {
        Button {
            if option == .barcode {
                guard FeatureGate.canScanBarcode else {
                    showPaywall = true
                    return
                }
            }
            selectedOption = option
        } label: {
            HStack(spacing: MemorySpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackground(for: option))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 24))
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
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(MemoryTheme.Colors.inkLightGray)
            }
            .padding(MemorySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.large)
                    .fill(MemoryTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MemoryRadius.large)
                            .stroke(
                                option.isRecommended ? MemoryTheme.Colors.primaryBlue.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .memoryShadow(option.isRecommended ? .medium : .soft)
        }
        .buttonStyle(PlainButtonStyle())
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
                MemoryTheme.Colors.warmCoralLight.opacity(0.2),
                MemoryTheme.Colors.warmCoral.opacity(0.1)
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
            return MemoryTheme.Colors.warmCoral
        case .manual:
            return MemoryTheme.Colors.inkGray
        }
    }
}

#Preview {
    BookAdditionFlowView()
        }
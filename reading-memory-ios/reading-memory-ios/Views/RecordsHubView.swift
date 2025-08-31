import SwiftUI

struct RecordsHubView: View {
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MemoryTheme.Colors.secondaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header using new component with segment control (no padding)
                    TabHeaderView(
                        title: "記録",
                        subtitle: "読書の成長を振り返る",
                        iconName: "chart.line.uptrend.xyaxis.circle.fill",
                        actionButton: {
                            AnyView(
                                VStack(spacing: 0) {
                                    HStack(spacing: 0) {
                                        ForEach(0..<3) { index in
                                            Button {
                                                withAnimation(MemoryTheme.Animation.fast) {
                                                    selectedSegment = index
                                                }
                                            } label: {
                                                VStack(spacing: 0) {
                                                    HStack(spacing: MemorySpacing.xs) {
                                                        Image(systemName: segmentIcon(for: index))
                                                            .font(.system(size: 18, weight: selectedSegment == index ? .semibold : .regular))
                                                        Text(segmentTitle(for: index))
                                                            .font(selectedSegment == index ? MemoryTheme.Fonts.headline() : MemoryTheme.Fonts.body())
                                                    }
                                                    .foregroundColor(selectedSegment == index ? MemoryTheme.Colors.primaryBlue : MemoryTheme.Colors.inkGray)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, MemorySpacing.sm)
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    
                                    // Indicator line
                                    GeometryReader { geometry in
                                        HStack(spacing: 0) {
                                            Rectangle()
                                                .fill(MemoryTheme.Colors.primaryBlue)
                                                .frame(width: geometry.size.width / 3, height: 3)
                                                .offset(x: CGFloat(selectedSegment) * (geometry.size.width / 3))
                                                .animation(MemoryTheme.Animation.spring, value: selectedSegment)
                                        }
                                    }
                                    .frame(height: 3)
                                    .background(MemoryTheme.Colors.inkPale.opacity(0.5))
                                }
                                .background(MemoryTheme.Colors.cardBackground)
                                .memoryShadow(.soft)
                            )
                        },
                        actionButtonNeedsPadding: false,
                        removeBottomPadding: true
                    )
                    
                    // Content
                    TabView(selection: $selectedSegment) {
                        StatisticsView()
                            .tag(0)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        GoalDashboardView()
                            .tag(1)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                        AchievementGalleryView()
                            .tag(2)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(MemoryTheme.Animation.normal, value: selectedSegment)
                }
            }
            .navigationBarHidden(true)
        }
            }
    
    private func segmentIcon(for index: Int) -> String {
        switch index {
        case 0:
            return "chart.bar.fill"
        case 1:
            return "target"
        case 2:
            return "trophy.fill"
        default:
            return "circle"
        }
    }
    
    private func segmentTitle(for index: Int) -> String {
        switch index {
        case 0:
            return "統計"
        case 1:
            return "目標"
        case 2:
            return "達成"
        default:
            return ""
        }
    }
}

#Preview {
    RecordsHubView()
        .environment(AuthViewModel())
}
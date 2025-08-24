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
                    // Header with gradient
                    VStack(spacing: MemorySpacing.md) {
                        // Title with icon
                        HStack(spacing: MemorySpacing.sm) {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            MemoryTheme.Colors.goldenMemoryLight,
                                            MemoryTheme.Colors.goldenMemory
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("読書の記録")
                                .font(MemoryTheme.Fonts.hero())
                                .foregroundColor(MemoryTheme.Colors.inkBlack)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, MemorySpacing.lg)
                        .padding(.top, MemorySpacing.md)
                        
                        // Custom Segment Control
                        HStack(spacing: 0) {
                            ForEach(0..<3) { index in
                                Button {
                                    withAnimation(MemoryTheme.Animation.fast) {
                                        selectedSegment = index
                                    }
                                } label: {
                                    VStack(spacing: MemorySpacing.xs) {
                                        HStack(spacing: MemorySpacing.xs) {
                                            Image(systemName: segmentIcon(for: index))
                                                .font(.system(size: 16))
                                            Text(segmentTitle(for: index))
                                                .font(MemoryTheme.Fonts.subheadline())
                                        }
                                        .foregroundColor(selectedSegment == index ? MemoryTheme.Colors.primaryBlue : MemoryTheme.Colors.inkGray)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, MemorySpacing.sm)
                                        
                                        // Indicator line
                                        Rectangle()
                                            .fill(MemoryTheme.Colors.primaryBlue)
                                            .frame(height: 3)
                                            .opacity(selectedSegment == index ? 1 : 0)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .background(MemoryTheme.Colors.background)
                        .cornerRadius(MemoryRadius.medium)
                        .padding(.horizontal, MemorySpacing.md)
                        .memoryShadow(.soft)
                    }
                    .padding(.bottom, MemorySpacing.md)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.background,
                                MemoryTheme.Colors.secondaryBackground
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
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
            return "アチーブメント"
        default:
            return ""
        }
    }
}

#Preview {
    RecordsHubView()
        .environment(AuthViewModel())
}
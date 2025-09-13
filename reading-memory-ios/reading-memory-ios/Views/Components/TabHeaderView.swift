import SwiftUI

struct TabHeaderView: View {
    let title: String
    let subtitle: String
    var actionButton: (() -> AnyView)? = nil
    var actionButtonNeedsPadding: Bool = true
    var removeBottomPadding: Bool = false
    
    var body: some View {
        VStack(spacing: MemorySpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                    Text(title)
                        .font(MemoryTheme.Fonts.hero())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                    Text(subtitle)
                        .font(MemoryTheme.Fonts.callout())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                }
                Spacer()
            }
            .padding(.horizontal, MemorySpacing.lg)
            .padding(.top, MemorySpacing.lg)
            
            // Optional action button area
            if let actionButton = actionButton {
                Group {
                    if actionButtonNeedsPadding {
                        actionButton()
                            .padding(.horizontal, MemorySpacing.md)
                    } else {
                        actionButton()
                    }
                }
            }
        }
        .padding(.bottom, removeBottomPadding ? 0 : MemorySpacing.lg)
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
    }
}

#Preview {
    TabHeaderView(
        title: "発見",
        subtitle: "新しい本との出会いを"
    )
}
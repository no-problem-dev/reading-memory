import SwiftUI

struct EmptyChatView: View {
    let isAIEnabled: Bool
    
    var body: some View {
        VStack(spacing: MemorySpacing.xl) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlue.opacity(0.1),
                                MemoryTheme.Colors.primaryBlueLight.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .memoryShadow(.soft)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 50))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlueLight,
                                MemoryTheme.Colors.primaryBlue
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: MemorySpacing.sm) {
                Text("読書メモを始めよう")
                    .font(MemoryTheme.Fonts.title3())
                    .fontWeight(.semibold)
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("読みながら感じたことを\n自由に書いてみてください")
                    .font(MemoryTheme.Fonts.body())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                if isAIEnabled {
                    HStack(spacing: MemorySpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .symbolEffect(.variableColor, options: .repeating)
                        Text("AIアシスタントがあなたの考えを深めます")
                            .font(MemoryTheme.Fonts.caption())
                    }
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.vertical, MemorySpacing.sm)
                    .background(
                        Capsule()
                            .fill(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(MemorySpacing.xxl)
        .animation(MemoryTheme.Animation.normal, value: isAIEnabled)
    }
}
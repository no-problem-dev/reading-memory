import SwiftUI

struct EmptyReadingCard: View {
    let onAddBook: () -> Void
    
    var body: some View {
        VStack(spacing: MemorySpacing.lg) {
            // アイコンとグラデーション背景
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.warmCoralLight.opacity(0.2),
                                MemoryTheme.Colors.warmCoral.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.warmCoralLight,
                                MemoryTheme.Colors.warmCoral
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: MemorySpacing.xs) {
                Text("最初の一冊から始めよう")
                    .font(MemoryTheme.Fonts.title3())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("本を追加して、読書メモリーを作りましょう")
                    .font(MemoryTheme.Fonts.callout())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddBook) {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("本を追加する")
                        .font(MemoryTheme.Fonts.headline())
                }
                .foregroundColor(.white)
                .padding(.horizontal, MemorySpacing.lg)
                .padding(.vertical, MemorySpacing.md)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            MemoryTheme.Colors.primaryBlueLight,
                            MemoryTheme.Colors.primaryBlue
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(MemoryRadius.full)
                .memoryShadow(.medium)
            }
        }
        .padding(.vertical, MemorySpacing.xxl)
        .padding(.horizontal, MemorySpacing.lg)
        .frame(maxWidth: .infinity)
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
    }
}
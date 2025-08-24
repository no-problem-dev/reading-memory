import SwiftUI

struct MemoryCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = MemorySpacing.md
    
    init(padding: CGFloat = MemorySpacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(MemoryTheme.Colors.cardBackground)
            .cornerRadius(MemoryRadius.large)
            .memoryShadow(.soft)
    }
}

struct InteractiveMemoryCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = MemorySpacing.md
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(padding: CGFloat = MemorySpacing.md, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(MemoryTheme.Colors.cardBackground)
            .cornerRadius(MemoryRadius.large)
            .memoryShadow(.soft)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .onTapGesture {
                action()
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

struct HighlightCard<Content: View>: View {
    let content: Content
    let gradientColors: [Color]
    
    init(gradientColors: [Color]? = nil, @ViewBuilder content: () -> Content) {
        self.gradientColors = gradientColors ?? [MemoryTheme.Colors.primaryBlueLight, MemoryTheme.Colors.primaryBlue]
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(MemorySpacing.md)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(MemoryRadius.large)
            .memoryShadow(.medium)
    }
}
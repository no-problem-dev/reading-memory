import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    var icon: String = "plus"
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlueLight,
                                    MemoryTheme.Colors.primaryBlue
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .memoryShadow(.medium)
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MemoryTheme.Animation.fast) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct MiniFloatingActionButton: View {
    let action: () -> Void
    let icon: String
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(MemoryTheme.Colors.primaryBlue)
                .clipShape(Circle())
                .memoryShadow(.soft)
        }
    }
}
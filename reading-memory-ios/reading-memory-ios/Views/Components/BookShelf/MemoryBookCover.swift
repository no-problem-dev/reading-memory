import SwiftUI

struct MemoryBookCover: View {
    let book: Book
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        BookCoverView(imageId: book.coverImageId, size: .medium)
            .frame(width: 85, height: 128)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        MemoryTheme.Colors.inkBlack.opacity(0.3)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                .cornerRadius(MemoryRadius.small)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .memoryShadow(.soft)
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(MemoryTheme.Animation.fast) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}
import SwiftUI

struct ProfileIconView: View {
    var size: CGFloat = 40
    var imageUrl: String? = nil
    var initials: String? = nil
    
    var body: some View {
        Group {
            if let imageUrl = imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderView
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholderView
            }
        }
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            MemoryTheme.Colors.primaryBlueLight.opacity(0.5),
                            MemoryTheme.Colors.primaryBlue.opacity(0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .memoryShadow(.soft)
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        MemoryTheme.Colors.goldenMemoryLight,
                        MemoryTheme.Colors.goldenMemory
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(initials ?? "👤")
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
}
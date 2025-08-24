import SwiftUI

/// チャット画像を表示するView
struct ChatImageView: View {
    let imageId: String?
    
    @State private var imageUrl: URL?
    
    var body: some View {
        if let imageUrl = imageUrl {
            CachedAsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(MemoryRadius.medium)
            } placeholder: {
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(MemoryTheme.Colors.inkPale)
                    .overlay(
                        ProgressView()
                            .tint(MemoryTheme.Colors.primaryBlue)
                    )
            }
        } else if imageId != nil {
            // 画像IDがあるがURLがまだ取得できていない場合
            RoundedRectangle(cornerRadius: MemoryRadius.medium)
                .fill(MemoryTheme.Colors.inkPale)
                .overlay(
                    ProgressView()
                        .tint(MemoryTheme.Colors.primaryBlue)
                )
        }
    }
    .task {
        imageUrl = await ImageService.shared.getImageUrl(id: imageId)
    }
}

#Preview {
    VStack(spacing: 20) {
        ChatImageView(imageId: nil)
            .frame(width: 240, height: 180)
    }
    .padding()
}
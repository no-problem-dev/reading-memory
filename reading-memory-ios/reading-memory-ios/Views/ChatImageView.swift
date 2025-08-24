import SwiftUI

/// チャット画像を表示するView
struct ChatImageView: View {
    let imageId: String?
    
    @State private var imageUrl: URL?
    
    var body: some View {
        Group {
            if let imageUrl = imageUrl {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: MemoryRadius.medium)
                            .fill(MemoryTheme.Colors.inkPale)
                            .overlay(
                                ProgressView()
                                    .tint(MemoryTheme.Colors.primaryBlue)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(MemoryRadius.medium)
                    case .failure(_):
                        RoundedRectangle(cornerRadius: MemoryRadius.medium)
                            .fill(MemoryTheme.Colors.inkPale)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
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
}

#Preview {
    VStack(spacing: 20) {
        ChatImageView(imageId: nil)
            .frame(width: 240, height: 180)
    }
    .padding()
}
import SwiftUI

/// プロフィール画像を表示するView
struct ProfileImageView: View {
    let imageId: String?
    let size: CGFloat
    
    @State private var imageUrl: URL?
    
    var body: some View {
        if let imageUrl = imageUrl {
            CachedAsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
                    .frame(width: size, height: size)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        } else if imageId != nil {
            // 画像IDがあるがURLがまだ取得できていない場合
            ProgressView()
                .frame(width: size, height: size)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())
        } else {
            // 画像IDがない場合
            Image(systemName: "person.circle.fill")
                .font(.system(size: size * 0.7))
                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                .frame(width: size, height: size)
        }
    }
    .task {
        imageUrl = await ImageService.shared.getImageUrl(id: imageId)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileImageView(imageId: nil, size: 60)
        ProfileImageView(imageId: nil, size: 80)
        ProfileImageView(imageId: nil, size: 110)
    }
    .padding()
}
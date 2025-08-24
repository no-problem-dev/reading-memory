import SwiftUI

/// プロフィール画像を表示するView
struct ProfileImageView: View {
    let imageId: String?
    let size: CGFloat
    
    @State private var imageUrl: URL?
    @State private var uiImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                // URLSessionで取得した画像を表示
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading {
                // 画像読み込み中
                ProgressView()
                    .frame(width: size, height: size)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
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
            if let imageId = imageId {
                isLoading = true
                imageUrl = await ImageService.shared.getImageUrl(id: imageId)
                
                // URLSessionで画像を取得
                if let url = imageUrl {
                    await loadImage(from: url)
                }
                isLoading = false
            }
        }
    }
    
    private func loadImage(from url: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.uiImage = image
                }
            }
        } catch {
            // Handle error silently
        }
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
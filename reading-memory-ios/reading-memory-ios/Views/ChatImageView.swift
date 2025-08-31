import SwiftUI

/// チャット画像を表示するView
struct ChatImageView: View {
    let imageId: String?
    
    @State private var imageUrl: URL?
    @State private var uiImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                // URLSessionで取得した画像を表示
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(MemoryRadius.medium)
            } else if isLoading {
                // 画像読み込み中
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(MemoryTheme.Colors.inkPale)
                    .overlay(
                        ProgressView()
                            .tint(MemoryTheme.Colors.primaryBlue)
                    )
            } else if imageId != nil {
                // 画像IDがあるがURLがまだ取得できていない場合
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(MemoryTheme.Colors.inkPale)
                    .overlay(
                        ProgressView()
                            .tint(MemoryTheme.Colors.primaryBlue)
                    )
            } else {
                // 画像がない場合（空のビュー）
                EmptyView()
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
            print("Failed to load image from URL: \(url), error: \(error)")
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
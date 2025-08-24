import SwiftUI

enum BookCoverSize {
    case small
    case medium
    case large
    case xlarge
    case custom(width: CGFloat, height: CGFloat)
    
    var width: CGFloat {
        switch self {
        case .small:
            return 60
        case .medium:
            return 80
        case .large:
            return 110
        case .xlarge:
            return 160
        case .custom(let width, _):
            return width
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small:
            return 90
        case .medium:
            return 120
        case .large:
            return 160
        case .xlarge:
            return 240
        case .custom(_, let height):
            return height
        }
    }
}

struct BookCoverView: View {
    let imageURL: String?
    let size: BookCoverSize
    
    var body: some View {
        ZStack {
            if let imageURL = imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.secondarySystemBackground))
                }
            } else {
                BookCoverPlaceholder()
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .id(imageURL) // URLが変わったときに再描画を強制
    }
}

struct BookCoverPlaceholder: View {
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [MemoryTheme.Colors.inkPale, MemoryTheme.Colors.inkLightGray.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Image(systemName: "book.closed.fill")
                .font(.title)
                .foregroundStyle(MemoryTheme.Colors.inkLightGray)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        BookCoverView(imageURL: nil, size: BookCoverSize.small)
        BookCoverView(imageURL: nil, size: BookCoverSize.medium)
        BookCoverView(imageURL: nil, size: BookCoverSize.large)
    }
    .padding()
}
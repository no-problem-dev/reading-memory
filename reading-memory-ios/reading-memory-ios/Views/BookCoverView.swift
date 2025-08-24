import SwiftUI

enum BookCoverSize {
    case small
    case medium
    case large
    case custom(width: CGFloat, height: CGFloat)
    
    var width: CGFloat {
        switch self {
        case .small:
            return 60
        case .medium:
            return 80
        case .large:
            return 110
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
            if let imageURL = imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure(_):
                        BookCoverPlaceholder()
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    @unknown default:
                        BookCoverPlaceholder()
                    }
                }
            } else {
                BookCoverPlaceholder()
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct BookCoverPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Image(systemName: "book.closed.fill")
                .font(.title)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        BookCoverView(imageURL: nil, size: .small)
        BookCoverView(imageURL: nil, size: .medium)
        BookCoverView(imageURL: nil, size: .large)
    }
    .padding()
}
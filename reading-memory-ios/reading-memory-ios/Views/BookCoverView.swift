import SwiftUI

struct BookCoverView: View {
    let book: Book
    var showTitle: Bool = true
    var showRating: Bool = true
    var width: CGFloat = 110
    var height: CGFloat = 160
    
    var body: some View {
        VStack(spacing: 8) {
            // Book cover
            ZStack {
                let imageUrl = book.coverImageUrl
                if let imageUrl = imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure(_):
                            BookCoverPlaceholder(title: book.title)
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.1))
                        @unknown default:
                            BookCoverPlaceholder(title: book.title)
                        }
                    }
                } else {
                    BookCoverPlaceholder(title: book.title)
                }
                
                // Status badge
                if book.status != .wantToRead {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            BookStatusBadge(status: book.status)
                                .padding(4)
                        }
                    }
                }
            }
            .frame(width: width, height: height)
            .clipped()
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            if showTitle {
                // Book title
                Text(book.title)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: width)
            }
            
            if showRating {
                // Rating
                if let rating = book.rating {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
        }
    }
}

struct BookCoverPlaceholder: View {
    let title: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.25))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 8)
                }
            }
        }
    }
}

struct EmptyBookCover: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
        }
        .frame(width: 110, height: 160)
    }
}

struct BookStatusBadge: View {
    let status: ReadingStatus
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: status.icon)
                .font(.system(size: 10))
            Text(status.displayName)
                .font(.system(size: 10))
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.9))
        .foregroundColor(.white)
        .cornerRadius(4)
    }
    
    var statusColor: Color {
        switch status {
        case .wantToRead:
            return .blue
        case .reading:
            return .orange
        case .completed:
            return .green
        case .dnf:
            return .gray
        }
    }
}

#Preview {
    BookCoverView(book: Book.new(
        isbn: nil,
        title: "SwiftUI実践入門",
        author: "山田太郎",
        publisher: nil,
        publishedDate: nil,
        pageCount: nil,
        description: nil,
        coverImageUrl: nil,
        dataSource: .manual
    ))
    .padding()
}
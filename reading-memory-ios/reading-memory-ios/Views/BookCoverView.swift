import SwiftUI

struct BookCoverView: View {
    let userBook: UserBook
    
    var body: some View {
        VStack(spacing: 8) {
            // Book cover
            ZStack {
                let imageUrl = userBook.bookCoverImageUrl
                if let imageUrl = imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure(_):
                            BookCoverPlaceholder(title: userBook.bookTitle)
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.opacity(0.1))
                        @unknown default:
                            BookCoverPlaceholder(title: userBook.bookTitle)
                        }
                    }
                } else {
                    BookCoverPlaceholder(title: userBook.bookTitle)
                }
                
                // Status badge
                if userBook.status != .wantToRead {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            BookStatusBadge(status: userBook.status)
                                .padding(4)
                        }
                    }
                }
            }
            .frame(width: 110, height: 160)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Book title
            Text(userBook.bookTitle)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 110)
            
            // Rating
            if let rating = userBook.rating {
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

struct BookCoverPlaceholder: View {
    let title: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 40))
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
        .frame(width: 110, height: 160)
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
    BookCoverView(userBook: UserBook(
        id: "1",
        userId: "user1",
        bookId: "book1",
        bookTitle: "SwiftUI実践入門",
        bookAuthor: "山田太郎",
        bookCoverImageUrl: nil,
        bookIsbn: nil,
        status: .reading,
        rating: 4.5,
        readingProgress: nil,
        currentPage: nil,
        startDate: Date(),
        completedDate: nil,
        memo: nil,
        tags: [],
        isPrivate: false,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .padding()
}
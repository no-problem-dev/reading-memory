import SwiftUI

struct BookShelfGridView: View {
    let books: [Book]
    let onBookTapped: (Book) -> Void
    let onChatTapped: (Book) -> Void
    
    let columns = [
        GridItem(.flexible(), spacing: MemorySpacing.sm),
        GridItem(.flexible(), spacing: MemorySpacing.sm),
        GridItem(.flexible(), spacing: MemorySpacing.sm)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: MemorySpacing.md) {
                ForEach(books) { book in
                    BookGridCard(
                        book: book,
                        onBookTapped: { onBookTapped(book) },
                        onChatTapped: { onChatTapped(book) }
                    )
                }
            }
            .padding(.horizontal, MemorySpacing.md)
            .padding(.bottom, 100)
        }
    }
}

struct BookGridCard: View {
    let book: Book
    let onBookTapped: () -> Void
    let onChatTapped: () -> Void
    
    var statusColor: Color {
        switch book.status {
        case .reading:
            return MemoryTheme.Colors.primaryBlue
        case .completed:
            return MemoryTheme.Colors.success
        case .dnf:
            return MemoryTheme.Colors.warning
        case .wantToRead:
            return MemoryTheme.Colors.info
        }
    }
    
    var statusText: String {
        switch book.status {
        case .reading:
            return "読書中"
        case .completed:
            return "読了"
        case .dnf:
            return "積読"
        case .wantToRead:
            return "読みたい"
        }
    }
    
    var body: some View {
        Button(action: onBookTapped) {
            VStack(spacing: 0) {
                // 表紙画像
                BookCoverView(
                    imageId: book.coverImageId,
                    size: .custom(width: 100, height: 140)
                )
                .shadow(radius: 4)
                .padding(.top, MemorySpacing.sm)
                
                // 本の情報（固定高さ）
                VStack(alignment: .leading, spacing: 4) {
                    // タイトルと著者（固定高さ）
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(MemoryTheme.Fonts.caption())
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)
                        
                        Text(book.author)
                            .font(MemoryTheme.Fonts.footnote())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .lineLimit(1)
                    }
                    .frame(height: 50)
                    
                    // ステータスバッジ（固定高さ）
                    HStack {
                        Text(statusText)
                            .font(MemoryTheme.Fonts.footnote())
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                statusColor.opacity(0.1)
                            )
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        // チャットボタン（読書中の本のみ）
                        if book.status == .reading {
                            Button(action: onChatTapped) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            }
                        }
                    }
                    .frame(height: 24)
                    
                    // 評価または空白（固定高さ）
                    Group {
                        if book.status == .completed, let rating = book.rating {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                }
                            }
                        } else {
                            Color.clear
                        }
                    }
                    .frame(height: 16)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, MemorySpacing.xs)
            }
            .frame(height: 250) // 全体の固定高さ
            .frame(maxWidth: .infinity)
            .background(MemoryTheme.Colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BookShelfGridView(
        books: [
            Book(
                id: "1",
                isbn: "1234567890",
                title: "サンプルブック1",
                author: "著者名",
                publisher: "出版社",
                publishedDate: Date(),
                pageCount: 200,
                coverImageId: nil,
                dataSource: .googleBooks,
                status: .reading,
                currentPage: 100,
                addedDate: Date(),
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        onBookTapped: { _ in },
        onChatTapped: { _ in }
    )
}
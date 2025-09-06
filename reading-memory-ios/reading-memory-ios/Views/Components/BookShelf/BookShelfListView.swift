import SwiftUI

struct BookShelfListView: View {
    let books: [Book]
    let onBookTapped: (Book) -> Void
    let onChatTapped: (Book) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: MemorySpacing.xs) {
                ForEach(books) { book in
                    BookListCard(
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

struct BookListCard: View {
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
            HStack(spacing: MemorySpacing.sm) {
                // 表紙画像
                BookCoverView(
                    imageId: book.coverImageId,
                    size: .custom(width: 60, height: 85)
                )
                
                // 本の情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(MemoryTheme.Fonts.body())
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(book.author)
                        .font(MemoryTheme.Fonts.caption())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                        .lineLimit(1)
                    
                    // ステータスと進捗
                    HStack {
                        // ステータスバッジ
                        Text(statusText)
                            .font(MemoryTheme.Fonts.footnote())
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                        
                        // 読書進捗（読書中の本のみ）
                        if book.status == .reading,
                           let currentPage = book.currentPage,
                           let pageCount = book.pageCount,
                           pageCount > 0 {
                            Text("・")
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            Text("\(Int((Double(currentPage) / Double(pageCount)) * 100))%")
                                .font(MemoryTheme.Fonts.footnote())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                        }
                        
                        // 評価（完了した本のみ）
                        if book.status == .completed, let rating = book.rating {
                            Text("・")
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            HStack(spacing: 1) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text("\(String(format: "%.1f", rating))")
                                    .font(MemoryTheme.Fonts.footnote())
                                    .foregroundColor(MemoryTheme.Colors.inkGray)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // 日付情報
                    if let date = book.status == .completed ? book.completedDate : book.startDate {
                        Text(formatDate(date))
                            .font(MemoryTheme.Fonts.footnote())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                }
                
                // チャットボタン（読書中の本のみ）
                if book.status == .reading {
                    Button(action: onChatTapped) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                            )
                    }
                }
            }
            .padding(MemorySpacing.sm)
            .background(MemoryTheme.Colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

#Preview {
    BookShelfListView(
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
                startDate: Date(),
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        onBookTapped: { _ in },
        onChatTapped: { _ in }
    )
}
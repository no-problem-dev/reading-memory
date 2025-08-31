import SwiftUI

struct CurrentlyReadingSection: View {
    let books: [Book]
    let onChatTapped: (Book) -> Void
    let onBookTapped: (Book) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.md) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                Text("いま読んでいる本")
                    .font(MemoryTheme.Fonts.headline())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
            }
            .padding(.horizontal, MemorySpacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MemorySpacing.md) {
                    ForEach(books, id: \.id) { book in
                        CurrentReadingCard(
                            book: book,
                            onChatTapped: {
                                onChatTapped(book)
                            },
                            onBookTapped: {
                                onBookTapped(book)
                            }
                        )
                        .id(book.id) // 各本を一意に識別
                    }
                }
                .padding(.horizontal, MemorySpacing.md)
            }
        }
    }
}
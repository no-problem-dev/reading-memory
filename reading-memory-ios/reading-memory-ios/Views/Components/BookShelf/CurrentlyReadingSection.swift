import SwiftUI

struct CurrentlyReadingSection: View {
    let books: [Book]
    let onChatTapped: (Book) -> Void
    let onBookTapped: (Book) -> Void
    
    @State private var showBookList = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.md) {
            HStack {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 16))
                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    Text("いま読んでいる本")
                        .font(MemoryTheme.Fonts.headline())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                }
                
                Spacer()
                
                if books.count > 2 {
                    Button(action: {
                        showBookList = true
                    }) {
                        Text("もっと見る")
                            .font(MemoryTheme.Fonts.footnote())
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                }
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
        .sheet(isPresented: $showBookList) {
            BookListView(
                books: books,
                title: "いま読んでいる本",
                listType: .currentlyReading,
                onBookTapped: onBookTapped,
                onChatTapped: onChatTapped,
                onDismiss: {
                    showBookList = false
                }
            )
        }
    }
}
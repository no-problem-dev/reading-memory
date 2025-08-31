import SwiftUI

struct MemoryShelfSection: View {
    let books: [Book]
    let onBookTapped: (Book) -> Void
    
    @State private var showAllBooks = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.md) {
            HStack {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.goldenMemory,
                                    MemoryTheme.Colors.goldenMemoryDark
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("メモリーシェルフ")
                        .font(MemoryTheme.Fonts.headline())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                }
                
                Spacer()
                
                if books.count > 12 {
                    Button(action: {
                        withAnimation(MemoryTheme.Animation.normal) {
                            showAllBooks.toggle()
                        }
                    }) {
                        Text(showAllBooks ? "閉じる" : "すべて見る")
                            .font(MemoryTheme.Fonts.footnote())
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                }
            }
            
            VStack(spacing: MemorySpacing.md) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 85), spacing: MemorySpacing.sm)
                ], spacing: MemorySpacing.md) {
                    ForEach(showAllBooks ? books : Array(books.prefix(12)), id: \.id) { book in
                        MemoryBookCover(book: book) {
                            onBookTapped(book)
                        }
                        .id(book.id) // 各本を一意に識別
                    }
                }
            }
            .padding(MemorySpacing.md)
            .background(MemoryTheme.Colors.secondaryBackground)
            .cornerRadius(MemoryRadius.large)
        }
    }
}
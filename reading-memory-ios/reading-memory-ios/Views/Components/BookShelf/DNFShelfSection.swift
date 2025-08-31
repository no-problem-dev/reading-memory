import SwiftUI

struct DNFShelfSection: View {
    let books: [Book]
    let onBookTapped: (Book) -> Void
    
    @State private var showAllBooks = false
    @State private var showBookList = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.md) {
            HStack {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.inkGray,
                                    MemoryTheme.Colors.inkGray.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("途中でやめた本")
                        .font(MemoryTheme.Fonts.headline())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                }
                
                Spacer()
                
                HStack(spacing: MemorySpacing.sm) {
                    if books.count > 6 {
                        Button(action: {
                            showBookList = true
                        }) {
                            Text("もっと見る")
                                .font(MemoryTheme.Fonts.footnote())
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                        }
                    }
                    
                    if books.count > 12 {
                        Button(action: {
                            withAnimation(MemoryTheme.Animation.normal) {
                                showAllBooks.toggle()
                            }
                        }) {
                            Text(showAllBooks ? "閉じる" : "すべて表示")
                                .font(MemoryTheme.Fonts.footnote())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                        }
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
                        .id(book.id)
                    }
                }
            }
            .padding(MemorySpacing.md)
            .background(MemoryTheme.Colors.secondaryBackground)
            .cornerRadius(MemoryRadius.large)
        }
        .sheet(isPresented: $showBookList) {
            BookListView(
                books: books,
                title: "途中でやめた本",
                listType: .dnf,
                onBookTapped: onBookTapped,
                onChatTapped: nil,
                onDismiss: {
                    showBookList = false
                }
            )
        }
    }
}
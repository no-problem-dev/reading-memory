import SwiftUI

struct BookShelfHomeView: View {
    @State private var viewModel = BookShelfViewModel()
    @Binding var showAddBook: Bool
    @State private var navigationPath = NavigationPath()
    @State private var chatBook: Book?
    
    var currentlyReadingBooks: [Book] {
        viewModel.filteredBooks.filter { $0.status == .reading }
    }
    
    var completedBooks: [Book] {
        viewModel.filteredBooks.filter { $0.status == .completed }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: MemorySpacing.xl) {
                    // ヘッダーメッセージ
                    if !currentlyReadingBooks.isEmpty || !completedBooks.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Text("本と過ごした時間を")
                                    .font(MemoryTheme.Fonts.callout())
                                    .foregroundColor(MemoryTheme.Colors.inkGray)
                                Text("ずっと大切に")
                                    .font(MemoryTheme.Fonts.title2())
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.top, MemorySpacing.sm)
                    }
                    
                    // 現在読書中セクション
                    if !currentlyReadingBooks.isEmpty {
                        CurrentlyReadingSection(
                            books: currentlyReadingBooks,
                            onChatTapped: { book in
                                chatBook = book
                            },
                            onBookTapped: { book in
                                navigationPath.append(book)
                            }
                        )
                    } else {
                        EmptyReadingCard(onAddBook: {
                            showAddBook = true
                        })
                        .padding(.horizontal, MemorySpacing.md)
                    }
                    
                    // メモリーシェルフ（完読本）
                    if !completedBooks.isEmpty {
                        MemoryShelfSection(books: completedBooks) { book in
                            navigationPath.append(book)
                        }
                        .padding(.horizontal, MemorySpacing.md)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(MemoryTheme.Colors.background)
            .navigationTitle("読書メモリー")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadBooks()
            }
            .navigationDestination(for: Book.self) { book in
                BookDetailView(bookId: book.id)
                                }
            .fullScreenCover(item: $chatBook) { book in
                BookChatView(book: book)
                                }
        }
        .task {
            await viewModel.loadBooks()
        }
    }
}

// 現在読書中セクション
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

// 現在読書中のカード
struct CurrentReadingCard: View {
    let book: Book
    let onChatTapped: () -> Void
    let onBookTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 本の情報部分
            Button(action: onBookTapped) {
                HStack(alignment: .top, spacing: MemorySpacing.md) {
                    // 本の表紙
                    BookCoverView(imageId: book.coverImageId, size: .large)
                        .frame(width: 80, height: 120)
                    
                    // 本の情報
                    VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                        Text(book.title)
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(book.author)
                            .font(MemoryTheme.Fonts.footnote())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // 読書進捗
                        if let progress = book.readingProgress {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(Int(progress))%")
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                    Spacer()
                                    Text("読書中")
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(MemoryTheme.Colors.inkGray)
                                }
                                
                                // プログレスバー
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(MemoryTheme.Colors.inkPale)
                                        .frame(height: 4)
                                    
                                    Capsule()
                                        .fill(MemoryTheme.Colors.primaryBlue)
                                        .frame(width: (280 - MemorySpacing.md * 2 - 80 - MemorySpacing.md) * (progress / 100.0), height: 4)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(MemorySpacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            
            Divider()
                .foregroundColor(MemoryTheme.Colors.inkPale)
            
            // チャットボタン
            Button(action: onChatTapped) {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 16))
                    Text("読書メモを書く")
                        .font(MemoryTheme.Fonts.subheadline())
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MemorySpacing.md)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            MemoryTheme.Colors.primaryBlueLight,
                            MemoryTheme.Colors.primaryBlue
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 320)
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
    }
}

// 読書中の本がない場合のカード
struct EmptyReadingCard: View {
    let onAddBook: () -> Void
    
    var body: some View {
        VStack(spacing: MemorySpacing.lg) {
            // アイコンとグラデーション背景
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.warmCoralLight.opacity(0.2),
                                MemoryTheme.Colors.warmCoral.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.warmCoralLight,
                                MemoryTheme.Colors.warmCoral
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: MemorySpacing.xs) {
                Text("最初の一冊から始めよう")
                    .font(MemoryTheme.Fonts.title3())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("本を追加して、読書メモリーを作りましょう")
                    .font(MemoryTheme.Fonts.callout())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddBook) {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("本を追加する")
                        .font(MemoryTheme.Fonts.headline())
                }
                .foregroundColor(.white)
                .padding(.horizontal, MemorySpacing.lg)
                .padding(.vertical, MemorySpacing.md)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            MemoryTheme.Colors.primaryBlueLight,
                            MemoryTheme.Colors.primaryBlue
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(MemoryRadius.full)
                .memoryShadow(.medium)
            }
        }
        .padding(.vertical, MemorySpacing.xxl)
        .padding(.horizontal, MemorySpacing.lg)
        .frame(maxWidth: .infinity)
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
    }
}

// メモリーシェルフセクション
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

// メモリーシェルフの本
struct MemoryBookCover: View {
    let book: Book
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        BookCoverView(imageId: book.coverImageId, size: .medium)
            .frame(width: 85, height: 128)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        MemoryTheme.Colors.inkBlack.opacity(0.3)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                .cornerRadius(MemoryRadius.small)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .memoryShadow(.soft)
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(MemoryTheme.Animation.fast) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

#Preview {
    BookShelfHomeView(showAddBook: .constant(false))
        .environment(AuthViewModel())
        }
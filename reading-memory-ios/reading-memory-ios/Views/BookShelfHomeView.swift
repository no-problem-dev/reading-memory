import SwiftUI

struct BookShelfHomeView: View {
    @State private var viewModel = BookShelfViewModel()
    @Binding var showAddBook: Bool
    @State private var selectedBook: Book?
    @State private var showChat = false
    
    var currentlyReadingBooks: [Book] {
        viewModel.filteredBooks.filter { $0.status == .reading }
    }
    
    var completedBooks: [Book] {
        viewModel.filteredBooks.filter { $0.status == .completed }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 現在読書中セクション
                    if !currentlyReadingBooks.isEmpty {
                        CurrentlyReadingSection(
                            books: currentlyReadingBooks,
                            onChatTapped: { book in
                                selectedBook = book
                                showChat = true
                            },
                            onBookTapped: { book in
                                selectedBook = book
                            }
                        )
                    } else {
                        EmptyReadingCard(onAddBook: {
                            showAddBook = true
                        })
                    }
                    
                    // メモリーシェルフ（完読本）
                    if !completedBooks.isEmpty {
                        MemoryShelfSection(books: completedBooks) { book in
                            selectedBook = book
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("読書メモリー")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadBooks()
            }
            .navigationDestination(item: $selectedBook) { book in
                BookDetailView(bookId: book.id)
            }
            .fullScreenCover(isPresented: $showChat) {
                if let book = selectedBook {
                    NavigationStack {
                        BookChatView(book: book)
                    }
                }
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
        VStack(alignment: .leading, spacing: 16) {
            Text("いま読んでいる本")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(books) { book in
                        CurrentReadingCard(
                            book: book,
                            onChatTapped: {
                                onChatTapped(book)
                            },
                            onBookTapped: {
                                onBookTapped(book)
                            }
                        )
                    }
                }
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
        VStack(alignment: .leading, spacing: 12) {
            // 本の表紙と情報
            HStack(spacing: 16) {
                BookCoverView(imageURL: book.coverImageUrl, size: .large)
                    .frame(width: 80, height: 120)
                    .onTapGesture {
                        onBookTapped()
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    // 読書進捗
                    if let progress = book.readingProgress {
                        ProgressView(value: progress / 100.0) {
                            Text("\(Int(progress))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // チャットボタン
            Button(action: onChatTapped) {
                Label("チャットを続ける", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// 読書中の本がない場合のカード
struct EmptyReadingCard: View {
    let onAddBook: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("読書を始めましょう")
                    .font(.headline)
                
                Text("本を追加して、読書の記録を始めます")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddBook) {
                Label("本を追加", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// メモリーシェルフセクション
struct MemoryShelfSection: View {
    let books: [Book]
    let onBookTapped: (Book) -> Void
    
    @State private var showAllBooks = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("メモリーシェルフ")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if books.count > 12 {
                    Button(showAllBooks ? "閉じる" : "すべて見る") {
                        withAnimation {
                            showAllBooks.toggle()
                        }
                    }
                    .font(.caption)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 12)
            ], spacing: 16) {
                ForEach(showAllBooks ? books : Array(books.prefix(12))) { book in
                    BookCoverView(imageURL: book.coverImageUrl, size: .medium)
                        .frame(width: 80, height: 120)
                        .onTapGesture {
                            onBookTapped(book)
                        }
                }
            }
        }
    }
}

#Preview {
    BookShelfHomeView(showAddBook: .constant(false))
        .environment(AuthViewModel())
}
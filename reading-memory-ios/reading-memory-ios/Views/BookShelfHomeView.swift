import SwiftUI

struct BookShelfHomeView: View {
    @State private var viewModel = BookShelfViewModel()
    @State private var showAddBook = false
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
            ZStack {
                // Main content
                ScrollView {
                VStack(spacing: MemorySpacing.xl) {
                    // ヘッダーメッセージ
                    if !currentlyReadingBooks.isEmpty || !completedBooks.isEmpty {
                        HeaderMessageView()
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
                BookMemoryTabView(bookId: book.id)
                                }
                
                // Floating Action Button
                if navigationPath.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingActionButton(action: {
                                showAddBook = true
                            }, icon: "plus")
                            .padding(.bottom, MemorySpacing.md)
                            .padding(.trailing, MemorySpacing.lg)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(), value: navigationPath.isEmpty)
                }
            }
        }
        .task {
            await viewModel.loadBooks()
        }
        .sheet(isPresented: $showAddBook) {
            BookAdditionFlowView()
        }
    }
}

private struct HeaderMessageView: View {
    var body: some View {
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
}

#Preview {
    BookShelfHomeView()
        .environment(AuthViewModel())
}

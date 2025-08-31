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
    
    var dnfBooks: [Book] {
        viewModel.filteredBooks.filter { $0.status == .dnf }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                MemoryTheme.Colors.secondaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header using new component with updated subtitle
                        TabHeaderView(
                            title: "本棚",
                            subtitle: "本との出会いと読書体験を大切に記録",
                            iconName: "books.vertical.circle.fill"
                        )
                        
                        VStack(spacing: MemorySpacing.xl) {
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
                            
                            // 読み終わった本セクション
                            if !completedBooks.isEmpty {
                                MemoryShelfSection(books: completedBooks) { book in
                                    navigationPath.append(book)
                                }
                                .padding(.horizontal, MemorySpacing.md)
                            }
                            
                            // 途中で読むのをやめた本セクション
                            if !dnfBooks.isEmpty {
                                DNFShelfSection(books: dnfBooks) { book in
                                    navigationPath.append(book)
                                }
                                .padding(.horizontal, MemorySpacing.md)
                            }
                        }
                        .padding(.bottom, 100)
                    }
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
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.loadBooks()
            }
            .navigationDestination(for: Book.self) { book in
                BookDetailView(bookId: book.id)
                            }
            .fullScreenCover(item: $chatBook) { book in
                BookMemoryTabView(bookId: book.id)
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

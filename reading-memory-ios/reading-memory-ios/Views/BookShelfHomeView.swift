import SwiftUI

struct BookShelfHomeView: View {
    @Environment(BookStore.self) private var bookStore
    @Environment(AnalyticsService.self) private var analytics
    @State private var showAddBook = false
    @State private var navigationPath = NavigationPath()
    @State private var chatBook: Book?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                MemoryTheme.Colors.secondaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header using new component with updated subtitle
                    TabHeaderView(
                        title: "本棚",
                        subtitle: "本との出会いと読書体験を大切に記録"
                    )
                    
                    // Status tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MemorySpacing.sm) {
                            ForEach(BookStore.BookFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        bookStore.setFilter(filter)
                                        analytics.track(AnalyticsEvent.userAction(action: .filterApplied(filterType: filter.rawValue)))
                                    }
                                }) {
                                    Text(filter.rawValue)
                                        .font(MemoryTheme.Fonts.body())
                                        .fontWeight(bookStore.currentFilter == filter ? .semibold : .regular)
                                        .foregroundColor(
                                            bookStore.currentFilter == filter
                                                ? MemoryTheme.Colors.primaryBlue
                                                : MemoryTheme.Colors.inkGray
                                        )
                                        .padding(.horizontal, MemorySpacing.md)
                                        .padding(.vertical, MemorySpacing.xs)
                                        .background(
                                            bookStore.currentFilter == filter
                                                ? MemoryTheme.Colors.primaryBlue.opacity(0.1)
                                                : Color.clear
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, MemorySpacing.md)
                    }
                    .padding(.vertical, MemorySpacing.sm)
                    
                    // Display mode toggle
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    bookStore.setDisplayMode(.grid)
                                }
                            }) {
                                Image(systemName: "square.grid.3x3.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(
                                        bookStore.displayMode == .grid
                                            ? MemoryTheme.Colors.primaryBlue
                                            : MemoryTheme.Colors.inkGray
                                    )
                                    .padding(MemorySpacing.xs)
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    bookStore.setDisplayMode(.list)
                                }
                            }) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 16))
                                    .foregroundColor(
                                        bookStore.displayMode == .list
                                            ? MemoryTheme.Colors.primaryBlue
                                            : MemoryTheme.Colors.inkGray
                                    )
                                    .padding(MemorySpacing.xs)
                            }
                        }
                        .background(MemoryTheme.Colors.cardBackground)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                        .padding(.horizontal, MemorySpacing.md)
                    }
                    .padding(.bottom, MemorySpacing.sm)
                    
                    // Content
                    if bookStore.filteredBooks.isEmpty {
                        EmptyStateView(filter: bookStore.currentFilter) {
                            showAddBook = true
                        }
                    } else {
                        switch bookStore.displayMode {
                        case .grid:
                            BookShelfGridView(
                                books: bookStore.filteredBooks,
                                onBookTapped: { book in
                                    analytics.track(AnalyticsEvent.bookEvent(event: .bookSelected(bookId: book.id, fromScreen: "book_shelf")))
                                    navigationPath.append(book)
                                },
                                onChatTapped: { book in
                                    chatBook = book
                                }
                            )
                        case .list:
                            BookShelfListView(
                                books: bookStore.filteredBooks,
                                onBookTapped: { book in
                                    analytics.track(AnalyticsEvent.bookEvent(event: .bookSelected(bookId: book.id, fromScreen: "book_shelf")))
                                    navigationPath.append(book)
                                },
                                onChatTapped: { book in
                                    chatBook = book
                                }
                            )
                        }
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
                await bookStore.loadBooks()
            }
            .navigationDestination(for: Book.self) { book in
                BookDetailView(bookId: book.id)
            }
            .fullScreenCover(item: $chatBook) { book in
                BookMemoryTabView(bookId: book.id)
            }
        }
        .task {
            await bookStore.loadBooks()
        }
        .onAppear {
            analytics.track(AnalyticsEvent.screenView(screen: .bookShelf))
        }
        .sheet(isPresented: $showAddBook) {
            BookAdditionFlowView()
        }
    }
}

// Empty state view
struct EmptyStateView: View {
    let filter: BookStore.BookFilter
    let onAddBook: () -> Void
    
    var message: String {
        switch filter {
        case .all:
            return "まだ本が登録されていません"
        case .reading:
            return "現在読書中の本はありません"
        case .completed:
            return "読了した本はまだありません"
        case .dnf:
            return "積読の本はありません"
        case .wantToRead:
            return "読みたい本はまだありません"
        }
    }
    
    var body: some View {
        VStack(spacing: MemorySpacing.lg) {
            Spacer()
            
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(MemoryTheme.Colors.inkGray.opacity(0.5))
            
            Text(message)
                .font(MemoryTheme.Fonts.body())
                .foregroundColor(MemoryTheme.Colors.inkGray)
                .multilineTextAlignment(.center)
            
            Button(action: onAddBook) {
                HStack {
                    Image(systemName: "plus")
                    Text("本を追加")
                }
                .font(MemoryTheme.Fonts.body())
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, MemorySpacing.lg)
                .padding(.vertical, MemorySpacing.md)
                .background(MemoryTheme.Colors.primaryBlue)
                .cornerRadius(24)
            }
            
            Spacer()
        }
        .padding()
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
import SwiftUI

struct WantToReadListView: View {
    @Environment(BookStore.self) private var bookStore
    @State private var viewModel = WantToReadListViewModel()
    @State private var showingSortOptions = false
    @State private var editMode: EditMode = .inactive
    @State private var selectedBook: Book?
    @State private var bookForSettings: Book?
    @State private var navigationPath = NavigationPath()
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading && viewModel.books.isEmpty {
            ProgressView("読みたいリストを読み込み中...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.books.isEmpty {
            EmptyWantToReadView()
        } else {
            bookListView
        }
    }
    
    private var bookListView: some View {
        VStack(spacing: 0) {
            // 統計ヘッダー
            WantToReadHeaderView(books: viewModel.books)
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
            
            // リスト
            List {
                ForEach(viewModel.books) { book in
                    NavigationLink(value: book) {
                        WantToReadRowView(book: book)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        deleteButton(for: book)
                        settingsButton(for: book)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        startReadingButton(for: book)
                    }
                }
                // .onMove { source, destination in
                //     Task {
                //         await viewModel.reorderBooks(from: source, to: destination)
                //     }
                // }
            }
            .listStyle(PlainListStyle())
            // .environment(\.editMode, $editMode)
        }
    }
    
    private func deleteButton(for book: Book) -> some View {
        Button(role: .destructive) {
            Task {
                await viewModel.deleteBook(bookId: book.id)
            }
        } label: {
            Label("削除", systemImage: "trash")
        }
    }
    
    private func startReadingButton(for book: Book) -> some View {
        Button {
            Task {
                await viewModel.startReading(bookId: book.id)
            }
        } label: {
            Label("読書開始", systemImage: "book.fill")
        }
        .tint(.green)
    }
    
    private func settingsButton(for book: Book) -> some View {
        Button {
            bookForSettings = book
        } label: {
            Label("設定", systemImage: "gear")
        }
        .tint(.blue)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContent
            .navigationTitle("読みたいリスト")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Book.self) { book in
                BookDetailView(bookId: book.id)
                                }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editMode == .active {
                        Button("完了") {
                            withAnimation {
                                editMode = .inactive
                            }
                        }
                    } else {
                        Menu {
                            ForEach(WantToReadListViewModel.SortOption.allCases, id: \.self) { option in
                                Button {
                                    viewModel.sortOption = option
                                } label: {
                                    HStack {
                                        Label(option.rawValue, systemImage: option.icon)
                                        if viewModel.sortOption == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadWantToReadBooks()
            }
            .sheet(item: $bookForSettings) { book in
                WantToReadDetailView(book: book) { updatedBook in
                    Task {
                        if let updatedBook = updatedBook {
                            await viewModel.updatePriority(bookId: updatedBook.id, priority: updatedBook.priority)
                            await viewModel.updatePlannedReadingDate(bookId: updatedBook.id, date: updatedBook.plannedReadingDate)
                            await viewModel.toggleReminder(bookId: updatedBook.id)
                            await viewModel.updatePurchaseLinks(bookId: updatedBook.id, links: updatedBook.purchaseLinks ?? [])
                        }
                    }
                }
            }
        }
        .task {
            viewModel.setBookStore(bookStore)
            await viewModel.loadWantToReadBooks()
        }
    }
}

// 空状態のビュー
struct EmptyWantToReadView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("読みたい本がありません")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("本を追加して「読みたい」に設定すると\nここに表示されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 統計ヘッダー
struct WantToReadHeaderView: View {
    let books: [Book]
    
    private var totalCount: Int {
        books.count
    }
    
    private var thisMonthCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return books.filter { book in
            let addedDate = book.addedDate
            return addedDate >= startOfMonth
        }.count
    }
    
    private var hasReminders: Int {
        books.filter { $0.reminderEnabled && $0.plannedReadingDate != nil }.count
    }
    
    var body: some View {
        HStack(spacing: 20) {
            WantToReadStatCard(title: "総数", value: "\(totalCount)", icon: "books.vertical", color: .blue)
            WantToReadStatCard(title: "今月追加", value: "\(thisMonthCount)", icon: "calendar", color: .green)
            WantToReadStatCard(title: "リマインダー", value: "\(hasReminders)", icon: "bell.fill", color: .orange)
        }
    }
}

struct WantToReadStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    WantToReadListView()
        .environment(ServiceContainer.shared.getBookStore())
}
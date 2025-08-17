import SwiftUI

struct BookListView: View {
    @State private var viewModel = ServiceContainer.shared.makeBookListViewModel()
    @State private var showingRegistration = false
    @State private var selectedStatus: UserBook.ReadingStatus? = nil
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.userBooks.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    bookList
                }
            }
            .navigationTitle("本棚")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingRegistration = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "タイトルや著者で検索")
            .onAppear {
                Task {
                    await viewModel.loadUserBooks()
                }
            }
            .refreshable {
                await viewModel.loadUserBooks()
            }
            .sheet(isPresented: $showingRegistration) {
                BookRegistrationView()
                    .onDisappear {
                        Task {
                            await viewModel.loadUserBooks()
                        }
                    }
            }
            .overlay {
                if viewModel.isLoading && viewModel.userBooks.isEmpty {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("まだ本が登録されていません")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("＋ボタンをタップして\n最初の本を登録しましょう")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                showingRegistration = true
            } label: {
                Label("本を登録", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var bookList: some View {
        ScrollView {
            VStack(spacing: 0) {
                statusFilterView
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                LazyVStack(spacing: 12) {
                    ForEach(filteredBooks, id: \.userBook.id) { bookData in
                        NavigationLink(destination: BookDetailView(
                            userBook: bookData.userBook,
                            book: bookData.book
                        )) {
                            BookRowView(userBook: bookData.userBook, book: bookData.book)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var statusFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "すべて",
                    isSelected: selectedStatus == nil,
                    action: { selectedStatus = nil }
                )
                
                ForEach(UserBook.ReadingStatus.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.displayName,
                        isSelected: selectedStatus == status,
                        action: { selectedStatus = status }
                    )
                }
            }
        }
    }
    
    private var filteredBooks: [(userBook: UserBook, book: Book)] {
        viewModel.userBooks
            .filter { bookData in
                if let status = selectedStatus {
                    return bookData.userBook.status == status
                } else {
                    return true
                }
            }
            .filter { bookData in
                if searchText.isEmpty {
                    return true
                }
                let searchLowercased = searchText.lowercased()
                return bookData.book.title.lowercased().contains(searchLowercased) ||
                       bookData.book.author.lowercased().contains(searchLowercased)
            }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct BookRowView: View {
    let userBook: UserBook
    let book: Book
    
    var body: some View {
        HStack(spacing: 12) {
            // 本の表紙（プレースホルダー）
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 60, height: 90)
                .overlay(
                    Image(systemName: "book.closed")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    StatusBadge(status: userBook.status)
                    
                    if let rating = userBook.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: UserBook.ReadingStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch status {
        case .wantToRead:
            return .blue.opacity(0.2)
        case .reading:
            return .green.opacity(0.2)
        case .completed:
            return .purple.opacity(0.2)
        case .dnf:
            return .red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .wantToRead:
            return .blue
        case .reading:
            return .green
        case .completed:
            return .purple
        case .dnf:
            return .red
        }
    }
}

#Preview {
    BookListView()
}
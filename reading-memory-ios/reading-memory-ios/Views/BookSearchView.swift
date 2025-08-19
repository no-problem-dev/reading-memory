import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BookSearchViewModel()
    @State private var searchText = ""
    @State private var selectedBook: Book?
    @State private var showingRegistration = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 検索バー
                searchBar
                
                // 検索結果
                if viewModel.isLoading {
                    ProgressView("検索中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    emptyStateView
                } else if viewModel.searchResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("本を検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingRegistration) {
                if let book = selectedBook {
                    BookRegistrationView(prefilledBook: book)
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("タイトル、著者、ISBN", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await viewModel.searchBooks(query: searchText)
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("本を検索してみましょう")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("タイトル、著者名、ISBNで検索できます")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("検索結果が見つかりませんでした")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("別のキーワードで検索してみてください")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                selectedBook = Book.new(
                    title: "",
                    author: "",
                    dataSource: .manual,
                    visibility: .private
                )
                showingRegistration = true
            }) {
                Label("手動で登録", systemImage: "plus.circle")
                    .foregroundColor(.accentColor)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.searchResults) { book in
                    BookSearchResultRow(book: book) {
                        selectedBook = book
                        showingRegistration = true
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Divider()
                        .padding(.leading, 80)
                }
            }
        }
    }
}

struct BookSearchResultRow: View {
    let book: Book
    let onTap: () -> Void
    @State private var isRegistered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 表紙画像
            AsyncImage(url: URL(string: book.coverImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 70)
            .cornerRadius(4)
            
            // 書籍情報
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    if let isbn = book.isbn {
                        Text("ISBN: \(isbn)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // データソース表示
                    Label {
                        Text(dataSourceText)
                            .font(.caption2)
                    } icon: {
                        Image(systemName: dataSourceIcon)
                            .font(.caption2)
                    }
                    .foregroundColor(dataSourceColor)
                }
            }
            
            Spacer()
            
            // 登録ボタン
            Button(action: onTap) {
                Image(systemName: isRegistered ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(isRegistered ? .green : .accentColor)
                    .font(.title2)
            }
            .disabled(isRegistered)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRegistered {
                onTap()
            }
        }
        .task {
            // 既に登録済みかチェック
            let viewModel = BookSearchViewModel()
            isRegistered = await viewModel.isBookAlreadyRegistered(book)
        }
    }
    
    private var dataSourceText: String {
        switch book.dataSource {
        case .googleBooks:
            return "Google Books"
        case .openBD:
            return "OpenBD"
        case .rakutenBooks:
            return "楽天ブックス"
        case .manual:
            return "手動入力"
        }
    }
    
    private var dataSourceIcon: String {
        switch book.dataSource {
        case .googleBooks, .openBD, .rakutenBooks:
            return "globe"
        case .manual:
            return "pencil"
        }
    }
    
    private var dataSourceColor: Color {
        switch book.visibility {
        case .public:
            return .blue
        case .private:
            return .gray
        }
    }
}

#Preview {
    BookSearchView()
}
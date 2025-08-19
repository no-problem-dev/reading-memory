import SwiftUI

struct PublicBookshelfView: View {
    @State private var viewModel = PublicBookshelfViewModel()
    @State private var selectedTab: PublicBookshelfTab = .popular
    @State private var searchText = ""
    @State private var showingBookDetail = false
    @State private var selectedBook: Book?
    
    enum PublicBookshelfTab: String, CaseIterable {
        case popular = "人気"
        case recent = "新着"
        case search = "検索"
        
        var icon: String {
            switch self {
            case .popular:
                return "star.fill"
            case .recent:
                return "clock.fill"
            case .search:
                return "magnifyingglass"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // タブバー
                tabBar
                
                // コンテンツ
                Group {
                    switch selectedTab {
                    case .popular:
                        popularBooksView
                    case .recent:
                        recentBooksView
                    case .search:
                        searchView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("みんなの本棚")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadInitialData()
            }
            .sheet(item: $selectedBook) { book in
                BookDetailSheet(book: book)
            }
        }
    }
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(PublicBookshelfTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(selectedTab == tab ? .accentColor : .gray)
                }
            }
        }
        .background(Color(.systemGray6))
    }
    
    private var popularBooksView: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if viewModel.popularBooks.isEmpty {
                EmptyStateView(
                    icon: "star.slash",
                    title: "人気の本がありません",
                    message: "まだ登録されている本がありません"
                )
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
                ], spacing: 20) {
                    ForEach(viewModel.popularBooks) { book in
                        PublicBookGridItem(book: book) {
                            selectedBook = book
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var recentBooksView: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if viewModel.recentBooks.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.xmark",
                    title: "新着の本がありません",
                    message: "最近追加された本がありません"
                )
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
                ], spacing: 20) {
                    ForEach(viewModel.recentBooks) { book in
                        PublicBookGridItem(book: book) {
                            selectedBook = book
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var searchView: some View {
        VStack {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("タイトルや著者で検索", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        Task {
                            await viewModel.searchPublicBooks(query: searchText)
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
            
            // 検索結果
            ScrollView {
                if viewModel.isSearching {
                    ProgressView("検索中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if searchText.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "本を検索",
                        message: "みんなが登録した本を検索できます"
                    )
                    .padding(.top, 100)
                } else if viewModel.searchResults.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass.circle",
                        title: "検索結果がありません",
                        message: "別のキーワードで検索してみてください"
                    )
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
                    ], spacing: 20) {
                        ForEach(viewModel.searchResults) { book in
                            PublicBookGridItem(book: book) {
                                selectedBook = book
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct PublicBookGridItem: View {
    let book: Book
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 表紙画像
            AsyncImage(url: URL(string: book.coverImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 150)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // タイトル
            Text(book.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // 著者
            Text(book.author)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // データソース
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.caption2)
                Text(dataSourceText)
                    .font(.caption2)
            }
            .foregroundColor(.blue)
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var dataSourceText: String {
        switch book.dataSource {
        case .googleBooks:
            return "Google"
        case .openBD:
            return "OpenBD"
        case .rakutenBooks:
            return "楽天"
        case .manual:
            return "手動"
        }
    }
}

struct BookDetailSheet: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var showingRegistration = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 表紙画像
                    AsyncImage(url: URL(string: book.coverImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "book.closed")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    // 書籍情報
                    VStack(alignment: .leading, spacing: 16) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Label(book.author, systemImage: "person")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if let publisher = book.publisher {
                            Label(publisher, systemImage: "building.2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let publishedDate = book.publishedDate {
                            Label(DateFormatter.yearMonth.string(from: publishedDate), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let isbn = book.isbn {
                            Label("ISBN: \(isbn)", systemImage: "barcode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let pageCount = book.pageCount {
                            Label("\(pageCount)ページ", systemImage: "doc.text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let description = book.description {
                            Text("内容紹介")
                                .font(.headline)
                                .padding(.top)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // 登録ボタン
                    Button(action: {
                        showingRegistration = true
                    }) {
                        Label("本棚に追加", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("本の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingRegistration) {
                BookRegistrationView(prefilledBook: book)
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// DateFormatter拡張
extension DateFormatter {
    static let yearMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

#Preview {
    PublicBookshelfView()
}
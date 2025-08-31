import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BookSearchViewModel()
    @State private var searchText = ""
    @State private var selectedSearchResult: BookSearchResult?
    @State private var showingRegistration = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // オプショナルなコールバック
    let onBookRegistered: ((Book) -> Void)?
    let defaultStatus: ReadingStatus
    
    init(defaultStatus: ReadingStatus = .wantToRead, onBookRegistered: ((Book) -> Void)? = nil) {
        self.onBookRegistered = onBookRegistered
        self.defaultStatus = defaultStatus
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content
                contentView
                    .background(backgroundGradient)
            }
            .navigationTitle("本を探す")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                }
            }
            .sheet(isPresented: $showingRegistration) {
                if let searchResult = selectedSearchResult {
                    BookRegistrationView(
                        searchResult: searchResult,
                        defaultStatus: defaultStatus,
                        onCompletion: { book in
                            onBookRegistered?(book)
                            dismiss()
                        }
                    )
                }
            }
        }
        .keyboardAware()
    }
    
    // MARK: - Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.secondarySystemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Search bar container
            searchBarContainer
            
            // Main content
            if viewModel.isLoading {
                loadingView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.isEmpty {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.searchResults.isEmpty {
                noResultsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                searchResultsList
            }
        }
    }
    
    private var searchBarContainer: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, MemorySpacing.md)
                .padding(.vertical, MemorySpacing.sm)
        }
        .background(Color(.tertiarySystemBackground))
        .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var searchBar: some View {
        HStack(spacing: MemorySpacing.sm) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(isSearchFieldFocused ? MemoryTheme.Colors.primaryBlue : Color(.secondaryLabel))
                .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
            
            // Text field
            TextField("タイトル、著者、ISBN", text: $searchText)
                .memoryTextFieldStyle()
                .focused($isSearchFieldFocused)
                .onSubmit {
                    Task {
                        await viewModel.searchBooks(query: searchText)
                    }
                }
            
            // Clear button
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                        viewModel.searchResults = []
                        isSearchFieldFocused = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            
            // Search button
            if !searchText.isEmpty {
                Button {
                    Task {
                        isSearchFieldFocused = false
                        await viewModel.searchBooks(query: searchText)
                    }
                } label: {
                    Text("検索")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, MemorySpacing.xs)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlue,
                                    MemoryTheme.Colors.primaryBlueDark
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(MemoryRadius.full)
                }
            }
        }
        .padding(.horizontal, MemorySpacing.md)
        .padding(.vertical, MemorySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MemoryRadius.large)
                .fill(MemoryTheme.Colors.inkPale.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: MemoryRadius.large)
                        .stroke(isSearchFieldFocused ? MemoryTheme.Colors.primaryBlue : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
    }
    
    private var loadingView: some View {
        VStack(spacing: MemorySpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MemoryTheme.Colors.primaryBlue))
                .scaleEffect(1.5)
            
            Text("検索中...")
                .font(.body)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: MemorySpacing.xl) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlueLight.opacity(0.2),
                                    MemoryTheme.Colors.primaryBlue.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "books.vertical")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlue,
                                    MemoryTheme.Colors.primaryBlueDark
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: MemorySpacing.sm) {
                    Text("本を検索してみましょう")
                        .font(.title3)
                        .foregroundColor(Color(.label))
                    
                    Text("タイトル、著者名、ISBNで\n検索できます")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(MemorySpacing.xl)
    }
    
    private var noResultsView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: MemorySpacing.xl) {
                // Icon with gradient background
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
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(MemoryTheme.Colors.warmCoral)
                }
                
                VStack(spacing: MemorySpacing.sm) {
                    Text("検索結果が見つかりませんでした")
                        .font(.title3)
                        .foregroundColor(Color(.label))
                    
                    Text("別のキーワードで\n検索してみてください")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(MemorySpacing.xl)
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: MemorySpacing.xs) {
                ForEach(viewModel.searchResults) { searchResult in
                    BookSearchResultRow(searchResult: searchResult) {
                        selectedSearchResult = searchResult
                        showingRegistration = true
                    }
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.vertical, MemorySpacing.xs)
                }
            }
            .padding(.vertical, MemorySpacing.sm)
        }
    }
}

// MARK: - Search Result Row

struct BookSearchResultRow: View {
    let searchResult: BookSearchResult
    let onTap: () -> Void
    @State private var isRegistered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MemorySpacing.md) {
                // Book cover
                Group {
                    if let coverImageUrl = searchResult.coverImageUrl {
                        RemoteImage(urlString: coverImageUrl)
                    } else {
                        Image(systemName: "book.closed")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.secondarySystemFill))
                    }
                }
                .frame(width: 60, height: 90)
                .cornerRadius(MemoryRadius.small)
                .memoryShadow(.soft)
                
                // Book info
                VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                    Text(searchResult.title)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(searchResult.author)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                    
                    HStack(spacing: MemorySpacing.sm) {
                        // Data source badge
                        HStack(spacing: MemorySpacing.xs) {
                            Image(systemName: dataSourceIcon)
                                .font(.system(size: 12))
                            Text(dataSourceText)
                                .font(.caption)
                        }
                        .foregroundColor(dataSourceColor)
                        .padding(.horizontal, MemorySpacing.sm)
                        .padding(.vertical, 2)
                        .background(dataSourceColor.opacity(0.1))
                        .cornerRadius(MemoryRadius.full)
                        
                        Spacer()
                        
                        // Status indicator
                        if isRegistered {
                            Label("登録済み", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color(.systemGreen))
                        }
                    }
                }
                
                Spacer()
                
                // Add/Check button
                if isRegistered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(MemoryTheme.Colors.success)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlue,
                                    MemoryTheme.Colors.primaryBlueDark
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(MemorySpacing.md)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(MemoryRadius.large)
            .memoryShadow(.soft)
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            let viewModel = BookSearchViewModel()
            isRegistered = await viewModel.isBookAlreadyRegistered(searchResult)
        }
    }
    
    private var dataSourceText: String {
        switch searchResult.dataSource {
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
        switch searchResult.dataSource {
        case .googleBooks, .openBD, .rakutenBooks:
            return "globe"
        case .manual:
            return "pencil"
        }
    }
    
    private var dataSourceColor: Color {
        switch searchResult.dataSource {
        case .googleBooks:
            return MemoryTheme.Colors.primaryBlue
        case .openBD:
            return MemoryTheme.Colors.warmCoral
        case .rakutenBooks:
            return MemoryTheme.Colors.goldenMemory
        case .manual:
            return Color(.secondaryLabel)
        }
    }
    
    private struct BookCoverPlaceholder: View {
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: MemoryRadius.small)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.inkPale.opacity(0.5),
                                MemoryTheme.Colors.inkPale.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 24))
                    .foregroundColor(MemoryTheme.Colors.inkLightGray)
            }
        }
    }
}

#Preview {
    BookSearchView()
}

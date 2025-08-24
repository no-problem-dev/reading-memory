import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BookSearchViewModel()
    @State private var searchText = ""
    @State private var selectedBook: Book?
    @State private var showingRegistration = false
    @State private var searchFocused = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, MemorySpacing.sm)
                        .background(
                            Color(.tertiarySystemBackground)
                                .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    
                    // Content
                    Group {
                        if viewModel.isLoading {
                            loadingView
                        } else if searchText.isEmpty {
                            emptyStateView
                        } else if viewModel.searchResults.isEmpty {
                            noResultsView
                        } else {
                            searchResultsList
                        }
                    }
                }
            }
            .navigationTitle("本を探す")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
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
    
    // MARK: - Components
    
    private var searchBar: some View {
        HStack(spacing: MemorySpacing.sm) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(searchFocused ? MemoryTheme.Colors.primaryBlue : Color(.secondaryLabel))
                .animation(.easeInOut(duration: 0.2), value: searchFocused)
            
            // Text field
            TextField("タイトル、著者、ISBN", text: $searchText)
                .font(.body)
                .foregroundColor(Color(.label))
                .onSubmit {
                    Task {
                        await viewModel.searchBooks(query: searchText)
                    }
                }
                .onChange(of: searchText) { _, _ in
                    searchFocused = true
                }
            
            // Clear button
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                        viewModel.searchResults = []
                        searchFocused = false
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
                        .stroke(searchFocused ? MemoryTheme.Colors.primaryBlue : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: searchFocused)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: MemorySpacing.xl) {
            Spacer()
            
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
            
            Spacer()
            Spacer()
        }
        .padding(MemorySpacing.xl)
    }
    
    private var noResultsView: some View {
        VStack(spacing: MemorySpacing.xl) {
            Spacer()
            
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
            
            // Manual registration option
            VStack(spacing: MemorySpacing.md) {
                Text("見つからない場合は")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
                
                Button {
                    guard let userId = AuthService.shared.currentUser?.uid else { return }
                    selectedBook = Book(
                        id: UUID().uuidString,
                        title: "",
                        author: "",
                        dataSource: .manual,
                        status: .wantToRead,
                        addedDate: Date(),
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    showingRegistration = true
                } label: {
                    HStack(spacing: MemorySpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text("手動で登録")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, MemorySpacing.lg)
                    .padding(.vertical, MemorySpacing.md)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.warmCoral,
                                MemoryTheme.Colors.warmCoralDark
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(MemoryRadius.full)
                    .memoryShadow(.medium)
                }
            }
            
            Spacer()
            Spacer()
        }
        .padding(MemorySpacing.xl)
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: MemorySpacing.xs) {
                ForEach(viewModel.searchResults) { book in
                    BookSearchResultRow(book: book) {
                        selectedBook = book
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
    let book: Book
    let onTap: () -> Void
    @State private var isRegistered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MemorySpacing.md) {
                // Book cover
                Group {
                    if let imageUrl = book.coverImageUrl {
                        CachedAsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            BookCoverPlaceholder()
                        }
                    } else {
                        BookCoverPlaceholder()
                    }
                }
                .frame(width: 60, height: 90)
                .cornerRadius(MemoryRadius.small)
                .memoryShadow(.soft)
                
                // Book info
                VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(book.author)
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
                
                // Add button
                if !isRegistered {
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
        .disabled(isRegistered)
        .task {
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
        switch book.dataSource {
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
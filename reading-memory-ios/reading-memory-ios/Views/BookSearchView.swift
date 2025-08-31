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
            .onAppear {
                isSearchFieldFocused = true
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
            // Search bar
            BookSearchBar(
                searchText: $searchText,
                isSearchFieldFocused: _isSearchFieldFocused,
                onSearch: {
                    await viewModel.searchBooks(query: searchText)
                },
                onClear: {
                    searchText = ""
                    viewModel.searchResults = []
                }
            )
            
            // Main content
            if viewModel.isLoading {
                BookSearchLoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.isEmpty {
                BookSearchEmptyState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.searchResults.isEmpty {
                BookSearchNoResults()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                searchResultsList
            }
        }
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

#Preview {
    BookSearchView()
}

import SwiftUI

struct OnboardingBookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BookSearchViewModel()
    @State private var searchText = ""
    
    let onBookSelected: (BookSearchResult) -> Void
    
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
            .navigationTitle("最初の本を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("タイトル、著者、ISBNで検索", text: $searchText)
                .memoryTextFieldStyle()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await searchBooks()
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("本のタイトルや著者名で検索")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("今読んでいる本や、最近読んだ本を登録しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("検索結果がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("別のキーワードで検索してみてください")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.searchResults) { searchResult in
                    OnboardingBookSearchResultRow(searchResult: searchResult) {
                        onBookSelected(searchResult)
                        dismiss()
                    }
                }
            }
            .padding()
        }
    }
    
    private func searchBooks() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        await viewModel.searchBooks(query: searchText)
    }
}

// MARK: - Onboarding Book Search Result Row
struct OnboardingBookSearchResultRow: View {
    let searchResult: BookSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
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
                .frame(width: 50, height: 75)
                .cornerRadius(4)
                
                // Book info
                VStack(alignment: .leading, spacing: 4) {
                    Text(searchResult.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(searchResult.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let publisher = searchResult.publisher {
                        Text(publisher)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
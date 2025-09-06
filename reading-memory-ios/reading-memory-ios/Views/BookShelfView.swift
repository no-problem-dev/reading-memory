import SwiftUI

struct BookShelfView: View {
    @State private var viewModel = BookShelfViewModel()
    @State private var selectedFilter: ReadingStatus? = nil
    @State private var selectedSort: SortOption = .dateAdded
    @State private var showingAddBook = false
    @State private var showingAddBookOptions = false
    @State private var showingBarcodeScanner = false
    @State private var showingBookSearch = false
    @State private var showPaywall = false
    
    enum SortOption: String, CaseIterable {
        case dateAdded = "追加日"
        case title = "タイトル"
        case author = "著者"
        case rating = "評価"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.filteredBooks.isEmpty {
                    EmptyBookShelfView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    BookShelfGridView(
                        books: viewModel.filteredBooks,
                        onBookTapped: { book in
                            // Navigate to book detail
                        },
                        onChatTapped: { book in
                            // Open chat
                        }
                    )
                }
                
                // Floating Action Button
                if !viewModel.filteredBooks.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showingAddBookOptions = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("本棚")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.filteredBooks.isEmpty {
                        Button {
                            showingAddBookOptions = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        filterMenu
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                NavigationStack {
                    BookRegistrationView()
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView()
            }
            .sheet(isPresented: $showingBookSearch) {
                BookSearchView()
            }
            .confirmationDialog("本を検索", isPresented: $showingAddBookOptions) {
                Button("バーコードでスキャン", action: {
                    guard FeatureGate.canScanBarcode else {
                        showPaywall = true
                        return
                    }
                    showingBarcodeScanner = true
                })
                Button("タイトルで検索", action: {
                    showingBookSearch = true
                })
                Button("手動で登録", action: {
                    showingAddBook = true
                })
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("どの方法で本を検索しますか？")
            }
            .task {
                await viewModel.loadBooks()
            }
            .onChange(of: selectedSort) { _, newValue in
                viewModel.sortBooks(by: newValue)
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
        }
    }
    
    private var filterMenu: some View {
        Menu {
            Section("ステータスで絞り込み") {
                Button(action: { selectedFilter = nil }) {
                    Label(
                        selectedFilter == nil ? "✓ すべて" : "すべて",
                        systemImage: "books.vertical"
                    )
                }
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Button(action: { selectedFilter = status }) {
                        Label(
                            selectedFilter == status ? "✓ \(status.displayName)" : status.displayName,
                            systemImage: iconName(for: status)
                        )
                    }
                }
            }
            
            Section("並び替え") {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: { selectedSort = option }) {
                        Label(
                            selectedSort == option ? "✓ \(option.rawValue)" : option.rawValue,
                            systemImage: sortIconName(for: option)
                        )
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    private func sortIconName(for option: SortOption) -> String {
        switch option {
        case .dateAdded:
            return "calendar"
        case .title:
            return "textformat"
        case .author:
            return "person"
        case .rating:
            return "star"
        }
    }
    
    private func iconName(for status: ReadingStatus) -> String {
        switch status {
        case .wantToRead:
            return "bookmark"
        case .reading:
            return "book"
        case .completed:
            return "checkmark.circle"
        case .dnf:
            return "xmark.circle"
        }
    }
}

struct EmptyBookShelfView: View {
    @State private var showingAddBook = false
    @State private var showingAddBookOptions = false
    @State private var showingBarcodeScanner = false
    @State private var showingBookSearch = false
    @State private var showPaywall = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 8) {
                    Text("本棚はまだ空です")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("読みたい本や読んだ本を\n追加して読書記録を始めましょう")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            
            VStack(spacing: 12) {
                Button {
                    showingAddBookOptions = true
                } label: {
                    Label("本を検索", systemImage: "magnifyingglass.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Text("本のタイトルで検索したり、\nバーコードをスキャンして簡単追加")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
        .sheet(isPresented: $showingAddBook) {
            NavigationStack {
                BookRegistrationView()
            }
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView()
        }
        .sheet(isPresented: $showingBookSearch) {
            BookSearchView()
        }
        .confirmationDialog("本を検索", isPresented: $showingAddBookOptions) {
            Button("バーコードでスキャン", action: {
                guard FeatureGate.canScanBarcode else {
                    showPaywall = true
                    return
                }
                showingBarcodeScanner = true
            })
            Button("タイトルで検索", action: {
                showingBookSearch = true
            })
            Button("手動で登録", action: {
                showingAddBook = true
            })
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("どの方法で本を検索しますか？")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    BookShelfView()
}
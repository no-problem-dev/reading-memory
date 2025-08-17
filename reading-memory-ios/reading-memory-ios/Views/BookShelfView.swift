import SwiftUI

struct BookShelfView: View {
    @State private var viewModel = BookShelfViewModel()
    @State private var selectedFilter: UserBook.ReadingStatus? = nil
    @State private var selectedSort: SortOption = .dateAdded
    
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
                    BookShelfGridView(books: viewModel.filteredBooks)
                }
            }
            .navigationTitle("本棚")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterMenu
                }
            }
            .task {
                await viewModel.loadBooks()
            }
            .onChange(of: selectedFilter) { _, newValue in
                viewModel.filterBooks(by: newValue)
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
                ForEach(UserBook.ReadingStatus.allCases, id: \.self) { status in
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
    
    private func iconName(for status: UserBook.ReadingStatus) -> String {
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
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("本棚はまだ空です")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("読みたい本や読んだ本を\n追加してみましょう")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: BookRegistrationView()) {
                Label("本を追加", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

struct BookShelfGridView: View {
    let books: [UserBook]
    
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 130), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(books) { userBook in
                    NavigationLink(destination: BookDetailView(userBookId: userBook.id)) {
                        BookCoverView(userBook: userBook)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

#Preview {
    BookShelfView()
}
import SwiftUI

struct BookListView: View {
    let books: [Book]
    let title: String
    let listType: BookListType
    let onBookTapped: (Book) -> Void
    let onChatTapped: ((Book) -> Void)?
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .addedDate
    @State private var showingSortOptions = false
    
    enum BookListType {
        case currentlyReading
        case completed
        case dnf
        
        var headerIcon: String {
            switch self {
            case .currentlyReading:
                return "book.fill"
            case .completed:
                return "checkmark.circle.fill"
            case .dnf:
                return "xmark.circle.fill"
            }
        }
        
        var headerColor: Color {
            switch self {
            case .currentlyReading:
                return MemoryTheme.Colors.primaryBlue
            case .completed:
                return MemoryTheme.Colors.success
            case .dnf:
                return MemoryTheme.Colors.inkGray
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case addedDate = "追加日順"
        case title = "タイトル順"
        case author = "著者順"
        case rating = "評価順"
        
        var icon: String {
            switch self {
            case .addedDate:
                return "calendar"
            case .title:
                return "textformat.abc"
            case .author:
                return "person"
            case .rating:
                return "star"
            }
        }
    }
    
    private var filteredAndSortedBooks: [Book] {
        let filtered = books.filter { book in
            searchText.isEmpty ||
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.author.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted { book1, book2 in
            switch sortOption {
            case .addedDate:
                return book1.addedDate > book2.addedDate
            case .title:
                return book1.title < book2.title
            case .author:
                return book1.author < book2.author
            case .rating:
                return (book1.rating ?? 0) > (book2.rating ?? 0)
            }
        }
    }
    
    private var headerStats: (total: Int, avgRating: Double, completionRate: Double) {
        let total = books.count
        let ratedBooks = books.compactMap { $0.rating }
        let avgRating = ratedBooks.isEmpty ? 0 : ratedBooks.reduce(0, +) / Double(ratedBooks.count)
        
        let completionRate: Double
        switch listType {
        case .currentlyReading:
            let progressBooks = books.compactMap { $0.readingProgress }
            completionRate = progressBooks.isEmpty ? 0 : progressBooks.reduce(0, +) / Double(progressBooks.count)
        case .completed:
            completionRate = 100.0
        case .dnf:
            let progressBooks = books.compactMap { $0.readingProgress }
            completionRate = progressBooks.isEmpty ? 0 : progressBooks.reduce(0, +) / Double(progressBooks.count)
        }
        
        return (total, avgRating, completionRate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 統計ヘッダー
                BookListHeaderView(
                    listType: listType,
                    stats: headerStats
                )
                .padding()
                .background(MemoryTheme.Colors.background)
                
                // 検索バー
                if books.count > 3 {
                    HStack {
                        MemoryTextField(
                            placeholder: "本を検索...",
                            text: $searchText,
                            icon: "magnifyingglass"
                        )
                        
                        Button {
                            showingSortOptions = true
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16))
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                .padding(MemorySpacing.sm)
                                .background(MemoryTheme.Colors.secondaryBackground)
                                .cornerRadius(MemoryRadius.medium)
                        }
                    }
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.bottom, MemorySpacing.sm)
                }
                
                // リスト
                if filteredAndSortedBooks.isEmpty {
                    BookListEmptyView(searchText: searchText)
                } else {
                    List {
                        ForEach(filteredAndSortedBooks) { book in
                            BookListRowView(
                                book: book,
                                listType: listType,
                                onBookTapped: {
                                    onDismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onBookTapped(book)
                                    }
                                },
                                onChatTapped: onChatTapped != nil ? {
                                    onDismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onChatTapped!(book)
                                    }
                                } : nil
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(MemoryTheme.Colors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        onDismiss()
                    }
                    .font(MemoryTheme.Fonts.body())
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                }
            }
            .confirmationDialog("ソート方法", isPresented: $showingSortOptions) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}

// MARK: - Header View
struct BookListHeaderView: View {
    let listType: BookListView.BookListType
    let stats: (total: Int, avgRating: Double, completionRate: Double)
    
    var body: some View {
        HStack(spacing: MemorySpacing.lg) {
            // 総数
            BookListStatCard(
                title: "総数",
                value: "\(stats.total)冊",
                icon: "books.vertical",
                color: listType.headerColor
            )
            
            // 平均評価 or 進捗率
            if listType == .currentlyReading {
                BookListStatCard(
                    title: "平均進捗",
                    value: "\(Int(stats.completionRate))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
            } else {
                BookListStatCard(
                    title: "平均評価",
                    value: stats.avgRating > 0 ? String(format: "%.1f", stats.avgRating) : "-",
                    icon: "star.fill",
                    color: .orange
                )
            }
            
            // 完了率（DNFの場合は中断率）
            if listType == .dnf {
                BookListStatCard(
                    title: "平均進捗",
                    value: "\(Int(stats.completionRate))%",
                    icon: "chart.bar.fill",
                    color: .gray
                )
            }
        }
    }
}

struct BookListStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: MemorySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(MemoryTheme.Fonts.title2())
                .fontWeight(.bold)
                .foregroundColor(MemoryTheme.Colors.inkBlack)
            
            Text(title)
                .font(MemoryTheme.Fonts.caption())
                .foregroundColor(MemoryTheme.Colors.inkGray)
        }
        .frame(maxWidth: .infinity)
        .padding(MemorySpacing.md)
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.medium)
    }
}

// MARK: - Row View
struct BookListRowView: View {
    let book: Book
    let listType: BookListView.BookListType
    let onBookTapped: () -> Void
    let onChatTapped: (() -> Void)?
    
    var body: some View {
        Button(action: onBookTapped) {
            HStack(spacing: MemorySpacing.md) {
                // 表紙
                BookCoverView(imageId: book.coverImageId, size: .custom(width: 60, height: 90))
                
                // 本の情報
                VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                    Text(book.title)
                        .font(MemoryTheme.Fonts.headline())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(book.author)
                        .font(MemoryTheme.Fonts.footnote())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                        .lineLimit(1)
                    
                    // ステータス固有の情報
                    HStack(spacing: MemorySpacing.sm) {
                        switch listType {
                        case .currentlyReading:
                            if let progress = book.readingProgress {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.caption2)
                                    Text("\(Int(progress))%")
                                        .font(MemoryTheme.Fonts.caption())
                                }
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            }
                        case .completed:
                            if let rating = book.rating {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                    Text(String(format: "%.1f", rating))
                                        .font(MemoryTheme.Fonts.caption())
                                }
                                .foregroundColor(.orange)
                            }
                            if let completedDate = book.completedDate {
                                Text(completedDate, style: .date)
                                    .font(MemoryTheme.Fonts.caption())
                                    .foregroundColor(MemoryTheme.Colors.inkGray)
                            }
                        case .dnf:
                            if let progress = book.readingProgress {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.bar")
                                        .font(.caption2)
                                    Text("\(Int(progress))%で中断")
                                        .font(MemoryTheme.Fonts.caption())
                                }
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            }
                        }
                        
                        Spacer()
                        
                        // チャットボタン
                        if let onChatTapped = onChatTapped {
                            Button(action: onChatTapped) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 18))
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                    .padding(MemorySpacing.xs)
                                    .background(
                                        Circle()
                                            .fill(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(MemorySpacing.md)
            .background(MemoryTheme.Colors.cardBackground)
            .cornerRadius(MemoryRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty View
struct BookListEmptyView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: MemorySpacing.lg) {
            Image(systemName: searchText.isEmpty ? "books.vertical" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(MemoryTheme.Colors.inkLightGray)
            
            VStack(spacing: MemorySpacing.xs) {
                Text(searchText.isEmpty ? "本がありません" : "検索結果が見つかりません")
                    .font(MemoryTheme.Fonts.title3())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text(searchText.isEmpty ? "このカテゴリにはまだ本が登録されていません" : "検索条件を変更してお試しください")
                    .font(MemoryTheme.Fonts.callout())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MemorySpacing.xl)
    }
}

#Preview {
    BookListView(
        books: [],
        title: "読み終わった本",
        listType: .completed,
        onBookTapped: { _ in },
        onChatTapped: { _ in },
        onDismiss: { }
    )
}

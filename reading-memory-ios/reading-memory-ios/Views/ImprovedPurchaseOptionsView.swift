import SwiftUI

struct ImprovedPurchaseOptionsView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var showingReadingStart = false
    @State private var bookRepository = BookRepository.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ヘッダー部分
                    VStack(spacing: MemorySpacing.lg) {
                        // 本の情報カード
                        HStack(alignment: .top, spacing: MemorySpacing.md) {
                            BookCoverView(imageId: book.coverImageId, size: .medium)
                                .frame(width: 80, height: 120)
                                .cornerRadius(MemoryRadius.medium)
                                .memoryShadow(.soft)
                            
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Text(book.title)
                                    .font(MemoryTheme.Fonts.headline())
                                    .fontWeight(.semibold)
                                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                                    .lineLimit(2)
                                
                                Text(book.author)
                                    .font(MemoryTheme.Fonts.callout())
                                    .foregroundColor(MemoryTheme.Colors.inkGray)
                                    .lineLimit(1)
                                
                                if let isbn = book.isbn {
                                    Text("ISBN: \(isbn)")
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(MemoryTheme.Colors.inkLightGray)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(MemorySpacing.lg)
                        .background(MemoryTheme.Colors.secondaryBackground)
                        .cornerRadius(MemoryRadius.large)
                        
                        // タイトル
                        Text("購入方法を選ぶ")
                            .font(MemoryTheme.Fonts.title2())
                            .fontWeight(.bold)
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                    }
                    .padding(.top, MemorySpacing.lg)
                    .padding(.horizontal, MemorySpacing.lg)
                    
                    // オプション部分
                    VStack(spacing: MemorySpacing.lg) {
                        // オンライン書店セクション
                        VStack(alignment: .leading, spacing: MemorySpacing.md) {
                            Label("オンライン書店", systemImage: "cart.fill")
                                .font(MemoryTheme.Fonts.callout())
                                .fontWeight(.semibold)
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            
                            VStack(spacing: MemorySpacing.sm) {
                                if let isbn = book.isbn, !isbn.isEmpty {
                                    // Amazon
                                    purchaseOptionCard(
                                        title: "Amazonで購入",
                                        subtitle: "",
                                        icon: "cart.fill",
                                        iconColor: .orange,
                                        url: "https://www.amazon.co.jp/s?k=\(isbn)"
                                    )
                                    
                                    // 楽天ブックス
                                    // dataSourceがrakutenBooksかつpurchaseUrlがある場合はそれを使用
                                    let rakutenUrl: String = {
                                        if book.dataSource == .rakutenBooks,
                                           let purchaseUrl = book.purchaseUrl,
                                           !purchaseUrl.isEmpty {
                                            return purchaseUrl
                                        } else {
                                            return "https://books.rakuten.co.jp/search?sitem=\(isbn)"
                                        }
                                    }()
                                    
                                    purchaseOptionCard(
                                        title: "楽天ブックスで購入",
                                        subtitle: "",
                                        icon: "cart.fill",
                                        iconColor: Color.red,
                                        url: rakutenUrl
                                    )
                                } else {
                                    // タイトル検索
                                    purchaseOptionCard(
                                        title: "オンラインで検索",
                                        subtitle: "",
                                        icon: "magnifyingglass",
                                        iconColor: MemoryTheme.Colors.primaryBlue,
                                        url: "https://www.google.com/search?q=\(book.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? book.title)+本"
                                    )
                                }
                                
                                // 電子書籍
                                purchaseOptionCard(
                                    title: "電子書籍で探す",
                                    subtitle: "",
                                    icon: "iphone",
                                    iconColor: MemoryTheme.Colors.primaryBlueDark,
                                    url: "https://www.google.com/search?q=\(book.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? book.title)+電子書籍"
                                )
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal, -MemorySpacing.lg)
                        
                        // 図書館セクション
                        VStack(alignment: .leading, spacing: MemorySpacing.md) {
                            Label("図書館", systemImage: "building.columns.fill")
                                .font(MemoryTheme.Fonts.callout())
                                .fontWeight(.semibold)
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            
                            purchaseOptionCard(
                                title: "近くの図書館で探す",
                                subtitle: "",
                                icon: "building.columns.fill",
                                iconColor: MemoryTheme.Colors.goldenMemory,
                                url: "https://calil.jp/search?q=\((book.isbn ?? book.title).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? book.title)"
                            )
                        }
                        
                        Divider()
                            .padding(.horizontal, -MemorySpacing.lg)
                        
                        // 読書開始セクション
                        VStack(spacing: MemorySpacing.md) {
                            Text("もう持っている場合")
                                .font(MemoryTheme.Fonts.caption())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            
                            Button(action: {
                                showingReadingStart = true
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 20))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("今すぐ読み始める")
                                            .font(MemoryTheme.Fonts.headline())
                                            .fontWeight(.semibold)
                                        
                                        Text("ステータスを「読書中」に変更")
                                            .font(MemoryTheme.Fonts.caption())
                                            .opacity(0.8)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                .foregroundColor(.white)
                                .padding(MemorySpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    MemoryTheme.Colors.primaryBlue,
                                                    MemoryTheme.Colors.primaryBlueDark
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .memoryShadow(.medium)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, MemorySpacing.xl)
                    .padding(.horizontal, MemorySpacing.lg)
                    .padding(.bottom, MemorySpacing.xxl)
                }
            }
            .background(MemoryTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("購入オプション")
                        .font(MemoryTheme.Fonts.headline())
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .font(MemoryTheme.Fonts.callout())
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                }
            }
        }
        .alert("読書を開始しますか？", isPresented: $showingReadingStart) {
            Button("開始する", role: .none) {
                Task {
                    let updatedBook = Book(
                        id: book.id,
                        isbn: book.isbn,
                        title: book.title,
                        author: book.author,
                        publisher: book.publisher,
                        publishedDate: book.publishedDate,
                        pageCount: book.pageCount,
                        description: book.description,
                        coverImageId: book.coverImageId,
                        dataSource: book.dataSource,
                        purchaseUrl: book.purchaseUrl,
                        status: .reading,
                        rating: book.rating,
                        readingProgress: book.readingProgress,
                        currentPage: book.currentPage,
                        addedDate: book.addedDate,
                        startDate: Date(),
                        completedDate: book.completedDate,
                        lastReadDate: Date(),
                        priority: book.priority,
                        plannedReadingDate: book.plannedReadingDate,
                        reminderEnabled: book.reminderEnabled,
                        purchaseLinks: book.purchaseLinks,
                        memo: book.memo,
                        tags: book.tags,
                        genre: book.genre,
                        aiSummary: book.aiSummary,
                        summaryGeneratedAt: book.summaryGeneratedAt,
                        createdAt: book.createdAt,
                        updatedAt: Date()
                    )
                    
                    do {
                        try await bookRepository.updateBook(updatedBook)
                        dismiss()
                    } catch {
                        print("Error updating book: \(error)")
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(book.title)を「読書中」に変更します")
        }
    }
    
    private func purchaseOptionCard(title: String, subtitle: String, icon: String, iconColor: Color, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: MemorySpacing.md) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MemoryTheme.Fonts.callout())
                        .fontWeight(.medium)
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                }
                
                Spacer()
                
                // 矢印
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(MemoryTheme.Colors.inkLightGray)
            }
            .padding(MemorySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(MemoryTheme.Colors.cardBackground)
                    .memoryShadow(.soft)
            )
        }
    }
}

#Preview {
    ImprovedPurchaseOptionsView(book: Book.preview)
}
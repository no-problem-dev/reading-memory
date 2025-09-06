import SwiftUI

struct PurchaseOptionsView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var showingReadingStart = false
    @State private var bookRepository = BookRepository.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: MemorySpacing.sm) {
                    Text("この本をどうしますか？")
                        .font(MemoryTheme.Fonts.headline())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                    
                    Text(book.title)
                        .font(MemoryTheme.Fonts.callout())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                        .lineLimit(1)
                }
                .padding(.top, MemorySpacing.lg)
                .padding(.bottom, MemorySpacing.xl)
                
                // Options
                VStack(spacing: MemorySpacing.md) {
                    // 購入オプション
                    if let isbn = book.isbn, !isbn.isEmpty {
                        HStack(spacing: MemorySpacing.md) {
                            purchaseButton(
                                title: "Amazon",
                                icon: "cart.fill",
                                color: .orange,
                                url: "https://www.amazon.co.jp/s?k=\(isbn)"
                            )
                            
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
                            
                            purchaseButton(
                                title: "楽天ブックス",
                                icon: "cart.fill",
                                color: .red,
                                url: rakutenUrl
                            )
                        }
                    } else {
                        purchaseButton(
                            title: "オンラインで探す",
                            icon: "magnifyingglass",
                            color: MemoryTheme.Colors.primaryBlue,
                            url: "https://www.google.com/search?q=\(book.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? book.title)+本"
                        )
                    }
                    
                    // 図書館で探す
                    libraryButton
                    
                    Divider()
                        .padding(.vertical, MemorySpacing.xs)
                    
                    // 読書開始
                    startReadingButton
                }
                .padding(.horizontal, MemorySpacing.lg)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .alert("読書を開始しますか？", isPresented: $showingReadingStart) {
            Button("開始する", role: .none) {
                Task {
                    // 読書状態を更新
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
                    } catch {
                        print("Error updating book: \(error)")
                    }
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(book.title)を「読書中」に変更します")
        }
    }
    
    private func purchaseButton(title: String, icon: String, color: Color, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: MemorySpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                Text(title)
                    .font(MemoryTheme.Fonts.caption())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MemorySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(MemoryTheme.Colors.cardBackground)
                    .memoryShadow(.soft)
            )
        }
    }
    
    private var libraryButton: some View {
        Link(destination: URL(string: "https://calil.jp/search?q=\((book.isbn ?? book.title).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? book.title)")!) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 20))
                    .foregroundColor(MemoryTheme.Colors.goldenMemory)
                
                Text("図書館で探す")
                    .font(MemoryTheme.Fonts.callout())
                    .fontWeight(.medium)
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(MemoryTheme.Colors.inkGray)
            }
            .padding(MemorySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(MemoryTheme.Colors.goldenMemory.opacity(0.1))
            )
        }
    }
    
    private var startReadingButton: some View {
        Button(action: {
            showingReadingStart = true
        }) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text("今すぐ読み始める")
                    .font(MemoryTheme.Fonts.callout())
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MemorySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(MemoryTheme.Colors.primaryBlue)
            )
            .memoryShadow(.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PurchaseOptionsView(book: Book.preview)
}
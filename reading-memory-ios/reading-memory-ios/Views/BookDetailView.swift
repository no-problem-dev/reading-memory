import SwiftUI

struct BookDetailView: View {
    let userBook: UserBook
    let book: Book
    
    @State private var viewModel: BookDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(userBook: UserBook, book: Book) {
        self.userBook = userBook
        self.book = book
        self._viewModel = State(wrappedValue: ServiceContainer.shared.makeBookDetailViewModel(userBook: userBook, book: book))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 本の基本情報
                bookInfoSection
                
                Divider()
                
                // 読書ステータスと評価
                statusAndRatingSection
                
                if let notes = viewModel.currentUserBook.notes, !notes.isEmpty {
                    Divider()
                    notesSection(notes: notes)
                }
                
                if let description = book.description, !description.isEmpty {
                    Divider()
                    descriptionSection(description: description)
                }
                
                // 本の詳細情報
                Divider()
                detailsSection
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditBookView(userBook: viewModel.currentUserBook, book: book) { updatedUserBook in
                viewModel.updateUserBook(updatedUserBook)
            }
        }
        .alert("本を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                Task {
                    if await viewModel.deleteUserBook() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("この本を削除してもよろしいですか？\nこの操作は取り消せません。")
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private var bookInfoSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // 本の表紙
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 120, height: 180)
                .overlay(
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(book.author)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if let publisher = book.publisher {
                    Text(publisher)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Spacer()
        }
    }
    
    private var statusAndRatingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ステータス
            HStack {
                Text("ステータス")
                    .fontWeight(.medium)
                Spacer()
                StatusBadge(status: viewModel.currentUserBook.status)
            }
            
            // 評価
            HStack {
                Text("評価")
                    .fontWeight(.medium)
                Spacer()
                if let rating = viewModel.currentUserBook.rating {
                    RatingView(rating: rating)
                } else {
                    Text("未評価")
                        .foregroundColor(.secondary)
                }
            }
            
            // 読書期間
            if viewModel.currentUserBook.status != .wantToRead {
                VStack(alignment: .leading, spacing: 8) {
                    if let startDate = viewModel.currentUserBook.startDate {
                        HStack {
                            Text("開始日")
                                .fontWeight(.medium)
                            Spacer()
                            Text(startDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.currentUserBook.status == .completed,
                       let completedDate = viewModel.currentUserBook.completedDate {
                        HStack {
                            Text("完了日")
                                .fontWeight(.medium)
                            Spacer()
                            Text(completedDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ")
                .font(.headline)
            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private func descriptionSection(description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容紹介")
                .font(.headline)
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細情報")
                .font(.headline)
            
            if let isbn = book.isbn {
                DetailRow(label: "ISBN", value: isbn)
            }
            
            if let pageCount = book.pageCount {
                DetailRow(label: "ページ数", value: "\(pageCount)ページ")
            }
            
            if let publishedDate = book.publishedDate {
                DetailRow(label: "出版日", value: publishedDate.formatted(date: .abbreviated, time: .omitted))
            }
            
            DetailRow(label: "登録日", value: viewModel.currentUserBook.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

struct RatingView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: starImageName(for: index))
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
            }
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
        }
    }
    
    private func starImageName(for index: Int) -> String {
        let adjustedRating = rating - Double(index)
        if adjustedRating >= 1.0 {
            return "star.fill"
        } else if adjustedRating >= 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

#Preview {
    NavigationStack {
        BookDetailView(
            userBook: UserBook(
                userId: "test",
                bookId: "test",
                status: .reading,
                rating: 4.5
            ),
            book: Book(
                title: "サンプルブック",
                author: "サンプル著者"
            )
        )
    }
}
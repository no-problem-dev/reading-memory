import SwiftUI

struct BookDetailView: View {
    let userBookId: String
    
    @State private var userBook: UserBook?
    @State private var isLoading = true
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    private let userBookRepository = ServiceContainer.shared.getUserBookRepository()
    private let bookRepository = ServiceContainer.shared.getBookRepository()
    private let authService = AuthService.shared
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let userBook = userBook {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 本の基本情報
                        bookInfoSection(userBook: userBook)
                        
                        Divider()
                        
                        // 読書ステータスと評価
                        statusAndRatingSection(userBook: userBook)
                        
                        // チャットメモへのボタン
                        NavigationLink(destination: BookChatView(userBook: userBook)) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text("チャットメモ")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("本との対話を記録しよう")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if let memo = userBook.memo, !memo.isEmpty {
                            Divider()
                            notesSection(notes: memo)
                        }
                    }
                    .padding()
                }
                .navigationTitle(userBook.bookTitle)
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
                    SimpleEditBookView(userBook: userBook) { updatedUserBook in
                        self.userBook = updatedUserBook
                    }
                }
                .alert("本を削除", isPresented: $showingDeleteAlert) {
                    Button("キャンセル", role: .cancel) {}
                    Button("削除", role: .destructive) {
                        Task {
                            await deleteBook()
                        }
                    }
                } message: {
                    Text("この本を削除してもよろしいですか？\nこの操作は取り消せません。")
                }
            } else {
                Text("本が見つかりません")
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadUserBook()
        }
    }
    
    private func loadUserBook() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        do {
            if let fetchedUserBook = try await userBookRepository.getUserBook(userId: userId, userBookId: userBookId) {
                self.userBook = fetchedUserBook
            }
        } catch {
            print("Error loading book: \(error)")
        }
        
        isLoading = false
    }
    
    private func deleteBook() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        do {
            try await userBookRepository.deleteUserBook(userId: userId, userBookId: userBookId)
            dismiss()
        } catch {
            print("Error deleting book: \(error)")
        }
    }
    
    private func bookInfoSection(userBook: UserBook) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // 本の表紙
            if let coverImageUrl = userBook.bookCoverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    BookCoverPlaceholder(title: userBook.bookTitle)
                }
                .frame(width: 120, height: 180)
                .cornerRadius(12)
            } else {
                BookCoverPlaceholder(title: userBook.bookTitle)
                    .frame(width: 120, height: 180)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(userBook.bookTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(userBook.bookAuthor)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Spacer()
        }
    }
    
    private func statusAndRatingSection(userBook: UserBook) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // ステータス
            HStack {
                Text("ステータス")
                    .fontWeight(.medium)
                Spacer()
                StatusBadge(status: userBook.status)
            }
            
            // 評価
            HStack {
                Text("評価")
                    .fontWeight(.medium)
                Spacer()
                if let rating = userBook.rating {
                    RatingView(rating: rating)
                } else {
                    Text("未評価")
                        .foregroundColor(.secondary)
                }
            }
            
            // 読書期間
            if userBook.status != .wantToRead {
                VStack(alignment: .leading, spacing: 8) {
                    if let startDate = userBook.startDate {
                        HStack {
                            Text("開始日")
                                .fontWeight(.medium)
                            Spacer()
                            Text(startDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if userBook.status == .completed,
                       let completedDate = userBook.completedDate {
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
}

struct StatusBadge: View {
    let status: ReadingStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(20)
    }
    
    var backgroundColor: Color {
        switch status {
        case .wantToRead:
            return .blue
        case .reading:
            return .orange
        case .completed:
            return .green
        case .dnf:
            return .gray
        }
    }
}

struct RatingView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: starType(for: index))
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
            }
        }
    }
    
    private func starType(for index: Int) -> String {
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5
        
        if index < fullStars {
            return "star.fill"
        } else if index == fullStars && hasHalfStar {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

struct SimpleEditBookView: View {
    let userBook: UserBook
    let onUpdate: (UserBook) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("編集画面は実装予定です")
                .navigationTitle("本を編集")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    NavigationStack {
        BookDetailView(userBookId: "test-id")
    }
}
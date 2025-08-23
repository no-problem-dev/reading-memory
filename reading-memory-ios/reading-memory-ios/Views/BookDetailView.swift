import SwiftUI
import PhotosUI

struct BookDetailView: View {
    let bookId: String
    
    @State private var book: Book?
    @State private var isLoading = true
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSummarySheet = false
    @State private var aiSummary: String?
    @State private var isGeneratingSummary = false
    @Environment(\.dismiss) private var dismiss
    
    private let bookRepository = ServiceContainer.shared.getBookRepository()
    private let authService = AuthService.shared
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let book = book {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 本の基本情報
                        bookInfoSection(book: book)
                        
                        Divider()
                        
                        // 読書ステータスと評価
                        statusAndRatingSection(book: book)
                        
                        // チャットメモへのボタン
                        NavigationLink(destination: BookChatView(book: book)) {
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
                        
                        // AI要約ボタン
                        Button {
                            Task {
                                await generateSummary()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                VStack(alignment: .leading) {
                                    Text("AI要約")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("読書メモから要点をまとめます")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isGeneratingSummary {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isGeneratingSummary)
                        
                        // AI要約があれば表示
                        if let aiSummary = book.aiSummary, !aiSummary.isEmpty {
                            Divider()
                            aiSummarySection(summary: aiSummary)
                        }
                        
                        if let memo = book.memo, !memo.isEmpty {
                            Divider()
                            notesSection(notes: memo)
                        }
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
                    SimpleEditBookView(book: book) { updatedBook in
                        self.book = updatedBook
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
                .sheet(isPresented: $showingSummarySheet) {
                    SummaryView(summary: aiSummary ?? "")
                }
            } else {
                Text("本が見つかりません")
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadBook()
        }
    }
    
    private func loadBook() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        do {
            if let fetchedBook = try await bookRepository.getBook(bookId: bookId) {
                self.book = fetchedBook
            }
        } catch {
            print("Error loading book: \(error)")
        }
        
        isLoading = false
    }
    
    private func deleteBook() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        do {
            try await bookRepository.deleteBook(bookId: bookId)
            dismiss()
        } catch {
            print("Error deleting book: \(error)")
        }
    }
    
    private func bookInfoSection(book: Book) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // 本の表紙
            if let coverImageUrl = book.coverImageUrl, 
               let url = URL(string: coverImageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    BookCoverPlaceholder(title: book.title)
                }
                .frame(width: 120, height: 180)
                .cornerRadius(12)
            } else {
                BookCoverPlaceholder(title: book.title)
                    .frame(width: 120, height: 180)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(book.author)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Spacer()
        }
    }
    
    private func statusAndRatingSection(book: Book) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // ステータス
            HStack {
                Text("ステータス")
                    .fontWeight(.medium)
                Spacer()
                StatusBadge(status: book.status)
            }
            
            // 評価
            HStack {
                Text("評価")
                    .fontWeight(.medium)
                Spacer()
                if let rating = book.rating {
                    RatingView(rating: rating)
                } else {
                    Text("未評価")
                        .foregroundColor(.secondary)
                }
            }
            
            // 読書期間
            if book.status != .wantToRead {
                VStack(alignment: .leading, spacing: 8) {
                    if let startDate = book.startDate {
                        HStack {
                            Text("開始日")
                                .fontWeight(.medium)
                            Spacer()
                            Text(startDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if book.status == .completed,
                       let completedDate = book.completedDate {
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
    
    private func generateSummary() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        isGeneratingSummary = true
        
        do {
            let aiService = AIService.shared
            let summary = try await aiService.generateBookSummaryAPI(
                bookId: bookId
            )
            
            aiSummary = summary
            showingSummarySheet = true
        } catch {
            print("Error generating summary: \(error)")
            // エラーメッセージを表示
            aiSummary = "要約の生成に失敗しました。しばらく時間をおいてから再度お試しください。"
            showingSummarySheet = true
        }
        
        isGeneratingSummary = false
    }
    
    private func aiSummarySection(summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("AI要約")
                    .font(.headline)
                Spacer()
                Text(book?.summaryGeneratedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

// AI要約表示ビュー
struct SummaryView: View {
    let summary: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        Text("AI要約")
                            .font(.headline)
                    }
                    
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("読書メモの要約")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
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
    let book: Book
    let onUpdate: (Book) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var memo = ""
    @State private var status: ReadingStatus = .wantToRead
    @State private var rating: Double = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let bookRepository = ServiceContainer.shared.getBookRepository()
    private let authService = AuthService.shared
    private let activityRepository = ActivityRepository.shared
    
    var body: some View {
        NavigationStack {
            contentView
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                coverImageSection
                Divider()
                statusSection
                ratingSection
                memoSection
            }
            .padding()
        }
        .navigationTitle("本を編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    Task {
                        await saveChanges()
                    }
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            status = book.status
            rating = book.rating ?? 0
            memo = book.memo ?? ""
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                await loadImage(from: newItem)
            }
        }
        .alert("エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .disabled(isLoading)
    }
    
    private var coverImageSection: some View {
        VStack(spacing: 16) {
            Text("表紙画像")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                currentCoverView
                customCoverPicker
                Spacer()
            }
        }
    }
    
    private var currentCoverView: some View {
        VStack {
            if let coverImageUrl = book.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    BookCoverPlaceholder(title: book.title)
                }
            } else {
                BookCoverPlaceholder(title: book.title)
            }
        }
        .frame(width: 100, height: 150)
        .cornerRadius(8)
    }
    
    private var customCoverPicker: some View {
        PhotosPicker(selection: $selectedPhoto,
                   matching: .images,
                   photoLibrary: .shared()) {
            VStack {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 150)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 150)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                Text("カスタム表紙")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        )
                }
            }
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            Text("読書ステータス")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker("ステータス", selection: $status) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var ratingSection: some View {
        Group {
            if status == .completed {
                VStack(spacing: 12) {
                    Text("評価")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                                .onTapGesture {
                                    rating = Double(index + 1)
                                }
                        }
                        Spacer()
                        if rating > 0 {
                            Button("クリア") {
                                rating = 0
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    private var memoSection: some View {
        VStack(spacing: 12) {
            Text("メモ")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextEditor(text: $memo)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Resize image to reduce file size
                let resizedImage = image.resized(to: CGSize(width: 600, height: 900))
                selectedImage = resizedImage
            }
        } catch {
            errorMessage = "画像の読み込みに失敗しました"
        }
    }
    
    @MainActor
    private func saveChanges() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        isLoading = true
        
        do {
            // カスタム表紙をアップロード
            var newCoverUrl = book.coverImageUrl
            if let selectedImage {
                let storageService = StorageService.shared
                newCoverUrl = try await storageService.uploadImage(
                    selectedImage,
                    path: .bookCover(userId: userId, bookId: book.id)
                )
            }
            
            // ステータスに応じて日付を更新
            var newStartDate = book.startDate
            var newCompletedDate = book.completedDate
            if status == .reading && book.status == .wantToRead {
                newStartDate = Date()
            } else if status == .completed && book.status != .completed {
                newCompletedDate = Date()
            }
            
            // 更新されたBookを作成
            let updatedBook = Book(
                id: book.id,
                isbn: book.isbn,
                title: book.title,
                author: book.author,
                publisher: book.publisher,
                publishedDate: book.publishedDate,
                pageCount: book.pageCount,
                description: book.description,
                coverImageUrl: newCoverUrl,
                dataSource: book.dataSource,
                status: status,
                rating: rating > 0 ? rating : nil,
                readingProgress: book.readingProgress,
                currentPage: book.currentPage,
                addedDate: book.addedDate,
                startDate: newStartDate,
                completedDate: newCompletedDate,
                lastReadDate: book.lastReadDate,
                priority: book.priority,
                plannedReadingDate: book.plannedReadingDate,
                reminderEnabled: book.reminderEnabled,
                purchaseLinks: book.purchaseLinks,
                memo: memo.isEmpty ? nil : memo,
                tags: book.tags,
                aiSummary: book.aiSummary,
                summaryGeneratedAt: book.summaryGeneratedAt,
                createdAt: book.createdAt,
                updatedAt: Date()
            )
            
            try await bookRepository.updateBook(updatedBook)
            
            // ステータスが完了に変更された場合、アクティビティを記録
            if status == .completed && book.status != .completed {
                try? await activityRepository.recordBookRead()
            }
            
            onUpdate(updatedBook)
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - UIImage Extension
private extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let targetSize = CGSize(
            width: min(size.width, self.size.width),
            height: min(size.height, self.size.height)
        )
        
        let widthRatio = targetSize.width / self.size.width
        let heightRatio = targetSize.height / self.size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: self.size.width * ratio,
            height: self.size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#Preview {
    NavigationStack {
        BookDetailView(bookId: "test-id")
    }
}
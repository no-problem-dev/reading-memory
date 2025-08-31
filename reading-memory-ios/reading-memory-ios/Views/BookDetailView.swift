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
    @State private var summaryError: String?
    @State private var showingSummaryError = false
    @State private var isUpdatingStatus = false
    @State private var showStatusChangeAnimation = false
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss
    
    private let bookRepository = ServiceContainer.shared.getBookRepository()
    private let authService = AuthService.shared
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(MemoryTheme.Colors.primaryBlue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            } else if let book = book {
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section with Book Cover
                        heroSection(book: book)
                        
                        VStack(spacing: MemorySpacing.lg) {
                            // Book Info
                            bookInfoSection(book: book)
                                .padding(.horizontal, MemorySpacing.md)
                            
                            // Action Buttons
                            actionButtonsSection(book: book)
                                .padding(.horizontal, MemorySpacing.md)
                            
                            // Status and Rating
                            MemoryCard(padding: MemorySpacing.md) {
                                statusAndRatingSection(book: book)
                            }
                            .padding(.horizontal, MemorySpacing.md)
                            
                            // AI Summary if exists
                            if let aiSummary = book.aiSummary, !aiSummary.isEmpty {
                                MemoryCard(padding: MemorySpacing.md) {
                                    aiSummarySection(summary: aiSummary)
                                }
                                .padding(.horizontal, MemorySpacing.md)
                            }
                            
                            // Notes if exists
                            if let memo = book.memo, !memo.isEmpty {
                                MemoryCard(padding: MemorySpacing.md) {
                                    notesSection(notes: memo)
                                }
                                .padding(.horizontal, MemorySpacing.md)
                            }
                        }
                        .padding(.vertical, MemorySpacing.lg)
                    }
                }
                .background(Color(.secondarySystemBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    
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
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditBookView(book: book) { updatedBook in
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
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
                .alert("要約生成エラー", isPresented: $showingSummaryError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(summaryError ?? "要約の生成に失敗しました")
                }
            } else {
                VStack(spacing: MemorySpacing.md) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(Color(.tertiaryLabel))
                    Text("本が見つかりません")
                        .font(.headline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .task {
            await loadBook()
        }
    }
    
    private func loadBook() async {
        guard authService.currentUser?.uid != nil else { return }
        
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
        guard authService.currentUser?.uid != nil else { return }
        
        do {
            try await bookRepository.deleteBook(bookId: bookId)
            dismiss()
        } catch {
            print("Error deleting book: \(error)")
        }
    }
    
    // Hero Section with Book Cover
    private func heroSection(book: Book) -> some View {
        ZStack(alignment: .bottom) {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    MemoryTheme.Colors.primaryBlue.opacity(0.1),
                    Color(.secondarySystemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)
            
            // Book Cover
            BookCoverView(imageId: book.coverImageId, size: .xlarge)
                .frame(width: 160, height: 240)
                .cornerRadius(MemoryRadius.medium)
                .memoryShadow(.medium)
        }
    }
    
    // Book Info Section
    private func bookInfoSection(book: Book) -> some View {
        VStack(spacing: MemorySpacing.xs) {
            Text(book.title)
                .font(.title2)
                .foregroundColor(Color(.label))
                .multilineTextAlignment(.center)
            
            Text(book.author)
                .font(.callout)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
    }
    
    // Action Buttons
    private func actionButtonsSection(book: Book) -> some View {
        VStack(spacing: MemorySpacing.sm) {
            // Chat Button
            NavigationLink(destination: BookChatView(book: book)) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.primaryBlueLight.opacity(0.2),
                                        MemoryTheme.Colors.primaryBlue.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 22))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("読書メモを書く")
                            .font(.headline)
                            .foregroundColor(Color(.label))
                        Text("読みながら感じたことを記録")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(MemorySpacing.md)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(MemoryRadius.large)
                .memoryShadow(.soft)
            }
            .buttonStyle(PlainButtonStyle())
            
            // AI Summary Button
            Button {
                Task {
                    await generateSummary()
                }
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.warmCoralLight.opacity(0.2),
                                        MemoryTheme.Colors.warmCoral.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundColor(MemoryTheme.Colors.warmCoral)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.aiSummary != nil ? "AI要約を再生成" : "AI要約を生成")
                            .font(.headline)
                            .foregroundColor(Color(.label))
                        Text(book.aiSummary != nil ? "最新の読書メモで要約を更新" : "読書メモから要点をまとめます")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    
                    Spacer()
                    
                    if isGeneratingSummary {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(MemoryTheme.Colors.warmCoral)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .padding(MemorySpacing.md)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(MemoryRadius.large)
                .memoryShadow(.soft)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isGeneratingSummary)
            
            // Purchase Button (if purchase URL exists)
            if let purchaseUrl = book.purchaseUrl, !purchaseUrl.isEmpty {
                Button {
                    if let url = URL(string: purchaseUrl) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            MemoryTheme.Colors.goldenMemoryLight.opacity(0.2),
                                            MemoryTheme.Colors.goldenMemory.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "cart.fill")
                                .font(.system(size: 22))
                                .foregroundColor(MemoryTheme.Colors.goldenMemory)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("オンラインで購入")
                                .font(.headline)
                                .foregroundColor(Color(.label))
                            Text("書籍の詳細を見る")
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(MemorySpacing.md)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(MemoryRadius.large)
                    .memoryShadow(.soft)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func statusAndRatingSection(book: Book) -> some View {
        VStack(spacing: MemorySpacing.md) {
            // Status
            HStack {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: statusIcon(for: book.status))
                        .font(.system(size: 16))
                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    Text("ステータス")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                // Status Menu
                Menu {
                    ForEach(ReadingStatus.allCases, id: \.self) { status in
                        Button {
                            Task {
                                await updateStatus(to: status)
                            }
                        } label: {
                            Label(status.displayName, systemImage: status.icon)
                        }
                    }
                } label: {
                    HStack(spacing: MemorySpacing.xs) {
                        if isUpdatingStatus {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Text(book.status.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(statusColor(for: book.status))
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(statusColor(for: book.status))
                    }
                    .padding(.horizontal, MemorySpacing.sm)
                    .padding(.vertical, MemorySpacing.xs)
                    .background(statusColor(for: book.status).opacity(0.1))
                    .cornerRadius(MemoryRadius.full)
                    .overlay(
                        RoundedRectangle(cornerRadius: MemoryRadius.full)
                            .stroke(statusColor(for: book.status).opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isUpdatingStatus)
                .scaleEffect(showStatusChangeAnimation ? 1.1 : 1.0)
                .animation(MemoryTheme.Animation.fast, value: showStatusChangeAnimation)
            }
            
            Divider()
                .foregroundColor(Color(.separator))
            
            // Rating
            HStack {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(MemoryTheme.Colors.goldenMemory)
                    Text("評価")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                if let rating = book.rating {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : (index < Int(rating + 0.5) ? "star.leadinghalf.filled" : "star"))
                                .font(.system(size: 16))
                                .foregroundColor(MemoryTheme.Colors.goldenMemory)
                        }
                        Text(String(format: "%.1f", rating))
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.leading, 4)
                    }
                } else {
                    Text("未評価")
                        .font(.subheadline)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            
            // Reading Progress
            if let progress = book.readingProgress, book.status == .reading {
                Divider()
                    .foregroundColor(Color(.separator))
                
                VStack(spacing: MemorySpacing.xs) {
                    HStack {
                        HStack(spacing: MemorySpacing.xs) {
                            Image(systemName: "book.pages")
                                .font(.system(size: 16))
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            Text("読書進捗")
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        
                        Spacer()
                        
                        Text("\(Int(progress))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                    
                    ProgressView(value: progress / 100.0)
                        .tint(MemoryTheme.Colors.primaryBlue)
                        .background(MemoryTheme.Colors.inkPale)
                        .clipShape(Capsule())
                }
            }
            
            // Reading Period
            if book.status != .wantToRead {
                if let startDate = book.startDate {
                    Divider()
                        .foregroundColor(Color(.separator))
                    
                    HStack {
                        HStack(spacing: MemorySpacing.xs) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            Text("開始日")
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        
                        Spacer()
                        
                        Text(startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(Color(.label))
                    }
                }
                
                if book.status == .completed, let completedDate = book.completedDate {
                    HStack {
                        HStack(spacing: MemorySpacing.xs) {
                            Image(systemName: "checkmark.calendar")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.systemGreen))
                            Text("完了日")
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        
                        Spacer()
                        
                        Text(completedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(Color(.label))
                    }
                }
            }
        }
    }
    
    private func aiSummarySection(summary: String) -> some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            HStack(spacing: MemorySpacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(MemoryTheme.Colors.warmCoral)
                Text("AI要約")
                    .font(.headline)
                    .foregroundColor(Color(.label))
            }
            
            Text(summary)
                .font(.body)
                .foregroundColor(Color(.label))
                .lineSpacing(4)
        }
    }
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            HStack(spacing: MemorySpacing.xs) {
                Image(systemName: "note.text")
                    .font(.system(size: 16))
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                Text("メモ")
                    .font(.headline)
                    .foregroundColor(Color(.label))
            }
            
            Text(notes)
                .font(.body)
                .foregroundColor(Color(.secondaryLabel))
                .lineSpacing(4)
        }
    }
    
    private func generateSummary() async {
        guard authService.currentUser?.uid != nil else { return }
        
        // プレミアムチェック
        guard FeatureGate.canUseAI else {
            showPaywall = true
            return
        }
        
        isGeneratingSummary = true
        summaryError = nil
        
        do {
            let aiService = AIService.shared
            let summary = try await aiService.generateBookSummaryAPI(
                bookId: bookId
            )
            
            aiSummary = summary
            showingSummarySheet = true
        } catch {
            print("Error generating summary: \(error)")
            
            // エラーメッセージの取得
            if let appError = error as? AppError {
                switch appError {
                case .custom(let message):
                    summaryError = message
                default:
                    summaryError = "要約の生成に失敗しました。しばらく時間をおいてから再度お試しください。"
                }
            } else {
                summaryError = "要約の生成に失敗しました。しばらく時間をおいてから再度お試しください。"
            }
            
            showingSummaryError = true
        }
        
        isGeneratingSummary = false
    }
    
    private func updateStatus(to newStatus: ReadingStatus) async {
        guard let currentBook = book, authService.currentUser?.uid != nil else { return }
        guard newStatus != currentBook.status else { return }
        
        isUpdatingStatus = true
        
        // Determine date updates based on status change
        let oldStatus = currentBook.status
        var startDate = currentBook.startDate
        var completedDate = currentBook.completedDate
        
        // Handle transitions
        if oldStatus == .wantToRead && newStatus != .wantToRead {
            // Starting to read
            if startDate == nil {
                startDate = Date()
            }
        }
        
        if oldStatus != .wantToRead && newStatus == .wantToRead {
            // Moving back to want to read - clear dates
            startDate = nil
            completedDate = nil
        }
        
        if oldStatus != .completed && newStatus == .completed {
            // Completing the book
            if startDate == nil {
                startDate = Date()
            }
            completedDate = Date()
        }
        
        if oldStatus != .dnf && newStatus == .dnf {
            // Marking as DNF
            if startDate == nil {
                startDate = Date()
            }
            completedDate = Date()
        }
        
        if (oldStatus == .completed || oldStatus == .dnf) && (newStatus == .reading || newStatus == .wantToRead) {
            // Uncompleting the book
            completedDate = nil
        }
        
        let updatedBook = Book(
            id: currentBook.id,
            isbn: currentBook.isbn,
            title: currentBook.title,
            author: currentBook.author,
            publisher: currentBook.publisher,
            publishedDate: currentBook.publishedDate,
            pageCount: currentBook.pageCount,
            description: currentBook.description,
            coverImageId: currentBook.coverImageId,
            dataSource: currentBook.dataSource,
            status: newStatus,
            rating: currentBook.rating,
            readingProgress: newStatus == .reading ? currentBook.readingProgress : nil,
            currentPage: newStatus == .reading ? currentBook.currentPage : nil,
            addedDate: currentBook.addedDate,
            startDate: startDate,
            completedDate: completedDate,
            lastReadDate: Date(),
            priority: newStatus == .wantToRead ? (currentBook.priority ?? 3) : nil,
            plannedReadingDate: newStatus == .wantToRead ? currentBook.plannedReadingDate : nil,
            reminderEnabled: newStatus == .wantToRead ? currentBook.reminderEnabled : false,
            purchaseLinks: currentBook.purchaseLinks,
            memo: currentBook.memo,
            tags: currentBook.tags,
            aiSummary: currentBook.aiSummary,
            summaryGeneratedAt: currentBook.summaryGeneratedAt,
            createdAt: currentBook.createdAt,
            updatedAt: Date()
        )
        
        do {
            try await bookRepository.updateBook(updatedBook)
            
            // Update local state with animation
            await MainActor.run {
                withAnimation(MemoryTheme.Animation.fast) {
                    self.book = updatedBook
                    showStatusChangeAnimation = true
                }
                
                // Reset animation after a short delay
                Task {
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    await MainActor.run {
                        showStatusChangeAnimation = false
                    }
                }
            }
        } catch {
            print("Error updating book status: \(error)")
        }
        
        isUpdatingStatus = false
    }
    
    private func statusIcon(for status: ReadingStatus) -> String {
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
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .wantToRead:
            return Color(.systemBlue)
        case .reading:
            return MemoryTheme.Colors.primaryBlue
        case .completed:
            return Color(.systemGreen)
        case .dnf:
            return Color(.secondaryLabel)
        }
    }
}


// Summary View
struct SummaryView: View {
    let summary: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MemorySpacing.lg) {
                    // Header
                    VStack(spacing: MemorySpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(MemoryTheme.Colors.warmCoral)
                        
                        Text("AI要約")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.label))
                    }
                    .padding(.top, MemorySpacing.lg)
                    
                    // Summary Content
                    VStack(alignment: .leading, spacing: MemorySpacing.md) {
                        Text(summary)
                            .font(.body)
                            .foregroundColor(Color(.label))
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(MemorySpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: MemoryRadius.large)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal, MemorySpacing.md)
                    
                    // Footer Note
                    Text("この要約は、あなたの読書メモをもとにAIが生成しました")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MemorySpacing.lg)
                        .padding(.bottom, MemorySpacing.lg)
                }
            }
            .background(Color(.systemBackground))
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


// Rating Selector
struct RatingSelector: View {
    @Binding var rating: Double?
    
    var body: some View {
        HStack(spacing: MemorySpacing.xs) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    if rating == Double(value) {
                        rating = nil
                    } else {
                        rating = Double(value)
                    }
                } label: {
                    Image(systemName: getRatingIcon(for: value))
                        .font(.system(size: 28))
                        .foregroundColor(MemoryTheme.Colors.goldenMemory)
                }
            }
        }
    }
    
    private func getRatingIcon(for value: Int) -> String {
        guard let rating = rating else {
            return "star"
        }
        
        if Double(value) <= rating {
            return "star.fill"
        } else if Double(value) - 0.5 <= rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
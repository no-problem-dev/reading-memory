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
            BookCoverView(imageURL: book.coverImageUrl, size: .xlarge)
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
                        Text("本とおしゃべりする")
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
                        Text("AI要約を生成")
                            .font(.headline)
                            .foregroundColor(Color(.label))
                        Text("読書メモから要点をまとめます")
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
                
                Text(book.status.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor(for: book.status))
                    .padding(.horizontal, MemorySpacing.sm)
                    .padding(.vertical, MemorySpacing.xs)
                    .background(statusColor(for: book.status).opacity(0.1))
                    .cornerRadius(MemoryRadius.full)
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
            aiSummary = "要約の生成に失敗しました。しばらく時間をおいてから再度お試しください。"
            showingSummarySheet = true
        }
        
        isGeneratingSummary = false
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

// Simple Edit Book View
struct SimpleEditBookView: View {
    let book: Book
    let onSave: (Book) -> Void
    
    @State private var status: ReadingStatus
    @State private var rating: Double?
    @State private var memo: String
    @State private var readingProgress: Double?
    @Environment(\.dismiss) private var dismiss
    
    private let bookRepository = ServiceContainer.shared.getBookRepository()
    
    init(book: Book, onSave: @escaping (Book) -> Void) {
        self.book = book
        self.onSave = onSave
        _status = State(initialValue: book.status)
        _rating = State(initialValue: book.rating)
        _memo = State(initialValue: book.memo ?? "")
        _readingProgress = State(initialValue: book.readingProgress)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("ステータス", selection: $status) {
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    if status == .reading {
                        VStack(alignment: .leading) {
                            Text("読書進捗: \(Int(readingProgress ?? 0))%")
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                            Slider(value: Binding(
                                get: { readingProgress ?? 0 },
                                set: { readingProgress = $0 }
                            ), in: 0...100, step: 5)
                            .tint(MemoryTheme.Colors.primaryBlue)
                        }
                    }
                    
                    if status == .completed || status == .dnf {
                        VStack(alignment: .leading) {
                            Text("評価")
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                            RatingSelector(rating: $rating)
                        }
                    }
                }
                
                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("本の編集")
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
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() async {
        let startDate: Date? = status == .reading && book.startDate == nil ? Date() : 
                               (status == .completed || status == .dnf) && book.startDate == nil ? Date() :
                               book.startDate
        
        let completedDate: Date? = (status == .completed || status == .dnf) && book.completedDate == nil ? Date() :
                                   status == .reading ? nil :
                                   book.completedDate
        
        let updatedBook = Book(
            id: book.id,
            isbn: book.isbn,
            title: book.title,
            author: book.author,
            publisher: book.publisher,
            publishedDate: book.publishedDate,
            pageCount: book.pageCount,
            description: book.description,
            coverImageUrl: book.coverImageUrl,
            dataSource: book.dataSource,
            status: status,
            rating: rating,
            readingProgress: readingProgress,
            currentPage: book.currentPage,
            addedDate: book.addedDate,
            startDate: startDate,
            completedDate: completedDate,
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
        
        do {
            try await bookRepository.updateBook(updatedBook)
            onSave(updatedBook)
            dismiss()
        } catch {
            print("Error updating book: \(error)")
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
                VStack(alignment: .leading, spacing: MemorySpacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(MemoryTheme.Colors.warmCoral)
                        .frame(maxWidth: .infinity)
                        .padding(.top, MemorySpacing.lg)
                    
                    Text("AI要約")
                        .font(.title2)
                        .foregroundColor(Color(.label))
                        .frame(maxWidth: .infinity)
                    
                    Text(summary)
                        .font(.body)
                        .foregroundColor(Color(.label))
                        .lineSpacing(6)
                        .padding(.horizontal, MemorySpacing.md)
                }
                .padding(.vertical, MemorySpacing.lg)
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
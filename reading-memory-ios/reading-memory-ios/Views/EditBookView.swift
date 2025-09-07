import SwiftUI

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let onSave: (Book) -> Void
    
    @State private var status: ReadingStatus
    @State private var rating: Double
    @State private var currentPage: String
    @State private var startDate: Date
    @State private var completedDate: Date
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    init(book: Book, onSave: @escaping (Book) -> Void) {
        self.book = book
        self.onSave = onSave
        
        _status = State(initialValue: book.status)
        _rating = State(initialValue: book.rating ?? 3.0)
        _currentPage = State(initialValue: book.currentPage != nil ? String(book.currentPage!) : "")
        _startDate = State(initialValue: book.startDate ?? Date())
        _completedDate = State(initialValue: book.completedDate ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MemoryTheme.Colors.secondaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: MemorySpacing.lg) {
                        // Book info header
                        bookInfoHeader
                            .padding(.horizontal, MemorySpacing.md)
                            .padding(.top, MemorySpacing.md)
                        
                        // Main content card
                        MemoryCard {
                            VStack(alignment: .leading, spacing: MemorySpacing.lg) {
                                // Status selector
                                VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                                    Label("読書ステータス", systemImage: "book.fill")
                                        .font(MemoryTheme.Fonts.headline())
                                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                                    
                                    statusSegmentedControl
                                }
                                
                                Divider()
                                
                                // Dynamic fields based on status
                                VStack(alignment: .leading, spacing: MemorySpacing.lg) {
                                    // Rating (only for completed)
                                    if status == .completed {
                                        ratingSection
                                    }
                                    
                                    // Current page (only for reading)
                                    if status == .reading {
                                        currentPageSection
                                    }
                                    
                                    // Start date (for reading and completed)
                                    if status == .reading || status == .completed {
                                        dateSection(
                                            title: "開始日",
                                            date: $startDate,
                                            icon: "calendar"
                                        )
                                    }
                                    
                                    // Completed date (only for completed)
                                    if status == .completed {
                                        dateSection(
                                            title: "完了日",
                                            date: $completedDate,
                                            icon: "calendar.badge.checkmark"
                                        )
                                    }
                                }
                            }
                            .padding(MemorySpacing.md)
                        }
                        .padding(.horizontal, MemorySpacing.md)
                    }
                    .padding(.bottom, MemorySpacing.xxl)
                }
            }
            .navigationTitle("読書状態を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    .fontWeight(.semibold)
                    .disabled(isLoading)
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "保存中にエラーが発生しました")
            }
        }
    }
    
    // MARK: - Components
    
    private var bookInfoHeader: some View {
        HStack(spacing: MemorySpacing.md) {
            // Book cover
            if let imageId = book.coverImageId {
                RemoteImage(imageId: imageId)
                    .frame(width: 60, height: 90)
                    .cornerRadius(MemoryRadius.medium)
                    .memoryShadow(.soft)
            } else {
                BookCoverPlaceholder()
                    .frame(width: 60, height: 90)
            }
            
            // Book info
            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                Text(book.title)
                    .font(MemoryTheme.Fonts.body())
                    .fontWeight(.semibold)
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(MemoryTheme.Fonts.caption())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
    
    private var statusSegmentedControl: some View {
        VStack(spacing: MemorySpacing.md) {
            ForEach(ReadingStatus.allCases, id: \.self) { readingStatus in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        status = readingStatus
                    }
                } label: {
                    HStack {
                        HStack(spacing: MemorySpacing.sm) {
                            Image(systemName: readingStatus.icon)
                                .font(.system(size: 20))
                            
                            Text(readingStatus.displayName)
                                .font(MemoryTheme.Fonts.body())
                        }
                        .foregroundColor(
                            status == readingStatus
                                ? statusColor(for: readingStatus)
                                : MemoryTheme.Colors.inkGray
                        )
                        
                        Spacer()
                        
                        if status == readingStatus {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(statusColor(for: readingStatus))
                        }
                    }
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.vertical, MemorySpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MemoryRadius.medium)
                            .fill(
                                status == readingStatus
                                    ? statusColor(for: readingStatus).opacity(0.1)
                                    : MemoryTheme.Colors.cardBackground
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MemoryRadius.medium)
                            .stroke(
                                status == readingStatus
                                    ? statusColor(for: readingStatus).opacity(0.5)
                                    : MemoryTheme.Colors.inkPale.opacity(0.3),
                                lineWidth: status == readingStatus ? 2 : 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            HStack {
                Label("評価", systemImage: "star.fill")
                    .font(MemoryTheme.Fonts.subheadline())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                
                Spacer()
                
                Text(String(format: "%.1f", rating))
                    .font(MemoryTheme.Fonts.headline())
                    .foregroundColor(MemoryTheme.Colors.goldenMemory)
            }
            
            HStack(spacing: MemorySpacing.xs) {
                ForEach(0..<5) { index in
                    Image(systemName: starImageName(for: index))
                        .font(.system(size: 32))
                        .foregroundColor(MemoryTheme.Colors.goldenMemory)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                updateRating(for: index)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var currentPageSection: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            Label("読書進捗", systemImage: "book.pages")
                .font(MemoryTheme.Fonts.subheadline())
                .foregroundColor(MemoryTheme.Colors.inkGray)
            
            HStack {
                MemoryTextField(
                    placeholder: "現在のページ",
                    text: $currentPage,
                    keyboardType: .numberPad
                )
                .frame(maxWidth: 150)
                
                if let pageCount = book.pageCount {
                    Text("/ \(pageCount) ページ")
                        .font(MemoryTheme.Fonts.body())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                }
                
                Spacer()
            }
            
            // Progress bar
            if let pageCount = book.pageCount,
               let currentPageInt = Int(currentPage),
               currentPageInt > 0 {
                let progress = min(Double(currentPageInt) / Double(pageCount), 1.0)
                
                VStack(spacing: MemorySpacing.xs) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: MemoryRadius.small)
                                .fill(MemoryTheme.Colors.inkPale.opacity(0.3))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: MemoryRadius.small)
                                .fill(MemoryTheme.Colors.primaryBlue)
                                .frame(width: geometry.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(Int(progress * 100))% 完了")
                        .font(MemoryTheme.Fonts.caption())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
    
    private func dateSection(title: String, date: Binding<Date>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            Label(title, systemImage: icon)
                .font(MemoryTheme.Fonts.subheadline())
                .foregroundColor(MemoryTheme.Colors.inkGray)
            
            DatePicker(
                "",
                selection: date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(MemoryTheme.Colors.primaryBlue)
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func updateRating(for index: Int) {
        let fullStarRating = Double(index + 1)
        let halfStarRating = Double(index) + 0.5
        
        if rating == fullStarRating {
            rating = halfStarRating
        } else {
            rating = fullStarRating
        }
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .wantToRead:
            return MemoryTheme.Colors.primaryBlue
        case .reading:
            return MemoryTheme.Colors.goldenMemory
        case .completed:
            return MemoryTheme.Colors.success
        case .dnf:
            return Color(.systemGray)
        }
    }
    
    private func saveChanges() {
        isLoading = true
        
        Task {
            do {
                // Calculate reading progress
                var readingProgress: Double? = nil
                var currentPageInt: Int? = nil
                
                if status == .reading,
                   let pageCount = book.pageCount,
                   pageCount > 0,
                   let page = Int(currentPage),
                   page > 0 {
                    currentPageInt = page
                    readingProgress = min(Double(page) / Double(pageCount), 1.0)
                }
                
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
                    status: status,
                    rating: status == .completed ? rating : nil,
                    readingProgress: readingProgress,
                    currentPage: currentPageInt,
                    addedDate: book.addedDate,
                    startDate: (status == .reading || status == .completed) ? startDate : nil,
                    completedDate: status == .completed ? completedDate : nil,
                    lastReadDate: Date(),
                    priority: book.priority,
                    plannedReadingDate: book.plannedReadingDate,
                    reminderEnabled: book.reminderEnabled,
                    purchaseLinks: book.purchaseLinks,
                    memo: book.memo,
                    tags: book.tags,
                    aiSummary: book.aiSummary,
                    summaryGeneratedAt: book.summaryGeneratedAt,
                    createdAt: book.createdAt,
                    updatedAt: Date()
                )
                
                try await BookRepository.shared.updateBook(updatedBook)
                
                await MainActor.run {
                    onSave(updatedBook)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    EditBookView(
        book: Book.new(
            isbn: nil,
            title: "サンプルブック",
            author: "サンプル著者",
            publisher: "サンプル出版社",
            publishedDate: nil,
            pageCount: 350,
            description: "これはサンプルの本の説明です。",
            coverImageId: nil,
            dataSource: .manual
        )
    ) { _ in }
}
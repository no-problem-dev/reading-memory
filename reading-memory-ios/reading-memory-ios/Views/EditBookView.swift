import SwiftUI

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let onSave: (Book) -> Void
    
    @State private var status: ReadingStatus
    @State private var rating: Double
    @State private var hasRating: Bool
    @State private var startDate: Date
    @State private var hasStartDate: Bool
    @State private var completedDate: Date
    @State private var hasCompletedDate: Bool
    @State private var notes: String
    
    // 追加フィールド
    @State private var tags: [String]
    @State private var newTag: String = ""
    @State private var currentPage: String
    @State private var priority: Int
    @State private var plannedReadingDate: Date
    @State private var hasPlannedReadingDate: Bool
    @State private var reminderEnabled: Bool
    @State private var description: String
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var selectedSection = 0
    
    init(book: Book, onSave: @escaping (Book) -> Void) {
        self.book = book
        self.onSave = onSave
        
        _status = State(initialValue: book.status)
        _rating = State(initialValue: book.rating ?? 3.0)
        _hasRating = State(initialValue: book.rating != nil)
        _startDate = State(initialValue: book.startDate ?? Date())
        _hasStartDate = State(initialValue: book.startDate != nil)
        _completedDate = State(initialValue: book.completedDate ?? Date())
        _hasCompletedDate = State(initialValue: book.completedDate != nil)
        _notes = State(initialValue: book.memo ?? "")
        
        _tags = State(initialValue: book.tags)
        _currentPage = State(initialValue: book.currentPage != nil ? String(book.currentPage!) : "")
        _priority = State(initialValue: book.priority ?? 3)
        _plannedReadingDate = State(initialValue: book.plannedReadingDate ?? Date())
        _hasPlannedReadingDate = State(initialValue: book.plannedReadingDate != nil)
        _reminderEnabled = State(initialValue: book.reminderEnabled)
        _description = State(initialValue: book.description ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        MemoryTheme.Colors.background,
                        MemoryTheme.Colors.secondaryBackground
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Book info header
                        bookInfoHeader
                            .padding(.bottom, MemorySpacing.md)
                        
                        // Section Tabs
                        sectionTabs
                            .padding(.bottom, MemorySpacing.md)
                        
                        // Content based on selected section
                        switch selectedSection {
                        case 0:
                            basicInfoSection
                        case 1:
                            progressSection
                        case 2:
                            plannedReadingSection
                        case 3:
                            detailsSection
                        default:
                            basicInfoSection
                        }
                    }
                    .padding(.bottom, MemorySpacing.xxl)
                }
            }
            .navigationTitle("本を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                            .font(MemoryTheme.Fonts.subheadline())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveChanges()
                    } label: {
                        Text("保存")
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                    .disabled(isLoading)
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "保存中にエラーが発生しました")
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Components
    
    private var bookInfoHeader: some View {
        HStack(spacing: MemorySpacing.md) {
            // Book cover
            if let imageId = book.coverImageId {
                RemoteImage(imageId: imageId)
                    .frame(width: 80, height: 120)
                    .cornerRadius(MemoryRadius.medium)
                    .memoryShadow(.soft)
            } else {
                BookCoverPlaceholder()
                    .frame(width: 80, height: 120)
            }
            
            // Book info
            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                Text(book.title)
                    .font(MemoryTheme.Fonts.headline())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(MemoryTheme.Fonts.subheadline())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .lineLimit(1)
                
                if let publisher = book.publisher {
                    Text(publisher)
                        .font(MemoryTheme.Fonts.caption())
                        .foregroundColor(MemoryTheme.Colors.inkLightGray)
                        .lineLimit(1)
                }
                
                if let pageCount = book.pageCount {
                    Text("\(pageCount)ページ")
                        .font(MemoryTheme.Fonts.caption())
                        .foregroundColor(MemoryTheme.Colors.inkLightGray)
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(MemorySpacing.md)
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
        .padding(.horizontal, MemorySpacing.md)
    }
    
    private var sectionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MemorySpacing.md) {
                ForEach(0..<4) { index in
                    Button {
                        withAnimation(MemoryTheme.Animation.fast) {
                            selectedSection = index
                        }
                    } label: {
                        Text(sectionTitle(for: index))
                            .font(MemoryTheme.Fonts.subheadline())
                            .foregroundColor(
                                selectedSection == index 
                                    ? MemoryTheme.Colors.inkWhite
                                    : MemoryTheme.Colors.inkGray
                            )
                            .padding(.horizontal, MemorySpacing.md)
                            .padding(.vertical, MemorySpacing.sm)
                            .background(
                                selectedSection == index
                                    ? MemoryTheme.Colors.primaryBlue
                                    : MemoryTheme.Colors.inkPale.opacity(0.3)
                            )
                            .cornerRadius(MemoryRadius.full)
                    }
                }
            }
            .padding(.horizontal, MemorySpacing.md)
        }
    }
    
    private func sectionTitle(for index: Int) -> String {
        switch index {
        case 0: return "基本情報"
        case 1: return "読書進捗"
        case 2: return "読書予定"
        case 3: return "詳細"
        default: return ""
        }
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: MemorySpacing.lg) {
            // Status card
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "book.fill",
                        title: "読書ステータス",
                        color: MemoryTheme.Colors.primaryBlue
                    )
                    
                    statusPicker
                }
            }
            .padding(.horizontal, MemorySpacing.md)
            
            // Rating card
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "star.fill",
                        title: "評価",
                        color: MemoryTheme.Colors.goldenMemory
                    )
                    
                    VStack(spacing: MemorySpacing.md) {
                        Toggle(isOn: $hasRating) {
                            Text("評価を設定")
                                .font(MemoryTheme.Fonts.subheadline())
                                .foregroundColor(MemoryTheme.Colors.inkBlack)
                        }
                        .tint(MemoryTheme.Colors.primaryBlue)
                        
                        if hasRating {
                            VStack(spacing: MemorySpacing.md) {
                                HStack {
                                    Text("評価")
                                        .font(MemoryTheme.Fonts.body())
                                        .foregroundColor(MemoryTheme.Colors.inkGray)
                                    Spacer()
                                    Text(String(format: "%.1f", rating))
                                        .font(MemoryTheme.Fonts.headline())
                                        .foregroundColor(MemoryTheme.Colors.goldenMemory)
                                }
                                
                                HStack(spacing: MemorySpacing.xs) {
                                    ForEach(0..<5) { index in
                                        Image(systemName: starImageName(for: index))
                                            .font(.system(size: 28))
                                            .foregroundColor(MemoryTheme.Colors.goldenMemory)
                                            .onTapGesture {
                                                withAnimation(MemoryTheme.Animation.fast) {
                                                    updateRating(for: index)
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MemorySpacing.md)
            
            // Tags card
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "tag.fill",
                        title: "タグ",
                        color: MemoryTheme.Colors.warmCoral
                    )
                    
                    // Tag list
                    if !tags.isEmpty {
                        FlowLayout(spacing: MemorySpacing.sm) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: MemorySpacing.xs) {
                                    Text(tag)
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(MemoryTheme.Colors.inkWhite)
                                    
                                    Button {
                                        withAnimation(MemoryTheme.Animation.fast) {
                                            tags.removeAll { $0 == tag }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(MemoryTheme.Colors.inkWhite.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal, MemorySpacing.sm)
                                .padding(.vertical, MemorySpacing.xs)
                                .background(MemoryTheme.Colors.warmCoral)
                                .cornerRadius(MemoryRadius.full)
                            }
                        }
                        .padding(.bottom, MemorySpacing.sm)
                    }
                    
                    // Add tag field
                    HStack {
                        TextField("新しいタグを追加", text: $newTag)
                            .memoryTextFieldStyle()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                addTag()
                            }
                        
                        Button {
                            addTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(.horizontal, MemorySpacing.md)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: MemorySpacing.lg) {
            // Progress card
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "chart.bar.fill",
                        title: "読書進捗",
                        color: MemoryTheme.Colors.primaryBlue
                    )
                    
                    // Current page
                    if let pageCount = book.pageCount, pageCount > 0 {
                        VStack(alignment: .leading, spacing: MemorySpacing.md) {
                            Text("現在のページ")
                                .font(MemoryTheme.Fonts.subheadline())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            
                            HStack {
                                TextField("ページ数", text: $currentPage)
                                    .memoryTextFieldStyle()
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100)
                                
                                Text("/ \(pageCount) ページ")
                                    .font(MemoryTheme.Fonts.body())
                                    .foregroundColor(MemoryTheme.Colors.inkGray)
                                
                                Spacer()
                            }
                            
                            // Progress bar
                            if let currentPageInt = Int(currentPage), currentPageInt > 0 {
                                let progress = min(Double(currentPageInt) / Double(pageCount), 1.0)
                                
                                VStack(spacing: MemorySpacing.xs) {
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: MemoryRadius.small)
                                                .fill(MemoryTheme.Colors.inkPale.opacity(0.3))
                                                .frame(height: 8)
                                            
                                            RoundedRectangle(cornerRadius: MemoryRadius.small)
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
                                                .frame(width: geometry.size.width * progress, height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                    
                                    Text("\(Int(progress * 100))% 完了")
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(MemoryTheme.Colors.inkGray)
                                }
                                .padding(.top, MemorySpacing.sm)
                            }
                        }
                    } else {
                        Text("ページ数が設定されていません")
                            .font(MemoryTheme.Fonts.body())
                            .foregroundColor(MemoryTheme.Colors.inkLightGray)
                    }
                }
            }
            .padding(.horizontal, MemorySpacing.md)
            
            // Date cards
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "calendar",
                        title: "読書日程",
                        color: MemoryTheme.Colors.goldenMemory
                    )
                    
                    dateToggleSection(
                        title: "開始日を設定",
                        isOn: $hasStartDate,
                        date: $startDate,
                        label: "開始日"
                    )
                    
                    if status == .completed || hasCompletedDate {
                        Divider()
                            .padding(.vertical, MemorySpacing.xs)
                        
                        dateToggleSection(
                            title: "完了日を設定",
                            isOn: $hasCompletedDate,
                            date: $completedDate,
                            label: "完了日"
                        )
                    }
                }
            }
            .padding(.horizontal, MemorySpacing.md)
        }
    }
    
    private var plannedReadingSection: some View {
        VStack(spacing: MemorySpacing.lg) {
            // Priority card
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "star.circle.fill",
                        title: "優先度",
                        color: MemoryTheme.Colors.warmCoral
                    )
                    
                    HStack {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                withAnimation(MemoryTheme.Animation.fast) {
                                    priority = level
                                }
                            } label: {
                                VStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: priority >= level ? "star.fill" : "star")
                                        .font(.system(size: 24))
                                        .foregroundColor(
                                            priority >= level
                                                ? MemoryTheme.Colors.warmCoral
                                                : MemoryTheme.Colors.inkLightGray
                                        )
                                    
                                    Text(priorityText(for: level))
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(
                                            priority == level
                                                ? MemoryTheme.Colors.warmCoral
                                                : MemoryTheme.Colors.inkGray
                                        )
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, MemorySpacing.md)
            
            // Planned reading date card
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "calendar.badge.clock",
                        title: "読書予定",
                        color: MemoryTheme.Colors.primaryBlue
                    )
                    
                    dateToggleSection(
                        title: "読書予定日を設定",
                        isOn: $hasPlannedReadingDate,
                        date: $plannedReadingDate,
                        label: "予定日"
                    )
                    
                    if hasPlannedReadingDate {
                        Divider()
                            .padding(.vertical, MemorySpacing.xs)
                        
                        Toggle(isOn: $reminderEnabled) {
                            HStack(spacing: MemorySpacing.sm) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                Text("リマインダーを設定")
                                    .font(MemoryTheme.Fonts.subheadline())
                                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                            }
                        }
                        .tint(MemoryTheme.Colors.primaryBlue)
                    }
                }
            }
            .padding(.horizontal, MemorySpacing.md)
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: MemorySpacing.lg) {
            // Description card
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "doc.text.fill",
                        title: "説明",
                        color: MemoryTheme.Colors.primaryBlue
                    )
                    
                    TextEditor(text: $description)
                        .memoryTextEditorStyle()
                        .padding(MemorySpacing.sm)
                        .background(MemoryTheme.Colors.inkPale.opacity(0.3))
                        .cornerRadius(MemoryRadius.medium)
                        .frame(minHeight: 100)
                }
            }
            .padding(.horizontal, MemorySpacing.md)
            
            // Notes card
            MemoryCard {
                VStack(spacing: MemorySpacing.lg) {
                    sectionHeader(
                        icon: "note.text",
                        title: "メモ",
                        color: MemoryTheme.Colors.goldenMemory
                    )
                    
                    TextEditor(text: $notes)
                        .memoryTextEditorStyle()
                        .padding(MemorySpacing.sm)
                        .background(MemoryTheme.Colors.inkPale.opacity(0.3))
                        .cornerRadius(MemoryRadius.medium)
                        .frame(minHeight: 150)
                }
            }
            .padding(.horizontal, MemorySpacing.md)
        }
    }
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: MemorySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(title)
                .font(MemoryTheme.Fonts.headline())
                .foregroundColor(MemoryTheme.Colors.inkBlack)
            Spacer()
        }
    }
    
    private var statusPicker: some View {
        Menu {
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                Button {
                    withAnimation(MemoryTheme.Animation.fast) {
                        let oldStatus = self.status
                        self.status = status
                        handleStatusChange(from: oldStatus, to: status)
                    }
                } label: {
                    Label(status.displayName, systemImage: status.icon)
                }
            }
        } label: {
            HStack {
                Label(status.displayName, systemImage: status.icon)
                    .font(MemoryTheme.Fonts.body())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(MemoryTheme.Colors.inkGray)
            }
            .padding(.horizontal, MemorySpacing.md)
            .padding(.vertical, MemorySpacing.sm)
            .background(MemoryTheme.Colors.inkPale.opacity(0.5))
            .cornerRadius(MemoryRadius.medium)
        }
    }
    
    private func dateToggleSection(title: String, isOn: Binding<Bool>, date: Binding<Date>, label: String) -> some View {
        VStack(spacing: MemorySpacing.sm) {
            Toggle(isOn: isOn) {
                Text(title)
                    .font(MemoryTheme.Fonts.subheadline())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
            }
            .tint(MemoryTheme.Colors.primaryBlue)
            
            if isOn.wrappedValue {
                DatePicker(
                    label,
                    selection: date,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(MemoryTheme.Colors.primaryBlue)
                .padding(.top, MemorySpacing.xs)
            }
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
    
    private func priorityText(for level: Int) -> String {
        switch level {
        case 1: return "低"
        case 2: return "やや低"
        case 3: return "普通"
        case 4: return "やや高"
        case 5: return "高"
        default: return ""
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            withAnimation(MemoryTheme.Animation.fast) {
                tags.append(trimmedTag)
                newTag = ""
            }
        }
    }
    
    private func handleStatusChange(from oldStatus: ReadingStatus, to newStatus: ReadingStatus) {
        if oldStatus == .wantToRead && newStatus != .wantToRead && !hasStartDate {
            hasStartDate = true
            startDate = Date()
        }
        
        if oldStatus != .wantToRead && newStatus == .wantToRead {
            hasStartDate = false
            hasCompletedDate = false
        }
        
        if oldStatus != .completed && newStatus == .completed && !hasCompletedDate {
            hasCompletedDate = true
            completedDate = Date()
            if !hasStartDate {
                hasStartDate = true
                startDate = Date()
            }
        }
        
        if oldStatus == .completed && newStatus != .completed {
            hasCompletedDate = false
        }
    }
    
    private func saveChanges() {
        isLoading = true
        
        Task {
            do {
                // Calculate reading progress
                var readingProgress: Double? = nil
                var currentPageInt: Int? = nil
                
                if let pageCount = book.pageCount, pageCount > 0,
                   let page = Int(currentPage), page > 0 {
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
                    description: description.isEmpty ? nil : description,
                    coverImageId: book.coverImageId,
                    dataSource: book.dataSource,
                    status: status,
                    rating: hasRating ? rating : nil,
                    readingProgress: readingProgress,
                    currentPage: currentPageInt,
                    addedDate: book.addedDate,
                    startDate: hasStartDate ? startDate : nil,
                    completedDate: hasCompletedDate ? completedDate : nil,
                    lastReadDate: Date(),
                    priority: status == .wantToRead ? priority : nil,
                    plannedReadingDate: hasPlannedReadingDate ? plannedReadingDate : nil,
                    reminderEnabled: hasPlannedReadingDate && reminderEnabled,
                    purchaseLinks: book.purchaseLinks,
                    memo: notes.isEmpty ? nil : notes,
                    tags: tags,
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
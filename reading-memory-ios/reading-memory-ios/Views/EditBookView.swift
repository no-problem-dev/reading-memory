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
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    
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
                    VStack(spacing: MemorySpacing.lg) {
                        // Book info header
                        bookInfoHeader
                        
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
                                                            updateRating(for: index)
                                                        }
                                                }
                                            }
                                            
                                            Slider(value: $rating, in: 0.5...5.0, step: 0.5)
                                                .tint(MemoryTheme.Colors.goldenMemory)
                                        }
                                        .padding(.top, MemorySpacing.xs)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        
                        // Reading period card
                        MemoryCard {
                            VStack(spacing: MemorySpacing.lg) {
                                sectionHeader(
                                    icon: "calendar",
                                    title: "読書期間",
                                    color: MemoryTheme.Colors.warmCoral
                                )
                                
                                VStack(spacing: MemorySpacing.md) {
                                    if status != .wantToRead {
                                        dateToggleSection(
                                            title: "開始日を設定",
                                            isOn: $hasStartDate,
                                            date: $startDate,
                                            label: "開始日"
                                        )
                                    }
                                    
                                    if status == .completed {
                                        dateToggleSection(
                                            title: "完了日を設定",
                                            isOn: $hasCompletedDate,
                                            date: $completedDate,
                                            label: "完了日"
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        
                        // Notes card
                        MemoryCard {
                            VStack(spacing: MemorySpacing.lg) {
                                sectionHeader(
                                    icon: "note.text",
                                    title: "メモ",
                                    color: MemoryTheme.Colors.primaryBlue
                                )
                                
                                TextEditor(text: $notes)
                                    .font(MemoryTheme.Fonts.body())
                                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                                    .scrollContentBackground(.hidden)
                                    .padding(MemorySpacing.sm)
                                    .frame(minHeight: 120)
                                    .background(MemoryTheme.Colors.inkPale.opacity(0.5))
                                    .cornerRadius(MemoryRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                            .stroke(MemoryTheme.Colors.inkPale, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.bottom, MemorySpacing.xl)
                    }
                    .padding(.top, MemorySpacing.lg)
                }
                
                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: MemorySpacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("保存中...")
                            .font(MemoryTheme.Fonts.body())
                            .foregroundColor(.white)
                    }
                    .padding(MemorySpacing.xl)
                    .background(MemoryTheme.Colors.inkBlack.opacity(0.8))
                    .cornerRadius(MemoryRadius.large)
                }
            }
            .navigationTitle("本の編集")
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
            Group {
                if let imageUrl = book.coverImageUrl {
                    CachedAsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        BookCoverPlaceholder()
                    }
                } else {
                    BookCoverPlaceholder()
                }
            }
            .frame(width: 80, height: 120)
            .cornerRadius(MemoryRadius.medium)
            .memoryShadow(.soft)
            
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
    
    private struct BookCoverPlaceholder: View {
            
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.inkPale.opacity(0.5),
                                MemoryTheme.Colors.inkPale.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 30))
                    .foregroundColor(MemoryTheme.Colors.inkLightGray)
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
        let newRating = Double(index) + 1.0
        if rating == newRating {
            rating = Double(index) + 0.5
        } else {
            rating = newRating
        }
    }
    
    private func handleStatusChange(from oldStatus: ReadingStatus, to newStatus: ReadingStatus) {
        // 読みたい → その他: 開始日を今日に設定
        if oldStatus == .wantToRead && newStatus != .wantToRead && !hasStartDate {
            hasStartDate = true
            startDate = Date()
        }
        
        // その他 → 読みたい: 開始日をクリア
        if oldStatus != .wantToRead && newStatus == .wantToRead {
            hasStartDate = false
            hasCompletedDate = false
        }
        
        // 完了以外 → 完了: 完了日を今日に設定
        if oldStatus != .completed && newStatus == .completed && !hasCompletedDate {
            hasCompletedDate = true
            completedDate = Date()
            if !hasStartDate {
                hasStartDate = true
                startDate = Date()
            }
        }
        
        // 完了 → 完了以外: 完了日をクリア
        if oldStatus == .completed && newStatus != .completed {
            hasCompletedDate = false
        }
    }
    
    private func saveChanges() {
        isLoading = true
        
        Task {
            do {
                let updatedBook = book.updated(
                    status: status,
                    rating: hasRating ? rating : nil,
                    readingProgress: book.readingProgress,
                    currentPage: book.currentPage,
                    startDate: hasStartDate ? startDate : nil,
                    completedDate: hasCompletedDate ? completedDate : nil,
                    memo: notes.isEmpty ? nil : notes,
                    tags: book.tags
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
            publisher: nil,
            publishedDate: nil,
            pageCount: nil,
            description: nil,
            coverImageId: nil,
            dataSource: .manual
        )
    ) { _ in }
    }
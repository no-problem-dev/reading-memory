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
            Form {
                Section("読書ステータス") {
                    Picker("ステータス", selection: $status) {
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: status) { oldValue, newValue in
                        handleStatusChange(from: oldValue, to: newValue)
                    }
                }
                
                Section("評価") {
                    Toggle("評価を設定", isOn: $hasRating)
                    
                    if hasRating {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("評価")
                                Spacer()
                                Text(String(format: "%.1f", rating))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 8) {
                                ForEach(0..<5) { index in
                                    Image(systemName: starImageName(for: index))
                                        .font(.title2)
                                        .foregroundColor(.yellow)
                                        .onTapGesture {
                                            updateRating(for: index)
                                        }
                                }
                            }
                            
                            Slider(value: $rating, in: 0.5...5.0, step: 0.5)
                                .tint(.yellow)
                        }
                    }
                }
                
                Section("読書期間") {
                    if status != .wantToRead {
                        Toggle("開始日を設定", isOn: $hasStartDate)
                        if hasStartDate {
                            DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                        }
                    }
                    
                    if status == .completed {
                        Toggle("完了日を設定", isOn: $hasCompletedDate)
                        if hasCompletedDate {
                            DatePicker("完了日", selection: $completedDate, displayedComponents: .date)
                        }
                    }
                }
                
                Section("メモ") {
                    TextEditor(text: $notes)
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
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "保存中にエラーが発生しました")
            }
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
            coverImageUrl: nil,
            dataSource: .manual
        )
    ) { _ in }
}
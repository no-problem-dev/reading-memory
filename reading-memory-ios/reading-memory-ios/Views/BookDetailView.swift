import SwiftUI
import PhotosUI

struct BookDetailView: View {
    let bookId: String
    
    @Environment(BookStore.self) private var bookStore
    @State private var book: Book?
    @State private var isLoading = false
    @State private var showingEditSheet = false
    @State private var showingBookInfoEdit = false
    @State private var showingDeleteAlert = false
    @State private var showingSummaryView = false
    @State private var showingMemoryView = false
    @State private var showStatusChangeAnimation = false
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss
    
    private let authService = AuthService.shared
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let book = book {
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section with Book Info
                        BookDetailHeroSection(
                            book: book,
                            onCoverTap: {
                                showingBookInfoEdit = true
                            }
                        )
                        
                        VStack(spacing: MemorySpacing.lg) {
                            // Action Buttons
                            BookDetailActionButtons(
                                book: book,
                                onMemoryTapped: { showingMemoryView = true },
                                onSummaryTapped: { showingSummaryView = true }
                            )
                            .padding(.horizontal)
                            
                            // Status and Rating
                            BookDetailStatusSection(
                                book: Binding(
                                    get: { book },
                                    set: { self.book = $0 }
                                ),
                                onStatusUpdate: updateStatus
                            )
                            .padding(.horizontal)
                            
                            // AI Summary Section
                            if let summary = book.aiSummary {
                                BookDetailAISummarySection(summary: summary)
                                    .padding(.horizontal)
                            }
                            
                            // Notes Section
                            if let notes = book.memo, !notes.isEmpty {
                                BookDetailNotesSection(notes: notes)
                                    .padding(.horizontal)
                            }
                            
                            // Additional Info
                            BookDetailAdditionalInfo(book: book)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("読書の進捗を更新", systemImage: "slider.horizontal.3")
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
        .task {
            await loadBook()
        }
        .refreshable {
            await loadBook()
        }
        .sheet(isPresented: $showingEditSheet) {
            if let book = book {
                EditBookView(book: book) { updatedBook in
                    Task {
                        do {
                            try await bookStore.updateBook(updatedBook)
                            self.book = updatedBook
                        } catch {
                            print("Error updating book: \(error)")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingBookInfoEdit) {
            if let book = book {
                BookInfoEditView(book: book) { updatedBook in
                    do {
                        try await bookStore.updateBook(updatedBook)
                        self.book = updatedBook
                    } catch {
                        print("Error updating book: \(error)")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingMemoryView) {
            BookMemoryTabView(bookId: bookId)
        }
        .fullScreenCover(isPresented: $showingSummaryView) {
            if let book = book {
                SummaryView(book: book)
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func loadBook() async {
        
        // BookStoreから本を取得
        book = bookStore.getBook(id: bookId)
        
        // もしBookStoreにない場合はロード
        if book == nil {
            await bookStore.loadBooks()
            book = bookStore.getBook(id: bookId)
        }
    }
    
    private func deleteBook() async {
        
        do {
            try await bookStore.deleteBook(id: bookId)
            dismiss()
        } catch {
            print("Error deleting book: \(error)")
        }
    }
    
    
    private func updateStatus(to newStatus: ReadingStatus) async {
        guard let book = book,
              book.status != newStatus else { return }
        
        do {
            var updatedBook = book.updated(status: newStatus)
            
            // ステータスに応じて日付を更新
            switch newStatus {
            case .reading:
                if book.startDate == nil {
                    updatedBook = updatedBook.updated(startDate: Date())
                }
            case .completed:
                updatedBook = updatedBook.updated(completedDate: Date())
                if book.startDate == nil {
                    updatedBook = updatedBook.updated(startDate: Date())
                }
            case .dnf:
                updatedBook = updatedBook.updated(completedDate: Date())
            case .wantToRead:
                // 読みたいに戻した場合は日付をクリア
                updatedBook = updatedBook.updatedWithClear(
                    startDate: .clear,
                    completedDate: .clear
                )
            }
            
            try await bookStore.updateBook(updatedBook)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.book = updatedBook
                showStatusChangeAnimation = true
            }
            
            // アニメーションを非表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showStatusChangeAnimation = false
                }
            }
            
        } catch {
            print("Error updating status: \(error)")
        }
    }
}
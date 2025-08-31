import SwiftUI
import PhotosUI

struct BookDetailView: View {
    let bookId: String
    
    @State private var book: Book?
    @State private var isLoading = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSummaryView = false
    @State private var showingMemoryView = false
    @State private var isUpdatingStatus = false
    @State private var showStatusChangeAnimation = false
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss
    
    private let bookRepository = BookRepository.shared
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
                        heroSection(book: book)
                        
                        VStack(spacing: MemorySpacing.lg) {
                            // Action Buttons
                            actionButtonsSection(book: book)
                                .padding(.horizontal)
                            
                            // Status and Rating
                            statusAndRatingSection(book: book)
                                .padding(.horizontal)
                            
                            // AI Summary Section
                            if let summary = book.aiSummary {
                                aiSummarySection(summary: summary)
                                    .padding(.horizontal)
                            }
                            
                            // Notes Section
                            if let notes = book.memo, !notes.isEmpty {
                                notesSection(notes: notes)
                                    .padding(.horizontal)
                            }
                            
                            // Additional Info
                            additionalInfoSection(book: book)
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
                        Label("編集", systemImage: "pencil")
                    }
                    
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
                EditBookView(book: book) { _ in
                    Task {
                        await loadBook()
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

// Rating Selector
    
    private func loadBook() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        isLoading = true
        do {
            book = try await bookRepository.getBook(bookId: bookId)
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
    
    @ViewBuilder
    private func heroSection(book: Book) -> some View {
        VStack(spacing: 0) {
            // Cover Image with gradient overlay
            ZStack(alignment: .bottom) {
                // Background
                Color(.secondarySystemBackground)
                    .frame(height: 320)
                
                // Cover Image
                RemoteImage(imageId: book.coverImageId, contentMode: .fill)
                    .frame(height: 320)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Book Info Overlay
                VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                    Text(book.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if !book.displayAuthor.isEmpty {
                        Text(book.displayAuthor)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    if let publisher = book.publisher {
                        Text(publisher)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 320)
        }
    }
    
    @ViewBuilder
    private func actionButtonsSection(book: Book) -> some View {
        VStack(spacing: MemorySpacing.sm) {
            // Memory (Chat & Note) Button
            Button {
                showingMemoryView = true
            } label: {
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
                showingSummaryView = true
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
                        Text(book.aiSummary != nil ? "AI要約を見る" : "AI要約を生成")
                            .font(.headline)
                            .foregroundColor(Color(.label))
                        Text(book.aiSummary != nil ? "生成された要約を確認" : "読書メモから要点をまとめます")
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
        }
    }
    
    private func statusAndRatingSection(book: Book) -> some View {
        VStack(spacing: MemorySpacing.lg) {
            // Status Section
            VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                Text("読書ステータス")
                    .font(.headline)
                
                HStack(spacing: MemorySpacing.sm) {
                    ForEach([ReadingStatus.wantToRead, .reading, .completed, .dnf], id: \.self) { status in
                        Button {
                            Task {
                                await updateStatus(to: status)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: statusIcon(for: status))
                                    .font(.system(size: 24))
                                Text(status.displayName)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MemorySpacing.sm)
                            .background(
                                book.status == status ?
                                statusColor(for: status).opacity(0.2) :
                                Color(.tertiarySystemBackground)
                            )
                            .foregroundColor(
                                book.status == status ?
                                statusColor(for: status) :
                                Color(.label)
                            )
                            .cornerRadius(MemoryRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                    .stroke(
                                        book.status == status ?
                                        statusColor(for: status) :
                                        Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isUpdatingStatus)
                    }
                }
            }
            
            // Rating Section
            if book.status == .completed {
                VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                    Text("評価")
                        .font(.headline)
                    
                    RatingSelector(book: book)
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
        }
    }
    
    @ViewBuilder
    private func aiSummarySection(summary: String) -> some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                Text("AI要約")
                    .font(.headline)
            }
            
            Text(summary)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(MemoryRadius.medium)
        }
    }
    
    @ViewBuilder
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            HStack {
                Image(systemName: "note.text")
                Text("メモ")
                    .font(.headline)
            }
            
            Text(notes)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(MemoryRadius.medium)
        }
    }
    
    @ViewBuilder
    private func additionalInfoSection(book: Book) -> some View {
        VStack(alignment: .leading, spacing: MemorySpacing.md) {
            Text("詳細情報")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                if let isbn = book.isbn {
                    HStack {
                        Text("ISBN")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        Text(isbn)
                            .font(.caption)
                    }
                }
                
                if let pageCount = book.pageCount {
                    HStack {
                        Text("ページ数")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        Text("\(pageCount)ページ")
                            .font(.caption)
                    }
                }
                
                if let publishedDate = book.publishedDate {
                    HStack {
                        Text("出版日")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        Text(publishedDate, style: .date)
                            .font(.caption)
                    }
                }
                
                if book.status == .completed, let completedDate = book.completedDate {
                    HStack {
                        Text("読了日")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        Text(completedDate, style: .date)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(MemoryRadius.medium)
            
            // Purchase Button
            if let purchaseUrl = book.purchaseUrl, !purchaseUrl.isEmpty {
                Button {
                    if let url = URL(string: purchaseUrl) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16))
                        Text("オンラインで購入")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MemoryTheme.Colors.goldenMemory)
                    .cornerRadius(MemoryRadius.medium)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func updateStatus(to newStatus: ReadingStatus) async {
        guard let userId = authService.currentUser?.uid,
              let book = book,
              book.status != newStatus else { return }
        
        isUpdatingStatus = true
        
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
            
            try await bookRepository.updateBook(updatedBook)
            
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
        
        isUpdatingStatus = false
    }
    
    private func statusIcon(for status: ReadingStatus) -> String {
        switch status {
        case .wantToRead:
            return "bookmark"
        case .reading:
            return "book.pages"
        case .completed:
            return "checkmark.circle"
        case .dnf:
            return "xmark.circle"
        }
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .wantToRead:
            return MemoryTheme.Colors.primaryBlue
        case .reading:
            return MemoryTheme.Colors.warmCoral
        case .completed:
            return MemoryTheme.Colors.success
        case .dnf:
            return Color(.systemGray)
        }
    }
}

struct RatingSelector: View {
    let book: Book
    @State private var rating: Double?
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    
    var body: some View {
        HStack(spacing: MemorySpacing.xs) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    Task {
                        await updateRating(to: Double(value))
                    }
                } label: {
                    Image(systemName: getRatingIcon(for: value))
                        .font(.system(size: 28))
                        .foregroundColor(MemoryTheme.Colors.goldenMemory)
                }
            }
        }
        .onAppear {
            rating = book.rating
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
    
    private func updateRating(to newRating: Double) async {
        guard let userId = authService.currentUser?.uid else { return }
        
        let targetRating = rating == newRating ? nil : newRating
        
        do {
            let updatedBook = book.updated(rating: targetRating)
            try await bookRepository.updateBook(updatedBook)
            
            withAnimation {
                rating = targetRating
            }
        } catch {
            print("Error updating rating: \(error)")
        }
    }
}
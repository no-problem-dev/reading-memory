import SwiftUI

struct BookInfoEditView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let onSave: (Book) async -> Void
    
    @State private var title: String
    @State private var author: String
    @State private var publisher: String
    @State private var isbn: String
    @State private var pageCount: String
    @State private var description: String
    @State private var coverImageId: String?
    @State private var publishedDate: Date
    @State private var hasPublishedDate: Bool
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showImagePicker = false
    
    init(book: Book, onSave: @escaping (Book) async -> Void) {
        self.book = book
        self.onSave = onSave
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _publisher = State(initialValue: book.publisher ?? "")
        _isbn = State(initialValue: book.isbn ?? "")
        _pageCount = State(initialValue: book.pageCount != nil ? "\(book.pageCount!)" : "")
        _description = State(initialValue: book.description ?? "")
        _coverImageId = State(initialValue: book.coverImageId)
        _publishedDate = State(initialValue: book.publishedDate ?? Date())
        _hasPublishedDate = State(initialValue: book.publishedDate != nil)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MemorySpacing.lg) {
                    // 表紙画像セクション
                    coverImageSection
                    
                    // 基本情報セクション
                    VStack(spacing: MemorySpacing.md) {
                        sectionHeader(icon: "book.closed", title: "基本情報", color: MemoryTheme.Colors.primaryBlue)
                        
                        VStack(alignment: .leading, spacing: MemorySpacing.md) {
                            // タイトル
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Label("タイトル", systemImage: "textformat")
                                    .font(MemoryTheme.Fonts.caption())
                                    .fontWeight(.medium)
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                
                                TextField("本のタイトル", text: $title)
                                    .font(MemoryTheme.Fonts.body())
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(MemoryTheme.Colors.inkPale.opacity(0.5))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(title.isEmpty ? Color.clear : MemoryTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // 著者
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Label("著者", systemImage: "person")
                                    .font(MemoryTheme.Fonts.caption())
                                    .fontWeight(.medium)
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                
                                TextField("著者名", text: $author)
                                    .font(MemoryTheme.Fonts.body())
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(MemoryTheme.Colors.inkPale.opacity(0.5))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(author.isEmpty ? Color.clear : MemoryTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // 出版社
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Label("出版社", systemImage: "building.2")
                                    .font(MemoryTheme.Fonts.caption())
                                    .fontWeight(.medium)
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                
                                TextField("出版社名", text: $publisher)
                                    .font(MemoryTheme.Fonts.body())
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(MemoryTheme.Colors.inkPale.opacity(0.5))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(publisher.isEmpty ? Color.clear : MemoryTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // 出版日
                            VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                                HStack {
                                    Label("出版日", systemImage: "calendar")
                                        .font(MemoryTheme.Fonts.caption())
                                        .fontWeight(.medium)
                                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $hasPublishedDate)
                                        .tint(MemoryTheme.Colors.primaryBlue)
                                }
                                
                                if hasPublishedDate {
                                    DatePicker("", selection: $publishedDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(MemoryTheme.Colors.primaryBlue.opacity(0.05))
                                        )
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MemoryTheme.Colors.cardBackground)
                                .shadow(color: MemoryTheme.Colors.primaryBlue.opacity(0.05), radius: 10, y: 4)
                        )
                    }
                    
                    // 詳細情報セクション
                    VStack(spacing: MemorySpacing.md) {
                        sectionHeader(icon: "info.circle", title: "詳細情報", color: MemoryTheme.Colors.primaryBlue)
                        
                        VStack(alignment: .leading, spacing: MemorySpacing.md) {
                            // ISBN
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Label("ISBN", systemImage: "barcode")
                                    .font(MemoryTheme.Fonts.caption())
                                    .fontWeight(.medium)
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                
                                TextField("ISBN番号", text: $isbn)
                                    .font(MemoryTheme.Fonts.body())
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(MemoryTheme.Colors.inkPale.opacity(0.5))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isbn.isEmpty ? Color.clear : MemoryTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 1)
                                    )
                                    .keyboardType(.numberPad)
                            }
                            
                            // ページ数
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Label("ページ数", systemImage: "doc.text")
                                    .font(MemoryTheme.Fonts.caption())
                                    .fontWeight(.medium)
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                
                                TextField("ページ数", text: $pageCount)
                                    .font(MemoryTheme.Fonts.body())
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(MemoryTheme.Colors.inkPale.opacity(0.5))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(pageCount.isEmpty ? Color.clear : MemoryTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 1)
                                    )
                                    .keyboardType(.numberPad)
                            }
                            
                            // 説明
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                Label("説明・あらすじ", systemImage: "text.alignleft")
                                    .font(MemoryTheme.Fonts.caption())
                                    .fontWeight(.medium)
                                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                
                                ZStack(alignment: .topLeading) {
                                    if description.isEmpty {
                                        Text("本の内容や感想をメモできます")
                                            .font(MemoryTheme.Fonts.body())
                                            .foregroundColor(MemoryTheme.Colors.inkGray.opacity(0.5))
                                            .padding(.horizontal, 12)
                                            .padding(.top, 12)
                                    }
                                    
                                    TextEditor(text: $description)
                                        .font(MemoryTheme.Fonts.body())
                                        .scrollContentBackground(.hidden)
                                        .padding(8)
                                        .background(Color.clear)
                                }
                                .frame(minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(MemoryTheme.Colors.inkPale.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(description.isEmpty ? Color.clear : MemoryTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MemoryTheme.Colors.cardBackground)
                                .shadow(color: MemoryTheme.Colors.primaryBlue.opacity(0.05), radius: 10, y: 4)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("本の情報を編集")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(MemoryTheme.Colors.secondaryBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await saveChanges()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("保存")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(
                            isLoading || title.isEmpty || author.isEmpty
                                ? MemoryTheme.Colors.inkGray
                                : MemoryTheme.Colors.primaryBlue
                        )
                    }
                    .disabled(isLoading || title.isEmpty || author.isEmpty)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(ProgressView())
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showImagePicker) {
                // TODO: 画像選択機能の実装
                Text("画像選択機能は後日実装予定")
            }
        }
    }
    
    private var coverImageSection: some View {
        VStack(spacing: MemorySpacing.md) {
            // 現在の表紙画像
            Button(action: {
                showImagePicker = true
            }) {
                ZStack {
                    if let imageId = coverImageId {
                        RemoteImage(imageId: imageId, contentMode: .fit)
                            .frame(width: 150, height: 210)
                            .cornerRadius(12)
                            .shadow(color: MemoryTheme.Colors.primaryBlue.opacity(0.2), radius: 8, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.primaryBlue.opacity(0.05),
                                        MemoryTheme.Colors.primaryBlue.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 150, height: 210)
                            .overlay(
                                VStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 36))
                                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                    Text("タップして画像を選択")
                                        .font(MemoryTheme.Fonts.caption())
                                        .fontWeight(.medium)
                                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                }
                            )
                    }
                    
                    // ホバーオーバーレイ
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlue.opacity(0.7),
                                    MemoryTheme.Colors.primaryBlue.opacity(0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 150, height: 210)
                        .overlay(
                            VStack(spacing: MemorySpacing.xs) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                Text("変更")
                                    .font(MemoryTheme.Fonts.body())
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        )
                        .opacity(0)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("表紙画像をタップして変更")
                .font(MemoryTheme.Fonts.footnote())
                .foregroundColor(MemoryTheme.Colors.inkGray.opacity(0.8))
        }
    }
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: MemorySpacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(MemoryTheme.Fonts.headline())
                .fontWeight(.bold)
                .foregroundColor(MemoryTheme.Colors.inkBlack)
            
            Spacer()
        }
        .padding(.bottom, MemorySpacing.xs)
    }
    
    private func saveChanges() async {
        guard !title.isEmpty && !author.isEmpty else { return }
        
        isLoading = true
        
        // 本の情報を更新
        let updatedBook = Book(
                id: book.id,
                isbn: isbn.isEmpty ? nil : isbn,
                title: title,
                author: author,
                publisher: publisher.isEmpty ? nil : publisher,
                publishedDate: hasPublishedDate ? publishedDate : nil,
                pageCount: Int(pageCount),
                description: description.isEmpty ? nil : description,
                coverImageId: coverImageId,
                dataSource: book.dataSource,
                purchaseUrl: book.purchaseUrl,
                status: book.status,
                rating: book.rating,
                readingProgress: book.readingProgress,
                currentPage: book.currentPage,
                addedDate: book.addedDate,
                startDate: book.startDate,
                completedDate: book.completedDate,
                lastReadDate: book.lastReadDate,
                priority: book.priority,
                plannedReadingDate: book.plannedReadingDate,
                reminderEnabled: book.reminderEnabled,
                purchaseLinks: book.purchaseLinks,
                memo: book.memo,
                tags: book.tags,
                genre: book.genre,
                aiSummary: book.aiSummary,
                summaryGeneratedAt: book.summaryGeneratedAt,
                createdAt: book.createdAt,
                updatedAt: Date()
            )
        
        await onSave(updatedBook)
        
        await MainActor.run {
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    BookInfoEditView(
        book: Book(
            id: "1",
            isbn: "1234567890",
            title: "サンプルブック",
            author: "著者名",
            dataSource: .googleBooks,
            status: .reading,
            addedDate: Date(),
            createdAt: Date(),
            updatedAt: Date()
        ),
        onSave: { _ in }
    )
}
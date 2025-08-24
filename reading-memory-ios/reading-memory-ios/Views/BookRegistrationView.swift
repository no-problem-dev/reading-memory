import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct BookRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ServiceContainer.shared.makeBookRegistrationViewModel()
    
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var publisher = ""
    @State private var publishedDate = Date()
    @State private var pageCount = ""
    @State private var description = ""
    @State private var showDatePicker = false
    @State private var hasPublishedDate = false
    @State private var coverUrl: String?
    @State private var selectedStatus: ReadingStatus = .wantToRead
    
    let prefilledBook: Book?
    
    init(prefilledBook: Book? = nil) {
        self.prefilledBook = prefilledBook
        if let book = prefilledBook {
            _selectedStatus = State(initialValue: book.status)
        }
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
                        // Cover image preview
                        if let url = coverUrl, !url.isEmpty {
                            coverImageSection(url: url)
                                .padding(.horizontal, MemorySpacing.md)
                        }
                        
                        // Basic information card
                        MemoryCard {
                            VStack(spacing: MemorySpacing.lg) {
                                sectionHeader(
                                    icon: "book.fill",
                                    title: "基本情報",
                                    color: MemoryTheme.Colors.primaryBlue
                                )
                                
                                VStack(spacing: MemorySpacing.md) {
                                    MemoryTextField(
                                        placeholder: "タイトル",
                                        text: $title,
                                        icon: "textformat",
                                        isRequired: true
                                    )
                                    
                                    MemoryTextField(
                                        placeholder: "著者",
                                        text: $author,
                                        icon: "person.fill",
                                        isRequired: true
                                    )
                                    
                                    MemoryTextField(
                                        placeholder: "ISBN",
                                        text: $isbn,
                                        icon: "barcode",
                                        keyboardType: .numberPad
                                    )
                                    
                                    MemoryTextField(
                                        placeholder: "出版社",
                                        text: $publisher,
                                        icon: "building.2.fill"
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        
                        // Reading status card
                        MemoryCard {
                            VStack(spacing: MemorySpacing.lg) {
                                sectionHeader(
                                    icon: "bookmark.fill",
                                    title: "読書ステータス",
                                    color: MemoryTheme.Colors.primaryBlue
                                )
                                
                                VStack(spacing: MemorySpacing.sm) {
                                    ForEach(ReadingStatus.allCases, id: \.self) { status in
                                        statusOption(status)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        
                        // Detailed information card
                        MemoryCard {
                            VStack(spacing: MemorySpacing.lg) {
                                sectionHeader(
                                    icon: "info.circle.fill",
                                    title: "詳細情報",
                                    color: MemoryTheme.Colors.warmCoral
                                )
                                
                                VStack(spacing: MemorySpacing.md) {
                                    // Published date
                                    publishedDateSection
                                    
                                    // Page count
                                    MemoryTextField(
                                        placeholder: "ページ数",
                                        text: $pageCount,
                                        icon: "doc.text.fill",
                                        keyboardType: .numberPad
                                    )
                                    
                                    // Description
                                    descriptionSection
                                }
                            }
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.bottom, MemorySpacing.xl)
                    }
                    .padding(.top, MemorySpacing.lg)
                }
                
                // Loading overlay
                if viewModel.isLoading {
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
            .navigationTitle("本を登録")
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
                        saveBook()
                    } label: {
                        Text("保存")
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(title.isEmpty || author.isEmpty ? MemoryTheme.Colors.inkLightGray : MemoryTheme.Colors.primaryBlue)
                    }
                    .disabled(title.isEmpty || author.isEmpty)
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
            }
        }
                .onAppear {
            if let book = prefilledBook {
                title = book.title
                author = book.author
                isbn = book.isbn ?? ""
                publisher = book.publisher ?? ""
                if let date = book.publishedDate {
                    publishedDate = date
                    hasPublishedDate = true
                }
                if let pages = book.pageCount {
                    pageCount = String(pages)
                }
                description = book.description ?? ""
                coverUrl = book.coverImageUrl
            }
        }
    }
    
    // MARK: - Components
    
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
    
    private func statusOption(_ status: ReadingStatus) -> some View {
        Button {
            selectedStatus = status
        } label: {
            HStack(spacing: MemorySpacing.md) {
                Image(systemName: status.icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedStatus == status ? .white : MemoryTheme.Colors.inkGray)
                
                Text(status.displayName)
                    .font(MemoryTheme.Fonts.body())
                    .foregroundColor(selectedStatus == status ? .white : MemoryTheme.Colors.inkBlack)
                
                Spacer()
                
                if selectedStatus == status {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(MemorySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .fill(selectedStatus == status ? 
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlue,
                                MemoryTheme.Colors.primaryBlueDark
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) : LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.cardBackground,
                                MemoryTheme.Colors.cardBackground
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MemoryRadius.medium)
                            .stroke(
                                selectedStatus == status ? Color.clear : MemoryTheme.Colors.inkPale,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .if(selectedStatus == status) { view in
            view.memoryShadow(.soft)
        }
    }
    
    private func coverImageSection(url: String) -> some View {
        VStack(spacing: MemorySpacing.md) {
            Text("表紙プレビュー")
                .font(MemoryTheme.Fonts.caption())
                .foregroundColor(MemoryTheme.Colors.inkGray)
            
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .cornerRadius(MemoryRadius.medium)
                        .memoryShadow(.medium)
                case .failure(_):
                    VStack(spacing: MemorySpacing.sm) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(MemoryTheme.Colors.inkLightGray)
                        Text("画像を読み込めませんでした")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(MemoryTheme.Colors.cardBackground)
                    .cornerRadius(MemoryRadius.medium)
                case .empty:
                    ProgressView()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(MemoryTheme.Colors.cardBackground)
                        .cornerRadius(MemoryRadius.medium)
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
    
    private var publishedDateSection: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.xs) {
            HStack {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                    Text("出版日")
                        .font(MemoryTheme.Fonts.subheadline())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                }
                
                Spacer()
                
                if hasPublishedDate {
                    Text(publishedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(MemoryTheme.Fonts.subheadline())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                        .padding(.horizontal, MemorySpacing.sm)
                        .padding(.vertical, MemorySpacing.xs)
                        .background(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                        .cornerRadius(MemoryRadius.small)
                        .onTapGesture {
                            withAnimation(MemoryTheme.Animation.fast) {
                                showDatePicker.toggle()
                            }
                        }
                } else {
                    Button {
                        withAnimation(MemoryTheme.Animation.fast) {
                            hasPublishedDate = true
                            showDatePicker = true
                        }
                    } label: {
                        Text("設定する")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            .padding(.horizontal, MemorySpacing.sm)
                            .padding(.vertical, MemorySpacing.xs)
                            .background(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                            .cornerRadius(MemoryRadius.full)
                    }
                }
            }
            
            if showDatePicker {
                DatePicker(
                    "",
                    selection: $publishedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(MemoryTheme.Colors.primaryBlue)
                .padding(.top, MemorySpacing.sm)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.xs) {
            HStack(spacing: MemorySpacing.xs) {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                Text("説明")
                    .font(MemoryTheme.Fonts.subheadline())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
            }
            
            TextEditor(text: $description)
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
    
    private func saveBook() {
        Task {
            let book: Book
            
            if let prefilledBook = prefilledBook {
                // API経由の本の場合、dataSourceとvisibilityを保持
                book = Book(
                    id: prefilledBook.id,
                    isbn: isbn.isEmpty ? prefilledBook.isbn : isbn.trimmingCharacters(in: .whitespacesAndNewlines),
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                    publisher: publisher.isEmpty ? prefilledBook.publisher : publisher.trimmingCharacters(in: .whitespacesAndNewlines),
                    publishedDate: hasPublishedDate ? publishedDate : prefilledBook.publishedDate,
                    pageCount: Int(pageCount) ?? prefilledBook.pageCount,
                    description: description.isEmpty ? prefilledBook.description : description.trimmingCharacters(in: .whitespacesAndNewlines),
                    coverImageUrl: coverUrl ?? prefilledBook.coverImageUrl,
                    dataSource: prefilledBook.dataSource,
                    status: prefilledBook.status,
                    addedDate: prefilledBook.addedDate,
                    createdAt: prefilledBook.createdAt,
                    updatedAt: Date()
                )
            } else {
                // 手動入力の本の場合
                guard let userId = AuthService.shared.currentUser?.uid else { return }
                book = Book(
                    id: UUID().uuidString,
                    isbn: isbn.isEmpty ? nil : isbn.trimmingCharacters(in: .whitespacesAndNewlines),
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                    publisher: publisher.isEmpty ? nil : publisher.trimmingCharacters(in: .whitespacesAndNewlines),
                    publishedDate: hasPublishedDate ? publishedDate : nil,
                    pageCount: Int(pageCount),
                    description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                    coverImageUrl: coverUrl,
                    dataSource: .manual,
                    status: selectedStatus,
                    addedDate: Date(),
                    createdAt: Date(),
                    updatedAt: Date()
                )
            }
            
            let success = await viewModel.registerBook(book)
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    BookRegistrationView()
        }
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
    @State private var coverImageId: String?
    @State private var selectedStatus: ReadingStatus = .wantToRead
    
    let isFromHome: Bool
    
    let prefilledBook: Book?
    let searchResult: BookSearchResult?
    
    init(prefilledBook: Book? = nil, isFromHome: Bool = false) {
        self.prefilledBook = prefilledBook
        self.searchResult = nil
        self.isFromHome = isFromHome
        if let book = prefilledBook {
            _selectedStatus = State(initialValue: book.status)
        } else {
            _selectedStatus = State(initialValue: isFromHome ? .reading : .wantToRead)
        }
    }
    
    init(searchResult: BookSearchResult, isFromHome: Bool = false) {
        self.prefilledBook = nil
        self.searchResult = searchResult
        self.isFromHome = isFromHome
        _selectedStatus = State(initialValue: isFromHome ? .reading : .wantToRead)
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
                        if let imageId = coverImageId, !imageId.isEmpty {
                            coverImageSection(imageId: imageId)
                                .padding(.horizontal, MemorySpacing.md)
                        } else if let coverImageUrl = searchResult?.coverImageUrl {
                            coverImageUrlSection(coverImageUrl: coverImageUrl)
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
                
            }
            .memoryLoading(isLoading: viewModel.isLoading, message: "保存中...")
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
        .scrollDismissesKeyboard(.interactively)
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
                coverImageId = book.coverImageId
            } else if let searchResult = searchResult {
                title = searchResult.title
                author = searchResult.author
                isbn = searchResult.isbn ?? ""
                publisher = searchResult.publisher ?? ""
                if let date = searchResult.publishedDate {
                    publishedDate = date
                    hasPublishedDate = true
                }
                if let pages = searchResult.pageCount {
                    pageCount = String(pages)
                }
                description = searchResult.description ?? ""
                // 検索結果の画像は後でアップロードされる
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
    
    private func coverImageSection(imageId: String) -> some View {
        VStack(spacing: MemorySpacing.md) {
            Text("表紙プレビュー")
                .font(MemoryTheme.Fonts.caption())
                .foregroundColor(MemoryTheme.Colors.inkGray)
            
            RemoteImage(imageId: imageId)
                .frame(maxHeight: 250)
                .cornerRadius(MemoryRadius.medium)
                .memoryShadow(.medium)
        }
    }
    
    private func coverImageUrlSection(coverImageUrl: String) -> some View {
        VStack(spacing: MemorySpacing.md) {
            Text("表紙プレビュー")
                .font(MemoryTheme.Fonts.caption())
                .foregroundColor(MemoryTheme.Colors.inkGray)
            
            RemoteImage(urlString: coverImageUrl)
                .frame(maxHeight: 250)
                .cornerRadius(MemoryRadius.medium)
                .memoryShadow(.medium)
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
            
            MemoryTextEditor(placeholder: "本の概要や感想を入力", text: $description, minHeight: 120)
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
                    coverImageId: coverImageId ?? prefilledBook.coverImageId,
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
                    coverImageId: coverImageId,
                    dataSource: .manual,
                    status: selectedStatus,
                    addedDate: Date(),
                    createdAt: Date(),
                    updatedAt: Date()
                )
            }
            
            // searchResultがある場合は専用のメソッドを使用
            let success: Bool
            if let searchResult = searchResult {
                // 検索結果からの登録（入力された情報で上書き）
                var updatedSearchResult = searchResult
                // フォームで編集された情報を反映（簡易的な実装）
                let modifiedSearchResult = BookSearchResult(
                    isbn: isbn.isEmpty ? searchResult.isbn : isbn,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                    publisher: publisher.isEmpty ? searchResult.publisher : publisher.trimmingCharacters(in: .whitespacesAndNewlines),
                    publishedDate: hasPublishedDate ? publishedDate : searchResult.publishedDate,
                    pageCount: Int(pageCount) ?? searchResult.pageCount,
                    description: description.isEmpty ? searchResult.description : description.trimmingCharacters(in: .whitespacesAndNewlines),
                    coverImageUrl: searchResult.coverImageUrl,
                    dataSource: searchResult.dataSource,
                    affiliateUrl: searchResult.affiliateUrl
                )
                success = await viewModel.registerBookFromSearchResult(modifiedSearchResult, status: selectedStatus)
            } else {
                success = await viewModel.registerBook(book)
            }
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    BookRegistrationView(isFromHome: false)
        }
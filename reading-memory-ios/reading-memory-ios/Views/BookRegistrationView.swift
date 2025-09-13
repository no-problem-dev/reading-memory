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
    @Environment(BookStore.self) private var bookStore
    @Environment(SubscriptionStateStore.self) private var subscriptionState
    @Environment(AnalyticsService.self) private var analytics
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
    
    let prefilledBook: Book?
    let searchResult: BookSearchResult?
    let defaultStatus: ReadingStatus
    let onCompletion: ((Book) -> Void)?
    let registrationSource: String
    
    init(prefilledBook: Book? = nil, defaultStatus: ReadingStatus = .wantToRead, onCompletion: ((Book) -> Void)? = nil) {
        self.prefilledBook = prefilledBook
        self.searchResult = nil
        self.defaultStatus = defaultStatus
        self.onCompletion = onCompletion
        self.registrationSource = "manual_entry"
        if let book = prefilledBook {
            _selectedStatus = State(initialValue: book.status)
        } else {
            _selectedStatus = State(initialValue: defaultStatus)
        }
    }
    
    init(searchResult: BookSearchResult, defaultStatus: ReadingStatus = .wantToRead, registrationSource: String = "manual_search", onCompletion: ((Book) -> Void)? = nil) {
        self.prefilledBook = nil
        self.searchResult = searchResult
        self.defaultStatus = defaultStatus
        self.onCompletion = onCompletion
        self.registrationSource = registrationSource
        _selectedStatus = State(initialValue: defaultStatus)
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
                                    color: MemoryTheme.Colors.goldenMemory
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
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .onAppear {
            viewModel.setSubscriptionStateStore(subscriptionState)
            
            // デバッグ：初期状態をチェック
            subscriptionState.updateTotalBookCount()
            print("DEBUG onAppear: Total book count: \(subscriptionState.totalBookCount)")
            print("DEBUG onAppear: Can add book: \(subscriptionState.canAddBook())")
            print("DEBUG onAppear: Total books in store: \(bookStore.allBooks.count)")
            
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
                        .padding(.horizontal, MemorySpacing.md)
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
    
    @State private var isRegistering = false
    
    private func saveBook() {
        // 二重登録を防ぐ
        guard !isRegistering else { return }
        isRegistering = true
        
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
                // APIはidTokenで認証するため、userIdのチェックは不要
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
            
            // 制限チェック
            subscriptionState.updateTotalBookCount()
            
            print("DEBUG: Total book count: \(subscriptionState.totalBookCount)")
            print("DEBUG: Can add book: \(subscriptionState.canAddBook())")
            print("DEBUG: Is premium: \(subscriptionState.isPremium)")
            
            guard subscriptionState.canAddBook() else {
                print("DEBUG: Book limit reached, showing paywall")
                viewModel.showPaywall = true
                isRegistering = false
                return
            }
            
            do {
                let registeredBook: Book
                
                // 検索結果から来た場合と手動入力の場合で処理を分ける
                if let searchResult = searchResult {
                    // 検索結果から本を登録（画像のダウンロード・アップロードを含む）
                    registeredBook = try await bookStore.addBookFromSearchResult(searchResult, status: selectedStatus)
                } else {
                    // 手動入力の本を登録
                    registeredBook = try await bookStore.addBook(book)
                }
                
                // SubscriptionStateStoreのカウントを即座に更新
                subscriptionState.updateTotalBookCount()
                
                // 本追加イベントを送信
                let dataSource = searchResult?.dataSource.rawValue ?? "manual"
                analytics.track(AnalyticsEvent.bookEvent(event: .added(
                    bookId: registeredBook.id,
                    method: registrationSource,
                    source: dataSource
                )))
                
                // 成功時の処理
                onCompletion?(registeredBook)
                dismiss()
            } catch {
                print("Error registering book: \(error)")
                isRegistering = false
                // エラー表示
                viewModel.handleError(error)
            }
        }
    }
}

#Preview {
    BookRegistrationView(defaultStatus: .wantToRead)
        }
import SwiftUI

struct DiscoveryView: View {
    @Environment(SubscriptionStateStore.self) private var subscriptionState
    @Environment(AnalyticsService.self) private var analytics
    @State private var viewModel = WantToReadViewModel()
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showBarcodeScanner = false
    @State private var navigationPath = NavigationPath()
    @State private var showPaywall = false
    @State private var showFullList = false
    @State private var selectedBook: Book?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        MemoryTheme.Colors.secondaryBackground,
                        MemoryTheme.Colors.background
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // ヘッダー部分
                        DiscoveryHeaderView(
                            showSearch: $showSearch,
                            showBarcodeScanner: $showBarcodeScanner,
                            showPaywall: $showPaywall,
                            subscriptionState: subscriptionState
                        )
                        .padding(.top, MemorySpacing.lg)
                        
                        // メインコンテンツ
                        if viewModel.books.isEmpty {
                            EmptyWantToReadStateView(showSearch: $showSearch)
                                .padding(.top, MemorySpacing.xxl)
                        } else {
                            // 読みたいリスト表示
                            WantToReadContentView(
                                books: viewModel.books,
                                navigationPath: $navigationPath,
                                selectedBook: $selectedBook,
                                showFullList: $showFullList
                            )
                            .padding(.top, MemorySpacing.xl)
                        }
                    }
                    .padding(.bottom, MemorySpacing.xxl)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Book.self) { book in
                BookDetailView(bookId: book.id)
            }
            .sheet(isPresented: $showSearch) {
                NavigationStack {
                    BookSearchView()
                }
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showFullList) {
                NavigationStack {
                    WantToReadListView()
                }
            }
            .fullScreenCover(item: $selectedBook) { book in
                PurchaseOptionsView(book: book)
            }
            .task {
                await viewModel.loadBooks()
            }
            .onAppear {
                analytics.track(AnalyticsEvent.screenView(screen: .discovery))
            }
            .onChange(of: showSearch) { _, newValue in
                if newValue {
                    analytics.track(AnalyticsEvent.userAction(action: .tabSelected(tabName: "search")))
                }
            }
            .onChange(of: showFullList) { _, newValue in
                if newValue {
                    analytics.track(AnalyticsEvent.userAction(action: .tabSelected(tabName: "want_to_read")))
                }
            }
        }
    }
}

// MARK: - Header View
struct DiscoveryHeaderView: View {
    @Binding var showSearch: Bool
    @Binding var showBarcodeScanner: Bool
    @Binding var showPaywall: Bool
    let subscriptionState: SubscriptionStateStore
    
    var body: some View {
        VStack(spacing: MemorySpacing.lg) {
            // タイトル部分
            VStack(spacing: MemorySpacing.xs) {
                Text("発見")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("新しい本との出会いを")
                    .font(MemoryTheme.Fonts.callout())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
            }
            
            // 検索バー
            Button {
                showSearch = true
            } label: {
                HStack(spacing: MemorySpacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                    
                    Text("本を探す...")
                        .font(MemoryTheme.Fonts.body())
                        .foregroundColor(MemoryTheme.Colors.inkLightGray)
                    
                    Spacer()
                    
                    // バーコードスキャン
                    Button {
                        if subscriptionState.canScanBarcode {
                            showBarcodeScanner = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 18))
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            
                            if !subscriptionState.canScanBarcode {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Circle().fill(MemoryTheme.Colors.inkGray))
                                    .offset(x: 12, y: -12)
                            }
                        }
                    }
                }
                .padding(.horizontal, MemorySpacing.md)
                .padding(.vertical, MemorySpacing.md)
                .background(MemoryTheme.Colors.cardBackground)
                .cornerRadius(MemoryRadius.full)
                .memoryShadow(.soft)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, MemorySpacing.lg)
    }
}

// MARK: - Want To Read Content
struct WantToReadContentView: View {
    let books: [Book]
    @Binding var navigationPath: NavigationPath
    @Binding var selectedBook: Book?
    @Binding var showFullList: Bool
    
    // 優先度でソートされた本のリスト
    private var sortedBooks: [Book] {
        books.sorted { book1, book2 in
            // まず優先度で比較
            if book1.wantToReadPriority != book2.wantToReadPriority {
                return book1.wantToReadPriority.sortOrder < book2.wantToReadPriority.sortOrder
            }
            // 優先度が同じ場合は待ち時間（古い順）
            return book1.wantToReadDate ?? book1.addedDate < book2.wantToReadDate ?? book2.addedDate
        }
    }
    
    var body: some View {
        VStack(spacing: MemorySpacing.xl) {
            // 統計情報セクション
            ReadingStatsSection(bookCount: books.count)
            
            // 本のリストセクション
            VStack(alignment: .leading, spacing: MemorySpacing.lg) {
                // セクションヘッダー
                HStack {
                    Text("読みたい本")
                        .font(MemoryTheme.Fonts.title2())
                        .fontWeight(.bold)
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                    
                    Spacer()
                    
                    if books.count > 5 {
                        Button("すべて見る") {
                            showFullList = true
                        }
                        .font(MemoryTheme.Fonts.subheadline())
                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                }
                .padding(.horizontal, MemorySpacing.lg)
                
                // 読みたい本リスト
                VStack(spacing: MemorySpacing.md) {
                    ForEach(sortedBooks.prefix(5), id: \.id) { book in
                        PriorityBookCard(
                            book: book,
                            rank: sortedBooks.firstIndex(where: { $0.id == book.id }) ?? 0,
                            navigationPath: $navigationPath,
                            onPurchaseTap: {
                                selectedBook = book
                            }
                        )
                    }
                }
                .padding(.horizontal, MemorySpacing.lg)
                
                // 残りの本がある場合
                if books.count > 5 {
                    RemainingBooksSection(
                        remainingBooks: Array(sortedBooks.dropFirst(5)),
                        onShowAll: {
                            showFullList = true
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Reading Stats Section
struct ReadingStatsSection: View {
    let bookCount: Int
    
    var body: some View {
        HStack {
            HStack(spacing: MemorySpacing.xs) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MemoryTheme.Colors.goldenMemory)
                
                Text("\(bookCount)冊の本が待っています")
                    .font(MemoryTheme.Fonts.callout())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
            }
            
            Spacer()
        }
        .padding(.horizontal, MemorySpacing.lg)
    }
}


// MARK: - Priority Book Card
struct PriorityBookCard: View {
    let book: Book
    let rank: Int
    @Binding var navigationPath: NavigationPath
    let onPurchaseTap: () -> Void
    
    @State private var isPressed = false
    
    private var daysSinceAdded: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: book.wantToReadDate ?? book.addedDate, to: Date()).day ?? 0
        return max(0, days)
    }
    
    
    var body: some View {
        Button {
            navigationPath.append(book)
        } label: {
            HStack(spacing: MemorySpacing.md) {
                
                // 本の表紙
                BookCoverView(imageId: book.coverImageId, size: .custom(width: 80, height: 120))
                    .cornerRadius(MemoryRadius.small)
                    .memoryShadow(.soft)
                
                // 本の情報
                VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                    // タイトルと著者
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(MemoryTheme.Fonts.headline())
                            .fontWeight(.semibold)
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(book.author)
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .lineLimit(1)
                    }
                    
                    // 待ち時間
                    if daysSinceAdded > 0 {
                        Text("\(daysSinceAdded)日待機中")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                    
                    // メモまたは購入ボタン
                    if let memo = book.wantToReadMemo, !memo.isEmpty {
                        Text(memo)
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .italic()
                            .lineLimit(1)
                    }
                    
                    // 購入ボタン
                    Button(action: onPurchaseTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 12))
                            Text("購入する")
                                .font(MemoryTheme.Fonts.caption())
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlue,
                                    MemoryTheme.Colors.primaryBlueDark
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(MemoryRadius.small)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // 矢印
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(MemoryTheme.Colors.inkLightGray)
            }
            .padding(MemorySpacing.md)
            .background(MemoryTheme.Colors.cardBackground)
            .cornerRadius(MemoryRadius.large)
            .memoryShadow(.medium)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Remaining Books Section
struct RemainingBooksSection: View {
    let remainingBooks: [Book]
    let onShowAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.md) {
            Text("その他の読みたい本")
                .font(MemoryTheme.Fonts.caption())
                .foregroundColor(MemoryTheme.Colors.inkGray)
                .padding(.horizontal, MemorySpacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MemorySpacing.md) {
                    ForEach(remainingBooks.prefix(5), id: \.id) { book in
                        MiniBookCard(book: book)
                    }
                    
                    if remainingBooks.count > 5 {
                        ShowMoreCard(count: remainingBooks.count - 5, onTap: onShowAll)
                    }
                }
                .padding(.horizontal, MemorySpacing.lg)
            }
        }
    }
}

// MARK: - Mini Book Card
struct MiniBookCard: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: MemorySpacing.xs) {
            BookCoverView(imageId: book.coverImageId, size: .small)
                .cornerRadius(MemoryRadius.small)
                .memoryShadow(.soft)
            
            Text(book.title)
                .font(MemoryTheme.Fonts.caption())
                .foregroundColor(MemoryTheme.Colors.inkBlack)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

// MARK: - Show More Card
struct ShowMoreCard: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: MemorySpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: MemoryRadius.small)
                        .fill(MemoryTheme.Colors.secondaryBackground)
                        .frame(width: 60, height: 90)
                    
                    VStack(spacing: 4) {
                        Text("+\(count)")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                        
                        Text("もっと")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                }
                
                Text("すべて見る")
                    .font(MemoryTheme.Fonts.caption())
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View
struct EmptyWantToReadStateView: View {
    @Binding var showSearch: Bool
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: MemorySpacing.xl) {
            // アニメーションアイコン
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            MemoryTheme.Colors.goldenMemory.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 80 + CGFloat(index) * 30, height: 80 + CGFloat(index) * 30)
                        .scaleEffect(animateIcon ? 1.2 : 1.0)
                        .opacity(animateIcon ? 0 : 0.6)
                        .animation(
                            Animation.easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                            value: animateIcon
                        )
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.goldenMemoryLight,
                                MemoryTheme.Colors.goldenMemory
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(animateIcon ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
            }
            
            // テキスト
            VStack(spacing: MemorySpacing.sm) {
                Text("読みたい本を見つけよう")
                    .font(MemoryTheme.Fonts.title2())
                    .fontWeight(.bold)
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("気になる本を追加して\n読書の楽しみを広げましょう")
                    .font(MemoryTheme.Fonts.body())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
            }
            
            // CTAボタン
            Button(action: {
                showSearch = true
            }) {
                HStack(spacing: MemorySpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                    Text("本を探す")
                        .font(MemoryTheme.Fonts.callout())
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, MemorySpacing.xl)
                .padding(.vertical, MemorySpacing.md)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            MemoryTheme.Colors.primaryBlue,
                            MemoryTheme.Colors.primaryBlueDark
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(MemoryRadius.full)
                .memoryShadow(.medium)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, MemorySpacing.xl)
        .padding(.vertical, MemorySpacing.xxl)
        .onAppear {
            animateIcon = true
        }
    }
}

#Preview {
    DiscoveryView()
        .environment(ServiceContainer.shared.getSubscriptionStateStore())
}

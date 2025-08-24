import SwiftUI

struct DiscoveryView: View {
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showBarcodeScanner = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                MemoryTheme.Colors.secondaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: MemorySpacing.md) {
                            HStack {
                                VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                    Text("発見")
                                        .font(MemoryTheme.Fonts.hero())
                                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                                    Text("新しい本との出会いを")
                                        .font(MemoryTheme.Fonts.callout())
                                        .foregroundColor(MemoryTheme.Colors.inkGray)
                                }
                                Spacer()
                                
                                Image(systemName: "sparkle.magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                MemoryTheme.Colors.warmCoralLight,
                                                MemoryTheme.Colors.warmCoral
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .padding(.horizontal, MemorySpacing.lg)
                            .padding(.top, MemorySpacing.lg)
                            
                            // Search Bar
                            Button {
                                showSearch = true
                            } label: {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 18))
                                        .foregroundColor(MemoryTheme.Colors.inkGray)
                                    
                                    Text("本を探す...")
                                        .font(MemoryTheme.Fonts.body())
                                        .foregroundColor(MemoryTheme.Colors.inkLightGray)
                                    
                                    Spacer()
                                    
                                    Button {
                                        showBarcodeScanner = true
                                    } label: {
                                        Image(systemName: "barcode.viewfinder")
                                            .font(.system(size: 20))
                                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                            .padding(8)
                                            .background(
                                                Circle()
                                                    .fill(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                                            )
                                    }
                                }
                                .padding(.horizontal, MemorySpacing.md)
                                .padding(.vertical, MemorySpacing.md)
                                .background(MemoryTheme.Colors.cardBackground)
                                .cornerRadius(MemoryRadius.full)
                                .memoryShadow(.soft)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, MemorySpacing.md)
                        }
                        .padding(.bottom, MemorySpacing.lg)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.background,
                                    MemoryTheme.Colors.secondaryBackground
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        VStack(spacing: MemorySpacing.xl) {
                            // 読みたいリストセクション
                            WantToReadSection(navigationPath: $navigationPath)
                            
                            // 将来的な機能のプレースホルダー
                            FutureFeatureSection()
                        }
                        .padding(.bottom, MemorySpacing.xl)
                    }
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
        }
            }
}

// 読みたいリストのセクション
struct WantToReadSection: View {
    @State private var viewModel = WantToReadViewModel()
    @State private var showFullList = false
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.md) {
                HStack {
                    HStack(spacing: MemorySpacing.xs) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.goldenMemoryLight,
                                        MemoryTheme.Colors.goldenMemory
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("読みたいリスト")
                            .font(MemoryTheme.Fonts.title3())
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                    }
                    
                    Spacer()
                    
                    if !viewModel.books.isEmpty {
                        Button("すべて見る") {
                            showFullList = true
                        }
                        .font(MemoryTheme.Fonts.caption())
                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                }
                .padding(.horizontal, MemorySpacing.lg)
                
                if viewModel.books.isEmpty {
                    EmptyWantToReadCard()
                        .padding(.horizontal, MemorySpacing.md)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MemorySpacing.md) {
                            ForEach(viewModel.books.prefix(5), id: \.id) { book in
                                NavigationLink(value: book) {
                                    WantToReadCard(book: book)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .id(book.id) // 各本を一意に識別
                            }
                        }
                        .padding(.horizontal, MemorySpacing.md)
                    }
                }
            }
        .task {
            await viewModel.loadBooks()
        }
        .sheet(isPresented: $showFullList) {
            NavigationStack {
                WantToReadListView()
            }
                    }
    }
}

// 読みたい本のカード
struct WantToReadCard: View {
    let book: Book
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.xs) {
            // Book Cover
            ZStack {
                BookCoverView(imageId: book.coverImageId, size: .medium)
                    .frame(width: 120, height: 180)
                    .cornerRadius(MemoryRadius.medium)
                    .memoryShadow(.medium)
                
                // グラデーションオーバーレイ
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        MemoryTheme.Colors.inkBlack.opacity(0.2)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                .cornerRadius(MemoryRadius.medium)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(MemoryTheme.Fonts.footnote())
                    .fontWeight(.medium)
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let priority = book.priority {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { index in
                            Image(systemName: index < priority ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(
                                    index < priority ? MemoryTheme.Colors.goldenMemory : MemoryTheme.Colors.inkPale
                                )
                        }
                    }
                }
            }
            .frame(width: 120, alignment: .leading)
        }
        .padding(MemorySpacing.xs)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MemoryTheme.Animation.fast) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// 空の読みたいリスト
struct EmptyWantToReadCard: View {
    
    var body: some View {
        VStack(spacing: MemorySpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.goldenMemoryLight.opacity(0.2),
                                MemoryTheme.Colors.goldenMemory.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bookmark")
                    .font(.system(size: 40))
                    .foregroundColor(MemoryTheme.Colors.goldenMemory)
            }
            
            VStack(spacing: MemorySpacing.xs) {
                Text("読みたい本を追加しよう")
                    .font(MemoryTheme.Fonts.headline())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("気になる本を見つけたら\nリストに追加してみましょう")
                    .font(MemoryTheme.Fonts.callout())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MemorySpacing.xl)
        .padding(.horizontal, MemorySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MemoryRadius.large)
                .fill(MemoryTheme.Colors.cardBackground)
        )
        .memoryShadow(.soft)
    }
}

// 将来の機能プレースホルダー
struct FutureFeatureSection: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.md) {
            HStack(spacing: MemorySpacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(MemoryTheme.Colors.warmCoral)
                Text("もうすぐ登場")
                    .font(MemoryTheme.Fonts.title3())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
            }
            .padding(.horizontal, MemorySpacing.lg)
            
            VStack(spacing: MemorySpacing.sm) {
                FutureFeatureCard(
                    icon: "sparkles",
                    iconColor: MemoryTheme.Colors.primaryBlue,
                    title: "AIによるおすすめ",
                    description: "あなたの読書履歴から、次に読むべき本を提案します"
                )
                
                FutureFeatureCard(
                    icon: "person.2.fill",
                    iconColor: MemoryTheme.Colors.warmCoral,
                    title: "読書コミュニティ",
                    description: "同じ本を読んでいる人とつながって、感想を共有しよう"
                )
                
                FutureFeatureCard(
                    icon: "chart.xyaxis.line",
                    iconColor: MemoryTheme.Colors.goldenMemory,
                    title: "読書分析",
                    description: "あなたの読書傾向を分析して、新しい発見をサポート"
                )
            }
            .padding(.horizontal, MemorySpacing.md)
        }
    }
}

struct FutureFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: MemorySpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                iconColor.opacity(0.2),
                                iconColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(MemoryTheme.Fonts.headline())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text(description)
                    .font(MemoryTheme.Fonts.caption())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(MemorySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MemoryRadius.large)
                .fill(MemoryTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: MemoryRadius.large)
                        .strokeBorder(MemoryTheme.Colors.inkPale, lineWidth: 1)
                )
        )
    }
}

#Preview {
    DiscoveryView()
        .environment(AuthViewModel())
}
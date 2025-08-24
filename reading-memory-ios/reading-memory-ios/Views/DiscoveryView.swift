import SwiftUI

struct DiscoveryView: View {
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showBarcodeScanner = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 検索バー風のボタン
                    Button {
                        showSearch = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text("本を検索...")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "barcode.viewfinder")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                    
                    // 読みたいリストセクション
                    WantToReadSection()
                    
                    // 将来的な機能のプレースホルダー
                    FutureFeatureSection()
                }
                .padding(.vertical)
            }
            .navigationTitle("発見")
            .navigationBarTitleDisplayMode(.large)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("読みたいリスト", systemImage: "bookmark.fill")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.books.isEmpty {
                    Button("すべて見る") {
                        showFullList = true
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            
            if viewModel.books.isEmpty {
                EmptyWantToReadCard()
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.books.prefix(5)) { book in
                            WantToReadCard(book: book)
                        }
                    }
                    .padding(.horizontal)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BookCoverView(imageURL: book.coverImageUrl, size: .medium)
                .frame(width: 100, height: 150)
            
            Text(book.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 100, alignment: .leading)
            
            if let priority = book.priority {
                HStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        Image(systemName: index < priority ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(index < priority ? .yellow : .gray)
                    }
                }
            }
        }
    }
}

// 空の読みたいリスト
struct EmptyWantToReadCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("読みたい本を追加しましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// 将来の機能プレースホルダー
struct FutureFeatureSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("もうすぐ登場")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                FutureFeatureCard(
                    icon: "sparkles",
                    title: "おすすめの本",
                    description: "あなたの読書履歴から、次に読むべき本を提案します"
                )
                
                FutureFeatureCard(
                    icon: "person.2.fill",
                    title: "読書仲間",
                    description: "同じ本を読んでいる人とつながりましょう"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct FutureFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

#Preview {
    DiscoveryView()
        .environment(AuthViewModel())
}
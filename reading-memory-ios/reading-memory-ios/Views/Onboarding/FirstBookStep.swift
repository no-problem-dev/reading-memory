import SwiftUI

struct FirstBookStep: View {
    @Binding var selectedBook: Book?
    @Binding var isShowingBookSearch: Bool
    @State private var showSearchSheet = false
    @State private var showBarcodeSheet = false
    
    enum AdditionOption {
        case search
        case barcode
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    VStack(spacing: 8) {
                        Text("最初の本を登録しましょう")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("今読んでいる本、または最近読んだ本はありますか？")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                // Book display or add button
                if let book = selectedBook {
                    // Selected book card
                    VStack(spacing: 16) {
                        BookCard(book: book)
                        
                        Button("別の本を選ぶ") {
                            isShowingBookSearch = true
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                } else {
                    // Add book options
                    VStack(spacing: 20) {
                        // Barcode scan button
                        Button(action: { 
                            showBarcodeSheet = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("バーコードで追加")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("本の裏表紙をスキャン")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        // Manual search button
                        Button(action: { 
                            showSearchSheet = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("タイトルで検索")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("本のタイトルや著者名で検索")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    // Skip option
                    VStack(spacing: 12) {
                        Text("後で登録することもできます")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                }
                
                // スクロールビューの最下部に余白を追加
                Color.clear
                    .frame(height: 50)
            }
            .padding(.vertical)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showSearchSheet) {
            NavigationStack {
                BookSearchView(
                    defaultStatus: .reading,
                    onBookRegistered: { book in
                        print("DEBUG: Book registered - title: \(book.title), coverImageId: \(book.coverImageId ?? "nil")")
                        selectedBook = book
                        // BookSearchView内でdismiss()が呼ばれるので、ここでは設定しない
                    }
                )
            }
        }
        .sheet(isPresented: $showBarcodeSheet) {
            NavigationStack {
                BarcodeScannerView(
                    defaultStatus: .reading,
                    onBookRegistered: { book in
                        print("DEBUG: Book registered from barcode - title: \(book.title), coverImageId: \(book.coverImageId ?? "nil")")
                        selectedBook = book
                        // BarcodeScannerView内でdismiss()が呼ばれるので、ここでは設定しない
                    }
                )
            }
        }
    }
}

// MARK: - Book Card
struct BookCard: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 16) {
            // Book cover - centered
            HStack {
                Spacer()
                if let imageId = book.coverImageId, !imageId.isEmpty {
                    RemoteImage(imageId: imageId)
                        .frame(width: 120, height: 180)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                } else {
                    // プレースホルダー画像
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 120, height: 180)
                        .overlay(
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                Spacer()
            }
            
            // Book info - centered
            VStack(spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                    Text("選択済み")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
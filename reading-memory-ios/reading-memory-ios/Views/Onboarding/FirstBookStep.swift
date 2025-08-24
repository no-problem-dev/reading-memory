import SwiftUI

struct FirstBookStep: View {
    @Binding var selectedBook: Book?
    @Binding var isShowingBookSearch: Bool
    
    var body: some View {
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
                    Button(action: { isShowingBookSearch = true }) {
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
                    Button(action: { isShowingBookSearch = true }) {
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
            
            Spacer()
        }
        .padding(.vertical)
    }
}

// MARK: - Book Card
struct BookCard: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            // Book cover
            RemoteImage(imageId: book.coverImageId)
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .shadow(radius: 4)
            
            // Book info
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("選択済み")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}
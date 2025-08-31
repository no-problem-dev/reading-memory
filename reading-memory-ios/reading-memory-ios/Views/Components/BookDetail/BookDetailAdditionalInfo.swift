import SwiftUI

struct BookDetailAdditionalInfo: View {
    let book: Book
    
    var body: some View {
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
}
import SwiftUI

struct BookDetailHeroSection: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 0) {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    MemoryTheme.Colors.primaryBlue.opacity(0.1),
                    MemoryTheme.Colors.primaryBlue.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            .overlay(
                HStack(spacing: MemorySpacing.lg) {
                    // 表紙画像
                    BookCoverView(
                        imageId: book.coverImageId,
                        size: .custom(width: 120, height: 170)
                    )
                    .shadow(radius: 8)
                    
                    // 本の情報
                    VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                        Text(book.displayTitle)
                            .font(MemoryTheme.Fonts.title())
                            .fontWeight(.bold)
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(book.displayAuthor)
                            .font(MemoryTheme.Fonts.body())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .lineLimit(1)
                        
                        if let publisher = book.publisher {
                            Text(publisher)
                                .font(MemoryTheme.Fonts.caption())
                                .foregroundColor(MemoryTheme.Colors.inkGray.opacity(0.8))
                                .lineLimit(1)
                        }
                        
                        // ページ数
                        if let pageCount = book.pageCount {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 12))
                                Text("\(pageCount)ページ")
                                    .font(MemoryTheme.Fonts.caption())
                            }
                            .foregroundColor(MemoryTheme.Colors.inkGray.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                .padding()
            )
        }
    }
}
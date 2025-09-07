import SwiftUI

struct BookDetailHeroSection: View {
    let book: Book
    let onCoverTap: () -> Void
    
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
                    // 表紙画像（タップ可能）
                    Button(action: onCoverTap) {
                        ZStack {
                            BookCoverView(
                                imageId: book.coverImageId,
                                size: .custom(width: 120, height: 170)
                            )
                            .shadow(radius: 8)
                            
                            // 編集アイコンのオーバーレイ
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(MemoryTheme.Colors.primaryBlue)
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                                }
                            }
                            .padding(8)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(1)
                    
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
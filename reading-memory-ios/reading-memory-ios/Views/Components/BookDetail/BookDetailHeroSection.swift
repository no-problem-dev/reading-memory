import SwiftUI

struct BookDetailHeroSection: View {
    let book: Book
    let onCoverTapped: (() -> Void)?
    
    init(book: Book, onCoverTapped: (() -> Void)? = nil) {
        self.book = book
        self.onCoverTapped = onCoverTapped
    }
    
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
                    Button(action: {
                        onCoverTapped?()
                    }) {
                        ZStack {
                            BookCoverView(
                                imageId: book.coverImageId,
                                size: .custom(width: 120, height: 170)
                            )
                            .shadow(radius: 8)
                            
                            // タップ可能であることを示すオーバーレイ
                            if onCoverTapped != nil {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 120, height: 170)
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.white)
                                            Text("編集")
                                                .font(MemoryTheme.Fonts.caption())
                                                .foregroundColor(.white)
                                        }
                                    )
                                    .opacity(0)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(MemoryTheme.Colors.primaryBlue, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(onCoverTapped == nil)
                    
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
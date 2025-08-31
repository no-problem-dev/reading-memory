import SwiftUI

struct CurrentReadingCard: View {
    let book: Book
    let onChatTapped: () -> Void
    let onBookTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 本の情報部分
            Button(action: onBookTapped) {
                HStack(alignment: .top, spacing: MemorySpacing.md) {
                    // 本の表紙
                    BookCoverView(imageId: book.coverImageId, size: .large)
                        .frame(width: 80, height: 120)
                    
                    // 本の情報
                    VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                        Text(book.title)
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(book.author)
                            .font(MemoryTheme.Fonts.footnote())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // 読書進捗
                        if let progress = book.readingProgress {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(Int(progress))%")
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                    Spacer()
                                    Text("読書中")
                                        .font(MemoryTheme.Fonts.caption())
                                        .foregroundColor(MemoryTheme.Colors.inkGray)
                                }
                                
                                // プログレスバー
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(MemoryTheme.Colors.inkPale)
                                        .frame(height: 4)
                                    
                                    Capsule()
                                        .fill(MemoryTheme.Colors.primaryBlue)
                                        .frame(width: (280 - MemorySpacing.md * 2 - 80 - MemorySpacing.md) * (progress / 100.0), height: 4)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(MemorySpacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            
            Divider()
                .foregroundColor(MemoryTheme.Colors.inkPale)
            
            // チャットボタン
            Button(action: onChatTapped) {
                HStack(spacing: MemorySpacing.xs) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 16))
                    Text("読書メモを書く")
                        .font(MemoryTheme.Fonts.subheadline())
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MemorySpacing.md)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            MemoryTheme.Colors.primaryBlueLight,
                            MemoryTheme.Colors.primaryBlue
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 320)
        .background(MemoryTheme.Colors.cardBackground)
        .cornerRadius(MemoryRadius.large)
        .memoryShadow(.soft)
    }
}
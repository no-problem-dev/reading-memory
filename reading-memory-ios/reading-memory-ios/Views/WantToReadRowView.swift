import SwiftUI

struct WantToReadRowView: View {
    let book: Book
    
    private var priorityColor: Color {
        guard let priority = book.priority else { return .gray }
        switch priority {
        case 0...2:
            return MemoryTheme.Colors.primaryBlue
        case 3...5:
            return MemoryTheme.Colors.goldenMemory
        case 6...8:
            return MemoryTheme.Colors.info
        default:
            return .gray
        }
    }
    
    private var daysUntilPlanned: Int? {
        guard let plannedDate = book.plannedReadingDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: plannedDate)
        return components.day
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 表紙画像
            BookCoverView(imageId: book.coverImageId, size: .custom(width: 50, height: 70))
            
            // 本の情報
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // タグとバッジ
                HStack(spacing: 8) {
                    // 優先度インジケーター
                    if book.priority != nil {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("優先度: \(book.priority! + 1)")
                                .font(.caption2)
                        }
                        .foregroundColor(priorityColor)
                    }
                    
                    // 予定日バッジ
                    if let days = daysUntilPlanned {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            if days == 0 {
                                Text("今日")
                            } else if days > 0 {
                                Text("\(days)日後")
                            } else {
                                Text("\(abs(days))日前")
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(days < 0 ? MemoryTheme.Colors.warning : MemoryTheme.Colors.primaryBlue)
                    }
                    
                    // リマインダーアイコン
                    if book.reminderEnabled && book.plannedReadingDate != nil {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    // 購入リンクアイコン
                    if let links = book.purchaseLinks, !links.isEmpty {
                        Image(systemName: "cart.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // 並び替えハンドル無効化
            // Image(systemName: "line.3.horizontal")
            //     .foregroundColor(.secondary)
            //     .opacity(0.5)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
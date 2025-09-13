import SwiftUI

struct BookDetailActionButtons: View {
    let book: Book
    let onMemoryTapped: () -> Void
    let onSummaryTapped: () -> Void
    
    var body: some View {
        VStack(spacing: MemorySpacing.sm) {
            // Memory (Chat & Note) Button
            Button(action: onMemoryTapped) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.primaryBlueLight.opacity(0.2),
                                        MemoryTheme.Colors.primaryBlue.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 22))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("読書メモを書く")
                            .font(.headline)
                            .foregroundColor(Color(.label))
                        Text("読みながら感じたことを記録")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(MemorySpacing.md)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(MemoryRadius.large)
                .memoryShadow(.soft)
            }
            .buttonStyle(PlainButtonStyle())
            
            // AI Summary Button
            Button(action: onSummaryTapped) {
                HStack {
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
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundColor(MemoryTheme.Colors.goldenMemory)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.aiSummary != nil ? "AI要約を見る" : "AI要約を生成")
                            .font(.headline)
                            .foregroundColor(Color(.label))
                        Text(book.aiSummary != nil ? "生成された要約を確認" : "読書メモから要点をまとめます")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(MemorySpacing.md)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(MemoryRadius.large)
                .memoryShadow(.soft)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
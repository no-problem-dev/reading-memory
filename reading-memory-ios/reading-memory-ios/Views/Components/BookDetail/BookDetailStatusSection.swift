import SwiftUI

struct BookDetailStatusSection: View {
    @Binding var book: Book?
    let onStatusUpdate: (ReadingStatus) async -> Void
    @State private var isUpdatingStatus = false
    
    var body: some View {
        if let book = book {
            VStack(spacing: MemorySpacing.lg) {
                // Status Section
                VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                    Text("読書ステータス")
                        .font(.headline)
                    
                    HStack(spacing: MemorySpacing.sm) {
                        ForEach([ReadingStatus.wantToRead, .reading, .completed, .dnf], id: \.self) { status in
                            Button {
                                Task {
                                    await onStatusUpdate(status)
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: statusIcon(for: status))
                                        .font(.system(size: 24))
                                    Text(status.displayName)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, MemorySpacing.sm)
                                .background(
                                    book.status == status ?
                                    statusColor(for: status).opacity(0.2) :
                                    Color(.tertiarySystemBackground)
                                )
                                .foregroundColor(
                                    book.status == status ?
                                    statusColor(for: status) :
                                    Color(.label)
                                )
                                .cornerRadius(MemoryRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                        .stroke(
                                            book.status == status ?
                                            statusColor(for: status) :
                                            Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isUpdatingStatus)
                        }
                    }
                }
                
                // Rating Section
                if book.status == .completed {
                    VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                        Text("評価")
                            .font(.headline)
                        
                        RatingSelector(book: book)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
        }
    }
    
    private func statusIcon(for status: ReadingStatus) -> String {
        switch status {
        case .wantToRead:
            return "bookmark"
        case .reading:
            return "book.pages"
        case .completed:
            return "checkmark.circle"
        case .dnf:
            return "xmark.circle"
        }
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .wantToRead:
            return MemoryTheme.Colors.primaryBlue
        case .reading:
            return MemoryTheme.Colors.goldenMemory
        case .completed:
            return MemoryTheme.Colors.success
        case .dnf:
            return Color(.systemGray)
        }
    }
}
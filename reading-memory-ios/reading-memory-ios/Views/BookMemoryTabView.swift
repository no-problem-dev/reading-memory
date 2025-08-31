import SwiftUI

enum MemoryTab: String, CaseIterable {
    case chat = "チャット"
    case note = "メモ"
    
    var icon: String {
        switch self {
        case .chat:
            return "bubble.left.and.bubble.right"
        case .note:
            return "note.text"
        }
    }
}

struct BookMemoryTabView: View {
    let bookId: String
    @State private var selectedTab: MemoryTab = .chat
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Bar
                tabBar()
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case .chat:
                        ChatContentView(bookId: bookId)
                    case .note:
                        BookNoteContentView(bookId: bookId)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            .navigationTitle("読書メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func tabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(MemoryTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(selectedTab == tab ? MemoryTheme.Colors.primaryBlue : Color(.secondaryLabel))
                    .background(
                        selectedTab == tab ?
                        MemoryTheme.Colors.primaryBlue.opacity(0.1) : Color.clear
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.secondarySystemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}
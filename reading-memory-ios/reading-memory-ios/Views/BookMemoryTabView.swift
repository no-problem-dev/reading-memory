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
    
    // ViewModelを親で管理してデータの重複読み込みを防ぐ
    @State private var chatViewModel: BookChatViewModel?
    @State private var noteViewModel = BookNoteViewModel()
    @State private var book: Book?
    
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if let book = book {
                    TabView(selection: $selectedTab) {
                        // チャットタブ
                        ChatContentView(
                            book: book,
                            viewModel: chatViewModel ?? BookChatViewModel(book: book)
                        )
                        .tabItem {
                            Label(MemoryTab.chat.rawValue, systemImage: MemoryTab.chat.icon)
                        }
                        .tag(MemoryTab.chat)
                        
                        // ノートタブ
                        BookNoteContentView(
                            book: book,
                            viewModel: noteViewModel
                        )
                        .tabItem {
                            Label(MemoryTab.note.rawValue, systemImage: MemoryTab.note.icon)
                        }
                        .tag(MemoryTab.note)
                    }
                    .tint(MemoryTheme.Colors.primaryBlue)
                } else {
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: MemoryTheme.Colors.primaryBlue))
                }
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
        .task {
            await loadBook()
        }
    }
    
    private func loadBook() async {
        guard authService.currentUser?.uid != nil else { return }
        
        do {
            if let loadedBook = try await bookRepository.getBook(bookId: bookId) {
                await MainActor.run {
                    self.book = loadedBook
                    // ViewModelを初期化
                    self.chatViewModel = ServiceContainer.shared.makeBookChatViewModel(book: loadedBook)
                    // NoteViewModelにも本の情報を設定
                    self.noteViewModel.book = loadedBook
                    self.noteViewModel.noteText = loadedBook.memo ?? ""
                }
                
                // 初期データ読み込み
                if selectedTab == .chat {
                    await chatViewModel?.loadChats()
                }
            }
        } catch {
            print("Error loading book: \(error)")
        }
    }
}
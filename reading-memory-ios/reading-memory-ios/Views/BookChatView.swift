import SwiftUI

struct BookChatView: View {
    @State private var viewModel: BookChatViewModel
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    init(userBook: UserBook) {
        _viewModel = State(wrappedValue: ServiceContainer.shared.makeBookChatViewModel(userBook: userBook))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メッセージリスト
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.chats) { chat in
                            ChatBubbleView(chat: chat)
                                .id(chat.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.chats.count) { _, _ in
                    withAnimation {
                        if let lastChat = viewModel.chats.last {
                            proxy.scrollTo(lastChat.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // 入力エリア
            HStack(spacing: 12) {
                TextField("メモを入力...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                
                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(messageText.isEmpty ? Color(.systemGray3) : .blue)
                }
                .disabled(messageText.isEmpty || viewModel.isLoading)
            }
            .padding()
        }
        .navigationTitle("チャットメモ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadChats()
            }
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .alert("エラー", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func sendMessage() async {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messageText = ""
        await viewModel.sendMessage(message)
    }
}

// チャットバブル
struct ChatBubbleView: View {
    let chat: BookChat
    
    var body: some View {
        HStack {
            if !chat.isAI {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: chat.isAI ? .leading : .trailing, spacing: 4) {
                Text(chat.message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(chat.isAI ? Color(.systemGray5) : Color.blue)
                    .foregroundStyle(chat.isAI ? .primary : Color.white)
                    .cornerRadius(16)
                
                Text(formatDate(chat.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if chat.isAI {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨日 HH:mm"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: Date()) {
            formatter.dateFormat = "MM/dd HH:mm"
        } else {
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
        }
        
        return formatter.string(from: date)
    }
}
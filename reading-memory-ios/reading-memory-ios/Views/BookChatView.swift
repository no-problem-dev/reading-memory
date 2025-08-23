import SwiftUI
import PhotosUI

struct BookChatView: View {
    @State private var viewModel: BookChatViewModel
    @State private var messageText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @FocusState private var isInputFocused: Bool
    
    init(book: Book) {
        _viewModel = State(wrappedValue: ServiceContainer.shared.makeBookChatViewModel(book: book))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メッセージリスト
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.chats) { chat in
                            ChatBubbleView(chat: chat) {
                                Task {
                                    await viewModel.deleteChat(chat)
                                }
                            }
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
            VStack(spacing: 8) {
                // 選択された画像のプレビュー
                if let selectedImage {
                    HStack {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                            .cornerRadius(8)
                            .overlay(
                                Button {
                                    self.selectedImage = nil
                                    self.selectedPhoto = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                }
                                .padding(4),
                                alignment: .topTrailing
                            )
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                HStack(spacing: 12) {
                    // カメラボタン
                    PhotosPicker(selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.blue)
                    }
                    
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
                            .foregroundStyle((messageText.isEmpty && selectedImage == nil) ? Color(.systemGray3) : .blue)
                    }
                    .disabled((messageText.isEmpty && selectedImage == nil) || viewModel.isLoading)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("チャットメモ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleAI()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isAIEnabled ? "sparkles" : "sparkle")
                            .font(.system(size: 16))
                        Text("AI")
                            .font(.caption)
                    }
                    .foregroundStyle(viewModel.isAIEnabled ? .blue : .secondary)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadChats()
            }
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                await loadImage(from: newItem)
            }
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
        guard !message.isEmpty || selectedImage != nil else { return }
        
        let image = selectedImage
        messageText = ""
        selectedImage = nil
        selectedPhoto = nil
        
        await viewModel.sendMessage(message, image: image)
    }
    
    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Resize image to reduce file size
                let resizedImage = image.resized(to: CGSize(width: 800, height: 800))
                selectedImage = resizedImage
            }
        } catch {
            viewModel.setError("画像の読み込みに失敗しました")
        }
    }
}

// チャットバブル
struct ChatBubbleView: View {
    let chat: BookChat
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack {
            if !chat.isAI {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: chat.isAI ? .leading : .trailing, spacing: 4) {
                // 画像がある場合は表示
                if let imageUrl = chat.imageUrl, let url = URL(string: imageUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(16)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(width: 200, height: 150)
                            .overlay(
                                ProgressView()
                            )
                    }
                }
                
                // メッセージがある場合は表示
                if !chat.message.isEmpty {
                    Text(chat.message)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(chat.isAI ? Color(.systemGray5) : Color.blue)
                        .foregroundStyle(chat.isAI ? .primary : Color.white)
                        .cornerRadius(16)
                }
                
                Text(formatDate(chat.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .contextMenu {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
            .confirmationDialog("メモを削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    onDelete()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は取り消せません")
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

// MARK: - UIImage Extension
private extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let targetSize = CGSize(
            width: min(size.width, self.size.width),
            height: min(size.height, self.size.height)
        )
        
        let widthRatio = targetSize.width / self.size.width
        let heightRatio = targetSize.height / self.size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: self.size.width * ratio,
            height: self.size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
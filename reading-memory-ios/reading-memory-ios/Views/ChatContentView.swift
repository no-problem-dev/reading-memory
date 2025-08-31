import SwiftUI
import PhotosUI

struct ChatContentView: View {
    let bookId: String
    @State private var book: Book?
    @State private var viewModel: BookChatViewModel?
    @State private var messageText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @FocusState private var isInputFocused: Bool
    @State private var scrollToBottom = false
    @State private var isLoading = true
    
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    isInputFocused = false
                }
            
            if isLoading {
                ProgressView("読み込み中...")
                    .progressViewStyle(CircularProgressViewStyle(tint: MemoryTheme.Colors.primaryBlue))
            } else if let _ = book, let viewModel = viewModel {
                VStack(spacing: 0) {
                    // AI トグルセクション
                    aiToggleSection(viewModel: viewModel)
                    
                    // メッセージリスト
                    chatMessagesSection(viewModel: viewModel)
                    
                    // 入力エリア
                    inputSection(viewModel: viewModel)
                }
            } else {
                Text("本の情報を読み込めませんでした")
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .task {
            await loadBook()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                await loadImage(from: newItem)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isInputFocused = false
                }
            }
        }
        .sheet(isPresented: .constant(viewModel?.showPaywall ?? false)) {
            PaywallView()
        }
        .alert("エラー", isPresented: .constant(viewModel?.showError ?? false)) {
            Button("OK") {
                viewModel?.clearError()
            }
        } message: {
            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func loadBook() async {
        guard authService.currentUser?.uid != nil else { return }
        
        do {
            if let loadedBook = try await bookRepository.getBook(bookId: bookId) {
                book = loadedBook
                await MainActor.run {
                    let chatViewModel = ServiceContainer.shared.makeBookChatViewModel(book: loadedBook)
                    viewModel = chatViewModel
                }
                await viewModel?.loadChats()
            } else {
                print("Book not found with ID: \(bookId)")
            }
        } catch {
            print("Error loading book: \(error)")
        }
        
        isLoading = false
    }
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
    }
    
    private func sendMessage() async {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty || selectedImage != nil else { return }
        
        let image = selectedImage
        messageText = ""
        selectedImage = nil
        selectedPhoto = nil
        
        await viewModel?.sendMessage(message, image: image)
        scrollToBottom = true
    }
    
    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        // プレミアムチェック
        guard FeatureGate.canAttachPhotos else {
            selectedPhoto = nil
            viewModel?.showPaywall = true
            return
        }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // チャット用に画像をリサイズ（アスペクト比を維持）
                let resizedImage = image.resizedToFit(
                    maxSize: CGSize(width: 1200, height: 1200),
                    maxFileSizeKB: 800
                )
                selectedImage = resizedImage
            }
        } catch {
            viewModel?.setError("画像の読み込みに失敗しました")
        }
    }
    
    @ViewBuilder
    private func aiToggleSection(viewModel: BookChatViewModel) -> some View {
        HStack {
            Text("AI アシスタント")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { viewModel.isAIEnabled },
                set: { _ in viewModel.toggleAI() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: MemoryTheme.Colors.primaryBlue))
            .labelsHidden()
            
            if viewModel.isAIEnabled {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .symbolEffect(.variableColor, options: .repeating, value: viewModel.isAIEnabled)
                    Text("オン")
                        .font(.caption)
                }
                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, MemorySpacing.sm)
        .background(Color(.tertiarySystemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isAIEnabled)
    }
    
    @ViewBuilder
    private func chatMessagesSection(viewModel: BookChatViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: MemorySpacing.md) {
                    if viewModel.isLoading && viewModel.chats.isEmpty {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: MemoryTheme.Colors.primaryBlue))
                            .scaleEffect(1.2)
                            .padding(.top, MemorySpacing.xxl)
                    } else if viewModel.chats.isEmpty {
                        EmptyChatView(isAIEnabled: viewModel.isAIEnabled)
                            .padding(.top, MemorySpacing.xxl)
                    }
                    
                    ForEach(viewModel.chats) { chat in
                        ChatBubbleView(chat: chat) {
                            Task {
                                await viewModel.deleteChat(chat)
                            }
                        }
                        .id(chat.id)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, MemorySpacing.md)
            }
            .refreshable {
                await viewModel.loadChats()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
            }
            .onAppear {
                if let lastChat = viewModel.chats.last {
                    proxy.scrollTo(lastChat.id, anchor: .bottom)
                }
            }
            .onChange(of: scrollToBottom) { _, shouldScroll in
                if shouldScroll {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let lastChat = viewModel.chats.last {
                            proxy.scrollTo(lastChat.id, anchor: .bottom)
                        }
                    }
                    scrollToBottom = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func inputSection(viewModel: BookChatViewModel) -> some View {
        VStack(spacing: 0) {
            // 選択された画像のプレビュー
            if let selectedImage {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                            .cornerRadius(MemoryRadius.medium)
                            .memoryShadow(.soft)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.selectedImage = nil
                                self.selectedPhoto = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color(.systemGray))
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding(8)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, MemorySpacing.sm)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            HStack(spacing: MemorySpacing.sm) {
                // カメラボタン
                PhotosPicker(selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()) {
                    ZStack {
                        Circle()
                            .fill(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    }
                }
                
                // テキストフィールド
                ZStack(alignment: .topLeading) {
                    if messageText.isEmpty {
                        Text("気づいたことを書いてみよう...")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                    
                    TextField("", text: $messageText, axis: .vertical)
                        .focused($isInputFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .foregroundColor(Color(.label))
                        .tint(MemoryTheme.Colors.primaryBlue)
                        .lineLimit(1...5)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(MemoryRadius.full)
                .overlay(
                    RoundedRectangle(cornerRadius: MemoryRadius.full)
                        .stroke(
                            isInputFocused ? MemoryTheme.Colors.primaryBlue : Color(.separator),
                            lineWidth: isInputFocused ? 2 : 0.5
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                
                // 送信ボタン
                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                canSend
                                    ? MemoryTheme.Colors.primaryBlue
                                    : Color(.systemGray4)
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(canSend ? .white : Color(.systemGray2))
                    }
                }
                .disabled(!canSend || viewModel.isLoading)
                .scaleEffect(canSend ? 1.0 : 0.9)
                .animation(.easeInOut(duration: 0.2), value: canSend)
            }
            .padding(.horizontal)
            .padding(.vertical, MemorySpacing.md)
            .background(Color(.tertiarySystemBackground))
            .overlay(
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5),
                alignment: .top
            )
        }
    }
}
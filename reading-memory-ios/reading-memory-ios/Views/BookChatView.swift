import SwiftUI
import PhotosUI

struct BookChatView: View {
    let book: Book
    @State private var viewModel: BookChatViewModel
    @State private var messageText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @FocusState private var isInputFocused: Bool
    @State private var scrollToBottom = false
    @Environment(\.dismiss) var dismiss
    
    init(book: Book) {
        self.book = book
        self._viewModel = State(initialValue: ServiceContainer.shared.makeBookChatViewModel(book: book))
    }
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    MemoryTheme.Colors.background,
                    MemoryTheme.Colors.secondaryBackground.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced Navigation Bar
                VStack(spacing: 0) {
                    HStack {
                        // Placeholder for balance
                        Color.clear
                            .frame(width: 28, height: 28)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("読書メモ")
                                .font(MemoryTheme.Fonts.headline())
                                .foregroundColor(MemoryTheme.Colors.inkBlack)
                            Text(book.title)
                                .font(MemoryTheme.Fonts.caption())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                        }
                    }
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.top, MemorySpacing.sm)
                    .padding(.bottom, MemorySpacing.xs)
                    
                    // Enhanced AI Toggle Section
                    HStack {
                        Text("AI アシスタント")
                            .font(MemoryTheme.Fonts.subheadline())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        
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
                                    .font(MemoryTheme.Fonts.caption())
                            }
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.bottom, MemorySpacing.sm)
                    .animation(MemoryTheme.Animation.fast, value: viewModel.isAIEnabled)
                }
                .background(
                    MemoryTheme.Colors.cardBackground
                        .shadow(color: MemoryTheme.Colors.inkBlack.opacity(0.05), radius: 2, x: 0, y: 2)
                )
                
                // メッセージリスト
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: MemorySpacing.md) {
                            // Loading state
                            if viewModel.isLoading && viewModel.chats.isEmpty {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: MemoryTheme.Colors.primaryBlue))
                                    .scaleEffect(1.2)
                                    .padding(.top, MemorySpacing.xxl)
                            }
                            // Welcome message if no chats
                            else if viewModel.chats.isEmpty {
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
                        .padding(.horizontal, MemorySpacing.md)
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
                            withAnimation(MemoryTheme.Animation.normal) {
                                if let lastChat = viewModel.chats.last {
                                    proxy.scrollTo(lastChat.id, anchor: .bottom)
                                }
                            }
                            scrollToBottom = false
                        }
                    }
                }
                
                // Enhanced input area with modern design
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
                                    withAnimation(MemoryTheme.Animation.fast) {
                                        self.selectedImage = nil
                                        self.selectedPhoto = nil
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, MemoryTheme.Colors.inkBlack.opacity(0.8))
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                        )
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.bottom, MemorySpacing.sm)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    HStack(spacing: MemorySpacing.sm) {
                        // Enhanced camera button
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
                        .hoverEffect(.highlight)
                        
                        // Modern text field with translucent background
                        HStack(spacing: MemorySpacing.xs) {
                            TextField("気づいたことを書いてみよう...", text: $messageText, axis: .vertical)
                                .font(MemoryTheme.Fonts.body())
                                .foregroundStyle(MemoryTheme.Colors.inkBlack)
                                .tint(MemoryTheme.Colors.primaryBlue)
                                .textFieldStyle(.plain)
                                .lineLimit(1...5)
                                .focused($isInputFocused)
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, MemorySpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: MemoryRadius.full)
                                .fill(.regularMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: MemoryRadius.full)
                                        .strokeBorder(
                                            isInputFocused ? MemoryTheme.Colors.primaryBlue.opacity(0.3) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                        .animation(MemoryTheme.Animation.fast, value: isInputFocused)
                        
                        // Modern send button
                        Button {
                            Task {
                                await sendMessage()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        canSend
                                            ? LinearGradient(
                                                gradient: Gradient(colors: [
                                                    MemoryTheme.Colors.primaryBlueLight,
                                                    MemoryTheme.Colors.primaryBlue
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : LinearGradient(
                                                gradient: Gradient(colors: [
                                                    MemoryTheme.Colors.inkPale,
                                                    MemoryTheme.Colors.inkPale
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                    )
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(canSend ? .white : MemoryTheme.Colors.inkGray)
                            }
                        }
                        .disabled(!canSend || viewModel.isLoading)
                        .scaleEffect(canSend ? 1.0 : 0.9)
                        .animation(MemoryTheme.Animation.fast, value: canSend)
                        .hoverEffect(.lift)
                    }
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.vertical, MemorySpacing.md)
                }
                .background(
                    .ultraThinMaterial
                )
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadChats()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                await loadImage(from: newItem)
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .alert("エラー", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
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
        
        await viewModel.sendMessage(message, image: image)
        scrollToBottom = true
    }
    
    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        // プレミアムチェック
        guard FeatureGate.canAttachPhotos else {
            selectedPhoto = nil
            viewModel.showPaywall = true
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
            viewModel.setError("画像の読み込みに失敗しました")
        }
    }
}
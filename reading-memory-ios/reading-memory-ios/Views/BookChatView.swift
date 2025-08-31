import SwiftUI
import PhotosUI

struct BookChatView: View {
    @Bindable private var viewModel: BookChatViewModel
    @State private var messageText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @FocusState private var isInputFocused: Bool
    @State private var scrollToBottom = false
    @Environment(\.dismiss) var dismiss
    
    init(book: Book) {
        viewModel = ServiceContainer.shared.makeBookChatViewModel(book: book)
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
                            Text(viewModel.book.title)
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
                            // Welcome message if no chats
                            if viewModel.chats.isEmpty {
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
        .onAppear {
            Task {
                await viewModel.loadChats()
            }
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
                let resizedImage = image.resized(to: CGSize(width: 800, height: 800))
                selectedImage = resizedImage
            }
        } catch {
            viewModel.setError("画像の読み込みに失敗しました")
        }
    }
}

// Enhanced Empty Chat View
struct EmptyChatView: View {
    let isAIEnabled: Bool
    
    var body: some View {
        VStack(spacing: MemorySpacing.xl) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlue.opacity(0.1),
                                MemoryTheme.Colors.primaryBlueLight.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .memoryShadow(.soft)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 50))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlueLight,
                                MemoryTheme.Colors.primaryBlue
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: MemorySpacing.sm) {
                Text("読書メモを始めよう")
                    .font(MemoryTheme.Fonts.title3())
                    .fontWeight(.semibold)
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("読みながら感じたことを\n自由に書いてみてください")
                    .font(MemoryTheme.Fonts.body())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                if isAIEnabled {
                    HStack(spacing: MemorySpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .symbolEffect(.variableColor, options: .repeating)
                        Text("AIアシスタントがあなたの考えを深めます")
                            .font(MemoryTheme.Fonts.caption())
                    }
                    .foregroundColor(MemoryTheme.Colors.primaryBlue)
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.vertical, MemorySpacing.sm)
                    .background(
                        Capsule()
                            .fill(MemoryTheme.Colors.primaryBlue.opacity(0.1))
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(MemorySpacing.xxl)
        .animation(MemoryTheme.Animation.normal, value: isAIEnabled)
    }
}

// Enhanced Chat Bubble
struct ChatBubbleView: View {
    let chat: BookChat
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: MemorySpacing.sm) {
            if chat.messageType != .ai {
                Spacer(minLength: 50)
            } else {
                // Enhanced AI Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlue.opacity(0.15),
                                    MemoryTheme.Colors.primaryBlueLight.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .symbolEffect(.variableColor.iterative, options: .repeating, value: chat.messageType == .ai)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlueLight,
                                    MemoryTheme.Colors.primaryBlue
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .memoryShadow(.soft)
            }
            
            VStack(alignment: chat.messageType == .ai ? .leading : .trailing, spacing: MemorySpacing.xs) {
                // 画像がある場合は表示
                if chat.imageId != nil {
                    ChatImageView(imageId: chat.imageId)
                        .frame(maxWidth: 240, maxHeight: 240)
                        .cornerRadius(MemoryRadius.medium)
                        .memoryShadow(.soft)
                }
                
                // Enhanced message bubble
                if !chat.message.isEmpty {
                    Text(chat.message)
                        .font(MemoryTheme.Fonts.callout())
                        .foregroundColor(chat.messageType == .ai ? MemoryTheme.Colors.inkBlack : .white)
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, MemorySpacing.sm + 2)
                        .background(
                            Group {
                                if chat.messageType == .ai {
                                    RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                        .fill(MemoryTheme.Colors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                                .strokeBorder(MemoryTheme.Colors.inkPale.opacity(0.5), lineWidth: 1)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    MemoryTheme.Colors.primaryBlue,
                                                    MemoryTheme.Colors.primaryBlueDark
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .memoryShadow(.soft)
                                }
                            }
                        )
                        .cornerRadius(4, corners: chat.messageType == .ai ? [.topLeft] : [.topRight])
                }
                
                HStack(spacing: MemorySpacing.xs) {
                    Text(formatDate(chat.createdAt))
                        .font(MemoryTheme.Fonts.caption())
                        .foregroundColor(MemoryTheme.Colors.inkGray.opacity(0.8))
                    
                    if chat.messageType == .ai {
                        Text("AI")
                            .font(MemoryTheme.Fonts.caption().weight(.medium))
                            .foregroundColor(MemoryTheme.Colors.primaryBlue.opacity(0.7))
                    }
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .contextMenu {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
            .confirmationDialog("メモを削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    withAnimation(MemoryTheme.Animation.normal) {
                        onDelete()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この操作は取り消せません")
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(MemoryTheme.Animation.fast) {
                    isPressed = pressing
                }
            }, perform: {})
            
            if chat.messageType == .ai {
                Spacer(minLength: 50)
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

// Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
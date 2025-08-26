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
            // Background
            MemoryTheme.Colors.secondaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("読書メモ")
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                        Text(viewModel.book.title)
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // AI Toggle
                    Button {
                        withAnimation(MemoryTheme.Animation.fast) {
                            viewModel.toggleAI()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isAIEnabled ? "sparkles" : "sparkle")
                                .font(.system(size: 16))
                                .symbolEffect(.bounce, value: viewModel.isAIEnabled)
                            Text("AI")
                                .font(MemoryTheme.Fonts.caption())
                        }
                        .foregroundColor(viewModel.isAIEnabled ? MemoryTheme.Colors.primaryBlue : MemoryTheme.Colors.inkGray)
                        .padding(.horizontal, MemorySpacing.sm)
                        .padding(.vertical, MemorySpacing.xs)
                        .background(
                            viewModel.isAIEnabled 
                                ? MemoryTheme.Colors.primaryBlue.opacity(0.1)
                                : MemoryTheme.Colors.inkPale
                        )
                        .cornerRadius(MemoryRadius.full)
                    }
                    .padding(.trailing, MemorySpacing.xs)
                }
                .padding(.horizontal, MemorySpacing.sm)
                .padding(.top, 8)
                .padding(.bottom, MemorySpacing.xs)
                .background(MemoryTheme.Colors.background)
                
                Divider()
                    .foregroundColor(MemoryTheme.Colors.inkPale)
                
                // メッセージリスト
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: MemorySpacing.md) {
                            // Welcome message if no chats
                            if viewModel.chats.isEmpty {
                                EmptyChatView()
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
                
                // 入力エリア
                VStack(spacing: MemorySpacing.xs) {
                    // 選択された画像のプレビュー
                    if let selectedImage {
                        HStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 100)
                                .cornerRadius(MemoryRadius.medium)
                                .overlay(
                                    Button {
                                        withAnimation(MemoryTheme.Animation.fast) {
                                            self.selectedImage = nil
                                            self.selectedPhoto = nil
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white, MemoryTheme.Colors.inkBlack.opacity(0.6))
                                    }
                                    .padding(4),
                                    alignment: .topTrailing
                                )
                            Spacer()
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    HStack(spacing: MemorySpacing.sm) {
                        // カメラボタン
                        PhotosPicker(selection: $selectedPhoto,
                                    matching: .images,
                                    photoLibrary: .shared()) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 22))
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                .frame(width: 44, height: 44)
                        }
                        
                        // テキストフィールド
                        HStack {
                            TextField("気づいたことを書いてみよう...", text: $messageText, axis: .vertical)
                                .font(MemoryTheme.Fonts.body())
                                .foregroundColor(MemoryTheme.Colors.inkBlack)
                                .textFieldStyle(.plain)
                                .lineLimit(1...5)
                                .focused($isInputFocused)
                        }
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, MemorySpacing.sm)
                        .background(MemoryTheme.Colors.inkWhite)
                        .cornerRadius(MemoryRadius.full)
                        
                        // 送信ボタン
                        Button {
                            Task {
                                await sendMessage()
                            }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
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
                                                MemoryTheme.Colors.inkLightGray,
                                                MemoryTheme.Colors.inkLightGray
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                        }
                        .disabled(!canSend || viewModel.isLoading)
                        .scaleEffect(canSend ? 1.0 : 0.9)
                        .animation(MemoryTheme.Animation.fast, value: canSend)
                    }
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.vertical, MemorySpacing.sm)
                }
                .background(MemoryTheme.Colors.background)
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

// Empty Chat View
struct EmptyChatView: View {
    
    var body: some View {
        VStack(spacing: MemorySpacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
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
            
            VStack(spacing: MemorySpacing.xs) {
                Text("読書メモを始めよう")
                    .font(MemoryTheme.Fonts.title3())
                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                
                Text("読みながら感じたことを\n自由に書いてみてください")
                    .font(MemoryTheme.Fonts.callout())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(MemorySpacing.xl)
    }
}

// チャットバブル
struct ChatBubbleView: View {
    let chat: BookChat
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: MemorySpacing.xs) {
            if !chat.isAI {
                Spacer(minLength: 60)
            } else {
                // AI Avatar
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
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(MemoryTheme.Colors.primaryBlue)
                }
            }
            
            VStack(alignment: chat.isAI ? .leading : .trailing, spacing: MemorySpacing.xs) {
                // 画像がある場合は表示
                if chat.imageId != nil {
                    ChatImageView(imageId: chat.imageId)
                        .frame(maxWidth: 240, maxHeight: 240)
                }
                
                // メッセージがある場合は表示
                if !chat.message.isEmpty {
                    Text(chat.message)
                        .font(MemoryTheme.Fonts.callout())
                        .foregroundColor(chat.isAI ? MemoryTheme.Colors.inkBlack : .white)
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, MemorySpacing.sm)
                        .background(
                            chat.isAI
                                ? AnyView(MemoryTheme.Colors.cardBackground)
                                : AnyView(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            MemoryTheme.Colors.primaryBlueLight,
                                            MemoryTheme.Colors.primaryBlue
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .cornerRadius(MemoryRadius.medium)
                        .cornerRadius(4, corners: chat.isAI ? [.topLeft] : [.topRight])
                }
                
                Text(formatDate(chat.createdAt))
                    .font(MemoryTheme.Fonts.caption())
                    .foregroundColor(MemoryTheme.Colors.inkLightGray)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
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
import SwiftUI

struct ChatExperienceStep: View {
    let book: Book?
    @Binding var firstMessage: String
    @State private var messages: [ChatMessage] = []
    @State private var isShowingAIResponse = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 8) {
                    Text("本とおしゃべりしてみましょう")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let book = book {
                        Text("「\(book.title)」について")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("読書の感想を気軽に記録できます")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 20)
            
            // Chat interface preview
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Initial prompt
                        ChatBubble(
                            message: book != nil ? "この本を選んだきっかけを教えてください" : "最近読んだ本の感想を聞かせてください",
                            isUser: false,
                            isAI: true
                        )
                        
                        // User messages
                        ForEach(messages) { message in
                            ChatBubble(
                                message: message.content,
                                isUser: message.isUser,
                                isAI: !message.isUser
                            )
                        }
                        
                        // AI response animation
                        if isShowingAIResponse {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                
                // Input field
                HStack(spacing: 12) {
                    TextField("メッセージを入力...", text: $firstMessage)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(firstMessage.isEmpty ? Color.gray : Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(firstMessage.isEmpty)
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Explanation
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text("AIが読書体験をサポート")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text("あなたの気づきに対して、AIが質問や関連情報を提供します")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func sendMessage() {
        guard !firstMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: firstMessage,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Clear input
        let sentMessage = firstMessage
        firstMessage = ""
        
        // Show AI response after delay
        withAnimation {
            isShowingAIResponse = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isShowingAIResponse = false
                
                // Add AI response
                let aiResponse = generateAIResponse(for: sentMessage)
                let aiMessage = ChatMessage(
                    id: UUID().uuidString,
                    content: aiResponse,
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)
            }
        }
    }
    
    private func generateAIResponse(for message: String) -> String {
        // Simple demo responses
        let responses = [
            "なるほど！その視点は興味深いですね。もう少し詳しく聞かせていただけますか？",
            "素晴らしい気づきですね！この本のどの部分が特に印象に残りましたか？",
            "その感想、とても共感できます。読み進めるうちに新しい発見がありそうですね。"
        ]
        return responses.randomElement() ?? responses[0]
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: String
    let isUser: Bool
    let isAI: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if isAI && !isUser {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("AI")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                }
                
                Text(message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(20)
            }
            
            if !isUser { Spacer() }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == Double(index) ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .onAppear {
            animationAmount = 2.0
        }
    }
}
import SwiftUI

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
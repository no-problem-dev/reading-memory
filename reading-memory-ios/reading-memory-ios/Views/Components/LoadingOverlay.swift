import SwiftUI

struct LoadingOverlay: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: MemorySpacing.md) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: MemoryTheme.Colors.inkWhite))
                        .scaleEffect(1.2)
                    
                    Text(message)
                        .font(MemoryTheme.Fonts.body())
                        .foregroundColor(MemoryTheme.Colors.inkWhite)
                }
                .padding(MemorySpacing.xl)
                .background(MemoryTheme.Colors.inkBlack.opacity(0.85))
                .cornerRadius(MemoryRadius.large)
                .memoryShadow(.medium)
            }
    }
}

struct MemoryLoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    LoadingOverlay(message: message)
                }
            }
    }
}

extension View {
    func memoryLoading(isLoading: Bool, message: String = "読み込み中...") -> some View {
        modifier(MemoryLoadingModifier(isLoading: isLoading, message: message))
    }
}

#Preview("Light Mode") {
    ZStack {
        MemoryTheme.Colors.background
            .ignoresSafeArea()
        
        VStack {
            Text("Content")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .memoryLoading(isLoading: true, message: "保存中...")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZStack {
        MemoryTheme.Colors.background
            .ignoresSafeArea()
        
        VStack {
            Text("Content")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .memoryLoading(isLoading: true, message: "保存中...")
    }
    .preferredColorScheme(.dark)
}
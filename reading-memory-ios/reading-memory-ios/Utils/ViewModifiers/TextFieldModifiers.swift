import SwiftUI

// TextFieldとTextEditorに一貫した色設定を適用するModifier
struct MemoryTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(MemoryTheme.Fonts.body())
            .foregroundStyle(MemoryTheme.Colors.inkBlack)
            .tint(MemoryTheme.Colors.primaryBlue) // カーソル色
            .autocorrectionDisabled()
    }
}

// TextEditor専用のスタイル
struct MemoryTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(MemoryTheme.Fonts.body())
            .foregroundStyle(MemoryTheme.Colors.inkBlack)
            .tint(MemoryTheme.Colors.primaryBlue) // カーソル色
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}

// View拡張
extension View {
    func memoryTextFieldStyle() -> some View {
        self.modifier(MemoryTextFieldStyle())
    }
    
    func memoryTextEditorStyle() -> some View {
        self.modifier(MemoryTextEditorStyle())
    }
}

// AppearanceベースのグローバルなTextFieldスタイリング
struct TextFieldAppearanceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // UITextFieldの外観をグローバルに設定
                UITextField.appearance().tintColor = UIColor(MemoryTheme.Colors.primaryBlue)
                
                // UITextViewの外観をグローバルに設定（TextEditor用）
                UITextView.appearance().tintColor = UIColor(MemoryTheme.Colors.primaryBlue)
            }
    }
}

extension View {
    func setupTextFieldAppearance() -> some View {
        self.modifier(TextFieldAppearanceModifier())
    }
}
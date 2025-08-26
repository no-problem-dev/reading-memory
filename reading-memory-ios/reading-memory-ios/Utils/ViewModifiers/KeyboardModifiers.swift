import SwiftUI

// キーボード表示時に画面が伸縮しないようにし、画面外タップでキーボードを閉じる修飾子
struct KeyboardAwareModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .ignoresSafeArea(.keyboard, edges: .bottom) // キーボードによる画面の伸縮を防ぐ
            .onTapGesture {
                hideKeyboard()
            }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// BookSearchView専用のキーボード処理
struct BookSearchKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// View拡張で簡単に使えるようにする
extension View {
    func keyboardAware() -> some View {
        self.modifier(KeyboardAwareModifier())
    }
    
    func bookSearchKeyboardAware() -> some View {
        self.modifier(BookSearchKeyboardModifier())
    }
}

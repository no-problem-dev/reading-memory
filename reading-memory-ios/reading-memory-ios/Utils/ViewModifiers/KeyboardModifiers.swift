import SwiftUI

// キーボード表示時に画面が伸縮しないようにし、画面外タップでキーボードを閉じる修飾子
struct KeyboardAwareModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // 背景に透明なビューを配置してタップジェスチャーを設定
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            // コンテンツは最前面に配置し、タップイベントを通過させない
            content
                .ignoresSafeArea(.keyboard, edges: .bottom) // キーボードによる画面の伸縮を防ぐ
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// より高度なキーボード制御を提供するモディファイア
struct SmartKeyboardDismissModifier: ViewModifier {
    @State private var isKeyboardVisible = false
    
    func body(content: Content) -> some View {
        ZStack {
            if isKeyboardVisible {
                // キーボードが表示されている時のみ、背景タップを検知
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            }
            
            content
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// BookSearchView専用のキーボード処理（廃止予定）
struct BookSearchKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(SmartKeyboardDismissModifier())
    }
}

// View拡張で簡単に使えるようにする
extension View {
    func keyboardAware() -> some View {
        self.modifier(SmartKeyboardDismissModifier())
    }
    
    func bookSearchKeyboardAware() -> some View {
        self.modifier(SmartKeyboardDismissModifier())
    }
    
    // ScrollView内で使用するための特別なモディファイア
    func scrollViewKeyboardAware() -> some View {
        self
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .scrollDismissesKeyboard(.interactively)
    }
}

// iOS 16以降でのみ使用可能
extension View {
    @available(iOS 16.0, *)
    func modernKeyboardDismiss() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
    }
}

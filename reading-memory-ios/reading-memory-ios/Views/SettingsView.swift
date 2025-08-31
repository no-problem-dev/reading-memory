import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var alertItem: AlertItem?
    @State private var isDeleting = false
    
    struct AlertItem: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let primaryButton: Alert.Button
        let secondaryButton: Alert.Button?
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.displayName ?? "ユーザー")
                                .font(.headline)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(action: {
                        Task {
                            await authViewModel.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("サインアウト")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        showFirstDeleteConfirmation()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("アカウントを削除")
                        }
                        .foregroundColor(.red)
                    }
                } footer: {
                    Text("アカウントを削除すると、すべてのデータが完全に削除され、復元できません。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("設定")
            .disabled(isDeleting)
            .overlay {
                if isDeleting {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("アカウントを削除しています...")
                            .font(.headline)
                        Text("この処理には時間がかかる場合があります")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                }
            }
        }
        .alert(item: $alertItem) { item in
            if let secondaryButton = item.secondaryButton {
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    primaryButton: item.primaryButton,
                    secondaryButton: secondaryButton
                )
            } else {
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: item.primaryButton
                )
            }
        }
    }
    
    private func showFirstDeleteConfirmation() {
        alertItem = AlertItem(
            title: "アカウント削除の確認",
            message: "本当に退会しますか？\n\nこの操作は取り消すことができません。すべての読書記録、メモ、設定が完全に削除されます。",
            primaryButton: .cancel(Text("キャンセル")),
            secondaryButton: .destructive(Text("続ける")) {
                showFinalDeleteConfirmation()
            }
        )
    }
    
    private func showFinalDeleteConfirmation() {
        alertItem = AlertItem(
            title: "最終確認",
            message: "本当に退会してよろしいですか？\n\nこの操作を実行すると、二度と元に戻すことはできません。",
            primaryButton: .cancel(Text("キャンセル")),
            secondaryButton: .destructive(Text("削除する")) {
                Task {
                    await deleteAccount()
                }
            }
        )
    }
    
    private func showError(_ message: String) {
        alertItem = AlertItem(
            title: "エラー",
            message: message,
            primaryButton: .default(Text("OK")),
            secondaryButton: nil
        )
    }
    
    private func deleteAccount() async {
        isDeleting = true
        
        // 認証状態を確認
        guard AuthService.shared.currentUser != nil else {
            isDeleting = false
            showError("認証情報が見つかりません。再度ログインしてください。")
            return
        }
        
        do {
            try await AuthService.shared.deleteAccount()
            
            // 削除成功 - アカウントが削除されたらAuthStateListenerが自動的に処理
            isDeleting = false
            
            // Auth削除後、少し待機してAuthStateの変更を待つ
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
            
            // AuthStateListenerが反応しない場合の保険として、手動でnilに設定
            if authViewModel.currentUser != nil {
                authViewModel.currentUser = nil
            }
        } catch {
            // Firebase Authのエラーコードを確認
            let nsError = error as NSError
            var errorMessage = ""
            
            if nsError.domain == "FIRAuthErrorDomain" {
                switch nsError.code {
                case 17014: // FIRAuthErrorCodeRequiresRecentLogin
                    errorMessage = "セキュリティ上の理由により、再度ログインが必要です。一度サインアウトして、もう一度ログインしてから退会処理を行ってください。"
                case 17008: // FIRAuthErrorCodeNetworkError
                    errorMessage = "ネットワークエラーが発生しました。インターネット接続を確認してください。"
                default:
                    errorMessage = "退会処理中にエラーが発生しました: \(error.localizedDescription)"
                }
            } else if let accountError = error as? DeleteAccountError {
                errorMessage = accountError.errorDescription ?? "退会処理中にエラーが発生しました。"
            } else {
                errorMessage = "退会処理中にエラーが発生しました: \(error.localizedDescription)"
            }
            
            isDeleting = false
            showError(errorMessage)
        }
    }
}
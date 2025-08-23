import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    
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
                        showingDeleteAccountAlert = true
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
            .alert("アカウント削除の確認", isPresented: $showingDeleteAccountAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("続ける", role: .destructive) {
                    showingDeleteAccountConfirmation = true
                }
            } message: {
                Text("本当にアカウントを削除しますか？\n\nこの操作は取り消すことができません。すべての読書記録、メモ、設定が完全に削除されます。")
            }
            .alert("最終確認", isPresented: $showingDeleteAccountConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("本当にアカウントを削除してよろしいですか？\n\nこの操作を実行すると、二度と元に戻すことはできません。")
            }
            .alert("エラー", isPresented: .constant(deleteError != nil)) {
                Button("OK") {
                    deleteError = nil
                }
            } message: {
                if let error = deleteError {
                    Text(error)
                }
            }
        }
    }
    
    private func deleteAccount() async {
        isDeleting = true
        
        // 認証状態を確認
        guard AuthService.shared.currentUser != nil else {
            deleteError = "認証情報が見つかりません。再度ログインしてください。"
            isDeleting = false
            return
        }
        
        do {
            try await AuthService.shared.deleteAccount()
            // 削除成功 - サインアウト処理
            await authViewModel.signOut()
        } catch {
            deleteError = error.localizedDescription
        }
        
        isDeleting = false
    }
}
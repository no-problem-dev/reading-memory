import SwiftUI

struct ProfileTabView: View {
    @State private var showLogout = false
    @State private var showDeleteAccount = false
    @State private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // プロフィール情報をリストのヘッダーとして配置
                Section {
                    EmptyView()
                } header: {
                    ZStack {
                        MemoryTheme.Colors.secondaryBackground
                            .ignoresSafeArea(edges: .horizontal)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, -20) // List のパディングを相殺
                        
                        ProfileHeaderView()
                            .padding(.vertical, MemorySpacing.lg)
                    }
                    .textCase(nil) // ヘッダーテキストの大文字変換を無効化
                    .listRowInsets(EdgeInsets())
                }
                
                Section {
                    NavigationLink {
                        ProfileEditView(viewModel: profileViewModel)
                    } label: {
                        Label("プロフィールを編集", systemImage: "person.fill")
                    }
                    
                    NavigationLink {
                        PublicBookshelfSettingsView()
                    } label: {
                        Label("公開本棚の設定", systemImage: "books.vertical.circle")
                    }
                }
                
                Section {
                    NavigationLink {
                        Text("プライバシー設定")
                            .navigationTitle("プライバシー設定")
                    } label: {
                        Label("プライバシー設定", systemImage: "lock.fill")
                    }
                    
                    NavigationLink {
                        Text("通知設定")
                            .navigationTitle("通知設定")
                    } label: {
                        Label("通知設定", systemImage: "bell.fill")
                    }
                }
                
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("このアプリについて", systemImage: "info.circle.fill")
                    }
                    
                    NavigationLink {
                        Text("お問い合わせ")
                            .navigationTitle("お問い合わせ")
                    } label: {
                        Label("お問い合わせ", systemImage: "envelope.fill")
                    }
                }
                
                Section {
                    Button {
                        showLogout = true
                    } label: {
                        Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.forward")
                            .foregroundColor(.red)
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAccount = true
                    } label: {
                        Label("アカウントを削除", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.large)
            .background(MemoryTheme.Colors.background)
            .sheet(isPresented: $showLogout) {
                LogoutConfirmationView()
                                }
            .sheet(isPresented: $showDeleteAccount) {
                DeleteAccountConfirmationView()
                                }
        }
        .task {
            await profileViewModel.loadProfile()
        }
    }
}

// ログアウト確認ビュー
struct LogoutConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: MemorySpacing.xl) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.1),
                                    Color.red.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }
                .padding(.top, MemorySpacing.xl)
                
                // メッセージ
                VStack(spacing: MemorySpacing.sm) {
                    Text("ログアウトしますか？")
                        .font(MemoryTheme.Fonts.title3())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                    
                    Text("ログアウトすると、再度ログインが必要になります")
                        .font(MemoryTheme.Fonts.callout())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MemorySpacing.lg)
                }
                
                Spacer()
                
                // ボタン
                VStack(spacing: MemorySpacing.md) {
                    Button {
                        Task {
                            await authViewModel.signOut()
                        }
                    } label: {
                        Text("ログアウト")
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MemorySpacing.md)
                            .background(Color.red)
                            .cornerRadius(MemoryRadius.medium)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                            .font(MemoryTheme.Fonts.headline())
                            .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MemorySpacing.md)
                            .background(MemoryTheme.Colors.cardBackground)
                            .cornerRadius(MemoryRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                    .stroke(MemoryTheme.Colors.primaryBlue, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, MemorySpacing.lg)
                .padding(.bottom, MemorySpacing.xl)
            }
            .background(MemoryTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .frame(width: 30, height: 30)
                            .background(MemoryTheme.Colors.cardBackground)
                            .clipShape(Circle())
                            .memoryShadow(.soft)
                    }
                }
            }
        }
    }
}

// アカウント削除確認ビュー
struct DeleteAccountConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let confirmPhrase = "アカウントを削除"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MemorySpacing.xl) {
                    // 警告アイコン
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.red.opacity(0.1),
                                        Color.red.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                    }
                    .padding(.top, MemorySpacing.xl)
                    
                    // 警告メッセージ
                    VStack(spacing: MemorySpacing.md) {
                        Text("アカウント削除の確認")
                            .font(MemoryTheme.Fonts.title2())
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                        
                        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                            Text("この操作は取り消すことができません。以下のデータがすべて削除されます：")
                                .font(MemoryTheme.Fonts.callout())
                                .foregroundColor(MemoryTheme.Colors.inkGray)
                            
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16))
                                    Text("すべての読書記録")
                                        .font(MemoryTheme.Fonts.callout())
                                }
                                
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16))
                                    Text("すべてのチャットメモ")
                                        .font(MemoryTheme.Fonts.callout())
                                }
                                
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16))
                                    Text("読書目標とアチーブメント")
                                        .font(MemoryTheme.Fonts.callout())
                                }
                                
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16))
                                    Text("プロフィール情報")
                                        .font(MemoryTheme.Fonts.callout())
                                }
                            }
                            .foregroundColor(MemoryTheme.Colors.inkBlack)
                            .padding(.leading, MemorySpacing.sm)
                        }
                        .padding(.horizontal, MemorySpacing.lg)
                    }
                    
                    // 確認入力
                    VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                        Text("確認のため「\(confirmPhrase)」と入力してください")
                            .font(MemoryTheme.Fonts.caption())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                        
                        TextField("", text: $confirmationText)
                            .font(MemoryTheme.Fonts.body())
                            .padding(MemorySpacing.md)
                            .background(MemoryTheme.Colors.cardBackground)
                            .cornerRadius(MemoryRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                    .stroke(
                                        confirmationText == confirmPhrase ? Color.red : MemoryTheme.Colors.inkPale,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .padding(.horizontal, MemorySpacing.lg)
                    
                    // ボタン
                    VStack(spacing: MemorySpacing.md) {
                        Button {
                            deleteAccount()
                        } label: {
                            if isDeleting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MemorySpacing.md)
                                    .background(Color.red.opacity(0.6))
                                    .cornerRadius(MemoryRadius.medium)
                            } else {
                                Text("アカウントを削除する")
                                    .font(MemoryTheme.Fonts.headline())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MemorySpacing.md)
                                    .background(confirmationText == confirmPhrase ? Color.red : Color.red.opacity(0.3))
                                    .cornerRadius(MemoryRadius.medium)
                            }
                        }
                        .disabled(confirmationText != confirmPhrase || isDeleting)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("キャンセル")
                                .font(MemoryTheme.Fonts.headline())
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, MemorySpacing.md)
                                .background(MemoryTheme.Colors.cardBackground)
                                .cornerRadius(MemoryRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: MemoryRadius.medium)
                                        .stroke(MemoryTheme.Colors.primaryBlue, lineWidth: 1)
                                )
                        }
                        .disabled(isDeleting)
                    }
                    .padding(.horizontal, MemorySpacing.lg)
                    .padding(.bottom, MemorySpacing.xl)
                }
            }
            .background(MemoryTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .frame(width: 30, height: 30)
                            .background(MemoryTheme.Colors.cardBackground)
                            .clipShape(Circle())
                            .memoryShadow(.soft)
                    }
                    .disabled(isDeleting)
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        
        Task {
            do {
                // TODO: Implement actual account deletion
                // This would typically involve:
                // 1. Call a Cloud Function to delete all user data
                // 2. Delete the Firebase Auth account
                // 3. Sign out
                
                // For now, just show an error that it's not implemented
                throw NSError(domain: "DeleteAccount", code: 0, userInfo: [NSLocalizedDescriptionKey: "アカウント削除機能は現在準備中です"])
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isDeleting = false
                }
            }
        }
    }
}

#Preview {
    ProfileTabView()
        .environment(AuthViewModel())
        }
import SwiftUI
import StoreKit
import MessageUI

struct ProfileTabView: View {
    @Environment(SubscriptionStateStore.self) private var subscriptionState
    @Environment(AnalyticsService.self) private var analytics
    @State private var showLogout = false
    @State private var showDeleteAccount = false
    @State private var showPaywall = false
    @State private var showMailComposer = false
    @State private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MemoryTheme.Colors.secondaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header using new component
                    TabHeaderView(
                        title: "設定",
                        subtitle: "アプリを自分好みに"
                    )
                    
                    // Content
                    List {
                        // プロフィール情報をリストのヘッダーとして配置
                        Section {
                            EmptyView()
                        } header: {
                            ZStack {
                                MemoryTheme.Colors.background
                                    .ignoresSafeArea(edges: .horizontal)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, -20) // List のパディングを相殺
                                
                                ProfileHeaderSection()
                                    .padding(.vertical, MemorySpacing.lg)
                            }
                            .textCase(nil) // ヘッダーテキストの大文字変換を無効化
                            .listRowInsets(EdgeInsets())
                        }
                        
                        // プレミアムプラン導線（非プレミアムユーザーのみ）
                        if !subscriptionState.isSubscribed {
                            Section {
                                PremiumPromotionCard(showPaywall: $showPaywall)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .listRowBackground(Color.clear)
                            }
                        }
                        
                        // アカウント設定
                        Section("アカウント") {
                            NavigationLink {
                                ProfileEditView()
                            } label: {
                                Label("プロフィールを編集", systemImage: "person.fill")
                            }
                            .onTapGesture {
                                analytics.track(AnalyticsEvent.userAction(action: .sectionTapped(section: "edit_profile")))
                            }
                        }
                        
                        // サポート
                        Section("サポート") {
                            Button {
                                analytics.track(AnalyticsEvent.userAction(action: .sectionTapped(section: "feedback")))
                                if MFMailComposeViewController.canSendMail() {
                                    showMailComposer = true
                                } else {
                                    // メールが設定されていない場合の処理
                                    openMailToURL()
                                }
                            } label: {
                                Label("お問い合わせ", systemImage: "envelope.fill")
                                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                            }
                            
                            Button {
                                requestAppReview()
                            } label: {
                                Label("アプリを評価する", systemImage: "star.fill")
                                    .foregroundColor(MemoryTheme.Colors.inkBlack)
                            }
                        }
                        
                        // その他
                        Section("その他") {
                            Button {
                                analytics.track(AnalyticsEvent.userAction(action: .sectionTapped(section: "logout")))
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
                    .background(MemoryTheme.Colors.background)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showLogout) {
                LogoutConfirmationView()
                            }
            .sheet(isPresented: $showDeleteAccount) {
                DeleteAccountConfirmationView()
                            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(
                    recipients: ["info@no-problem-net.com"],
                    subject: "読書メモリー お問い合わせ",
                    messageBody: generateSupportEmailBody()
                )
            }
        }
        .task {
            await profileViewModel.loadProfile()
        }
        .onAppear {
            analytics.track(AnalyticsEvent.screenView(screen: .profile))
        }
    }
    
    // MARK: - Helper Methods
    
    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func openMailToURL() {
        let subject = "読書メモリー お問い合わせ"
        let body = generateSupportEmailBody()
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:info@no-problem-net.com?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func generateSupportEmailBody() -> String {
        let device = UIDevice.current
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "不明"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "不明"
        
        return """
        【お問い合わせ内容】
        
        
        
        ---
        【アプリ情報】
        アプリバージョン: \(appVersion) (\(buildNumber))
        iOS バージョン: \(device.systemVersion)
        デバイス: \(device.model)
        """
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
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showFinalConfirmation = false
    @State private var showingSheet = true
    
    var body: some View {
        if showingSheet {
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
                                        .foregroundColor(MemoryTheme.Colors.warning)
                                        .font(.system(size: 16))
                                    Text("すべての読書記録")
                                        .font(MemoryTheme.Fonts.callout())
                                }
                                
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MemoryTheme.Colors.warning)
                                        .font(.system(size: 16))
                                    Text("すべてのチャットメモ")
                                        .font(MemoryTheme.Fonts.callout())
                                }
                                
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MemoryTheme.Colors.warning)
                                        .font(.system(size: 16))
                                    Text("読書目標とアチーブメント")
                                        .font(MemoryTheme.Fonts.callout())
                                }
                                
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MemoryTheme.Colors.warning)
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
                    
                    Spacer()
                    
                    // ボタン
                    VStack(spacing: MemorySpacing.md) {
                        Button {
                            showFinalConfirmation = true
                        } label: {
                            if isDeleting {
                                HStack(spacing: MemorySpacing.sm) {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                    Text("削除しています...")
                                        .font(MemoryTheme.Fonts.headline())
                                        .foregroundColor(.white)
                                }
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
                                    .background(Color.red)
                                    .cornerRadius(MemoryRadius.medium)
                            }
                        }
                        .disabled(isDeleting)
                        
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
            .alert("最終確認", isPresented: $showFinalConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("本当に退会してよろしいですか？\n\nこの操作を実行すると、二度と元に戻すことはできません。")
            }
        }
    } else {
        Color.clear
            .onAppear {
                // シートが閉じられた後、少し待ってからログイン画面に遷移
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                    if authViewModel.currentUser == nil {
                        // すでにログイン画面に遷移しているはず
                    }
                }
            }
    }
    }
    
    private func deleteAccount() {
        isDeleting = true
        
        Task {
            do {
                try await AuthService.shared.deleteAccount()
                // 削除が成功した場合、シートを閉じる
                await MainActor.run {
                    showingSheet = false
                    dismiss()
                    
                    // 強制的にサインアウト処理を実行
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
                        try? AuthService.shared.signOut()
                        authViewModel.currentUser = nil
                    }
                }
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

// プロフィールヘッダーセクション
struct ProfileHeaderSection: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profile: UserProfile?
    @State private var statistics = ProfileViewModel.ProfileStatistics()
    
    var body: some View {
        VStack(spacing: MemorySpacing.md) {
            // アバター
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                MemoryTheme.Colors.primaryBlueLight.opacity(0.3),
                                MemoryTheme.Colors.primaryBlue.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .memoryShadow(.soft)
                
                ProfileImageView(imageId: profile?.avatarImageId, size: 72)
            }
            
            // 名前
            if let profile = profile {
                VStack(spacing: MemorySpacing.xs) {
                    Text(profile.displayName)
                        .font(MemoryTheme.Fonts.headline())
                        .foregroundColor(MemoryTheme.Colors.inkBlack)
                    
                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(MemoryTheme.Fonts.footnote())
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
            
            // 統計サマリー
            HStack(spacing: MemorySpacing.lg) {
                ProfileStatItem(
                    value: "\(statistics.completedBooks)",
                    label: "読了"
                )
                Divider()
                    .frame(height: 30)
                    .foregroundColor(MemoryTheme.Colors.inkPale)
                ProfileStatItem(
                    value: "\(statistics.readingBooks)",
                    label: "読書中"
                )
                Divider()
                    .frame(height: 30)
                    .foregroundColor(MemoryTheme.Colors.inkPale)
                ProfileStatItem(
                    value: "\(statistics.wantToReadBooks)",
                    label: "読みたい"
                )
            }
            .padding(.horizontal, MemorySpacing.lg)
            .padding(.vertical, MemorySpacing.sm)
            .background(MemoryTheme.Colors.cardBackground)
            .cornerRadius(MemoryRadius.medium)
            .memoryShadow(.soft)
        }
        .task {
            await loadProfile()
            await loadStatistics()
        }
    }
    
    private func loadProfile() async {
        do {
            profile = try await APIClient.shared.getUserProfile()
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
    
    private func loadStatistics() async {
        let viewModel = ProfileViewModel()
        await viewModel.loadProfile()
        statistics = viewModel.statistics
    }
}

struct ProfileStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: MemorySpacing.xs) {
            Text(value)
                .font(MemoryTheme.Fonts.title3())
                .fontWeight(.bold)
                .foregroundColor(MemoryTheme.Colors.primaryBlue)
            Text(label)
                .font(MemoryTheme.Fonts.caption())
                .foregroundColor(MemoryTheme.Colors.inkGray)
        }
    }
}

// MARK: - Premium Promotion Card
struct PremiumPromotionCard: View {
    @Binding var showPaywall: Bool
    @State private var animateGradient = false
    
    var body: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(spacing: 0) {
                // グラデーション背景
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            MemoryTheme.Colors.goldenMemory,
                            MemoryTheme.Colors.goldenMemoryLight,
                            MemoryTheme.Colors.primaryBlue
                        ]),
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                    
                    VStack(spacing: MemorySpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                                HStack(spacing: MemorySpacing.xs) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    
                                    Text("メモリープラス")
                                        .font(MemoryTheme.Fonts.title3())
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                Text("もっと便利な機能を使おう")
                                    .font(MemoryTheme.Fonts.callout())
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(MemorySpacing.lg)
                    }
                }
                .frame(height: 100)
            }
            .cornerRadius(MemoryRadius.large)
            .padding(.horizontal, MemorySpacing.md)
            .padding(.vertical, MemorySpacing.sm)
            .memoryShadow(.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Mail Composer View
struct MailComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients(recipients)
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(messageBody, isHTML: false)
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    ProfileTabView()
        .environment(AuthViewModel())
        .environment(ServiceContainer.shared.getSubscriptionStateStore())
        }
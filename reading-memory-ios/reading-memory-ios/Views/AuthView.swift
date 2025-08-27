import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    MemoryTheme.Colors.primaryBlue.opacity(0.05),
                    MemoryTheme.Colors.warmCoral.opacity(0.03),
                    Color(.systemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo and Title Section
                VStack(spacing: MemorySpacing.xl) {
                    // Book Icon with gradient
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.primaryBlueLight.opacity(0.2),
                                        MemoryTheme.Colors.primaryBlue.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .memoryShadow(.soft)
                        
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        MemoryTheme.Colors.primaryBlue,
                                        MemoryTheme.Colors.primaryBlueDark
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: MemorySpacing.sm) {
                        Text("読書メモリー")
                            .font(.largeTitle)
                            .foregroundColor(Color(.label))
                        
                        VStack(spacing: MemorySpacing.xs) {
                            Text("本と過ごした時間を")
                                .font(.callout)
                                .foregroundColor(Color(.secondaryLabel))
                            Text("ずっと大切に")
                                .font(.callout)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
                .padding(.top, 80)
                
                Spacer()
                
                // Sign In Buttons
                VStack(spacing: MemorySpacing.md) {
                    // Feature Highlights
                    VStack(spacing: MemorySpacing.sm) {
                        FeatureHighlight(
                            icon: "bubble.left.and.bubble.right.fill",
                            text: "読書メモで感想を記録",
                            color: MemoryTheme.Colors.primaryBlue
                        )
                        
                        FeatureHighlight(
                            icon: "sparkles",
                            text: "AIが読書体験をサポート",
                            color: MemoryTheme.Colors.warmCoral
                        )
                        
                        FeatureHighlight(
                            icon: "books.vertical.fill",
                            text: "美しい本棚で思い出を整理",
                            color: MemoryTheme.Colors.goldenMemory
                        )
                    }
                    .padding(.horizontal, MemorySpacing.xl)
                    .padding(.bottom, MemorySpacing.lg)
                    
                    // Google Sign In
                    Button(action: {
                        Task {
                            await authViewModel.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: MemorySpacing.sm) {
                            Image(systemName: "globe")
                                .font(.system(size: 20))
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            Text("Googleでサインイン")
                                .font(.headline)
                                .foregroundColor(Color(.label))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.tertiarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: MemoryRadius.large)
                                .stroke(MemoryTheme.Colors.primaryBlue.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(MemoryRadius.large)
                        .memoryShadow(.soft)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, MemorySpacing.lg)
                    
                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: { request in
                            let appleRequest = authViewModel.startSignInWithAppleFlow()
                            request.requestedScopes = appleRequest.requestedScopes
                            request.nonce = appleRequest.nonce
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                Task {
                                    await authViewModel.signInWithApple(authorization: authorization)
                                }
                            case .failure(let error):
                                authViewModel.errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(MemoryRadius.large)
                    .padding(.horizontal, MemorySpacing.lg)
                    
                    // Legal Links
                    VStack(spacing: MemorySpacing.xs) {
                        Text("サインインすることで、以下に同意したものとみなされます")
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: MemorySpacing.xs) {
                            Link("利用規約", destination: URL(string: "https://taniguchi-kyoichi.com/products/dokusho-memory/terms")!)
                                .font(.caption)
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                            
                            Text("・")
                                .font(.caption)
                                .foregroundColor(Color(.tertiaryLabel))
                            
                            Link("プライバシーポリシー", destination: URL(string: "https://taniguchi-kyoichi.com/products/dokusho-memory/privacy")!)
                                .font(.caption)
                                .foregroundColor(MemoryTheme.Colors.primaryBlue)
                        }
                    }
                    .padding(.top, MemorySpacing.md)
                    .padding(.horizontal, MemorySpacing.lg)
                }
                .padding(.bottom, 50)
            }
            
            if authViewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack(spacing: MemorySpacing.md) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("サインイン中...")
                        .font(.callout)
                        .foregroundColor(.white)
                }
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { authViewModel.showError },
            set: { _ in authViewModel.clearError() }
        )) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }
}

struct FeatureHighlight: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: MemorySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
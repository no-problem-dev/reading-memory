import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var authViewModel = AuthViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.tint)
                    
                    VStack(spacing: 8) {
                        Text("読書メモリー")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("本と過ごした時間を、ずっと大切に")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await authViewModel.signInWithGoogle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.title3)
                            Text("Googleでサインイン")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                    }
                    .foregroundColor(.primary)
                    
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(_):
                                // TODO: Handle Apple Sign In
                                break
                            case .failure(let error):
                                authViewModel.errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            
            if authViewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .alert("エラー", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }
}
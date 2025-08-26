import SwiftUI
import PhotosUI
// import FirebaseStorage

struct ProfileSetupView: View {
    @State private var displayName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @Environment(AuthViewModel.self) private var authViewModel
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill.badge.plus")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                    
                    VStack(spacing: 8) {
                        Text("プロフィールを設定")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("読書メモリーへようこそ！\nあなたのプロフィールを設定しましょう")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                
                // Profile Image Section
                VStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhoto,
                               matching: .images,
                               photoLibrary: .shared()) {
                        VStack(spacing: 12) {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 3)
                                    )
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.title)
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            Text("プロフィール画像を選択")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            await loadImage(from: newItem)
                        }
                    }
                }
                
                // Display Name Section
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("表示名")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("あなたの名前を入力してください", text: $displayName)
                            .memoryTextFieldStyle()
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                            .submitLabel(.done)
                    }
                    
                    Text("この名前は他のユーザーに表示されます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Continue Button
                Button {
                    Task {
                        await createProfile()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        
                        Text(isLoading ? "設定中..." : "始める")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidInput ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValidInput || isLoading)
                
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .navigationBarHidden(true)
            .disabled(isLoading)
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .keyboardAware()
    }
    
    private var isValidInput: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Resize image to reduce file size
                let resizedImage = image.resized(to: CGSize(width: 400, height: 400))
                profileImage = resizedImage
            }
        } catch {
            errorMessage = "画像の読み込みに失敗しました"
        }
    }
    
    @MainActor
    private func createProfile() async {
        guard let currentUser = authViewModel.currentUser else {
            errorMessage = "ユーザー情報が見つかりません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let userProfileRepository = UserProfileRepository.shared
            
            // Upload profile image if selected
            var avatarImageId: String?
            if let profileImage = profileImage {
                avatarImageId = try await uploadProfileImage(image: profileImage, userId: currentUser.id)
            }
            
            // Create minimal profile
            let profile = UserProfile(
                id: currentUser.id,
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                avatarImageId: avatarImageId,
                bio: nil,
                favoriteGenres: [],
                readingGoal: nil,
                isPublic: false
            )
            
            _ = try await userProfileRepository.createUserProfile(profile)
            
            // Complete onboarding
            onComplete()
            
        } catch {
            errorMessage = AppError.from(error).localizedDescription
        }
        
        isLoading = false
    }
    
    private func uploadProfileImage(image: UIImage, userId: String) async throws -> String {
        let storageService = StorageService.shared
        return try await storageService.uploadImage(image)
    }
}

// MARK: - UIImage Extension
private extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    ProfileSetupView {
        print("Profile setup completed")
    }
    .environment(AuthViewModel())
}
import SwiftUI
import PhotosUI

struct ProfileSetupStep: View {
    @Binding var displayName: String
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var profileImage: UIImage?
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    VStack(spacing: 8) {
                        Text("プロフィールを設定")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("あなたのことを教えてください")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 40)
                
                // Profile Image
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
                        
                        Text("写真を選択")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        await loadImage(from: newItem)
                    }
                }
                
                // Display Name
                VStack(alignment: .leading, spacing: 12) {
                    Text("表示名")
                        .font(.headline)
                    
                    TextField("あなたの名前", text: $displayName)
                        .memoryTextFieldStyle()
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .submitLabel(.done)
                        .focused($isNameFieldFocused)
                        .onSubmit {
                            isNameFieldFocused = false
                        }
                    
                    Text("この名前は公開本棚で他のユーザーに表示されます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .onTapGesture {
            isNameFieldFocused = false
        }
    }
    
    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Crop to square and resize image
                let processedImage = image.croppedToSquare(targetSize: 400)
                profileImage = processedImage
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}


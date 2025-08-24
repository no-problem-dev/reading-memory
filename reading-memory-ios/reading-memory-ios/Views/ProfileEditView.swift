import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newGenre = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Image Section
                Section {
                    HStack {
                        Spacer()
                        
                        PhotosPicker(selection: $viewModel.selectedPhoto,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            VStack {
                                if let profileImage = viewModel.profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    ProfileImageView(imageId: viewModel.userProfile?.avatarImageId, size: 100)
                                }
                                
                                Text("写真を変更")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .onChange(of: viewModel.selectedPhoto) { _, newItem in
                            Task {
                                await viewModel.loadImage(from: newItem)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Basic Information
                Section("基本情報") {
                    TextField("表示名", text: $viewModel.editDisplayName)
                        .textContentType(.name)
                    
                    TextField("自己紹介", text: $viewModel.editBio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Reading Goal
                Section("読書目標") {
                    HStack {
                        TextField("年間読書目標", text: $viewModel.editReadingGoal)
                            .keyboardType(.numberPad)
                        Text("冊")
                    }
                }
                
                // Favorite Genres
                Section("お気に入りジャンル") {
                    if !viewModel.editFavoriteGenres.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.editFavoriteGenres, id: \.self) { genre in
                                HStack(spacing: 4) {
                                    Text(genre)
                                        .font(.caption)
                                    
                                    Button {
                                        viewModel.removeGenre(genre)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(15)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                    
                    HStack {
                        TextField("ジャンルを追加", text: $newGenre)
                            .textFieldStyle(.roundedBorder)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                addGenre()
                            }
                        
                        Button("追加") {
                            addGenre()
                        }
                        .disabled(newGenre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                // Privacy Settings
                Section("プライバシー設定") {
                    Toggle("プロフィールを公開", isOn: $viewModel.editIsPublic)
                    
                    if viewModel.editIsPublic {
                        Text("他のユーザーがあなたのプロフィールを閲覧できるようになります")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await viewModel.saveProfile()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.editDisplayName.isEmpty)
                }
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("保存中...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func addGenre() {
        viewModel.addGenre(newGenre)
        newGenre = ""
        isTextFieldFocused = false
    }
}

#Preview {
    ProfileEditView(viewModel: ProfileViewModel())
}
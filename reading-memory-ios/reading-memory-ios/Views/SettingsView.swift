import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
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
            }
            .navigationTitle("設定")
        }
    }
}
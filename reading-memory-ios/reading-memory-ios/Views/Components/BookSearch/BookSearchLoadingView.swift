import SwiftUI

struct BookSearchLoadingView: View {
    var body: some View {
        VStack(spacing: MemorySpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MemoryTheme.Colors.primaryBlue))
                .scaleEffect(1.5)
            
            Text("検索中...")
                .font(.body)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
}
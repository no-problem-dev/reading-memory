import SwiftUI

struct BookSearchNoResults: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: MemorySpacing.xl) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.goldenMemoryLight.opacity(0.2),
                                    MemoryTheme.Colors.goldenMemory.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(MemoryTheme.Colors.goldenMemory)
                }
                
                VStack(spacing: MemorySpacing.sm) {
                    Text("検索結果が見つかりませんでした")
                        .font(.title3)
                        .foregroundColor(Color(.label))
                    
                    Text("別のキーワードで\n検索してみてください")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(MemorySpacing.xl)
    }
}
import SwiftUI

struct BookSearchEmptyState: View {
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
                                    MemoryTheme.Colors.primaryBlueLight.opacity(0.2),
                                    MemoryTheme.Colors.primaryBlue.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "books.vertical")
                        .font(.system(size: 50))
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
                    Text("本を検索してみましょう")
                        .font(.title3)
                        .foregroundColor(Color(.label))
                    
                    Text("タイトル、著者名、ISBNで\n検索できます")
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
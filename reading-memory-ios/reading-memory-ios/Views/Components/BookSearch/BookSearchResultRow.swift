import SwiftUI

struct BookSearchResultRow: View {
    let searchResult: BookSearchResult
    let onTap: () -> Void
    @State private var isRegistered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MemorySpacing.md) {
                // Book cover
                Group {
                    if let coverImageUrl = searchResult.coverImageUrl {
                        RemoteImage(urlString: coverImageUrl)
                    } else {
                        Image(systemName: "book.closed")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.secondarySystemFill))
                    }
                }
                .frame(width: 60, height: 90)
                .cornerRadius(MemoryRadius.small)
                .memoryShadow(.soft)
                
                // Book info
                VStack(alignment: .leading, spacing: MemorySpacing.xs) {
                    Text(searchResult.title)
                        .font(.headline)
                        .foregroundColor(Color(.label))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(searchResult.author)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                    
                    HStack(spacing: MemorySpacing.sm) {
                        // Data source badge
                        DataSourceBadge(dataSource: searchResult.dataSource)
                        
                        Spacer()
                        
                        // Status indicator
                        if isRegistered {
                            Label("登録済み", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color(.systemGreen))
                        }
                    }
                }
                
                Spacer()
                
                // Add/Check button
                if isRegistered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(MemoryTheme.Colors.success)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
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
            }
            .padding(MemorySpacing.md)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(MemoryRadius.large)
            .memoryShadow(.soft)
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            let viewModel = BookSearchViewModel()
            isRegistered = await viewModel.isBookAlreadyRegistered(searchResult)
        }
    }
}

// MARK: - Data Source Badge
private struct DataSourceBadge: View {
    let dataSource: BookDataSource
    
    var body: some View {
        HStack(spacing: MemorySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, MemorySpacing.sm)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(MemoryRadius.full)
    }
    
    private var text: String {
        switch dataSource {
        case .googleBooks:
            return "Google Books"
        case .openBD:
            return "OpenBD"
        case .rakutenBooks:
            return "楽天ブックス"
        case .manual:
            return "手動入力"
        }
    }
    
    private var icon: String {
        switch dataSource {
        case .googleBooks, .openBD, .rakutenBooks:
            return "globe"
        case .manual:
            return "pencil"
        }
    }
    
    private var color: Color {
        switch dataSource {
        case .googleBooks:
            return MemoryTheme.Colors.primaryBlue
        case .openBD:
            return MemoryTheme.Colors.warmCoral
        case .rakutenBooks:
            return MemoryTheme.Colors.goldenMemory
        case .manual:
            return Color(.secondaryLabel)
        }
    }
}


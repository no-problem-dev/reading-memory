import SwiftUI

struct BookSearchBar: View {
    @Binding var searchText: String
    @FocusState var isSearchFieldFocused: Bool
    let onSearch: () async -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, MemorySpacing.md)
                .padding(.vertical, MemorySpacing.sm)
        }
        .background(Color(.tertiarySystemBackground))
        .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var searchBar: some View {
        HStack(spacing: MemorySpacing.sm) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(isSearchFieldFocused ? MemoryTheme.Colors.primaryBlue : Color(.secondaryLabel))
                .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
            
            // Text field
            TextField("タイトル、著者、ISBN", text: $searchText)
                .memoryTextFieldStyle()
                .focused($isSearchFieldFocused)
                .onSubmit {
                    Task {
                        await onSearch()
                    }
                }
            
            // Clear button
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onClear()
                        isSearchFieldFocused = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            
            // Search button
            if !searchText.isEmpty {
                Button {
                    Task {
                        isSearchFieldFocused = false
                        await onSearch()
                    }
                } label: {
                    Text("検索")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, MemorySpacing.md)
                        .padding(.vertical, MemorySpacing.xs)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MemoryTheme.Colors.primaryBlue,
                                    MemoryTheme.Colors.primaryBlueDark
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(MemoryRadius.full)
                }
            }
        }
        .padding(.horizontal, MemorySpacing.md)
        .padding(.vertical, MemorySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MemoryRadius.large)
                .fill(MemoryTheme.Colors.inkPale.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: MemoryRadius.large)
                        .stroke(isSearchFieldFocused ? MemoryTheme.Colors.primaryBlue : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
    }
}
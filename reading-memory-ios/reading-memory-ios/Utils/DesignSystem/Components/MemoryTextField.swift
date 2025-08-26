import SwiftUI

struct MemoryTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isRequired: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.xs) {
            // Label if required indicator is needed
            if isRequired {
                HStack(spacing: MemorySpacing.xs) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(MemoryTheme.Colors.inkGray)
                    }
                    
                    Text(placeholder)
                        .font(MemoryTheme.Fonts.subheadline())
                        .foregroundColor(MemoryTheme.Colors.inkGray)
                    
                    Text("*")
                        .font(MemoryTheme.Fonts.subheadline())
                        .foregroundColor(MemoryTheme.Colors.error)
                }
            }
            
            // Text field
            HStack(spacing: MemorySpacing.sm) {
                if !isRequired, let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? MemoryTheme.Colors.primaryBlue : MemoryTheme.Colors.inkGray)
                        .font(.system(size: 20))
                }
                
                TextField(isRequired ? "" : placeholder, text: $text)
                    .font(MemoryTheme.Fonts.body())
                    .foregroundStyle(textColor)
                    .tint(MemoryTheme.Colors.primaryBlue)
                    .keyboardType(keyboardType)
                    .focused($isFocused)
            }
            .padding(.horizontal, MemorySpacing.md)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(MemoryRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: MemoryRadius.medium)
                    .stroke(isFocused ? MemoryTheme.Colors.primaryBlue : MemoryTheme.Colors.inkPale.opacity(0.5), lineWidth: isFocused ? 2 : 1)
            )
            .animation(MemoryTheme.Animation.fast, value: isFocused)
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : MemoryTheme.Colors.inkBlack
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? MemoryTheme.Colors.cardBackground.opacity(0.8) : MemoryTheme.Colors.cardBackground
    }
}

struct MemoryTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(MemoryTheme.Fonts.body())
                    .foregroundColor(MemoryTheme.Colors.inkGray)
                    .padding(.horizontal, MemorySpacing.md)
                    .padding(.top, MemorySpacing.sm)
            }
            
            TextEditor(text: $text)
                .font(MemoryTheme.Fonts.body())
                .foregroundStyle(textColor)
                .tint(MemoryTheme.Colors.primaryBlue)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, MemorySpacing.xs)
                .padding(.vertical, MemorySpacing.xs)
                .focused($isFocused)
        }
        .frame(minHeight: minHeight)
        .background(backgroundColor)
        .cornerRadius(MemoryRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: MemoryRadius.medium)
                .stroke(isFocused ? MemoryTheme.Colors.primaryBlue : MemoryTheme.Colors.inkPale.opacity(0.5), lineWidth: isFocused ? 2 : 1)
        )
        .animation(MemoryTheme.Animation.fast, value: isFocused)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : MemoryTheme.Colors.inkBlack
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? MemoryTheme.Colors.cardBackground.opacity(0.8) : MemoryTheme.Colors.cardBackground
    }
}
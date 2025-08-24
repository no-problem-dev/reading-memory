import SwiftUI

enum MemoryButtonStyle {
    case primary
    case secondary
    case text
}

struct MemoryButton: View {
    let title: String
    let style: MemoryButtonStyle
    let action: () -> Void
    
    @Environment(\.isEnabled) var isEnabled
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(.headline)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, MemorySpacing.lg)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(background)
                .overlay(overlay)
                .cornerRadius(MemoryRadius.large)
        }
        .memoryShadow(style == .primary ? .medium : .soft)
        .scaleEffect(isEnabled ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .text:
            return isEnabled ? ColorPalette.primary : ColorPalette.textTertiary
        }
    }
    
    private var background: some View {
        Group {
            switch style {
            case .primary:
                ColorPalette.primary.opacity(isEnabled ? 1.0 : 0.6)
            case .secondary:
                ColorPalette.primary.opacity(0.1)
            case .text:
                Color.clear
            }
        }
    }
    
    private var overlay: some View {
        Group {
            if style == .secondary {
                RoundedRectangle(cornerRadius: MemoryRadius.large)
                    .stroke(ColorPalette.primary.opacity(isEnabled ? 1.0 : 0.6), lineWidth: 1)
            }
        }
    }
}

struct SmallMemoryButton: View {
    let title: String
    let icon: String?
    let style: MemoryButtonStyle
    let action: () -> Void
    
    init(title: String, icon: String? = nil, style: MemoryButtonStyle = .secondary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MemorySpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .memoryFont(.subheadline)
            }
            .foregroundColor(style == .primary ? .white : ColorPalette.primary)
            .padding(.horizontal, MemorySpacing.md)
            .padding(.vertical, MemorySpacing.xs)
            .background(
                Group {
                    switch style {
                    case .primary:
                        ColorPalette.primary
                    case .secondary:
                        ColorPalette.primary.opacity(0.1)
                    case .text:
                        Color.clear
                    }
                }
            )
            .cornerRadius(MemoryRadius.small)
        }
        .memoryShadow(style == .primary ? .soft : .soft)
    }
}
import SwiftUI

enum MemorySpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

enum MemoryRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let full: CGFloat = .infinity
}

struct MemoryShadow {
    enum Style {
        case soft
        case medium
        case strong
        
        var radius: CGFloat {
            switch self {
            case .soft: return 8
            case .medium: return 12
            case .strong: return 16
            }
        }
        
        var y: CGFloat {
            switch self {
            case .soft: return 2
            case .medium: return 4
            case .strong: return 8
            }
        }
        
        func opacity(for colorScheme: ColorScheme) -> Double {
            let multiplier: Double = colorScheme == .dark ? 1.5 : 1.0
            switch self {
            case .soft: return 0.1 * multiplier
            case .medium: return 0.15 * multiplier
            case .strong: return 0.2 * multiplier
            }
        }
    }
}

extension View {
    func memoryShadow(_ style: MemoryShadow.Style) -> some View {
        self.modifier(MemoryShadowModifier(style: style))
    }
}

struct MemoryShadowModifier: ViewModifier {
    let style: MemoryShadow.Style
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(style.opacity(for: colorScheme)),
                radius: style.radius,
                x: 0,
                y: style.y
            )
    }
}
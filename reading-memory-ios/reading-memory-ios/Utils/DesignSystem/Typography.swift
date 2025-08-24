import SwiftUI

enum MemoryFont {
    case hero
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    
    var size: CGFloat {
        switch self {
        case .hero: return 34
        case .title1: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        }
    }
    
    var weight: Font.Weight {
        switch self {
        case .hero, .title1: return .bold
        case .title2, .title3, .headline: return .semibold
        case .body, .callout, .subheadline, .footnote, .caption: return .regular
        }
    }
    
    var font: Font {
        Font.system(size: size, weight: weight, design: .default)
    }
}

extension View {
    func memoryFont(_ font: MemoryFont) -> some View {
        self.font(font.font)
    }
}

struct MemoryTextStyle: ViewModifier {
    let font: MemoryFont
    
    func body(content: Content) -> some View {
        content
            .font(font.font)
            .foregroundColor(ColorPalette.text)
    }
}

extension View {
    func textStyle(_ font: MemoryFont) -> some View {
        modifier(MemoryTextStyle(font: font))
    }
}
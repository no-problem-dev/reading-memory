import SwiftUI

extension Color {
    enum MemoryColors {
        static let primaryBlue = Color("MemoryBlue")
        static let primaryBlueLight = Color("MemoryBlueLight")
        static let primaryBlueDark = Color("MemoryBlueDark")
        
        static let secondaryCoral = Color("WarmCoral")
        static let secondaryCoralLight = Color("WarmCoralLight")
        static let secondaryCoralDark = Color("WarmCoralDark")
        
        static let accentGold = Color("GoldenMemory")
        static let accentGoldLight = Color("GoldenMemoryLight")
        static let accentGoldDark = Color("GoldenMemoryDark")
        
        static let inkBlack900 = Color("InkBlack900")
        static let inkBlack700 = Color("InkBlack700")
        static let inkBlack500 = Color("InkBlack500")
        static let inkBlack300 = Color("InkBlack300")
        static let inkBlack100 = Color("InkBlack100")
        static let inkBlack50 = Color("InkBlack50")
        
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let error = Color("Error")
        static let info = Color("Info")
        
        static let primaryBackground = Color("PrimaryBackground")
        static let secondaryBackground = Color("SecondaryBackground")
        static let cardBackground = Color("CardBackground")
        static let overlayBackground = Color("OverlayBackground")
    }
}

enum ColorPalette {
    static var primary: Color {
        Color.MemoryColors.primaryBlue
    }
    
    static var primaryLight: Color {
        Color.MemoryColors.primaryBlueLight
    }
    
    static var primaryDark: Color {
        Color.MemoryColors.primaryBlueDark
    }
    
    static var secondary: Color {
        Color.MemoryColors.secondaryCoral
    }
    
    static var secondaryLight: Color {
        Color.MemoryColors.secondaryCoralLight
    }
    
    static var secondaryDark: Color {
        Color.MemoryColors.secondaryCoralDark
    }
    
    static var accent: Color {
        Color.MemoryColors.accentGold
    }
    
    static var text: Color {
        MemoryTheme.Colors.inkBlack
    }
    
    static var textSecondary: Color {
        MemoryTheme.Colors.inkGray
    }
    
    static var textTertiary: Color {
        MemoryTheme.Colors.inkLightGray
    }
    
    static var background: Color {
        MemoryTheme.Colors.background
    }
    
    static var backgroundSecondary: Color {
        MemoryTheme.Colors.secondaryBackground
    }
    
    static var cardBackground: Color {
        MemoryTheme.Colors.cardBackground
    }
    
    static var divider: Color {
        MemoryTheme.Colors.inkLightGray
    }
    
    static var overlay: Color {
        Color.black.opacity(0.3)
    }
}


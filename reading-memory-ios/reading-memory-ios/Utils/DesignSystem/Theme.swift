import SwiftUI

struct MemoryTheme {
    // Asset Catalogから色を読み込む - 全て静的プロパティとして定義
    enum Colors {
        static let primaryBlue = Color("MemoryBlue")
        static let primaryBlueLight = Color("PrimaryBlueLight")
        static let primaryBlueDark = Color("PrimaryBlueDark")
        static let warmCoral = Color("WarmCoral")
        static let warmCoralLight = Color("WarmCoralLight")
        static let warmCoralDark = Color("WarmCoralDark")
        static let goldenMemory = Color("GoldenMemory")
        static let goldenMemoryLight = Color("GoldenMemoryLight")
        static let goldenMemoryDark = Color("GoldenMemoryDark")
        static let inkBlack = Color("InkBlack")
        static let inkGray = Color("InkGray")
        static let inkLightGray = Color("InkLightGray")
        static let inkPale = Color("InkPale")
        static let inkWhite = Color("InkWhite")
        static let background = Color("Background")
        static let cardBackground = Color("CardBackground")
        static let secondaryBackground = Color("SecondaryBackground")
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let error = Color("Error")
        static let info = Color("Info")
    }
    
    enum Fonts {
        static func hero() -> Font { .largeTitle.weight(.bold) }
        static func title() -> Font { .title.weight(.semibold) }
        static func title2() -> Font { .title2.weight(.semibold) }
        static func title3() -> Font { .title3.weight(.medium) }
        static func headline() -> Font { .headline }
        static func subheadline() -> Font { .subheadline }
        static func body() -> Font { .body }
        static func callout() -> Font { .callout }
        static func footnote() -> Font { .footnote }
        static func caption() -> Font { .caption }
    }
    
    enum Animation {
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
}


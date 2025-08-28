import SwiftUI

struct SplashScreenView: View {
    @State private var bookScale: CGFloat = 0.8
    @State private var bookOpacity: Double = 0
    @State private var pageFlipRotation: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    
    let onAnimationComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Solid gradient background using asset colors
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("PrimaryBlueLight"),
                    Color("MemoryBlue"),
                    Color("PrimaryBlueDark")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Additional overlay for depth
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.1),
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Book icon with animations
                ZStack {
                    // Glow effect behind book
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .blur(radius: 30)
                        .opacity(glowOpacity)
                        .scaleEffect(bookScale * 1.2)
                    
                    // Book base
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .scaleEffect(bookScale)
                        .opacity(bookOpacity)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    // Page flip effect
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.9))
                        .scaleEffect(bookScale)
                        .rotation3DEffect(
                            .degrees(pageFlipRotation),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(pageFlipRotation > 90 ? 0 : 1)
                    
                    // Sparkle effect using golden memory color
                    ForEach(0..<4) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 20))
                            .foregroundStyle(Color("GoldenMemory"))
                            .offset(
                                x: CGFloat([-40, 45, -20, 35][i]),
                                y: CGFloat([-30, -25, 35, 30][i])
                            )
                            .opacity(sparkleOpacity)
                            .rotationEffect(.degrees(Double(i) * 45))
                            .animation(
                                Animation.easeInOut(duration: 0.4)
                                    .delay(Double(i) * 0.1),
                                value: sparkleOpacity
                            )
                            .scaleEffect(sparkleOpacity > 0 ? 1.0 : 0.5)
                    }
                }
                
                VStack(spacing: 16) {
                    // App title
                    Text("読書メモリー")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)
                    
                    // Subtitle
                    Text("本との出会いを、ずっと大切に")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        .opacity(subtitleOpacity)
                }
            }
        }
        // Ensure full coverage with dark blue
        .background(Color("PrimaryBlueDark"))
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Phase 1: Book fade in and scale (0.0s - 0.4s)
        withAnimation(.easeOut(duration: 0.4)) {
            bookScale = 1.0
            bookOpacity = 1.0
            glowOpacity = 1.0
        }
        
        // Phase 2: Page flip animation (0.4s - 1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.8)) {
                pageFlipRotation = 180
            }
            
            // Sparkle effect during flip
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                sparkleOpacity = 1.0
            }
        }
        
        // Phase 3: Title animation (1.2s - 1.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        // Phase 4: Subtitle animation (1.7s - 2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeIn(duration: 0.3)) {
                subtitleOpacity = 1.0
            }
        }
        
        // Phase 5: Hold the final state (2.0s - 3.0s)
        // Then complete after 3 seconds total
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onAnimationComplete()
        }
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SplashScreenView {
        print("Animation completed")
    }
}
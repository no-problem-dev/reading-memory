import SwiftUI

struct SplashScreenView: View {
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    
    let onAnimationComplete: () -> Void
    
    var body: some View {
        ZStack {
            // シンプルで温かみのあるグラデーション背景
            LinearGradient(
                colors: [
                    Color("SplashGradientStart"),
                    Color("SplashGradientMid"),
                    Color("SplashGradientEnd")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 36) {
                Spacer()
                
                // 本のアイコン（シンプルに）
                Image(systemName: "book.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(Color("SplashAccent"))
                    .scaleEffect(showIcon ? 1 : 0.8)
                    .opacity(showIcon ? 1 : 0)
                
                // タイトルとサブタイトル
                VStack(spacing: 12) {
                    Text("読書メモリー")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundColor(Color("SplashText"))
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 10)
                    
                    Text("本との出会いを、ずっと大切に")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color("SplashText").opacity(0.8))
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 10)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            // シンプルで効果的なアニメーション
            withAnimation(.easeOut(duration: 0.6)) {
                showIcon = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showTitle = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showSubtitle = true
            }
            
            // 2秒後に完了（アニメーション時間 + 余韻）
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onAnimationComplete()
            }
        }
    }
}

#Preview {
    SplashScreenView {
        print("Animation completed")
    }
}
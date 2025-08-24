import SwiftUI

struct RecordsHubView: View {
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // セグメントコントロール
                Picker("記録タイプ", selection: $selectedSegment) {
                    Text("統計").tag(0)
                    Text("目標").tag(1)
                    Text("アチーブメント").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // コンテンツ
                TabView(selection: $selectedSegment) {
                    StatisticsView()
                        .tag(0)
                    
                    GoalDashboardView()
                        .tag(1)
                    
                    AchievementGalleryView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("読書記録")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    RecordsHubView()
        .environment(AuthViewModel())
}
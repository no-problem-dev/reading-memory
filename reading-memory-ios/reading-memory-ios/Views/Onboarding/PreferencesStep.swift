import SwiftUI

struct PreferencesStep: View {
    @Binding var selectedGenres: Set<String>
    @Binding var monthlyGoal: Int
    
    let genres = [
        "小説", "ビジネス", "自己啓発", "技術書",
        "歴史", "科学", "哲学", "アート",
        "料理", "旅行", "エッセイ", "漫画"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 8) {
                    Text("読書の好みを教えてください")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("あなたに合った体験をご提供します")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 40)
            
            // Genre Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("好きなジャンル（複数選択可）")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(genres, id: \.self) { genre in
                        GenreChip(
                            genre: genre,
                            isSelected: selectedGenres.contains(genre),
                            action: {
                                if selectedGenres.contains(genre) {
                                    selectedGenres.remove(genre)
                                } else {
                                    selectedGenres.insert(genre)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            // Monthly Goal
            VStack(alignment: .leading, spacing: 16) {
                Text("月間読書目標")
                    .font(.headline)
                
                HStack {
                    Stepper(value: $monthlyGoal, in: 1...20) {
                        HStack {
                            Text("\(monthlyGoal)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("冊/月")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Text("後から設定画面で変更できます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
}

// MARK: - Genre Chip
struct GenreChip: View {
    let genre: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(genre)
                .font(.callout)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
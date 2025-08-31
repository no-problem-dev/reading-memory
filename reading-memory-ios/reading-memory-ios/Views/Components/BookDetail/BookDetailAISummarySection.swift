import SwiftUI

struct BookDetailAISummarySection: View {
    let summary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                Text("AI要約")
                    .font(.headline)
            }
            
            Text(summary)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(MemoryRadius.medium)
        }
    }
}
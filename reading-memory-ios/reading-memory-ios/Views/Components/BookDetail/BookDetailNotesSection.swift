import SwiftUI

struct BookDetailNotesSection: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MemorySpacing.sm) {
            HStack {
                Image(systemName: "note.text")
                Text("メモ")
                    .font(.headline)
            }
            
            Text(notes)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(MemoryRadius.medium)
        }
    }
}
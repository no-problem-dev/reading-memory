import SwiftUI

struct RatingSelector: View {
    let book: Book
    @State private var rating: Double?
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    
    var body: some View {
        HStack(spacing: MemorySpacing.xs) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    Task {
                        await updateRating(to: Double(value))
                    }
                } label: {
                    Image(systemName: getRatingIcon(for: value))
                        .font(.system(size: 28))
                        .foregroundColor(MemoryTheme.Colors.goldenMemory)
                }
            }
        }
        .onAppear {
            rating = book.rating
        }
    }
    
    private func getRatingIcon(for value: Int) -> String {
        guard let rating = rating else {
            return "star"
        }
        
        if Double(value) <= rating {
            return "star.fill"
        } else if Double(value) - 0.5 <= rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    private func updateRating(to newRating: Double) async {
        guard let userId = authService.currentUser?.uid else { return }
        
        let targetRating = rating == newRating ? nil : newRating
        
        do {
            let updatedBook = book.updated(rating: targetRating)
            try await bookRepository.updateBook(updatedBook)
            
            withAnimation {
                rating = targetRating
            }
        } catch {
            print("Error updating rating: \(error)")
        }
    }
}
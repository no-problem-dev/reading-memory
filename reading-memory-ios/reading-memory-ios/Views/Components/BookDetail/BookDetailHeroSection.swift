import SwiftUI

struct BookDetailHeroSection: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover Image with gradient overlay
            ZStack(alignment: .bottom) {
                // Background
                Color(.secondarySystemBackground)
                    .frame(height: 320)
                
                // Cover Image
                RemoteImage(imageId: book.coverImageId, contentMode: .fill)
                    .frame(height: 320)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Book Info Overlay
                VStack(alignment: .leading, spacing: MemorySpacing.sm) {
                    Text(book.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if !book.displayAuthor.isEmpty {
                        Text(book.displayAuthor)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    if let publisher = book.publisher {
                        Text(publisher)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 320)
        }
    }
}
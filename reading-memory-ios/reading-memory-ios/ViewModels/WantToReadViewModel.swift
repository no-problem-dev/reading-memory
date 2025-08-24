import Foundation
import SwiftUI

@Observable
class WantToReadViewModel {
    private(set) var books: [Book] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allBooks = try await apiClient.getBooks()
            // 読みたいリストの本のみフィルタリング
            books = allBooks.filter { $0.status == .wantToRead }
                .sorted { (lhs, rhs) in
                    // 優先度でソート（高い順）
                    if let lhsPriority = lhs.priority, let rhsPriority = rhs.priority {
                        return lhsPriority > rhsPriority
                    }
                    // 優先度がない場合は追加日でソート（新しい順）
                    return lhs.addedDate > rhs.addedDate
                }
        } catch {
            errorMessage = "読みたいリストの読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateBookPriority(_ book: Book, priority: Int) async {
        do {
            let updatedBook = book.updated(priority: priority)
            _ = try await apiClient.updateBook(updatedBook)
            await loadBooks()
        } catch {
            errorMessage = "優先度の更新に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func moveToReading(_ book: Book) async {
        do {
            let updatedBook = book.updated(status: .reading, startDate: Date())
            _ = try await apiClient.updateBook(updatedBook)
            await loadBooks()
        } catch {
            errorMessage = "ステータスの更新に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func removeFromWantToRead(_ book: Book) async {
        do {
            try await apiClient.deleteBook(id: book.id)
            await loadBooks()
        } catch {
            errorMessage = "本の削除に失敗しました: \(error.localizedDescription)"
        }
    }
}
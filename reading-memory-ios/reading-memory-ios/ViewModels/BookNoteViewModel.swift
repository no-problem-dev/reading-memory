import Foundation
import SwiftUI

@Observable
@MainActor
class BookNoteViewModel {
    var book: Book?
    var noteText: String = ""
    var isLoading = false
    var errorMessage: String?
    var showingSaveConfirmation = false
    
    private let bookRepository = BookRepository.shared
    private let authService = AuthService.shared
    
    func loadBook(bookId: String) async {
        guard authService.currentUser?.uid != nil else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedBook = try await bookRepository.getBook(bookId: bookId)
            book = loadedBook
            noteText = loadedBook?.memo ?? ""
        } catch {
            errorMessage = "本の情報を読み込めませんでした"
            print("Error loading book: \(error)")
        }
        
        isLoading = false
    }
    
    func saveNote() async {
        guard authService.currentUser?.uid != nil,
              let book = book else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedBook = book.updated(memo: noteText)
            try await bookRepository.updateBook(updatedBook)
            self.book = updatedBook
            showingSaveConfirmation = true
            
            // 3秒後に確認メッセージを非表示
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showingSaveConfirmation = false
            }
        } catch {
            errorMessage = "メモの保存に失敗しました"
            print("Error saving note: \(error)")
        }
        
        isLoading = false
    }
    
    func clearNote() {
        noteText = ""
    }
}
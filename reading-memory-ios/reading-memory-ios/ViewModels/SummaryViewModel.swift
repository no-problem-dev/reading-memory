import Foundation
import SwiftUI

@MainActor
@Observable
final class SummaryViewModel {
    // MARK: - Properties
    private let bookId: String
    private let bookTitle: String
    private let bookAuthor: String
    private let aiService = AIService.shared
    
    // UI State
    enum ViewState {
        case loading
        case loaded(summary: String)
        case error(message: String)
    }
    
    var viewState: ViewState = .loading
    private(set) var existingSummary: String?
    private(set) var isGenerating = false
    
    // MARK: - Initialization
    init(bookId: String, bookTitle: String, bookAuthor: String, existingSummary: String?) {
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.existingSummary = existingSummary
    }
    
    // MARK: - Public Methods
    func generateSummary() async {
        // 既に生成中の場合は何もしない
        guard !isGenerating else { return }
        
        isGenerating = true
        viewState = .loading
        
        do {
            let summary = try await aiService.generateBookSummary(bookId: bookId)
            
            // アニメーションで表示
            withAnimation(.easeInOut(duration: 0.3)) {
                viewState = .loaded(summary: summary)
                existingSummary = summary
            }
        } catch {
            print("Error generating summary: \(error)")
            
            // エラーメッセージの取得
            let errorMessage: String
            if let appError = error as? AppError {
                switch appError {
                case .custom(let message):
                    errorMessage = message
                default:
                    errorMessage = "要約の生成に失敗しました"
                }
            } else {
                errorMessage = "要約の生成に失敗しました"
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                viewState = .error(message: errorMessage)
            }
        }
        
        isGenerating = false
    }
    
    func retry() async {
        await generateSummary()
    }
}

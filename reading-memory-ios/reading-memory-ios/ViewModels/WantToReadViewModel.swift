import Foundation
import SwiftUI

enum WantToReadSortOption: String, CaseIterable {
    case smart = "おすすめ順"
    case priority = "優先度順"
    case plannedDate = "読書予定日順"
    case addedDate = "追加日順"
    
    var icon: String {
        switch self {
        case .smart:
            return "sparkles"
        case .priority:
            return "star.fill"
        case .plannedDate:
            return "calendar"
        case .addedDate:
            return "clock"
        }
    }
}

@Observable
@MainActor
class WantToReadViewModel {
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var selectedSortOption: WantToReadSortOption = .smart
    
    private var bookStore: BookStore?
    
    func setBookStore(_ store: BookStore) {
        self.bookStore = store
    }
    
    // 読みたいリストの本を取得（フィルタリング＆ソート済み）
    var wantToReadBooks: [Book] {
        guard let bookStore = bookStore else { return [] }
        
        // 読みたいリストの本のみフィルタリング
        let filteredBooks = bookStore.allBooks.filter { $0.status == .wantToRead }
        
        // 選択されたソートオプションに基づいて並び替え
        return sortBooks(filteredBooks, by: selectedSortOption)
    }
    
    private func sortBooks(_ books: [Book], by option: WantToReadSortOption) -> [Book] {
        switch option {
        case .smart:
            return smartSort(books)
        case .priority:
            return prioritySort(books)
        case .plannedDate:
            return plannedDateSort(books)
        case .addedDate:
            return addedDateSort(books)
        }
    }
    
    // スマートソート：複合的な優先度計算
    private func smartSort(_ books: [Book]) -> [Book] {
        let now = Date()
        let calendar = Calendar.current
        
        return books.sorted { lhs, rhs in
            // スコア計算（高い方が優先）
            let lhsScore = calculateSmartScore(for: lhs, now: now, calendar: calendar)
            let rhsScore = calculateSmartScore(for: rhs, now: now, calendar: calendar)
            
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }
            
            // スコアが同じ場合は追加日でソート
            return lhs.addedDate > rhs.addedDate
        }
    }
    
    private func calculateSmartScore(for book: Book, now: Date, calendar: Calendar) -> Double {
        var score: Double = 0
        
        // 読書予定日のスコア（最大50ポイント）
        if let plannedDate = book.plannedReadingDate {
            let daysUntil = calendar.dateComponents([.day], from: now, to: plannedDate).day ?? 0
            
            if daysUntil < 0 {
                // 期限切れ：最高優先度
                score += 50
            } else if daysUntil <= 7 {
                // 1週間以内：高優先度
                score += 45 - Double(daysUntil) * 2
            } else if daysUntil <= 30 {
                // 1ヶ月以内：中優先度
                score += 35 - Double(daysUntil) * 0.5
            } else {
                // それ以降：低優先度
                score += 20
            }
            
            // リマインダーが有効な場合はボーナス
            if book.reminderEnabled {
                score += 5
            }
        }
        
        // 優先度スコア（最大25ポイント）
        if let priority = book.priority {
            score += Double(priority) * 5
        }
        
        // 追加からの経過日数（最大15ポイント）
        let daysSinceAdded = calendar.dateComponents([.day], from: book.addedDate, to: now).day ?? 0
        score += min(Double(daysSinceAdded) * 0.1, 15)
        
        return score
    }
    
    // 優先度ソート
    private func prioritySort(_ books: [Book]) -> [Book] {
        return books.sorted { lhs, rhs in
            // 優先度でソート（高い順）
            if let lhsPriority = lhs.priority, let rhsPriority = rhs.priority {
                if lhsPriority != rhsPriority {
                    return lhsPriority > rhsPriority
                }
            } else if lhs.priority != nil {
                return true
            } else if rhs.priority != nil {
                return false
            }
            
            // 優先度が同じまたは両方nilの場合は追加日でソート
            return lhs.addedDate > rhs.addedDate
        }
    }
    
    // 読書予定日ソート
    private func plannedDateSort(_ books: [Book]) -> [Book] {
        return books.sorted { lhs, rhs in
            // 両方に予定日がある場合
            if let lhsDate = lhs.plannedReadingDate, let rhsDate = rhs.plannedReadingDate {
                return lhsDate < rhsDate
            }
            // 片方だけ予定日がある場合は予定日ありを優先
            else if lhs.plannedReadingDate != nil {
                return true
            } else if rhs.plannedReadingDate != nil {
                return false
            }
            
            // 両方予定日なしの場合は優先度でソート
            if let lhsPriority = lhs.priority, let rhsPriority = rhs.priority {
                if lhsPriority != rhsPriority {
                    return lhsPriority > rhsPriority
                }
            }
            
            // 最後は追加日でソート
            return lhs.addedDate > rhs.addedDate
        }
    }
    
    // 追加日ソート
    private func addedDateSort(_ books: [Book]) -> [Book] {
        return books.sorted { lhs, rhs in
            lhs.addedDate > rhs.addedDate
        }
    }
    
    func changeSortOption(_ option: WantToReadSortOption) {
        selectedSortOption = option
    }
    
    func updateBookPriority(_ book: Book, priority: Int) async {
        guard let bookStore = bookStore else {
            errorMessage = "BookStoreが設定されていません"
            return
        }
        
        do {
            let updatedBook = book.updated(priority: priority)
            try await bookStore.updateBook(updatedBook)
        } catch {
            errorMessage = "優先度の更新に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func moveToReading(_ book: Book) async {
        guard let bookStore = bookStore else {
            errorMessage = "BookStoreが設定されていません"
            return
        }
        
        do {
            let updatedBook = book.updated(status: .reading, startDate: Date())
            try await bookStore.updateBook(updatedBook)
        } catch {
            errorMessage = "ステータスの更新に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func removeFromWantToRead(_ book: Book) async {
        guard let bookStore = bookStore else {
            errorMessage = "BookStoreが設定されていません"
            return
        }
        
        do {
            try await bookStore.deleteBook(id: book.id)
        } catch {
            errorMessage = "本の削除に失敗しました: \(error.localizedDescription)"
        }
    }
}
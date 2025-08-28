import Foundation
import UIKit

final class BookRepository {
    static let shared = BookRepository()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - CRUD Operations
    
    func getBook(bookId: String) async throws -> Book? {
        do {
            return try await apiClient.getBook(id: bookId)
        } catch {
            if let appError = error as? AppError,
               case .custom(let message) = appError,
               message.contains("404") {
                return nil
            }
            throw error
        }
    }
    
    func getBooks() async throws -> [Book] {
        return try await apiClient.getBooks()
    }
    
    func getBooksByStatus(status: ReadingStatus) async throws -> [Book] {
        let allBooks = try await getBooks()
        return allBooks.filter { $0.status == status }
    }
    
    func getBookByISBN(isbn: String) async throws -> Book? {
        let allBooks = try await getBooks()
        return allBooks.first { $0.isbn == isbn }
    }
    
    func createBook(_ book: Book) async throws -> Book {
        return try await apiClient.createBook(book)
    }
    
    /// 検索結果から本を作成（画像のアップロードを含む）
    func createBookFromSearchResult(_ searchResult: BookSearchResult, status: ReadingStatus = .wantToRead) async throws -> Book {
        var book = searchResult.toBook()
        
        // ステータスを設定
        book = Book(
            id: book.id,
            isbn: book.isbn,
            title: book.title,
            author: book.author,
            publisher: book.publisher,
            publishedDate: book.publishedDate,
            pageCount: book.pageCount,
            description: book.description,
            coverImageId: book.coverImageId,
            dataSource: book.dataSource,
            purchaseUrl: book.purchaseUrl,
            status: status,
            rating: book.rating,
            readingProgress: book.readingProgress,
            currentPage: book.currentPage,
            addedDate: book.addedDate,
            startDate: book.startDate,
            completedDate: book.completedDate,
            lastReadDate: book.lastReadDate,
            priority: book.priority,
            plannedReadingDate: book.plannedReadingDate,
            reminderEnabled: book.reminderEnabled,
            purchaseLinks: book.purchaseLinks,
            memo: book.memo,
            tags: book.tags,
            genre: book.genre,
            aiSummary: book.aiSummary,
            summaryGeneratedAt: book.summaryGeneratedAt,
            createdAt: book.createdAt,
            updatedAt: book.updatedAt
        )
        
        // coverImageUrlがある場合は画像をアップロード
        if let coverImageUrl = searchResult.coverImageUrl,
           let url = URL(string: coverImageUrl) {
            do {
                // 画像をダウンロード
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let image = UIImage(data: data) {
                    // 画像をアップロードしてIDを取得
                    let imageId = try await StorageService.shared.uploadImage(image)
                    
                    // bookのcoverImageIdを更新
                    book = Book(
                        id: book.id,
                        isbn: book.isbn,
                        title: book.title,
                        author: book.author,
                        publisher: book.publisher,
                        publishedDate: book.publishedDate,
                        pageCount: book.pageCount,
                        description: book.description,
                        coverImageId: imageId,  // アップロードしたimageIdを設定
                        dataSource: book.dataSource,
                        purchaseUrl: book.purchaseUrl,
                        status: book.status,
                        rating: book.rating,
                        readingProgress: book.readingProgress,
                        currentPage: book.currentPage,
                        addedDate: book.addedDate,
                        startDate: book.startDate,
                        completedDate: book.completedDate,
                        lastReadDate: book.lastReadDate,
                        priority: book.priority,
                        plannedReadingDate: book.plannedReadingDate,
                        reminderEnabled: book.reminderEnabled,
                        purchaseLinks: book.purchaseLinks,
                        memo: book.memo,
                        tags: book.tags,
                        genre: book.genre,
                        aiSummary: book.aiSummary,
                        summaryGeneratedAt: book.summaryGeneratedAt,
                        createdAt: book.createdAt,
                        updatedAt: book.updatedAt
                    )
                }
            } catch {
                // 画像のアップロードに失敗してもbook作成は続行
                print("Failed to upload cover image: \(error)")
            }
        }
        
        return try await apiClient.createBook(book)
    }
    
    func updateBook(_ book: Book) async throws {
        _ = try await apiClient.updateBook(book)
    }
    
    func deleteBook(bookId: String) async throws {
        try await apiClient.deleteBook(id: bookId)
    }
    
    // MARK: - Convenience Methods
    
    func deleteBook(_ bookId: String) async throws {
        try await deleteBook(bookId: bookId)
    }
    
    // 読みたいリスト関連
    func getWantToReadBooks() async throws -> [Book] {
        return try await getBooksByStatus(status: .wantToRead)
    }
    
    // 統計用
    func getCompletedBooksCount() async throws -> Int {
        let books = try await getBooksByStatus(status: .completed)
        return books.count
    }
    
    func getReadingBooksCount() async throws -> Int {
        let books = try await getBooksByStatus(status: .reading)
        return books.count
    }
    
    // 指定日以降の本の数を取得
    func getBookCount(userId: String, since date: Date) async -> Int {
        do {
            let books = try await getBooks()
            return books.filter { $0.addedDate >= date }.count
        } catch {
            print("Error getting book count: \(error)")
            return 0
        }
    }
}

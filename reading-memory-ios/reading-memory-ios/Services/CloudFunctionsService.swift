import Foundation
import FirebaseFunctions

final class CloudFunctionsService {
    static let shared = CloudFunctionsService()
    
    private lazy var functions = Functions.functions(region: "asia-northeast1")
    
    private init() {}
    
    // MARK: - 書籍検索
    
    func searchBookByISBN(_ isbn: String) async throws -> [Book] {
        let callable = functions.httpsCallable("searchBookByISBN")
        
        do {
            let result = try await callable.call(["isbn": isbn])
            
            guard let data = result.data as? [String: Any],
                  let booksData = data["books"] as? [[String: Any]] else {
                throw NSError(domain: "CloudFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            
            return booksData.compactMap { bookData in
                parseBookFromCloudFunction(bookData)
            }
        } catch {
            print("Cloud Functions error: \(error)")
            throw error
        }
    }
    
    func searchBooksByQuery(_ query: String) async throws -> [Book] {
        let callable = functions.httpsCallable("searchBooksByQuery")
        
        do {
            let result = try await callable.call(["query": query])
            
            guard let data = result.data as? [String: Any],
                  let booksData = data["books"] as? [[String: Any]] else {
                throw NSError(domain: "CloudFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            
            return booksData.compactMap { bookData in
                parseBookFromCloudFunction(bookData)
            }
        } catch {
            print("Cloud Functions error: \(error)")
            throw error
        }
    }
    
    // MARK: - 公開本の取得
    
    func getPopularBooks(limit: Int = 20) async throws -> [Book] {
        let callable = functions.httpsCallable("getPopularBooks")
        
        do {
            let result = try await callable.call(["limit": limit])
            
            guard let data = result.data as? [String: Any],
                  let booksData = data["books"] as? [[String: Any]] else {
                throw NSError(domain: "CloudFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            
            return booksData.compactMap { bookData in
                parseBookFromFirestore(bookData)
            }
        } catch {
            print("Cloud Functions error: \(error)")
            throw error
        }
    }
    
    func getRecentBooks(limit: Int = 20) async throws -> [Book] {
        let callable = functions.httpsCallable("getRecentBooks")
        
        do {
            let result = try await callable.call(["limit": limit])
            
            guard let data = result.data as? [String: Any],
                  let booksData = data["books"] as? [[String: Any]] else {
                throw NSError(domain: "CloudFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            
            return booksData.compactMap { bookData in
                parseBookFromFirestore(bookData)
            }
        } catch {
            print("Cloud Functions error: \(error)")
            throw error
        }
    }
    
    func searchPublicBooks(query: String, limit: Int = 20) async throws -> [Book] {
        let callable = functions.httpsCallable("searchPublicBooks")
        
        do {
            let result = try await callable.call(["query": query, "limit": limit])
            
            guard let data = result.data as? [String: Any],
                  let booksData = data["books"] as? [[String: Any]] else {
                throw NSError(domain: "CloudFunctions", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }
            
            return booksData.compactMap { bookData in
                parseBookFromFirestore(bookData)
            }
        } catch {
            print("Cloud Functions error: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func parseBookFromCloudFunction(_ data: [String: Any]) -> Book? {
        guard let title = data["title"] as? String,
              let author = data["author"] as? String,
              let dataSourceString = data["dataSource"] as? String else {
            return nil
        }
        
        let dataSource: BookDataSource
        switch dataSourceString {
        case "googleBooks":
            dataSource = .googleBooks
        case "openBD":
            dataSource = .openBD
        default:
            dataSource = .manual
        }
        
        // 出版日の変換
        var publishedDate: Date?
        if let dateString = data["publishedDate"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            publishedDate = formatter.date(from: dateString)
        }
        
        return Book.new(
            isbn: data["isbn"] as? String,
            title: title,
            author: author,
            publisher: data["publisher"] as? String,
            publishedDate: publishedDate,
            pageCount: data["pageCount"] as? Int,
            description: data["description"] as? String,
            coverImageUrl: data["coverImageUrl"] as? String,
            dataSource: dataSource,
            visibility: .public  // APIから取得した本は常にpublic
        )
    }
    
    private func parseBookFromFirestore(_ data: [String: Any]) -> Book? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let author = data["author"] as? String else {
            return nil
        }
        
        // データソースとビジビリティの解析
        let dataSource: BookDataSource = {
            if let dataSourceString = data["dataSource"] as? String,
               let source = BookDataSource(rawValue: dataSourceString) {
                return source
            }
            return .manual
        }()
        
        let visibility: BookVisibility = {
            if let visibilityString = data["visibility"] as? String,
               let vis = BookVisibility(rawValue: visibilityString) {
                return vis
            }
            return .private
        }()
        
        // 出版日の変換
        var publishedDate: Date?
        if let timestamp = data["publishedDate"] as? [String: Any],
           let seconds = timestamp["_seconds"] as? Double {
            publishedDate = Date(timeIntervalSince1970: seconds)
        } else if let dateString = data["publishedDate"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            publishedDate = formatter.date(from: dateString)
        }
        
        // 作成日の変換
        var createdAt: Date?
        if let timestamp = data["createdAt"] as? [String: Any],
           let seconds = timestamp["_seconds"] as? Double {
            createdAt = Date(timeIntervalSince1970: seconds)
        }
        
        return Book(
            id: id,
            isbn: data["isbn"] as? String,
            title: title,
            author: author,
            publisher: data["publisher"] as? String,
            publishedDate: publishedDate,
            pageCount: data["pageCount"] as? Int,
            description: data["description"] as? String,
            coverImageUrl: data["coverImageUrl"] as? String,
            dataSource: dataSource,
            visibility: visibility,
            createdAt: createdAt ?? Date(),
            updatedAt: Date()
        )
    }
}
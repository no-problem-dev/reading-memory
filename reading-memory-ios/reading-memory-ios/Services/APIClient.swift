import Foundation
import FirebaseAuth

/// REST APIクライアント
final class APIClient {
    static let shared = APIClient()
    
    private let baseURL: String
    private let session: URLSession
    
    private init() {
        self.baseURL = Config.shared.apiBaseURL
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Request Methods
    
    private func makeRequest(
        method: String,
        path: String,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> URLRequest {
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw AppError.custom("無効なURLです")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Firebase IDトークンを取得して設定
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        return request
    }
    
    private func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.custom("無効なレスポンスです")
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw AppError.custom("レスポンスの解析に失敗しました")
            }
        } else {
            // エラーレスポンスの解析
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AppError.custom(errorResponse.error.message)
            } else {
                throw AppError.custom("サーバーエラーが発生しました (\(httpResponse.statusCode))")
            }
        }
    }
    
    // MARK: - Public Methods
    
    // MARK: AI関連
    
    func generateAIResponse(userId: String, userBookId: String, message: String) async throws -> AIResponseResult {
        let body = try JSONEncoder().encode([
            "message": message
        ])
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/users/\(userId)/books/\(userBookId)/ai-response",
            body: body
        )
        
        return try await execute(request, responseType: AIResponseResult.self)
    }
    
    func generateBookSummary(userId: String, userBookId: String) async throws -> SummaryResult {
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/users/\(userId)/books/\(userBookId)/summary"
        )
        
        return try await execute(request, responseType: SummaryResult.self)
    }
    
    // MARK: 書籍検索
    
    func searchBookByISBN(_ isbn: String) async throws -> BookSearchResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/books/search/isbn/\(isbn)"
        )
        
        return try await execute(request, responseType: BookSearchResult.self)
    }
    
    func searchBooksByQuery(_ query: String) async throws -> BookSearchResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/books/search",
            queryItems: [URLQueryItem(name: "q", value: query)]
        )
        
        return try await execute(request, responseType: BookSearchResult.self)
    }
    
    // MARK: 公開本
    
    func getPopularBooks(limit: Int = 20) async throws -> PublicBooksResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/public/books/popular",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
        
        return try await execute(request, responseType: PublicBooksResult.self)
    }
    
    func getRecentBooks(limit: Int = 20) async throws -> PublicBooksResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/public/books/recent",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
        
        return try await execute(request, responseType: PublicBooksResult.self)
    }
    
    func searchPublicBooks(query: String, limit: Int = 20) async throws -> PublicBooksResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/public/books/search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
        
        return try await execute(request, responseType: PublicBooksResult.self)
    }
    
    // MARK: アカウント管理
    
    func deleteAccount() async throws -> DeleteAccountResult {
        let request = try await makeRequest(
            method: "DELETE",
            path: "/api/v1/users/me"
        )
        
        return try await execute(request, responseType: DeleteAccountResult.self)
    }
}

// MARK: - Response Types

struct ErrorResponse: Decodable {
    let error: ErrorDetail
    
    struct ErrorDetail: Decodable {
        let code: String
        let message: String
    }
}

struct AIResponseResult: Decodable {
    let success: Bool
    let chatId: String
    let message: String
}

struct SummaryResult: Decodable {
    let success: Bool
    let summary: String
}

struct BookSearchResult: Decodable {
    let books: [APIBookDTO]
}

struct PublicBooksResult: Decodable {
    let books: [APIBookDTO]
}

struct DeleteAccountResult: Decodable {
    let success: Bool
    let deletedCollections: [String]
    let errors: [String]
}